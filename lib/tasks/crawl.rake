# encoding: utf-8
namespace :crawl do
  task :crawl_novel_link => :environment do
    categories = Category.all
    
    categories.each do |category|

      (1..100).each do |i|
        CrawlNewNovelWorker.perform_async(category.id,i)
      end
    end
  end

  task :crawl_cat_ranks => :environment do
    Novel.update_all({:is_category_recommend => false , :is_category_hot => false, :is_category_this_week_hot => false})
    categories = Category.all
    
    categories.each do |category|
      crawler = CrawlerAdapter.get_instance category.cat_link
      crawler.fetch category.cat_link
      crawler.crawl_cat_rank category.id
    end
  end

  task :crawl_rank => :environment do
    ThisWeekHotShip.delete_all
    ThisMonthHotShip.delete_all
    HotShip.delete_all
    url = "http://www.bestory.com/html/r-1.html"
    crawler = CrawlerAdapter.get_instance url
    crawler.fetch url
    crawler.crawl_rank
  end

  task :crawl_articles_and_update_novel => :environment do
    Novel.select("id").find_in_batches do |novels|
      novels.each do |novel|
        CrawlWorker.perform_async(novel.id)
      end
    end
  end

  task :send_notification => :environment do
    gcm = GCM.new("AIzaSyBSeIzNxqXm2Rr4UnThWTBDXiDchjINbrc")
    u = User.find(2)
    registration_ids= ["APA91bGxJM5H56NzVECqZs3rHUgQfubcEld5lehLAzz08Ok41EiRBmoz7X-8OL1x7Jte3Q1lc3nyFsVU5pCK3kx3i9jmurQjK4pTXbNkDnev_zHImTOIboUdftOSntW8qpuiyFZ7Mj2xk7DGDl31aqcSHoB2sDHaEQ"]
    options = {data: {
                  activity: 5, 
                  title: "小說王出新版本囉", 
                  big_text: "新功能，xxxx", 
                  content: "我是 content", 
                  is_resent: true, 
                  category_name: "test", 
                  category_id: 1,
                  novel_name: "novel_name",
                  novel_author: "novel_author",
                  novel_description: "novel_description",
                  novel_update: "20000",
                  novel_pic_url: "http",
                  novel_article_num: "2222",
                  novel_id: 133,
                  open_url: "https://play.google.com/store/apps/details?id=com.novel.reader"
                  }, collapse_key: "updated_score"}
    response = gcm.send_notification(registration_ids, options)
  end

end