# encoding: utf-8
class Crawler::Jjwxc
  include Crawler

  def crawl_articles novel_id
    nodes = @page_html.css("#oneboolt a")
    nodes.each do |node|
      next unless node[:href] && node[:href].index('chapterid')
      article = Article.find_by_link(node[:href])
      next if isSkipCrawlArticle(article)
      

      unless article 
        article = Article.new
        article.novel_id = novel_id
        article.link = node[:href]
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
    node = @page_html.css(".noveltext")
    node.css("a").remove
    node.css("font").remove
    node.css("span").remove
    node.css("script").remove
    text = change_node_br_to_newline(node).strip.gsub("[]","").gsub("  ","").gsub("\n\n","")
    article.text = ZhConv.convert("zh-tw", text.strip)
    article.save
  end

end