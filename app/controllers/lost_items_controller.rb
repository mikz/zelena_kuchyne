class LostItemsController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins, :deliverymen)}
  include_javascripts 'calendar_widget', 'jquery.autocomplete', 'lost_items', 'scheduled_items'
  include_stylesheets 'jquery-ui', 'jquery.autocomplete'
  exposure :title => "item", :columns => [:user, :lost_at, :amount]
  
  def index
    dates = CalendarWidget.parse params[:id]
    @dates = Day.find(:all).collect {|day| day.scheduled_for }
    @lost_items = LostItem.find :all, :conditions => ["lost_items.lost_at::date BETWEEN ? AND ?", dates[0], dates[1] ], :order => "lost_at ASC", :include => [:item, {:user => :user_profiles}]
    
    respond_to do |format|
      format.html do
        render
      end
      format.js do
        render :update do |page|
          page.replace 'list', :partial => 'list'
        end
      end
    end
  end
  
  
  def new
    super
  end
  
  def create
    if params[:record]["users"]
      users = params[:record].delete 'users'
      for user in users
        user = User.find_by_login(user)
        params[:record]['user'] = user
        @record = LostItem.new(params[:record])
        @record.save
      end
    else
      params[:record]['user'] = User.find_by_login(params[:record]['user'])
      @record = LostItem.new(params[:record])
    end
    super
  end
  
  def update
    @record = LostItem.find_by_oid(params[:id])
    params[:record]['user'] = User.find_by_login(params[:record]['user'])
    super
  end
  
  def edit
    @record = LostItem.find_by_oid params[:id]
    super
  end
end
