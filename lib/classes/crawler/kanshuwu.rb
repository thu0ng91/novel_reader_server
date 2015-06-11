# encoding: utf-8
class Crawler::Kanshuwu
  include Crawler

  def crawl_article article

    node = @page_html.css("#content")
    text = change_node_br_to_newline(node).strip
    text = ZhConv.convert("zh-tw", text.strip)

    if text.length < 150
      imgs = @page_html.css("#content img")
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

  def crawl_articles novel_id
    url = "http://www.kanshuwu.net"
    nodes = @page_html.css(".zjbox ul li a")
    nodes.each do |node|
      article = Article.select("articles.id, is_show, title, link, novel_id, subject, num").find_by_link(url + node[:href])
      next if article

      unless article 
      article = Article.new
      article.novel_id = novel_id
      article.link = url + node[:href]
      article.title = ZhConv.convert("zh-tw",node.text.strip)
      novel = Novel.select("id,num,name").find(novel_id)
      article.subject = novel.name
      article.num = novel.num + 1
      novel.num = novel.num + 1
      novel.save
      article.save
      end
      ArticleWorker.perform_async(article.id)
    end
  end

end