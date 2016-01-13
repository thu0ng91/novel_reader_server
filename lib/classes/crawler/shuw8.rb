# encoding: utf-8
class Crawler::Shuw8
  include Crawler

  def crawl_articles novel_id
    nodes = @page_html.css(".indexlist a")
    do_not_crawl = true
    nodes.each do |node|
      do_not_crawl = false if crawl_this_article(novel_id,node[:href])
      next if do_not_crawl
      
      if novel_id == 18838
        do_not_crawl = false if node[:href] == "http://tw.8shuw.net/book/7634/8364035.html"
        next if do_not_crawl
      end
      if novel_id == 21195
        do_not_crawl = false if node[:href] == "http://tw.8shuw.net/book/7816/8542085.html"
        next if do_not_crawl
      end
      article = Article.select("articles.id, is_show, title, link, novel_id, subject, num").find_by_link(node[:href])
      next if article

      unless article 
        article = Article.new
        article.novel_id = novel_id
        article.link = node[:href]
        article.title = node.text.strip
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
    node = @page_html.css("#content")
    node.css(".ad,.prevue,#adtxt0,script,iframe,style").remove
    text = change_node_br_to_newline(node).strip
    if text.length < 100
      imgs = @page_html.css(".divimage img")
      text_img = ""
      imgs.each do |img|
          text_img = text_img + img[:src] + "*&&$$*"
      end
      text_img = text_img + "如果看不到圖片, 請更新至新版"
      text = text_img
    end
    raise 'Do not crawl the article text ' unless isArticleTextOK(article,text)
    ArticleText.update_or_create(article_id: article.id, text: text)
  end

end