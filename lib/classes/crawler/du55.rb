# encoding: utf-8
class Crawler::Du55
  include Crawler

  def crawl_articles novel_id
    nodes = @page_html.css("li.chapter a")
    nodes.each do |node|

      link = node[:href]
      article = Article.select("articles.id, is_show, title, link, novel_id, subject, num").find_by_link(link)
      next if article

      unless article 
        article = Article.new
        article.novel_id = novel_id
        article.link = link
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
    set_novel_last_update_and_num(novel_id)
  end


  def crawl_article article

    node = @page_html.css("#content")
    node.css("a,script").remove
    text = change_node_br_to_newline(node).strip
    text = ZhConv.convert("zh-tw", text.strip)

    raise 'Do not crawl the article text ' unless isArticleTextOK(article,text)
    ArticleText.update_or_create(article_id: article.id, text: text)
  end

end