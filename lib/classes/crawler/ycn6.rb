# encoding: utf-8
class Crawler::Ycn6
  include Crawler
  
  def crawl_article article
    @page_html.css("#content style, #content .pagesloop").remove
    text = @page_html.css("#content").text.strip
    article_text = ZhConv.convert("zh-tw",text)
    article.text = article_text
    raise 'Do not crawl the article text ' unless isArticleTextOK(article)
    article.save
  end

end