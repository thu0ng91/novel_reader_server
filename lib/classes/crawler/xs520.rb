# encoding: utf-8
class Crawler::Xs520
  include Crawler

  def crawl_articles novel_id
    nodes = @page_html.css("#list dl").children
    subject = ""
    nodes.each do |node|
      
      if node[:id] == "qw"
        subject = node.text
        puts subject
      elsif node.css("a")[0]
        node = node.css("a")[0]
        article = Article.find_by_link("http://www.520xs.com" + node[:href])
        next if isArticleTextOK(article)

        unless article
          article = Article.new
          article.novel_id = novel_id
          article.link = "http://www.520xs.com" + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          if(subject == "")
            subject = novel.name
          end
          article.subject = ZhConv.convert("zh-tw",subject)
          /(\d*)\/\z/ =~ node[:href]
          article.num = $1.to_i
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    end
  end

  def crawl_article article
    @page_html.css("#TXT a").remove
    node = @page_html.css("#TXT")
    text = change_node_br_to_newline(node).strip
    text = text.gsub("最新章节","")
    text = text.gsub("TXT下载","")
    text = text.gsub("520小说提供无弹窗全文字在线阅读，更新速度更快文章质量更好，如果您觉得520小说网不错就多多分享本站!谢谢各位读者的支持!","")
    text = text.gsub("520小说高速首发","")
    text = text.gsub(/本章节是.*地址为/,"")
    text = text.gsub("如果你觉的本章节还不错的话请不要忘记向您QQ群和微博里的朋友推荐哦！","")
    article.text = ZhConv.convert("zh-tw", text)
    raise 'Do not crawl the article text ' unless isArticleTextOK(article)
    article.save
  end

end