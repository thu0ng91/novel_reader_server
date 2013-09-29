# encoding: UTF-8

class Api::V1::ArticlesController < Api::ApiController

  MESSAGE = "\n  十分抱歉，之前伺服器出了問題，所以用暫時的伺服器給大家使用！\n\n現在已更換到新伺服器，如果你從書籤進入，看到這個訊息, 請你:\n  (1)刪除書籤\n  (2)從小說介紹頁重新進入小說閱讀頁即可 \n  如果還是沒有文章，你可以使用上方的問題回報按鈕寄信給我們，謝謝！"

  def index
    novel_id = params[:novel_id]
    order = params[:order]

    if order == "true"
      articles = Article.where('novel_id = (?)', novel_id).show.select("id,title,subject")
    else
      articles = Article.where('novel_id = (?)', novel_id).show.select("id,title,subject").by_id_desc
    end

    render :json => articles
  end

  # def db_transfer_index
  #   novel_id = params[:novel_id]
  #   articles = Article.where('novel_id = (?)', novel_id).select("id,title,subject,link,novel_id")

  #   render :json => articles
  # end

  def show
    begin
      article = Article.joins(:article_text).select("text, title").find(params[:id])
      if article.text.nil?
        render :json => {title: article.title, text: MESSAGE}.to_json
      else
        render :json => article
      end
    rescue
      render :json => {title: "", text: MESSAGE}.to_json
    end
  end

  def next_article
    next_article = Article.find_next_article(params[:article_id].to_i,params[:novel_id])
    render :json => next_article
  end

  def previous_article
    previous_article = Article.find_previous_article(params[:article_id].to_i,params[:novel_id])
    render :json => previous_article
  end

  def articles_by_num
    novel_id = params[:novel_id]
    order = params[:order]

    if order == "true"
      articles = Article.where('novel_id = (?)', novel_id).show.select("id,title,subject,num").by_num_asc
    else
      articles = Article.where('novel_id = (?)', novel_id).show.select("id,title,subject,num").by_num_desc
    end

    render :json => articles
  end

  def next_article_by_num
    params[:num] = Article.select("num").find(params[:article_id]).num if(params[:num] == "0")
    articles = Article.select("id").where("novel_id = #{params[:novel_id]} and num > #{params[:num]}").show.by_num_asc
    if articles.length > 0
      render :json => Article.joins(:article_text).select('articles.id, novel_id, text, title,num').find(articles[0].id)
    else
      render :json => nil
    end
  end

  def previous_article_by_num
    params[:num] = Article.select("num").find(params[:article_id]).num if(params[:num] == "0")
    articles = Article.select("id").where("novel_id = #{params[:novel_id]} and num < #{params[:num]}").show.by_num_desc
    if articles.length > 0
      render :json => Article.joins(:article_text).select('articles.id, novel_id, text, title,num').find(articles[articles.length-1].id)
    else
      render :json => nil
    end
  end

end
