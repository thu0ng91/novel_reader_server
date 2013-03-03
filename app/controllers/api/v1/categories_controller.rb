class Api::V1::CategoriesController < Api::ApiController

  def index
    categories = Category.all
    render :json => categories
  end
end
