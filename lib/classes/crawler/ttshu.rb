# encoding: utf-8
class Crawler::Ttshu
  include Crawler
  
  def crawl_article article
    imgs = @page_html.css("#253 img")
    text_img = ""
    imgs.each do |img|
        text_img = text_img + "http://www.ttshu.com" + img[:src] + "*&&$$*"
    end
    text_img = text_img + "如果看不到圖片, 請更新至新版APP"
    article.text = text_img
    article.save
  end

end