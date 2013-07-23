# encoding: utf-8
class NovelCrawler
  include Crawler

  def parse_old_db_novel
    j_array = JSON.parse @page_html
    j_array.each do |json|
      novel = Novel.new
      novel.id = json["id"]
      novel.link = json["link"]
      novel.is_classic_action = json["is_classic_action"]
      novel.is_classic = json["is_classic"]
      novel.save
    end
  end

  def parse_old_db_article
    j_array = JSON.parse @page_html
    j_array.each do |json|
      article = Article.new
      
      article.id = json["id"]
      article.link = json["link"]
      article.novel_id = json["novel_id"]
      article.title = json["title"]
      article.subject = json["subject"]
      
      novel = Novel.select("id,num").find(json["novel_id"])
      article.num = novel.num + 1
      novel.num = novel.num + 1
      novel.save
      article.save
    end
  end

  def parse_old_db_article_detail article_id
    json = JSON.parse @page_html
    article = Article.find(article_id)
    article.text = json["text"]
    article.save
  end

  def crawl_novels category_id
    # puts @page_url
    nodes = @page_html.css("#ItemContent_dl")
    nodes = nodes.children
    
    puts "error" if nodes.size == 0

    nodes.each do |novel_row|
      novels = novel_row.children
      
      begin 
        (1..3).each do |i|
          novel_html = novels[i-1]
          link = "http://www.bestory.com" + novel_html.css("a")[0][:href]
          novel = Novel.find_by_link link
          unless novel
            novel = Novel.new
            novel.link = link
            novel.category_id = category_id
            novel.is_show = false
            novel.save
          end
          # CrawlWorker.perform_async(novel.id)
        end
      rescue
      end 
    end

    # page_nodes = @page_html.css("#ItemContent_pager")
    # next_link = page_nodes.css("font")[0].parent.next.css("a")
    
    # if next_link.present?
    #   next_page_link = "http://www.bestory.com/category/" + next_link[0][:href]
    #   puts next_page_link
    #   crawler = NovelCrawler.new
    #   crawler.fetch next_page_link
    #   crawler.crawl_novels category_id
    # end
  end
  

  def crawl_novel_detail novel_id
    novel = Novel.find(novel_id)
    return if novel.name

    nodes = @page_html.css("table")
    node = nodes[4].css("table")[3]

    img_link = "http://www.bestory.com" + node.css("img")[1][:src]
    name = node.css("font")[0].text
    is_serializing = true
    is_serializing = false if node.css("font")[0].next.text.index("全本")
    article_num = node.css("font")[1].text
    author = node.css("font")[3].text
    last_update = node.css("font")[4].text
    description = change_node_br_to_newline(node.css("table")[0].children.children[0].children.children.children[2].children.children[2]).strip

    novel.author = author
    novel.description = description
    novel.pic = img_link
    novel.is_serializing = is_serializing
    novel.article_num = article_num
    novel.last_update = last_update
    novel.name = name
    novel.crawl_times = novel.crawl_times + 1
    novel.save
  end

  def crawl_cat_rank category_id
    nodes = @page_html.css("table")
    this_week_nodes = nodes[5].children[1].children[2].children[1].children
    
    this_week_nodes.each do |node|
      name = node.css("a").text.split("/")[0]
      puts name
      if (name && name.size > 6) 
        novel = Novel.where(["name like ?", "%#{name[0..6]}%"])[0]
      else
        novel = Novel.find_by_name name
      end

      if novel
        novel.is_category_this_week_hot = true 
        novel.save
        puts "yes"
      end
    end

    hot_nodes = @page_html.xpath("//td[@bgcolor='#29ABCE']")[0].parent.parent.parent.parent.parent.children[1].children[2].children[1].children
    hot_nodes.each do |node|
      name = node.css("a").text.split("/")[0]
      puts name
      if (name && name.size > 6)
        novel = Novel.where(["name like ?", "%#{name[0..6]}%"])[0]
      else
        novel = Novel.find_by_name name
      end

      if novel
        novel.is_category_hot = true 
        novel.save
        puts "yes"
      end
    end

    recommend_nodes = @page_html.xpath("//td[@bgcolor='#FFFFFF' and @colspan='2']")[0].children[3].children
    recommend_nodes = recommend_nodes.css("a.blue")
    return if recommend_nodes.text.strip.blank?
    recommend_nodes.each do |node|
      name = node.text
      puts name
      if (name && name.size > 6)
        novel = Novel.where(["name like ?", "%#{name[0..6]}%"])[0]
      else
        novel = Novel.find_by_name name
      end

      if novel
        novel.is_category_recommend = true 
        novel.save
        puts "yes"
      end
    end
  end

  def crawl_articles novel_id

    if(@page_url.index('www.bestory.com'))
      nodes = @page_html.css("a")
      nodes.each do |node|
        if (node[:href].index("/novel/") || node[:href].index("/view/"))
          article = Article.find_by_link("http://www.bestory.com" + node[:href])
          # article = Article.where("novel_id = #{novel_id} and title = ?",node.text.strip)[0]
          next if (article != nil && article.text != nil)

          unless article 
            article = Article.new
            article.novel_id = novel_id
            article.link = "http://www.bestory.com" + node[:href]
            article.title = node.text.strip
            article.subject = node.parent.parent.parent.parent.parent.previous.previous.previous.text.strip
            novel = Novel.select("id,num").find(novel_id)
            article.num = novel.num + 1
            novel.num = novel.num + 1
            novel.save
            # puts node.text
            article.save
          end
          ArticleWorker.perform_async(article.id)
        end
      end
    elsif(@page_url.index('77wx'))
      nodes = @page_html.css(".box_con #list dl dd a")
      nodes.each do |node|
        article = Article.find_by_link(node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('tw.hjwzw'))
      nodes = @page_html.css("#tbchapterlist tr a")
      nodes.each do |node|
        article = Article.find_by_link("http://tw.hjwzw.com" + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = "http://tw.hjwzw.com" + node[:href]
          article.title = node.text.strip
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('xuanhutang'))
      nodes = @page_html.css(".acss tr a")
      nodes.each do |node|
        article = Article.find_by_link(@page_url + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = @page_url + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('quanben'))
      nodes = @page_html.css("tr")
      novel = Novel.select("id,num,name").find(novel_id)
      subject = ""
      nodes.each do |node|
        if (node.children.size() == 1)
          subject = ZhConv.convert("zh-tw",node.children.text.strip)
        elsif (node.children.size() == 4)
          inside_nodes = node.children.children
          inside_nodes.each do |n|
            if n.name == "a"
              article = Article.find_by_link(@page_url + n[:href])
              next if (article != nil && article.text != nil)

              unless article 
              article = Article.new
              article.novel_id = novel_id
              article.link = @page_url + n[:href]
              article.title = ZhConv.convert("zh-tw",n.text.strip)
              article.subject = subject
              /(\d*)/ =~ n[:href]
              article.num = $1.to_i
              # puts node.text
              article.save
              end
              novel.num = article.num + 1
              novel.save
              ArticleWorker.perform_async(article.id)
            end
          end
        end
      end

      # nodes = @page_html.css(".acss tr .ccss a")
      # novel = Novel.select("id,num,name").find(novel_id)
      # nodes.each do |node|
      #   article = Article.find_by_link(@page_url + node[:href])
      #   next if (article != nil && article.text != nil)

      #   unless article 
      #     article = Article.new
      #     article.novel_id = novel_id
      #     article.link = @page_url + node[:href]
      #     article.title = ZhConv.convert("zh-tw",node.text.strip)
      #     article.subject = novel.name
      #     /(\d*)/ =~ node[:href]
      #     article.num = $1.to_i
      #     # puts node.text
      #     article.save
      #   end
      #   novel.num = article.num + 1
      #   novel.save
      #   ArticleWorker.perform_async(article.id)
      # end
    elsif(@page_url.index('shu88.net'))
      url = @page_url.gsub("index.html","")
      nodes = @page_html.css('ol li')
      nodes.each do |node|
        article = Article.find_by_link(url+node.child[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = url + node.child[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('dawenxue'))
      nodes = @page_html.css(".ccss a")
      nodes.each do |node|
        article = Article.find_by_link(@page_url + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = @page_url + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('ranhen'))
      nodes = @page_html.css("dd a")
      nodes.each do |node|
        article = Article.find_by_link(@page_url + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = @page_url + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end  
    elsif(@page_url.index('book.sfacg'))
      @page_html.css("div.list_menu_title .Download_box").remove
      @page_html.css("div.list_menu_title a").remove
      subjects = @page_html.css("div.list_menu_title")
      subject_titles = []

      subjects.each do |subject|
        text = subject.text
        text = text.gsub("【】","")
        text = text.gsub("下载本卷","")
        subject_titles << ZhConv.convert("zh-tw",text.strip)
      end

      num = @page_html.css(".list_Content").size()
      index = 0
      while index < num do
        nodes = @page_html.css(".list_Content")[index].css("a")
        nodes.each do |node|
            article = Article.find_by_link("http://book.sfacg.com" + node[:href])
            next if (article != nil && article.text != nil)

            unless article 
              article = Article.new
              article.novel_id = novel_id
              article.link = "http://book.sfacg.com" + node[:href]
              article.title = ZhConv.convert("zh-tw",node.text.strip)
              novel = Novel.select("id,num,name").find(novel_id)
              article.subject = subject_titles[index]
              article.num = novel.num + 1
              novel.num = novel.num + 1
              novel.save
                # puts node.text
              article.save
            end
            ArticleWorker.perform_async(article.id)
          end
        index = index +1        
      end   

      # nodes = @page_html.css(".list_Content  a")
      # nodes.each do |node|
      #   article = Article.find_by_link("http://book.sfacg.com" + node[:href])
      #   next if (article != nil && article.text != nil)

      #   unless article 
      #     article = Article.new
      #     article.novel_id = novel_id
      #     article.link = "http://book.sfacg.com" + node[:href]
      #     article.title = ZhConv.convert("zh-tw",node.text.strip)
      #     novel = Novel.select("id,num,name").find(novel_id)
      #     article.subject = novel.name
      #     article.num = novel.num + 1
      #     novel.num = novel.num + 1
      #     novel.save
      #     # puts node.text
      #     article.save
      #   end
      #   ArticleWorker.perform_async(article.id)
      # end
    elsif(@page_url.index('xianjie'))
      url = @page_url.gsub("index.html","")

      subject = ""
      nodes = @page_html.css(".zhangjie dl").children
      nodes.each do |node|
        if node.name == "dt"
          subject = ZhConv.convert("zh-tw",node.text.strip)
        elsif (node.name == "dd" && node.children.size() == 1 && node.children[0][:href] != nil)
          article = Article.find_by_link(url + node.children[0][:href])
          next if (article != nil && article.text != nil)

          unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = url + node.children[0][:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
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

      # nodes = @page_html.css(".zhangjie dl dd a")
      # nodes.each do |node|
      #   article = Article.find_by_link(url + node[:href])
      #   next if (article != nil && article.text != nil)

      #   unless article 
      #     article = Article.new
      #     article.novel_id = novel_id
      #     article.link = url + node[:href]
      #     article.title = ZhConv.convert("zh-tw",node.text.strip)
      #     novel = Novel.select("id,num,name").find(novel_id)
      #     article.subject = novel.name
      #     article.num = novel.num + 1
      #     novel.num = novel.num + 1
      #     novel.save
      #     # puts node.text
      #     article.save
      #   end
      #   ArticleWorker.perform_async(article.id)
      # end
    elsif(@page_url.index('5ccc.net'))
      url = page_url.gsub('index.html','')
      nodes = @page_html.css(".ccss a")
      nodes.each do |node|
        article = Article.find_by_link(url+node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = url + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('tw.mingzw'))
      nodes = @page_html.css(".chapterlist a")
      nodes.each do |node|
        article = Article.find_by_link("http://tw.mingzw.com/" + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = "http://tw.mingzw.com/" + node[:href]
          article.title = node.text.strip
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('520xs'))
      nodes = @page_html.css("#list dl").children
      subject = ""
      nodes.each do |node|
        
        if node[:id] == "qw"
          subject = node.text
          puts subject
        elsif node.css("a")[0]
          node = node.css("a")[0]
          article = Article.find_by_link("http://www.520xs.com" + node[:href])
          next if (article != nil && article.text != nil)

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
    elsif(@page_url.index('tw.xiaoshuokan'))
      nodes = @page_html.css(".booklist a")
      nodes.each do |node|
        article = Article.find_by_link("http://tw.xiaoshuokan.com" + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = "http://tw.xiaoshuokan.com" + node[:href]
          article.title = node.text.strip
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('92txt.net'))
      nodes = @page_html.css(".ccss a")
      nodes.each do |node|
        article = Article.find_by_link(@page_url + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = @page_url + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('ranwenxiaoshuo'))
      url = "http://www.ranwenxiaoshuo.com"
      nodes = @page_html.css("div.uclist dd a")
      nodes.each do |node|
        article = Article.find_by_link(url + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = url + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('ranwen.net'))
      url = @page_url.gsub("index.html","")
      nodes = @page_html.css("div#defaulthtml4 a")
      nodes.each do |node|
        article = Article.find_by_link(url + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = url + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('qbxiaoshuo.com'))
      url = "http://www.qbxiaoshuo.com"
      nodes = @page_html.css(".booklist a")
      nodes.each do |node|
        article = Article.find_by_link(url + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = url + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('xhxsw.com'))
      url = @page_url.sub("reader.htm","")
      nodes = @page_html.css("td.ccss a")
      nodes.each do |node|
        article = Article.find_by_link(url + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = url + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end  
    elsif(@page_url.index('bsxsw'))
      url = "http://www.bsxsw.com"
      nodes = @page_html.css(".chapterlist a")
      nodes.each do |node|
        article = Article.find_by_link(url + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = url + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('lwxs'))
      url = @page_url
      nodes = @page_html.css("div#defaulthtml4 td a")
      nodes.each do |node|
        article = Article.find_by_link(url + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = url + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          article.num = novel.num + 1
          novel.num = novel.num + 1
          novel.save
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end  
    elsif(@page_url.index('yawen8'))
      url = @page_url
      nodes = @page_html.css("dd a")
      nodes.each do |node|
        if (node.text.index(yawen8) ==nil)
          article = Article.find_by_link(url + node[:href])
          next if (article != nil && article.text != nil)

          unless article 
            article = Article.new
            article.novel_id = novel_id
            article.link = url + node[:href]
            article.title = ZhConv.convert("zh-tw",node.text.strip)
            novel = Novel.select("id,num,name").find(novel_id)
            article.subject = novel.name
            article.num = novel.num + 1
            novel.num = novel.num + 1
            novel.save
            # puts node.text
            article.save
          end
          ArticleWorker.perform_async(article.id)
        end
      end        
    elsif (@page_url.index('zizaidu'))
       url = @page_url.sub("index.html","")
       nodes = @page_html.css("div.uclist a")
       nodes.each do |node|
        article = Article.find_by_link(url + node[:href])
        next if (article != nil && article.text != nil)

        unless article 
          article = Article.new
          article.novel_id = novel_id
          article.link = url + node[:href]
          article.title = ZhConv.convert("zh-tw",node.text.strip)
          novel = Novel.select("id,num,name").find(novel_id)
          article.subject = novel.name
          /(\d*)/ =~ node[:href]
          article.num = $1.to_i
          # puts node.text
          article.save
        end
        ArticleWorker.perform_async(article.id)
      end
    elsif(@page_url.index('59to'))
      url = @page_url

      subject = ""
      nodes = @page_html.css(".acss").children
      nodes.each do |node|
        if node.children.children[0].name == "h2"
          subject = ZhConv.convert("zh-tw",node.children.text.strip)
        elsif (node.children.children[0].name == "a")
          inside_nodes = node.children.children
          inside_nodes.each do |n|
            if n[:href] != nil
              article = Article.find_by_link(url + n[:href])
              next if (article != nil && article.text != nil)

              unless article 
              article = Article.new
              article.novel_id = novel_id
              article.link = url + n[:href]
              article.title = ZhConv.convert("zh-tw",n.text.strip)
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
        end
      end
    end

  end

  def crawl_article article
    nodes = @page_html.css(".content")
    nodes = nodes[0].children
    text = ""
    nodes.each do |node|
      next if node.text.nil?
      if node.text.index("bookview")
        node.css("script").remove
      end
      text = text + change_node_br_to_newline(node)
    end
    text = text.gsub("◎ 精品文學網 Bestory.com  ◎", "")
    text = text.gsub("※ 精 品 文 學 網 B e s t o r y  .c o m  ※", "")
    text = text.gsub("精品文學網  歡迎廣大書友光臨閱讀", "")
    text = text.gsub("手 機 用 戶 請 登 陸  隨 時 隨 地 看 小 說!","")
    text = text.gsub("精品文學 iPhone App現已推出！支持離線下載看小說，請使用iPhone下載安裝！","")
    article.text = text
    article.save
    puts "#{@page_url}  article_id : #{article.id}"
  end

  def crawl_text_onther_site article
    if(@page_url.index("yantengzw"))
      nodes = @page_html.css("#htmlContent")
      text  = change_node_br_to_newline(nodes)
      article_text = ZhConv.convert("zh-tw", text)
      article.text = article_text
      article.save
    elsif(@page_url.index("book.qq"))
      nodes = @page_html.css("#content")
      text  = change_node_br_to_newline(nodes)
      article_text = ZhConv.convert("zh-tw", text)
      article.text = article_text
      article.save
    elsif(@page_url.index("www.zizaidu.com/big5"))
      nodes = @page_html.css("#content")
      text  = change_node_br_to_newline(nodes).strip
      article_text = text.gsub("（最好的全文字小說網︰自在讀小說網 www.zizaidu.com）","")
      article.text = article_text
      article.save
    elsif (@page_url.index("www.4hw.com.cn"))
      @page_html.css(".art_cont .art_ad,.art_cont .fenye, .art_cont .tishi").remove
      article_text = ZhConv.convert("zh-tw",@page_html.css(".art_cont").text.strip)
      article.text = article_text
      article.save
    elsif (@page_url.index("read.shanwen.com"))
      @page_html.css("#content")
      @page_html.css("#content center").remove
      article_text = ZhConv.convert("zh-tw",@page_html.css("#content").text.strip)
      article.text = article_text
      article.save
    elsif (@page_url.index("shushu.com.cn"))
      @page_html.css("#content script,#content a").remove
      article_text = ZhConv.convert("zh-tw",@page_html.css("#content").text.strip)
      article.text = article_text
      article.save
    elsif (@page_url.index("tw.9pwx.com"))
      @page_html.css(".bookcontent #msg-bottom").remove
      text = @page_html.css(".bookcontent").text.strip
      article_text = text.gsub("鑾勾絏ュ庤鎷誨潒濯兼煉鐪磭榪惰琚氣-官家求魔殺神武動乾坤最終進化神印王座| www.9pwx.com","")
      article_text = text.gsub("鍗兼雞銇264264-官家求魔殺神武動乾坤最終進化神印王座|","")
      article_text = text.gsub("www.9pwx.com","")
      article.text = article_text.strip
      article.save
    elsif (@page_url.index('sj131'))
      @page_html.css("#content a").remove
      article_text = ZhConv.convert("zh-tw",@page_html.css("#content").text.strip)
      article_text = article_text.gsub("如果您喜歡這個章節","")
      article_text = article_text.gsub("精品小說推薦","")
      article.text = article_text
      article.save
    elsif (@page_url.index('yawen8'))
      article_text = ZhConv.convert("zh-tw",@page_html.css("div.txtc").text.strip)
      text2 =""
      if article_text.index('本章未完')
        c = NovelCrawler.new
        c.fetch_other_site @page_url+"?p=2"
        text2 = ZhConv.convert("zh-tw",c.page_html.css("div.txtc").text.strip)
      end
      article_text = article_text + text2
      article_text = article_text.gsub("［本章未完，請點擊下一頁繼續閱讀！］","")
      article_text = article_text.gsub("...   ","")
      article.text = article_text
      article.save
    elsif (@page_url.index('52buk.com'))
      text = @page_html.css(".novelcon").text.strip
      article_text = ZhConv.convert("zh-tw",text)
      article.text = article_text
      article.save
    elsif (@page_url.index('8535.org'))
      @page_html.css("#bookcontent #adtop, #bookcontent #endtips").remove
      text = @page_html.css("#bookcontent").text.strip
      article_text = ZhConv.convert("zh-tw",text)
      article.text = article_text
      article.save
    elsif (@page_url.index('59to.com'))
      @page_html.css("#content a").remove
      text = @page_html.css("#content").text
      article_text = text.gsub("*** 现在加入59文学，和万千书友交流阅读乐趣！59文学永久地址：www.59to.com ***", "")
      final_text = ZhConv.convert("zh-tw",article_text.strip)
      article.text = final_text
      article.save
    elsif (@page_url.index('www.k6uk.com'))
      text = @page_html.css("#content").text.strip
      article_text = ZhConv.convert("zh-tw",text)
      article.text = article_text
      article.save
    elsif (@page_url.index('www.dawenxue.net'))
      text = @page_html.css("#clickeye_content").text.strip
      text1 = text.gsub("大文学", "")
      text2 = text1.gsub("www.dawenxue.net", "")
      text2 = text2.gsub("()", "")
      text2 = text2.gsub("www.Sxiaoshuo.com", "")
      text2 = text2.gsub("最快的小说搜索网", "")
      text2 = text2.gsub("/////", "")
      article_text = ZhConv.convert("zh-tw",text2)
      article.text = article_text
      article.save
    elsif (@page_url.index('quanben'))
      text = @page_html.css("#content").text.strip
      text = text.gsub(/[a-zA-Z]/,"")
      text = text.gsub("全本小说网","")
      text = text.gsub("wWw!QuanBEn!CoM","")
      text = text.gsub("(www.quanben.com)","")
      article_text = ZhConv.convert("zh-tw",text)
      article.text = article_text
      article.save
    elsif (@page_url.index('wcxiaoshuo'))
      @page_html.css("#htmlContent a").remove
      @page_html.css("#htmlContent img").remove
      text = @page_html.css("#htmlContent").text.strip
      text = text.gsub("由【无*错】【小-说-网】会员手打，更多章节请到网址：www.wcxiaoshuo.com","")
      article_text = ZhConv.convert("zh-tw",text)
      article.text = article_text
      article.save
    elsif (@page_url.index('shumilou'))
      @page_html.css("#content span").remove
      @page_html.css("#content b").remove
      @page_html.css("#content .title").remove
      @page_html.css("#content script").remove
      text = @page_html.css("#content").text.strip
      article_text = ZhConv.convert("zh-tw",text)
      article.text = article_text
      article.save
    elsif (@page_url.index('dzxsw'))
      text = @page_html.css("#content").text
      text = text.gsub(/\/\d*/,"")
      text = text.gsub("'>","")
      text = text.gsub(".+?","")
      article_text = ZhConv.convert("zh-tw",text)
      article.text = article_text
      article.save
    elsif(@page_url.index('xianjie'))
      @page_html.css(".para script").remove
      text = @page_html.css(".para").text
      text = text.gsub("阅读最好的小说，就上仙界小说网www.xianjie.me","")
      article_text = ZhConv.convert("zh-tw",text)
      article.text = article_text
      article.save
    elsif (@page_url.index('u8xs'))
      text = change_node_br_to_newline(@page_html.css("#content"))
      article_text = ZhConv.convert("zh-tw",text)
      article.text = article_text
      article.save
    elsif (@page_url.index('ranhen.net'))
      text = @page_html.css("#content p").text
      text2 = text.gsub('小技巧：按 Ctrl+D 快速保存当前章节页面至浏览器收藏夹；按 回车[Enter]键 返回章节目录，按 ←键 回到上一章，按 →键 进入下一章。','')
      article_text = ZhConv.convert("zh-tw",text2)
      article.text = article_text
      article.save
    elsif (@page_url.index('6ycn.net'))
      @page_html.css("#content style, #content .pagesloop").remove
      text = @page_html.css("#content").text.strip
      article_text = ZhConv.convert("zh-tw",text)
      article.text = article_text
      article.save
    elsif (@page_url.index('book108.com'))
      @page_html.css("#content a").remove
      text = @page_html.css("#content p").text
      text2 = text.gsub("1０８尒説WWW.Book１０８。com鯁","")
      article_text = ZhConv.convert("zh-tw",text2)
      article.text = article_text
      article.save
    elsif (@page_url.index('77wx'))
      @page_html.css(".content a").remove
      text = @page_html.css(".content").text.strip
      text = text.gsub("七七文学","")
      text = text.gsub("九星天辰诀","")
      article_text = ZhConv.convert("zh-tw",text)
      article.text = article_text
      article.save
    elsif (@page_url.index('tw.hjwzw'))
      @page_html.css("#AllySite")[0].next.next
      @page_html.css("#AllySite")[0].next.next.css("a").remove
      @page_html.css("#AllySite")[0].next.next.css("b").remove
      text = @page_html.css("#AllySite")[0].next.next.text.strip
      text = text.gsub("返回書頁","")
      text = text.gsub("回車鍵","")
      text = text.gsub("快捷鍵: 上一章(\"←\"或者\"P\")","")
      text = text.gsub("下一章(\"→\"或者\"N\")","")
      text = text.gsub("在搜索引擎輸入","")
      text = text.gsub("就可以找到本書","")
      text = text.gsub("最快,最新TXT更新盡在書友天下:本文由“網”書友更新上傳我們的網址是“”如章節錯誤/舉報謝","")
      article.text = text
      article.save
    elsif (@page_url.index('xuanhutang'))
      @page_html.xpath("//div[@align='center']").remove
      @page_html.xpath("//div[@style='padding:6px 12px;line-height:20px;']").remove
      @page_html.css("#content a").remove
      text = @page_html.css("#content").text.strip
      text = text.gsub("看校园小说到-玄葫堂","")
      article_text = ZhConv.convert("zh-tw",text)
      article.text = article_text
      article.save
    elsif (@page_url.index('shu88.net'))
      text = @page_html.css(".contentbox").text.strip
      article.text = ZhConv.convert("zh-tw", text)
      article.save
    elsif (@page_url.index('sfacg'))
      node = @page_html.css("#ChapterBody")
      text = change_node_br_to_newline(node)
      article.text = ZhConv.convert("zh-tw", text)
      article.save
    elsif (@page_url.index('5ccc.net'))
      @page_html.css("#content a").remove
      @page_html.css("#content script").remove
      node = @page_html.css("#content")
      text = node.text.strip
      article.text = ZhConv.convert("zh-tw", text)
      article.save
    elsif (@page_url.index('tw.mingzw'))
      @page_html.css("div[@style='text-align: center']").remove
      @page_html.css("div[@style='border: 1px solid #a6a6a6; width: 850px; margin: 0 auto;'] script").remove
      node = @page_html.css("div[@style='border: 1px solid #a6a6a6; width: 850px; margin: 0 auto;']")
      text = node.text.strip
      text = text.gsub("如需請通過此鏈接進入沖囍下載頁面","")
      text = text.gsub("明智屋中文","")
      text = text.gsub("wWw.MinGzw.cOm","")
      text = text.gsub("沒有彈窗","")
      text = text.gsub("更新及時","")
      article.text = text
      article.save
    elsif (@page_url.index('520xs'))
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
      article.save
    elsif (@page_url.index('tw.xiaoshuokan'))
      node = @page_html.css(".bookcontent")
      text = change_node_br_to_newline(node).strip
      text = text.gsub(/&(.*)WWW.3Zcn.net/,"")
      text = text.gsub(/&(.*)WWW.3Zcn.net/,"")
      text = text.gsub("三藏中文","")
      text = text.gsub("bsp","")
      text = text.gsub("Www.Xiaoshuokan.com","")
      text = text.gsub("好看小說網","")
      text = text.gsub("(本章免費)","")
      text = text.gsub("&n8","")
      text = text.gsub("ｏ","")
      article.text = text
      article.save
    elsif (@page_url.index('92txt.net'))
      node = @page_html.css("#chapter_content")
      text = change_node_br_to_newline(node)
      text = text.gsub("www.92txt.net 就爱网","")
      text = text.gsub("亲们记得多给戚惜【投推荐票】、【投月票】，【加入书架】，【留言评论】哦，鞠躬敬谢","")
      article.text = ZhConv.convert("zh-tw", text)
      article.save
    elsif (@page_url.index('guli.cc'))
      text = @page_html.css("div#content").text.strip
      text = text.gsub("txtrightshow();","").strip
      article.text = ZhConv.convert("zh-tw", text)
      article.save
    elsif (@page_url.index('ranwenxiaoshuo'))
      # the site may change content web element, use carefully
      # sometimes can't reach content by sidekiq
      text = @page_html.css("p").text.strip
      text = text.gsub("求金牌、求收藏、求推荐、求点击、求评论、求红包、求礼物，各种求，有什么要什么，都砸过来吧！","").strip
      text = text.gsub("小窍门：按左右键快速翻到上下章节","").strip
      article.text = ZhConv.convert("zh-tw", text)
      article.save
    elsif (@page_url.index('ranwen.net'))
      text = @page_html.css("div#content").text.strip
      article.text = ZhConv.convert("zh-tw", text)
      article.save
    elsif (@page_url.index('qbxiaoshuo'))
      text = @page_html.css(".bookcontent").text.strip
      text = text.gsub("[www.16Kbook.com]","")
      text = text.gsub("www.qbxiaoshuo.com全本小说网","")
      article.text = ZhConv.convert("zh-tw", text)
      article.save
    elsif (@page_url.index('xhxsw'))
      text = @page_html.css("#content").text.strip
      article.text = ZhConv.convert("zh-tw", text)
      article.save
    elsif (@page_url.index('lwxs'))
      text = @page_html.css("div#content").text.strip
      article.text = ZhConv.convert("zh-tw", text)
      article.save      
    elsif (@page_url.index('bsxsw'))
      text = @page_html.css(".ReadContents").text
      text = text.gsub("上一章  |  万事如易目录  |  下一章","")
      text = text.gsub("=波=斯=小=说=网= bsxsw.com","")
      text = text.gsub("sodu,,返回首页","")
      text = text.gsub("sodu","")
      text = text.gsub("zybook,返回首页","")
      text = text.gsub("zybook","")
      text = text.gsub("三月果)","")
      text = text.gsub("三月果","")
      text = text.gsub("处理SSI文件时出错","")
      text = text.gsub("收费章节(12点)","")
      article.text = ZhConv.convert("zh-tw", text.strip)
      article.save
    end
  end

  def crawl_rank
    nodes = @page_html.xpath("//font[@color='#0099CC']")
    ships = ["ThisWeekHotShip", "ThisMonthHotShip", "HotShip"]

    (0..2).each do |i|
      novel_nodes = nodes[i].parent.parent.parent.parent.css("a")
      novel_nodes.each do |node|
        ship = eval "#{ships[i]}.new"
        # link = "http://www.bestory.com" + node[:href]
        # novel = Novel.find_by_link link
        name = node.text.split("/")[0]
        if name.size > 6
          novel = Novel.where(["name like ?", "%#{name[0..6]}%"])[0]
        else
          novel = Novel.find_by_name name
        end
        if novel
          ship.novel = novel
          ship.save
          puts name
        end
      end
    end
  end

  def change_node_br_to_newline node
    content = node.to_html
    content = content.gsub("<br>","\n")
    n = Nokogiri::HTML(content)
    n.text
  end
end
