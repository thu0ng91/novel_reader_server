# encoding: utf-8
class Crawler::Dmzj
  include Crawler

  def crawl_articles novel_id
    nodes = @page_html.css(".download_rtx")
    # do_not_crawl = true
    nodes.each do |node|
      node.css("ol li span").remove
      subject = ZhConv.convert("zh-tw",node.css("ol li").text.strip,false)
      a_nodes = node.css("ul li a")
      a_nodes.each do |a_node|
        # if novel_id == 23463
        #   do_not_crawl = false if a_node[:href] == '/b/30530/119958.html'
        #   next if do_not_crawl
        # end
        article = Article.select("articles.id, is_show, title, link, novel_id, subject, num").find_by_link(get_article_url(a_node[:href]))
        next if article

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = get_article_url(a_node[:href])
          article.title = ZhConv.convert("zh-tw",a_node.text.strip,false)
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
    set_novel_last_update_and_num(novel_id)
  end

  def crawl_article article
    article_text = ""
    links = @page_html.css('.pages a')
    links.each_with_index do |link,index|
      next if(index == 0 || index == links.size - 1 || index == links.size - 2) 
      c = Crawler::NovelCrawler.new
      c.fetch get_article_url(link[:href])
      node = c.page_html.css("#novel_contents")
      node.css("script,a").remove
      text = change_node_br_to_newline(node).strip
      text = ZhConv.convert("zh-tw", text.strip, false)
      article_text += text
    end
    text = article_text

    raise 'Do not crawl the article text ' unless isArticleTextOK(article,text)
    ArticleText.update_or_create(article_id: article.id, text: text)
  end

end