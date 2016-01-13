# encoding: utf-8
class Crawler::Zhaishu
  include Crawler

  def crawl_articles novel_id
    url = @page_url.gsub("Index.shtm","")
    nodes = @page_html.css("#BookText a")
    do_not_crawl = true
    nodes.each do |node|
      do_not_crawl = false if crawl_this_article(novel_id,node[:href])
      next if do_not_crawl
      
      article = Article.select("articles.id, is_show, title, link, novel_id, subject, num").find_by_link(url + node[:href])
      next if article

      unless article 
        article = Article.new
        article.novel_id = novel_id
        article.link = url + node[:href]
        article.title = ZhConv.convert("zh-tw",node.text.strip,false)
        novel = Novel.select("id,num,name").find(novel_id)
        article.subject = novel.name
        article.num = novel.num + 1
        novel.num = novel.num + 1
        novel.save
        article.save
      end
      ArticleWorker.perform_async(article.id)
    end
    set_novel_last_update_and_num(novel_id)
  end

  def crawl_article article
    node = @page_html.css("#texts")
    node.css("script,a,h2").remove
    text = change_node_br_to_newline(node).strip
    text = text.gsub("完结穿越小说推荐：","")
    text = text.gsub("\r\n","")
    text = ZhConv.convert("zh-tw", text.strip, false)

    if text.length < 100
      imgs = @page_html.css("#imgbook")
      text_img = ""
      imgs.each do |img|
        text_img = text_img + "http://www.zhaishu.com" + img[:src] + "*&&$$*"
      end
      text_img = text_img + "如果看不到圖片, 請更新至新版APP"
      text = text_img
    end

    raise 'Do not crawl the article text ' unless isArticleTextOK(article,text)
    ArticleText.update_or_create(article_id: article.id, text: text)
  end

end