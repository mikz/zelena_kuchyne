class SnippetsController < ApplicationController
  before_filter {|c| c.must_belong_to_one_of(:admins)}
  exposure :form_fields => {:name => :text_field, :content => :text_area}
  include_javascripts 'fckeditor/fckeditor'
  
  def index
    @records = Snippet.paginate :all, :page => params[:page], :order => "name"
    #order records by localized name
    if params[:order] == "name"
     @records.sort! { |first, second|
        locales["snippet_" + first.send(params[:order])].chars.downcase <=> locales["snippet_" + second.send(params[:order])].chars.downcase
      }
    end
    super
  end
  def create
    expire_fragment("snippet_#{params[:id]}")
    super
  end
  
  def update
    expire_fragment("snippet_#{params[:id]}")
    super
  end
  
  def destroy
    expire_fragment("snippet_#{params[:id]}")
    super
  end
  
  def delete_snippets_cache
    expire_fragment(/snippet_.*/)
    flash[:notice] = 'Snippets cache smazána.'
    redirect_to :back
  end
end