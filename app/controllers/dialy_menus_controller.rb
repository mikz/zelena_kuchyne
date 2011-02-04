class DialyMenusController < ApplicationController
    include_stylesheets 'jquery-ui'
    include_javascripts 'dialy_menu'
    before_filter(:except => [:show]) { |c| c.must_belong_to_one_of(:admins)}
    before_filter :load
    exposure :title => 'date'

    def index
      @records = DialyMenu.paginate(:page => params[:page], :order => params[:order] || "date DESC")
    end

    def show
      @record, @entries, @categories = load_dialy_menu(params[:id])
      
      return render :action => "not_found" unless @record
      
      respond_to do |format|
        format.html
        format.js
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
            flash[:notice] = t(:update_successful)
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
      @flags = MealFlag.all_in_dialy_menu
    end

end
