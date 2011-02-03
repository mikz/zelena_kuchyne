# The X makes it sound cool
module Exposure
  def self.included(base)
    base.class_eval do
      def self.exposure(options = {})
        ExposureController.load(self, options)
      end
    end
  end
  
  module ExposureController
    # load ExposureController
    def self.load(base, options)
      # set up paths before we override controller_path
      base.view_paths = ["#{RAILS_ROOT}/app/views/#{base.controller_path}",
                         "#{RAILS_ROOT}/vendor/plugins/exposure/lib/views",
                         "#{RAILS_ROOT}/app/views"]
      
      # This class_eval 
      # - includes the ExposureController,
      # - sets up options into an instance variable of the controller class
      # - patches the controller_path to return an empty string (so that views may be automatically loaded from the plugin)
      base.class_eval do
        include Exposure::ExposureController
        
        # Set up options as an instance variable for the controller class
        @options = options
        @options[:model] ||= base.to_s.gsub('Controller', '').singularize.constantize
        @options[:title] ||= 'name'
        if @options[:title].is_a?(String)
          @options[:title] = {:name => @options[:title]}
        end
        @options[:columns] ||= []
        @options[:columns].map! do |column|
          if column.is_a? Hash
            column
          else
            {:name => column}
          end
        end
        
        @options[:form_fields] ||= {@options[:title][:name] => :text_field}
        if @options[:form_fields].is_a? Hash
          ff = @options[:form_fields].clone
          @options[:form_fields] = []
          ff.each_pair do |key,val|
            @options[:form_fields] << {:name => key, :type => val, :options => {}}
          end
        end
        @options[:form_fields].each {|ff|
          ff[:options] ||= {}
        }
        @options[:form] ||= {}
        @options[:content_column] ||= :inspect
        @options[:formats] ||= [:html, :js, :xml]
        @options[:read_only] ||= false
        @options[:filter_widget] = base.include?(FilterWidget)
        @options[:include] ||= []
        
        #initialize calendar widget
        include_javascripts('calendar_widget') if @options[:calendar_widget]
        
        # attribute accessor
        # (so that from the controller instance methods, you can get the options via self.class.options)
        def base.options
          @options
        end
        
        # This is the part where rails once again fail to provide a flexible architecture for just about anything
        # and we end up needing nasty hacks like this one to disable the automatic (and useless) detection of that path
        # where our views are.
        def self.controller_path
          ''
        end
      end
    end
    
    # We load the options into an instance variable so that it's visible to helpers
    def initialize
      super
      @options = self.class.options
      self.class.append_before_filter :read_only, :except => [:show, :index, :filter]
      self.class.append_before_filter :execute_procs
    end
    
    def index
      
      conditions = []
      if options[:filter_widget]
        conditions.push "#{filter_widget_conditions(params[:filter])}" if params[:filter].is_a?(Array)
      end
      if options[:calendar_widget] && params[:date]
        dates = CalendarWidget.parse(params[:date]) if params[:date] 
      end
      conditions.push "#{options[:date_column]||"date"} BETWEEN '#{dates[0]}' AND '#{dates[1]}'" if dates
      conditions = conditions.join(" AND ")
      
      @records ||= options[:model].paginate(:all, :page => params[:page], :per_page => current_user.pagination_setting, :joins => options[:joins], :include => options[:include], :conditions => conditions, :order => (params[:order] ? params[:order] : options[:title][:order] || options[:title][:name]) + ' ASC')
      respond_to do |f|
        format f, :html do
          render 'index.html'
        end
        format f, :js do 
          render 'index.js'
        end 
        format f, :xml do
          render :xml => @records
        end
        saved_formats f
      end
    end
    
    def new
      @record ||= options[:model].new
      respond_to do |f|
        format f, :html do
          render 'new.html'
        end
        format f, :js do
          render 'new.js'
        end
        saved_formats f
      end
    end
    
    def show
      @record ||= options[:model].find(params[:id])
      respond_to do |f|
        format f, :html do
          render 'show.html'
        end
        format f, :js do
          render 'show.js'
        end
        format f, :xml do
          render :xml => @record
        end
        saved_formats f
      end
    end
    
    def filter
      @records ||= options[:model].paginate(:all, :page => params[:page], :per_page => 2, :order => (params[:order] ? params[:order] : options[:title][:name]) + ' ASC', :conditions => params[:id])
      respond_to do |f|
        format f, :xml do
          render :xml => @records
        end
        format f, :html do
          render :action => 'index'
        end
        saved_formats f
      end
    end
    
    def destroy
      options[:model].find(params[:id]).destroy
      respond_to do |f|
        format f, :html do
          redirect_to :action => 'index'
        end
        format f, :xml do
          head :ok
        end
        format f, :js do
          render 'destroy.js'
        end
        saved_formats f
      end
    end
    
    def create
      @record ||= options[:model].new(params['record'])
      if(@record.save and @record.errors.empty?)
        respond_to do |f|
          format f, :html do
            flash[:notice] = t(:create_successful)
            redirect_to :action => 'index'
          end
          format f, :xml do
            render :xml => @record, :status => :created, :location => @record
          end
          format f, :js do
            if(request.referer =~ /^#{url_for(:action => 'index')}/)
              render 'create.js'
            else
              render :update do |page|
                page.redirect_to :action => 'index'
              end
            end
          end
          saved_formats f
        end
      else
        respond_to do |f|
          format f, :html do
            redirect_to :action => 'new'
          end
          format f, :xml do
            render :xml => @record.errors, :status => 422
          end
          format f, :js do
            render 'error.js'
          end
          saved_formats f
        end
      end
    end
    
    def edit
      @record ||= options[:model].find(params[:id])
      respond_to do |f|
        format f, :html do
          if(request.referer =~ /^#{url_for(:action => 'index')}/)
            session[:return_to] = request.referer
          end
          render
        end
        format f, :js do
          render 'edit.js'
        end
        saved_formats f
      end
    end
    
    def update
      @record ||= options[:model].find(params[:id])
      if(@record.update_attributes(params['record']) and @record.errors.empty?)
        respond_to do |f|
          
          format f, :xml do
            DEBUG {%w{f "xml"}}
            head :ok
          end
          
          format f, :js do
            DEBUG {%w{f "js"}}
            if(request.referer =~ /^#{url_for(:action => 'index')}/)
              render 'show.js'
            else
              render :update do |page|
                page.redirect_to :action => 'index'
          end
          
          format f, :html do
            DEBUG {%w{f "html"}}
            flash[:notice] = t(:update_successful)
            redirect_back_or_default :action => 'show', :id => @record
          end
          
          saved_formats f
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
            render "error.js"
          end
          saved_formats f
        end
      end
    end
    
    protected
    
    def read_only
      if(options[:read_only])
        raise ActionController::UnknownAction
      end
    end
    
    def format(responder, format, &block)
      if options[:formats].include? format
        responder.send format, &block
      end
    end
    
    def saved_formats responder
      @formats.each_pair do |format, block|
        responder.send format, block
      end unless @formats.blank?
    end

    def execute_procs
      @options[:form_fields].each {|field|
        field[:data] = field[:data_proc].call if field[:data_proc].is_a?(Proc)
      }
    end

    def options
      @options
    end
  end
end