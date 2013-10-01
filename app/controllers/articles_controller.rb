class ArticlesController < ApplicationController
  
  def edit
    @article = Article.find(params[:id])
    @websites = CrawlerAdapter.adapter_map
  end

  def update
    @article = Article.find(params[:id])
    text = params[:article][:article_all_text]
    params[:article].delete(:article_all_text)
    if @article.update_attributes(params[:article])
      article_text = ArticleText.find_or_initialize_by_article_id(params[:id])
      article_text.text = text
      article_text.save
      render :action => 'show'
    else
      render :action => "edit" 
    end
  end

  def reset_num
    num = params[:num]
    novel_id = params[:novel_id]
    article_id = params[:article_id]

    article = Article.where("novel_id = #{novel_id} and num = #{num}")
    if article[0]
      articles = Article.select("id,num").where("novel_id = #{novel_id} and num >= #{num}")
      Article.transaction do
        articles.each do |a|
          a.update_column(:num,a.num + 1)
        end
      end
      novel = Novel.select("id,num").find(novel_id)
      novel.update_column(:num,novel.num + 1)
      article = Article.select("id,num").find(article_id)
      article.update_column(:num,num)
    else
      article = Article.select("id,num").find(article_id)
      article.update_column(:num,num)
    end
    
    redirect_to :controller => 'novels', :action => 'show', :id => novel_id, :page => params[:page]
  end

  def show
    @article = Article.find(params[:id]) 
  end

  def new
    @novel_id = params[:novel_id]
  end

  def create
    text = params[:article][:article_all_text]
    params[:article].delete(:article_all_text)
    article = Article.new(params[:article])
    novel = Novel.select("id,num").find(article.novel_id)
    article.num = novel.num + 1
    novel.num = novel.num + 1
    if article.save && novel.save
      ArticleText.create(article_id: article.id, text: text)
      redirect_to article_path(article.id)
    else
      render :action => "new", :novel_id => article.novel_id
    end
  end

  def crawl_text_onther_site
    article = Article.select("id, link, is_show").find(params[:article_id])
    crawler = CrawlerAdapter.get_instance params[:url]
    crawler.fetch params[:url]
    crawler.crawl_article article
      
    redirect_to :action => 'show', :id => article.id
  end

  def re_crawl
    article = Article.select("id, link, is_show").find(params[:article_id])
    crawler = CrawlerAdapter.get_instance article.link
    crawler.fetch article.link
    crawler.crawl_article article
      
    redirect_to :action => 'show', :id => article.id
  end


  def destroy
    @article = Article.find(params[:id])
    @article.destroy
    redirect_to :controller => 'novels', :action => 'show', :id => @article.novel_id
  end

  def search_by_num
    @article = Article.where("novel_id = #{params[:novel_id]} and num = #{params[:num]}")[0]
    render :show
  end
end
