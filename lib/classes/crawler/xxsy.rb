# encoding: utf-8
class Crawler::Xxsy
  include Crawler

  def crawl_articles novel_id
    url = @page_url.sub("default.html","")
    nodes = @page_html.css("#catalog_list a")
    nodes.each do |node|
      article = Article.select("articles.id, is_show, title, link, novel_id, subject, num").find_by_link(url + node[:href])
      next if isArticleTextOK(article,article.article_all_text) if article

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
    @page_html.css("#zjcontentdiv a").remove
    text = @page_html.css("#zjcontentdiv").text.strip
    article_text = ZhConv.convert("zh-tw",text)
    text = article_text
    raise 'Do not crawl the article text ' unless isArticleTextOK(article,text)
    ArticleText.update_or_create(article_id: article.id, text: text)
  end

end