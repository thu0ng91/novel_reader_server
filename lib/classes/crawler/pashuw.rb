# encoding: utf-8
class Crawler::Pashuw
  include Crawler

  def crawl_articles novel_id
    novel = Novel.select("id,num,name").find(novel_id)
    subject = novel.name
    nodes = @page_html.css(".acss tr td")
    url = @page_url.gsub("index.html","")
    nodes.each do |node|
      if node[:class] == "vcss"
        subject = ZhConv.convert("zh-tw",node.text.strip,false)
      else
        a_node = node.css("a")[0]
        next if a_node.nil?
        article = Article.select("articles.id, is_show, title, link, novel_id, subject, num").find_by_link(a_node[:href])
        next if article
        unless article 
        article = Article.new
        article.novel_id = novel_id
        article.link = a_node[:href]
        article.title = ZhConv.convert("zh-tw",a_node.text.strip,false)
        article.subject = subject
        article.num = novel.num + 1
        novel.num = novel.num + 1
        novel.save
        # puts node.text
        article.save
        end
        ArticleWorker.perform_async(article.id)    
      end
    end
    set_novel_last_update_and_num(novel_id)
  end

  def crawl_article article
    @page_html.css("#novel_content a").remove
    @page_html.css("#novel_content script").remove
    node = @page_html.css("#novel_content")
    text = change_node_br_to_newline(node).strip
    text = ZhConv.convert("zh-tw", text,false)
    
    if text.length < 150
      imgs = @page_html.css("#novel_content .divimage img")
      text_img = ""
      imgs.each do |img|
          text_img = text_img + img[:src] + "*&&$$*"
      end
      text_img = text_img + "如果看不到圖片, 請更新至新版APP"
      text = text_img
    end

    raise 'Do not crawl the article text ' unless isArticleTextOK(article,text)
    ArticleText.update_or_create(article_id: article.id, text: text)
  end

end