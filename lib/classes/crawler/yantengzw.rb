# encoding: utf-8
class Crawler::Yantengzw
  include Crawler
  
  def crawl_article article
    nodes = @page_html.css("#htmlContent")
    text  = change_node_br_to_newline(nodes)
    article_text = ZhConv.convert("zh-tw", text)
    text = article_text
    raise 'Do not crawl the article text ' unless isArticleTextOK(article,text)
    ArticleText.update_or_create(article_id: article.id, text: text)
  end

end