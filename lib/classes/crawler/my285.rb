# encoding: utf-8
class Crawler::My285
  include Crawler

  def crawl_articles novel_id
    url = @page_url.sub("index.htm","")
    @page_html.css("div tr td a").first.remove
    @page_html.css("div tr td a").first.remove
    @page_html.css("div tr td a").last.remove
    @page_html.css("div tr td a").last.remove
    nodes = @page_html.css("div tr td a")
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
    text = change_node_br_to_newline(@page_html.css("tr")[4]).strip
    text = ZhConv.convert("zh-tw", text)
    raise 'Do not crawl the article text ' unless isArticleTextOK(article,text)
    ArticleText.update_or_create(article_id: article.id, text: text)
  end

end