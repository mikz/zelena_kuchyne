class DialyMenusController < ApplicationController
    include_stylesheets 'jquery-ui'
    include_javascripts 'dialy_menu'
    before_filter { |c| c.must_belong_to_one_of(:admins)}
    before_filter :load
    exposure :title => 'date'
    
    def show
      unless params[:id]
        @record = DialyMenu.first(:conditions=>["date = ?", Date.today])
        raise ActiveRecord::RecordNotFound.new unless @record
      end
      
      @record ||= DialyMenu.find(params[:id])

      @hash = ActiveSupport::OrderedHash.new
      @record.meals.each do |meal|
        @hash[meal.category] ||= []
        @hash[meal.category] << meal
      end
      @record.entries.each do |entry|
        @hash[entry.category] ||= []
        @hash[entry.category] << entry
      end
    end
    
    def update
      @record = DialyMenu.find(params[:id])
      @record.attributes = params[:record]
      
      disabled = []
      params[:scheduled].reject! { |key, val|
        val.to_i == 0 && disabled.push(key)
      } unless params[:scheduled].blank?

      @record.disabled.clear
      disabled.each do |item_id|
        @record.disabled.build :item_id => item_id.to_i
      end
      
      entries = @record.entries.index_by &:id
      
      delete = []
      params[:entries].each_pair do |id, attrs|
        destroy = attrs.delete(:_destroy).to_i == 1
        
        if entry = entries[id.to_i]
          if destroy
            delete << entry
          else
            entry.attributes = attrs
          end
        else
          entry = @record.entries.build attrs unless destroy
          if entry
            entry.valid? 
          end
        end
      end unless params[:entries].blank?
      
      @record.entries.delete *delete
      
      
      if(@record.save and @record.errors.empty?)
        respond_to do |f|
          format f, :html do
            flash[:notice] = locales[:update_successful]
            redirect_back_or_default :action => 'show', :id => @record
          end
          format f, :xml do
            head :ok
          end
          format f, :js do
            if(request.referer =~ /^#{url_for(:action => 'index')}/)
              render :action => 'show'
            else
              render :update do |page|
                page.redirect_to :action => 'index'
          end
        end
          end
        end
      else
        DEBUG{%w{@record.errors}}
        respond_to do |f|
          format f, :html do
            redirect_to :action => 'edit'
          end
          format f, :xml do
            render :xml => @record.errors, :status => 422
          end
          format f, :js do
            render :action => 'error'
          end
        end
      end
    end
    
    
    private
    def load
      @categories = MealCategory.all
    end
end
