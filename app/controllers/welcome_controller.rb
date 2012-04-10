# -*- encoding : utf-8 -*-

class WelcomeController < ApplicationController
  include_javascripts 'jquery.lightbox', :only => ['index']
  include_stylesheets 'jquery.lightbox', :only => ['index']
  before_filter :load_sidebar_content
  
  def index
    
  end
  
  protected
  def load_sidebar_content
    @polls ||= Poll.find_all_by_active true, :include => [:poll_votes, :poll_answers_results], :order => "created_at DESC"
    @news ||= News.valid_news :order => 'publish_at DESC, id DESC', :limit => 5
    @days ||= Day.find :all
    @date ||= params[:id] ? Date.parse(params[:id]) : Date.today
    @dialy_menu, @dialy_entries, @dialy_categories = load_dialy_menu
    
  end
end

