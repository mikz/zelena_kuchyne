class DeliveryMenController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  include_javascripts 'calendar_widget', 'tooltip'
  
  def index
    @date = Day.find_by_scheduled_for CalendarWidget.parse(params[:date]).first
    @dates = Day.find(:all).collect {|day| day.scheduled_for }
    unless @date
      render :action => "no_scheduled_meals"
      return
    end
    @scheduled_meals = ScheduledItem.total :all, :conditions => ["scheduled_for = ?", @date.scheduled_for], :include => [:item], :order => "item_id DESC"
    @scheduled_items = ScheduledItem.find :all, :conditions => ["scheduled_for = ?", @date.scheduled_for], :include => [:item], :order => "item_id DESC"
    @delivery_men = DeliveryMan.find :all
    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace "delivery_men", :partial => "delivery_men"
          page << '$("td.need_info").need_info();'
        end
      end
      format.html do
        render
      end
    end
  end
  
  def update_items
    ItemInTrunk.update_items(params[:item_in_trunk])
    redirect_to :action => :index, :date => params[:item_in_trunk]['scheduled_for']
  end
  
  def add_item
    @record = ItemInTrunk.find_by_item_id_and_deliver_at_and_delivery_man_id(params[:item_in_trunk]['item_id'], params[:item_in_trunk]['deliver_at'],params[:item_in_trunk]['delivery_man_id'])
    if @record
      @record.amount = @record.amount + params[:item_in_trunk]["amount"].to_i
    else
      @record = ItemInTrunk.new params[:item_in_trunk]
    end
    if(@record.save)
      respond_to do |format|
        format.html do
          redirect_to :action => :index, :date => params[:item_in_trunk]['deliver_at']
        end
      end
    else
      respond_to do |format|
        format.html do 
          flash[:notice] = locales[:error_adding_item_in_trunk]
          redirect_to :action => :index, :date => params[:item_in_trunk]['deliver_at']
        end
      end
    end
  end
end
