require File.dirname(__FILE__) + '/../test_helper'

class UserSystemTest < ActiveSupport::TestCase                   
  fixtures :users, :scheduled_meals

  def test_getter_setter
    user = users(:peter)
    controller = fake_controller
    
    # test guest session
    assert !controller.logged_in?
    assert controller.current_user.is_a?(UserSystem::Guest)
    assert !UserSystem.logged_in?
    assert UserSystem.current_user.is_a?(UserSystem::Guest)
    
    # test signing in
    controller.current_user = user
    assert controller.logged_in?
    assert_equal user, controller.current_user
    assert UserSystem.logged_in?
    assert_equal user, UserSystem.current_user
    
    # test signing out
    controller.current_user = nil

    assert !controller.logged_in?
    assert controller.current_user.is_a?(UserSystem::Guest)
    assert !UserSystem.logged_in?
    assert UserSystem.current_user.is_a?(UserSystem::Guest)
    
    # test that session gets reloaded 
    controller = fake_controller_with_session_user(user)

    assert controller.logged_in?
    assert_equal user, controller.current_user
    assert UserSystem.logged_in?
    assert_equal user, UserSystem.current_user
  end
  
  def test_login_required
    user = users(:peter)
    controller = fake_controller
    
    assert_raise UserSystem::LoginRequired do
      controller.login_required
    end
    
    controller.current_user = user
    assert_nothing_raised do
      controller.login_required
    end
  end
  
  def test_access_control
    peter = users(:peter)
    martin = users(:martin)
    
    controller = fake_controller
    
    assert_raise UserSystem::AccessDenied, UserSystem::LoginRequired do
      controller.must_belong_to(:admins)
    end
    
    controller.current_user = peter
    assert_raise UserSystem::AccessDenied, UserSystem::LoginRequired do
      controller.must_belong_to(:admins)
    end
    assert_raise UserSystem::AccessDenied, UserSystem::LoginRequired do
      controller.must_belong_to(:admins, :customers)
    end
    assert_nothing_raised do
      controller.must_belong_to_one_of(:admins, :customers)
    end
    
    controller.current_user = martin
    
    assert_nothing_raised do
      controller.must_belong_to(:admins, :customers)
    end
    assert_nothing_raised do
      controller.must_belong_to_one_of(:admins, :customers)
    end
  end
  
  def test_guest
    controller = fake_controller
    guest = UserSystem::Guest.new(controller.session)
    
    # test attributes
    assert controller.session.has_key?(:guest_id)
    assert_equal controller.session[:guest_id], guest.id
    assert guest.guest?
    assert guest.belongs_to?(:guests)
    assert !guest.belongs_to?(:customers)
    assert_equal 'not logged in', guest.login
    assert_equal Configuration.default_language, guest.interface_language
    
    # test basket
    assert guest.basket.nil?
    
    deliver = scheduled_meals(:scheduled_meal_1).scheduled_for.to_s
    id = scheduled_meals(:scheduled_meal_1).meal.item_id
    OrderedItem.add_to_user :user => guest, :deliver_at => deliver, :item_id => id, :amount => 1
    assert guest.basket.is_a?(::Order)
    assert_equal 'basket', guest.basket.state
    
    # test interface_language update
    guest.interface_language = 'en'
    assert_equal 'en', controller.session[:interface_language]
    
    # test preconfigured interface_language
    controller = fake_controller
    controller.session[:interface_language] = 'en'
    guest = UserSystem::Guest.new(controller.session)
    
    assert_equal 'en', guest.interface_language
    
    # test changes from outside    
    controller.session[:interface_language] = 'cs'
    assert_equal 'cs', guest.interface_language
    controller.session.delete(:interface_language)
    assert_equal Configuration.default_language, guest.interface_language
  end
end