# encoding: utf-8
class Crawler::Daomuxsw
  include Crawler

  def crawl_articles novel_id
    subject = ""
    nodes = @page_html.css(".mainbody td")
    url = @page_url.gsub("index.html","")
    do_not_crawl = true
    nodes.each do |node|
      if node[:class] == "vcss"
        subject = ZhConv.convert("zh-tw",node.text.strip,false)
      else
        a_nodes = node.css("a")
        a_nodes.each do |a_node|
          next if a_node.nil?
          do_not_crawl = false if crawl_this_article(novel_id,a_node[:href]))
          next if do_not_crawl

          article = Article.select("articles.id, is_show, title, link, novel_id, subject, num").find_by_link(url + a_node[:href])
          next if article
          unless article 
            article = Article.new
            article.novel_id = novel_id
            article.link = url + a_node[:href]
            article.title = ZhConv.convert("zh-tw",a_node.text.strip,false)
            novel = Novel.select("id,num,name").find(novel_id)
            article.subject = subject
            /(\d*)\.html/ =~ a_node[:href]
            next unless $1
            article.num = $1.to_i + novel.num
            novel.num = novel.num + 1
            novel.save
            # puts node.text
            article.save
          end
          ArticleWorker.perform_async(article.id)
        end  
      end
    end
    set_novel_last_update_and_num(novel_id)
  end

  def crawl_article article
    node = @page_html.css("#content")
    text = node.text.strip
    text.encode!("utf-8", :undef => :replace, :replace => "?", :invalid => :replace)
    text = ZhConv.convert("zh-tw", text.strip, false)
    raise 'Do not crawl the article text ' unless isArticleTextOK(article,text)
    ArticleText.update_or_create(article_id: article.id, text: text)
  end

end