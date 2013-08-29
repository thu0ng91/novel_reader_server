require 'sidekiq/web'
NovelServer::Application.routes.draw do
  mount Sidekiq::Web, at: '/sidekiq'
  

  resources :novels do 
    collection do
      put 'search'
      put 'update_novel'
    end
    member do
      get 'set_all_articles_to_invisiable'
      get 'recrawl_all_articles'
    end
  end

  resources :articles do
    collection do
      get 're_crawl'
      put 'crawl_text_onther_site'
      put 'reset_num'
      put 'search_by_num'
    end
  end


  namespace :api do
    get 'status_check' => 'api#status_check'
    namespace :v1 do

      
      resources :categories, :only => [:index]
      resources :novels,:only => [:index, :show] do
        collection do
          get 'category_hot'
          get 'category_this_week_hot'
          get 'category_recommend'
          get 'hot'
          get 'this_week_hot'
          get 'this_month_hot'
          get 'search'
          get 'classic'
          get 'classic_action'
          # get 'db_transfer_index'
        end
        member do 
          get 'detail_for_save'
        end
      end
      resources :articles,:only => [:index, :show] do
        collection do 
          get 'next_article'
          get 'previous_article'
          get 'articles_by_num'
          get 'next_article_by_num'
          get 'previous_article_by_num'
          # get 'db_transfer_index'
        end
      end

      resources :users, :only => [:create] do
        collection do
          put 'update_novel'
          put 'update_collected_novels'
          put 'update_downloaded_novels'
        end
      end
    end
  end
end
