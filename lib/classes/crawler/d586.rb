# encoding: utf-8
class Crawler::D586
  include Crawler

  def crawl_articles novel_id
    nodes = @page_html.css(".ml_main dd a")

    novel = Novel.select("id,num,name").find(novel_id)
    subject = novel.name
    nodes.each do |node|
      article = Article.select("articles.id, is_show, title, link, novel_id, subject, num").find_by_link(node[:href])
      next if article

      unless article 
        article = Article.new
        article.novel_id = novel_id
        article.link = node[:href]
        article.title = ZhConv.convert("zh-tw",node.text.strip)
        article.subject = subject
        article.num = novel.num + 1
        novel.num = novel.num + 1
        novel.save
        article.save
      end
      # novel.num = article.num + 1
      # novel.save
      ArticleWorker.perform_async(article.id)
    end
    set_novel_last_update_and_num(novel_id)
  end

  def crawl_article article
    node = @page_html.css(".content")
    node = @page_html.css(".yd_text2") unless node.present?
    node.css("a").remove
    node.css("script").remove
    text = change_node_br_to_newline(node)
    text = ZhConv.convert("zh-tw", text.strip)
    raise 'Do not crawl the article text ' unless isArticleTextOK(article,text)
    ArticleText.update_or_create(article_id: article.id, text: text)
  end

end