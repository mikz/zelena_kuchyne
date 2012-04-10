# coding: utf-8

namespace :mailer do
  desc "Send tomorrow menu to users."
  task :tomorrow_menu => [:environment, :init_fake_controller] do
    @date = Date.tomorrow
    @categories = MealCategory.find :all, :include => [{:meals => :scheduled_meals}], :conditions => "meals.always_available = true OR scheduled_meals.scheduled_for = '#{@date.to_s}'"
    @scheduled_bundles = ScheduledBundle.find(:all, :conditions => ["scheduled_bundles.scheduled_for = ?", @date.to_s], :include => [{:bundle => {:meal => :meal_category}}])
    @scheduled_bundles.each {|sb|
      @categories.each {|c|
        c.meals.push sb.bundle if c == sb.bundle.meal.meal_category
      }
    }
    @menus = Menu.find :all, :include => [:meals, :scheduled_menus], :conditions => "scheduled_menus.scheduled_for = '#{@date.to_s}'"
    users = User.find :all, :joins => "LEFT JOIN user_profiles ON users.id = user_profiles.user_id and user_profiles.field_type = (SELECT id FROM user_profile_types WHERE name = 'tomorrow_menu_by_mail')", :conditions => "field_body = 'on' AND guest = false", :include => [:user_profiles, :user_discounts]
    
    ActionView::Base.send :include, ApplicationHelper
    @locales = {}
    i = 0
    size = users.size
    print "\n#{size} users found. Starting ...\n"
    silence_stream(STDERR) do
      for user in users
        @fc.current_user =  user
        # FIXME: syntax errors
        #@t(user.interface_language) = @fc.locales unless @locales.has_key? user.interface_language
        #Mailer.deliver_tomorrow_menu(user, @menus, @categories, :currency_template => @t(user.interface_language)[:currency])
        i += 1
        percent = (i.to_f/size)*100
        print "#{i} of #{size} users done (#{percent}%)\t Mail sent to '#{user.login}'\n"
      end
    end
    print "Mailing process finished\n"
  end
  
  desc "Send Échos de Belleville invitations"
  task :echosdb => [:environment] do
    #users = UsersView.find :all, :limit => 81, :order => "spent_money DESC"
    users = UsersView.find_all_by_login "mikz"
    i = 0
    ok = []
    fail = []
    size = users.size
    print "\n#{size} users found. Starting ...\n"
    for user in users
      begin
        Mailer.deliver_echosdb(user.email)
        ok << user
      rescue
        fail << user
      ensure
        i += 1
        percent = (i.to_f/size)*100
         print "#{i} of #{size} users done (#{percent}%)\t"
         if ok.include? user
           print  "Mail sent to '#{user.login}'\n"
         else
           print "Sending mail to '#{user.login}'\n failed!\n"
         end
      end
     
    end
    print "Mailing process finished\n"
  end
  
  task :init_fake_controller do
    # fakes the controller's behavior for the UserSystem
    class FakeController
      def session
        @session ||= {}
      end

      def self.helper_method(*args); end

      def initialize #:nodoc:
        super
        # Don't look. Seriously, the line just under this one is only in your imagination.
        # What line? No one, that's who. Look! Behind you!
        ApplicationController.save_instance(self)
      end

      include UserSystem
      include LocalesSystem
      
      def set_user_id(user_id)
        session[:user] = user_id
        self
      end
    end
    @fc = FakeController.new()
  end
end
