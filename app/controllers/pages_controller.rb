class PagesController < ApplicationController
  before_filter(:except => [:show]) {|c| c.must_belong_to_one_of(:admins)}
  exposure :title => 'title', :columns => [:url], :form_fields => {:title => :text_field, :url => :text_field, :body => :text_area}, :content_column => :body
  include_javascripts 'fckeditor/fckeditor', 'fullscreen', :except => [:show]
  include_stylesheets 'pages', :only => [:show]
  before_filter :load_sidebar_content
  
  def show
    path = "#{RAILS_ROOT}/app/static_content/#{params[:id]}.html"
    if File.exist?(path)
      return render(:file => path, :layout => true)
    end
    
    @record = Page.find_by_url(params[:id])

    if(@record)
      super
    else
      @record = PageHistory.find_by_url(params[:id])
      if(@record)
        redirect_to :id => @record.page.url, :status => 302
      else
        raise ActiveRecord::RecordNotFound
      end
    end
  end
  
  def update
    @record = Page.find_by_id params[:id]
    (@record.page_history_ids - params[:record]["page_history_ids"].collect{|id|id.to_i}).each do |history_id|
      PageHistory.find_by_id(history_id).destroy
      params[:record]["page_history_ids"].delete history_id.to_s
    end if params[:record]["page_history_ids"]
    super
  end
    
  protected
  def load_sidebar_content
    @polls ||= Poll.find_all_by_active true, :include => [:poll_votes, :poll_answers_results], :order => "created_at DESC"
    @news ||= News.valid_news :order => 'publish_at DESC, id DESC', :limit => 5
    @days ||= Day.find :all
    @date ||= Date.today
    
    @dialy_menu, @dialy_entries, @dialy_categories = load_dialy_menu
  end
  

end
