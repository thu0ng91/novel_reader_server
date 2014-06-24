# encoding: utf-8
class Crawler::Rijigu
  include Crawler
  include Capybara::DSL

  def crawl_articles novel_id
    url = "http://www.rijigu.com"
    nodes = @page_html.css("a.J_chapter")
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
    set_novel_last_update_and_num(novel_id)
  end

  def crawl_article article
    link = article.link
    Capybara.current_driver = :selenium
    Capybara.app_host = "http://book.rijigu.com"
    page.visit(link.gsub("http://book.rijigu.com",""))

    text = page.find("#content").native.text
    text = ZhConv.convert("zh-tw", text)
    raise 'Do not crawl the article text ' unless isArticleTextOK(article,text)
    ArticleText.update_or_create(article_id: article.id, text: text)
  end

end