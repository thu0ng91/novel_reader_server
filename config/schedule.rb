env :PATH, ENV['PATH']

every :day, :at => '03:32pm' do
  rake 'crawl:crawl_article_text',:output => {:error => 'log/error.log', :standard => 'log/cron.log'}
end