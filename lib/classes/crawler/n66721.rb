# encoding: utf-8
class Crawler::N66721
  include Crawler

  def crawl_articles novel_id
    nodes = @page_html.css(".body .dirlist")
    nodes = nodes[1].css('a')
    do_not_crawl = true
    nodes.each do |node|
      do_not_crawl = false if crawl_this_article(novel_id,node[:href])
      next if do_not_crawl
      
      if novel_id == 22525
        do_not_crawl = false if node[:href] == "/ZhiMo/976.html"
        next if do_not_crawl
      end
      if novel_id == 21315
        do_not_crawl = false if node[:href] == "/YiDongCangJingGe/1752.html"
        next if do_not_crawl
      end
      if novel_id == 18489
        do_not_crawl = false if node[:href] == "/QuanQiuGuaiWuZaiXian/1353.html"
        next if do_not_crawl
      end
      if novel_id == 21541
        do_not_crawl = false if node[:href] == "/CangLangXing/1059.html"
        next if do_not_crawl
      end
      
      article = Article.select("articles.id, is_show, title, link, novel_id, subject, num").find_by_link(get_article_url(node[:href]))
      next if article

      unless article 
        article = Article.new
        article.novel_id = novel_id
        article.link = get_article_url(node[:href])
        article.title = ZhConv.convert("zh-tw",node.text.strip,false)
        novel = Novel.select("id,num,name").find(novel_id)
        article.subject = novel.name
        article.num = novel.num + 1
        novel.num = novel.num + 1
        novel.save
        article.save
      end
      ArticleWorker.perform_async(article.id)
    end
    set_novel_last_update_and_num(novel_id)
  end

  def crawl_article article
    node = @page_html.css("#chaptercontent")
    node.css("font,a,script").remove
    text = change_node_br_to_newline(node).strip
    text = ZhConv.convert("zh-tw", text.strip, false)
    raise 'Do not crawl the article text ' unless isArticleTextOK(article,text)
    ArticleText.update_or_create(article_id: article.id, text: text)
  end

end