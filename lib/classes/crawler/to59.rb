# encoding: utf-8
class Crawler::To59
  include Crawler

  def crawl_articles novel_id
    url = @page_url
    subject = ""
    nodes = @page_html.css(".acss").children
    nodes.each do |node|
      if node.children.children[0].name == "h2"
        subject = ZhConv.convert("zh-tw",node.children.text.strip)
      elsif (node.children.children[0].name == "a")
        inside_nodes = node.children.children
        inside_nodes.each do |n|
          if n[:href] != nil
            article = Article.find_by_link(url + n[:href])
            next if isSkipCrawlArticle(article)

            unless article 
            article = Article.new
            article.novel_id = novel_id
            article.link = url + n[:href]
            article.title = ZhConv.convert("zh-tw",n.text.strip)
            novel = Novel.select("id,num,name").find(novel_id)
            article.subject = subject
            article.num = novel.num + 1
            novel.num = novel.num + 1
            novel.save
            # puts node.text
            article.save
            end
            ArticleWorker.perform_async(article.id)
          end  
        end                  
      end
    end
  end

  def crawl_article article
    @page_html.css("#content a").remove
    text = @page_html.css("#content").text
    article_text = text.gsub("*** 现在加入59文学，和万千书友交流阅读乐趣！59文学永久地址：www.59to.com ***", "")
    final_text = ZhConv.convert("zh-tw",article_text.strip)
    article.text = final_text
    if (article_text.length < 250)
      imgs = @page_html.css(".divimage img")
      text_img = ""
      imgs.each do |img|
          text_img = text_img + img[:src] + "*&&$$*"
      end
      text_img = text_img + "如果看不到圖片, 請更新至新版APP"
      article_text = text_img
    end
    article.save
  end

end