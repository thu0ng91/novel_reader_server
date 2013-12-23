class Api::V1::NovelsController < Api::ApiController

  def index
    category_id = params[:category_id]
    unless category_id == "13"
      categoryies_id = find_same_set_ids(category_id)
      novels = Novel.where('category_id in (?)', categoryies_id).show.select("id,name,author,pic,article_num,last_update,is_serializing").paginate(:page => params[:page], :per_page => 30)
    else
      novels = Novel.where('is_serializing = false').show.select("id,name,author,pic,article_num,last_update,is_serializing").paginate(:page => params[:page], :per_page => 30)
    end
    render :json => novels
  end

  def show
    novel = Novel.find(params[:id])
    render :json => novel
  end

  def category_hot
    category_id = params[:category_id]
    unless category_id == "13"
      categoryies_id = find_same_set_ids(category_id)
      novels = Novel.where('category_id in (?) and is_category_hot = true', categoryies_id).show.select("id,name,author,pic,article_num,last_update,is_serializing").paginate(:page => params[:page], :per_page => 30).order("updated_at DESC")
    else
      novels = Novel.where('is_serializing = false and is_category_hot = true').show.select("id,name,author,pic,article_num,last_update,is_serializing").paginate(:page => params[:page], :per_page => 30).order("updated_at DESC")
    end
    render :json => novels
  end

  def category_this_week_hot
    category_id = params[:category_id]
    unless category_id == "13"
      categoryies_id = find_same_set_ids(category_id)
      novels = Novel.where('category_id in (?) and is_category_this_week_hot = true', categoryies_id).show.select("id,name,author,pic,article_num,last_update,is_serializing").paginate(:page => params[:page], :per_page => 30).order("updated_at DESC")
    else
      novels = Novel.where('is_serializing = false and is_category_this_week_hot = true').show.select("id,name,author,pic,article_num,last_update,is_serializing").paginate(:page => params[:page], :per_page => 30).order("updated_at DESC")
    end
    render :json => novels
  end

  def category_recommend
    category_id = params[:category_id]
    unless category_id == "13"
      categoryies_id = find_same_set_ids(category_id)
      novels = Novel.where('category_id in (?) and is_category_recommend = true', categoryies_id).show.select("id,name,author,pic,article_num,last_update,is_serializing").paginate(:page => params[:page], :per_page => 30).order("updated_at DESC")
    else
      novels = Novel.where('is_serializing = false and is_category_recommend = true').show.select("id,name,author,pic,article_num,last_update,is_serializing").paginate(:page => params[:page], :per_page => 30).order("updated_at DESC")
    end
    render :json => novels
  end

  def category_latest_update
    category_id = params[:category_id]
    unless category_id == "13"
      categoryies_id = find_same_set_ids(category_id)
      novels = Novel.where('category_id in (?)', categoryies_id).show.select("id,name,author,pic,article_num,last_update,is_serializing").order("updated_at DESC").paginate(:page => params[:page], :per_page => 30)
    else
      novels = Novel.where('is_serializing = false').order("updated_at DESC").show.select("id,name,author,pic,article_num,last_update,is_serializing").paginate(:page => params[:page], :per_page => 30)
    end
    render :json => novels
  end

  def hot
    novels_id = HotShip.all.map{|ship| ship.novel_id}.join(',')
    novels = Novel.where("id in (#{novels_id})").show.select("id,name,author,pic,article_num,last_update,is_serializing").paginate(:page => params[:page], :per_page => 30).order("updated_at DESC")
    render :json => novels
  end

  def this_week_hot
    novels_id = ThisWeekHotShip.all.map{|ship| ship.novel_id}.join(',')
    novels = Novel.where("id in (#{novels_id})").show.select("id,name,author,pic,article_num,last_update,is_serializing").paginate(:page => params[:page], :per_page => 30).order("updated_at DESC")
    render :json => novels
  end

  def this_month_hot
    novels_id = ThisMonthHotShip.all.map{|ship| ship.novel_id}.join(',')
    novels = Novel.where("id in (#{novels_id})").show.select("id,name,author,pic,article_num,last_update,is_serializing").paginate(:page => params[:page], :per_page => 30).order("updated_at DESC")
    render :json => novels
  end

  def all_novel_update
    novels = Novel.show.select("id,name,author,pic,article_num,last_update,is_serializing").order("updated_at DESC").paginate(:page => params[:page], :per_page => 30)
    render :json => novels
  end

  def search
    keyword = params[:search].strip
    keyword_cn = keyword.clone
    keyword_cn = ZhConv.convert("zh-tw",keyword_cn)
    novels = Novel.where("name like ? or author like ? or name like ? or author like ?", "%#{keyword}%","%#{keyword}%","%#{keyword_cn}","%#{keyword_cn}").show.select("id,name,author,pic,article_num,last_update,is_serializing")
    render :json => novels
  end

  def detail_for_save
    @novel = Novel.find(params[:id])
    render :json => { "novel" =>  @novel }
    # @articles = Article.where("novel_id = #{@novel.id}").select("id, subject, title")
  end

  
  def classic
    novels = Novel.where('is_classic = true').show.select("id,name,author,pic,article_num,last_update,is_serializing")
    render :json => novels
  end

  def classic_action
    novels = Novel.where('is_classic_action = true').show.select("id,name,author,pic,article_num,last_update,is_serializing")
    render :json => novels
  end

private
  def find_same_set_ids(category_id)
    case category_id
    when "14"
      [1,14]
    when "15"
      [2,15]
    when "16"
      [3,16]
    when "17"
      [9,17]
    when "18"
      [7,18]
    when "19"
      [5,19]
    when "20"
      [6,20]
    when "21"
      [21]
    when "22"
      [22]
    when "23"
      [8,23]
    else
      [category_id.to_i]
    end
  end
end
