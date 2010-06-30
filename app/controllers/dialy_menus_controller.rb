class DialyMenusController < ApplicationController
    include_stylesheets 'jquery-ui'
    include_javascripts 'dialy_menu'
    before_filter(:except => [:show]) { |c| c.must_belong_to_one_of(:admins)}
    before_filter :load
    exposure :title => 'date'
    
    def show
      unless params[:id]
        @record = DialyMenu.first(:conditions=>["date = ?", Date.today])
        raise ActiveRecord::RecordNotFound.new unless @record
      end
      
      @record ||= DialyMenu.find(params[:id])

      @entries = ActiveSupport::OrderedHash.new
      @record.entries.each do |entry|
        @entries[entry.category] ||= []
        @entries[entry.category] << entry
      end
      
      @categories = {}
      @entries.each do |category, entries|
        @categories[:first] ||= category if entries.any?(&:in_menu?)
        @categories[:last] = category if entries.any?(&:in_menu?)
      end
      respond_to do |format|
        format.html
        format.xml {
          render :xml => @entries.to_xml
        }
        format.json {
          render :json => @entries.to_json
        }
      end
    end
    
    def update
      @record = DialyMenu.find(params[:id])
      @record.attributes = params[:record]
      
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
