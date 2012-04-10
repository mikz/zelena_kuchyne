# -*- encoding : utf-8 -*-

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  include UserSystem
#  include LocalesSystem
  include WillPaginateMod
  include Includers
  include SnippetsSystem
  
  helper_method :locales, :version
    
  ActionView::Base.field_error_proc = Proc.new {|html_tag, instance|  html_tag  }

  rescue_from  ActionController::UnknownAction, UserSystem::AccessDenied, ActionController::RoutingError, ActiveRecord::RecordNotFound, :with => :not_found
  rescue_from  UserSystem::LoginRequired, :with => :forbidden

  def initialize #:nodoc:
    super
    # Don't look. Seriously, the line just under this one is only in your imagination.
    # What line? No one, that's who. Look! Behind you!
    ApplicationController.save_instance(self)
  end
  
  def self.save_instance(c) #:nodoc:
    @instance = c
  end
  
  def self.get_controller #:nodoc:
    @instance
  end
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery# :secret => self.session.first[:secret]
  
  # Stores current location to be returned to in the future.
  # Redirection is accomplished using ApplicationController#redirect_back_or_default.
  def store_location
    session[:return_to] = request.request_uri
  end
  
  # Redirects to the last stored location (see ApplicationController#store_location).
  # If there is no previously stored url in session, instead passes options to normal redirect.
  # Note that the stored location is erased from the session upon this redirect.
  def redirect_back_or_default(default)
    session[:return_to] ? redirect_to(session[:return_to]) : redirect_to(default)
    session[:return_to] = nil
  end
  
  def redirect_back_or_fallback(fallback = {}, response_status = {})
    begin
      redirect_to :back, response_status
    rescue ActionController::RedirectBackError
      redirect_to fallback, response_status
    end
  end
  
  def active_section
    'nothing'
  end
  
  helper_method :active_section
  
  # Under production mode, this eval _should_ happen once for each controller only.
  # That _should_ make it significantly faster than a variable and an accessor.
  def self.active_section(section)
    self.class_eval %{
      def active_section
        '#{section}'
      end
    }
  end
  

  
  # Provides version string
  def version
    'HEAD'
  end
  
protected
  # This method is called when an exception occurs sometime during the request evaluation.
  # It attempts to gather available information on the exception and render it in a friendly form using either AJAX or pure HTML
  def rescue_action(e)

    # sometimes, Rails likes to pass you instance variables that you don't want
    # this should get rid of any junk that the previous renders left behind that rails failed to clean up
    erase_render_results
    #forget_variables_added_to_assigns
    reset_variables_added_to_assigns
    
    @error = e
    debugger
    @error_name = e.class.to_s.demodulize.underscore
    if(@error.backtrace.length == 1)
      # sometimes, Rails likes to screw with the exception just to piss off unsuspecting programmers
      @error_trace = @error.backtrace.first.gsub('<', '&lt;').gsub('>', '&gt;').gsub(/([ \n\r\t]+[0-9]+\:)/, '<br />\0')
      @error_message = "#{@error.class.to_s} #{@error.clean_message.gsub('<', '&lt;').gsub('>', '&gt;')}<br />"
    else
      @error_trace = @error.backtrace
      @error_message = @error.to_s.gsub('<', '&lt;').gsub('>', '&gt;')
    end
    if(@error.respond_to? :status_code)
      @status = @error.status_code
    elsif(DEFAULT_RESCUE_RESPONSES.has_key? @error.class.to_s)
      @status = DEFAULT_RESCUE_RESPONSES[@error.class.to_s]
    else
      @status = DEFAULT_RESCUE_RESPONSE
    end
    
    if logger.level > Logger::INFO
      logger.error %{
    Processing #{self.class.name}\##{action_name} (for #{request_origin}) [#{request.method.to_s.upcase}]
    Session ID: #{@_session.session_id if @_session and @_session.respond_to?(:session_id)}
    Parameters: #{respond_to?(:filter_parameters) ? filter_parameters(params).inspect : params.inspect}}
    end
    logger.error %{
    Error: #{@error.clean_message}  (status: #{@status})
    Trace: #{(@error_trace.is_a? Array)? @error_trace.join("\n\t   ") : @error_trace }
    }

    respond_to do |format|
      format.html do
        begin
          render :partial => "shared/errors/error", :layout => 'error', :status => @status
        rescue
          super(e)
        end
      end
      format.js do
        begin
          render :template => "shared/errors/error"
        rescue
          render :update do |page|
            page.alert "There has been an error, and then another error occured while first error was being processed... Too bad. The original error was: #{@error.to_s}."
            page.alert "The additional error was: #{$!.to_s}."
          end
        end
      end
    end
    
    rescue_with_handler(e) or notify_airbrake(e)
  end
  
  def not_found
  end

  def forbidden
  end
  
  def load_dialy_menu id=nil
    if id
      menu = DialyMenu.find(id)
    else
      menu = DialyMenu.first(:conditions=>"date = current_date")
    end
    return nil unless menu
    
    entries = ActiveSupport::OrderedHash.new
    menu.entries.each do |entry|
      entries[entry.category] ||= []
      entries[entry.category] << entry
    end
    categories = {}
    entries.each do |category, meals|
      categories[:first] ||= category if meals.any?(&:in_menu?)
      categories[:last] = category if meals.any?(&:in_menu?)
    end
    [menu, entries, categories]
  end
end

