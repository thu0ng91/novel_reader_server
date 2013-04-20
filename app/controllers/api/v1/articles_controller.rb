class Api::V1::ArticlesController < Api::ApiController
  def index
    novel_id = params[:novel_id]
    order = params[:order]

    if order == "true"
      articles = Article.where('novel_id = (?)', novel_id).select("id,title,subject")
    else
      articles = Article.where('novel_id = (?)', novel_id).select("id,title,subject").by_id_desc
    end

    render :json => articles
  end

  def show
    article = Article.select("text, title").find(params[:id])
    render :json => article
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
      articles = Article.where('novel_id = (?)', novel_id).select("id,title,subject").by_num_asc
    else
      articles = Article.where('novel_id = (?)', novel_id).select("id,title,subject").by_num_desc
    end

    render :json => articles
  end

  def article_by_num
    next_article = Article.select("id,title,subject").where("novel_id = #{params[:novel_id]} and num = #{params[:num]}")
    if next_article.present?
      render :json => next_article[0]
    else
      render :json => nil
    end
  end

end
