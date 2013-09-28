# encoding: utf-8
class Crawler::Ranwenxiaoshuo
  include Crawler

  def crawl_articles novel_id
    url = "http://www.ranwenxiaoshuo.com"
    nodes = @page_html.css("div.uclist dd a")
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
        # puts node.text
        article.save
      end
      ArticleWorker.perform_async(article.id)
    end
  end

  def crawl_article article
    # the site may change content web element, use carefully
    # sometimes can't reach content by sidekiq
    text = @page_html.css("p").text.strip
    text = text.gsub("求金牌、求收藏、求推荐、求点击、求评论、求红包、求礼物，各种求，有什么要什么，都砸过来吧！","").strip
    text = text.gsub("小窍门：按左右键快速翻到上下章节","").strip
    text = ZhConv.convert("zh-tw", text)
    
    if text.length < 100
      imgs = @page_html.css("p img")
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