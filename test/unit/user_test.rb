require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  fixtures :users, :addresses, :user_discounts, :zones
  
  ### validation tests
  
  def test_user_creation
    user = User.new( "login"=>"admin", "first_name"=>"Admin", "family_name"=>"Adminovič", "company_name"=>"", "groups"=>["1"], "password" => "12345", "password_confirmation"=>"12345", "phone_number"=>"627669677", "email"=>"admin@zelenakuchyne.cz", "company_tax_no"=>"", "company_registration_no"=>"", "home_address"=>{"zone_id" => zones(:zone1).id, "house_no"=>"1", "city"=>"Praha", "zip"=>"12000", "company_name"=>"", "district"=>"Vinohrady", "address_type"=>"home", "family_name"=>"Adminovič", "street"=>"Jana Masaryka", "note"=>"", "first_name"=>"Generál"}, "delivery_address"=>{"house_no"=>"", "city"=>"", "zip"=>"", "company_name"=>"", "district"=>"", "address_type"=>"delivery", "family_name"=>"", "street"=>"", "note"=>"", "first_name"=>"", "zone_id" => zones(:zone2).id})
    assert_valid user   
  end
  
  def test_presence_validation
    peter = users(:peter)
    
    # login
    t = peter.login
    peter.login = ''
    assert !peter.valid?
    peter.login = t
    assert_valid peter
    
    # password confirmation
    peter.password = 'heslo'
    assert !peter.valid?
    peter.password_confirmation = 'heslo'
    assert_valid peter
    peter.password = ''
    peter.password_confirmation = ''
    assert_valid peter
    
    # password on create
    newcommer = User.new(:login => 'adolf', :email => 'adolf@users.cz', :first_name => 'Adolf', :family_name => 'Jebavý')
    assert !newcommer.valid?
    newcommer.password = 'heslo'
    newcommer.password_confirmation = 'heslo'
    assert_valid newcommer
  end
  
  def test_allowed_name_company_combinations
    peter = users(:peter)
    fn = peter.first_name
    ln = peter.family_name
    cn = peter.company_name
    
    # fn ln cn
    assert_valid peter
    
    # fn ln !cn
    peter.company_name = ''
    assert_valid peter
    
    # !fn ln !cn
    peter.first_name = ''
    assert !peter.valid?
    peter.first_name = fn
    
    # fn !ln !cn
    peter.family_name = ''
    assert !peter.valid?
    peter.family_name = ln
    
    peter.company_name = cn
    
    # !fn ln cn
    peter.first_name = ''
    assert !peter.valid?
    peter.first_name = fn
    
    # fn !ln cn
    peter.family_name = ''
    assert !peter.valid?
    peter.family_name = ln
    
    # !fn !ln cn
    peter.first_name = ''
    peter.family_name = ''
    assert_valid peter
    
    peter.company_name = ''
    assert !peter.valid?
  end
  
  def test_password_confirmation
    peter = users(:peter)
    
    peter.password = "heslo"
    peter.password_confirmation = "neheslo"
    assert !peter.valid?
    
    peter.password_confirmation = "heslo"
    assert_valid peter
  end
  
  def test_length_validations
    peter = users(:peter)
    
    t = peter.login
    peter.login = 'a'
    assert !peter.valid?
    peter.login = 'a'*51
    assert !peter.valid?
    peter.login = t
    
    t = peter.password
    peter.password = 'a'*4
    assert !peter.valid?
    peter.password = 'a'*33
    assert !peter.valid?
    peter.password = t
    
    t = peter.email
    peter.email = 'a'*51
    assert !peter.valid?
    peter.email = t
  
    t = peter.email
    peter.email = 'a'*51
    assert !peter.valid?
    peter.email = t
    
    t = peter.first_name
    peter.first_name = 'a'*101
    assert !peter.valid?
    peter.first_name = nil
    assert_valid peter
    peter.first_name = t
    
    t = peter.family_name
    peter.family_name = 'a'*101
    assert !peter.valid?
    peter.family_name = nil
    assert_valid peter
    peter.family_name = t
    
    t = peter.company_name
    peter.company_name = 'a'*101
    assert !peter.valid?
    peter.company_name = nil
    assert_valid peter
    peter.company_name = t
    
    t = peter.company_registration_no
    peter.company_registration_no = ''
    assert !peter.valid?
    peter.company_registration_no = '312' # too short unless your country has two hundred citizens and it is not believed to change in the future
    assert !peter.valid?
    peter.company_registration_no = '12354'*12 # that should be long enough to be too damn long
    assert !peter.valid?
    peter.company_registration_no = t    
  end
  
  def test_format_validation
    peter = users(:peter)
    
    t = peter.login
    peter.login = "peter.baby.oh_yeaaah"
    assert_valid peter
    
    peter.login = "peter.baby.oh_yeaaah!!"
    assert !peter.valid?
    peter.login = "peter.baby.oh__yeaaah"
    assert !peter.valid?
    peter.login = "peter.baby..oh_yeaaah"
    assert !peter.valid?
    peter.login = t
    
    t = peter.email
    peter.email = "peter.kun@zlutastaj.cz"
    assert_valid peter
    peter.email = "peter.kun@zlutastaj.czugc"
    assert !peter.valid?
    peter.email = "peter.kun@žlutastaj.cz"
    assert !peter.valid?
    peter.email = "peter.kůn@zlutastaj.cz"
    assert !peter.valid?
    peter.email = "peter/kun@zlutastaj.cz"
    assert !peter.valid?
    peter.email = "peterkun.zlutastaj.cz"
    assert !peter.valid?
    peter.email = "peterkun@zlutastaj"
    assert !peter.valid?
    peter.email = "peterkun@cz"
    assert !peter.valid?
    peter.email = "peterkun@"
    assert !peter.valid?
    peter.email = "@zlutastaj.cz"
    assert !peter.valid?
    peter.email = t
    
    t = peter.phone_number
    peter.phone_number = "556244"
    assert_valid peter
    peter.phone_number = "abcdef"
    assert !peter.valid?
    peter.phone_number = "33"
    assert !peter.valid?
    peter.phone_number = "6574769876987965746987"
    assert !peter.valid?
    peter.phone_number = t
  end
  
  def test_address_dont_validate_flag
    user = users(:peter)
    user.address[:home].zip = '13000'
    
    Address.with_mapy_cz do
      assert !user.valid?
      user.update_attributes({"home_address" => {"dont_validate" => true}})
      assert_valid user
    end
  end
  
  ### authentication tests
  
  def test_valid_login
    assert_equal(users(:peter), User.authenticate(users(:peter).login, "54321"))
  end
  
  def test_bad_login
    assert_nil User.authenticate(users(:peter).login, "bad_password")
  end
  
  ### logic tests
  
  def test_create_user_without_validation
    user = User.new(:login => "pavol", :email => "pavol@hackujeme.sk", :password => "00000")
    assert user.save_without_validation
    assert_equal user, User.find_by_login('pavol')
  end

  def test_model_authentication
    peter = users(:peter)
    assert_equal peter.password_hash, peter.encrypt('54321')
    assert peter.authenticated?('54321')
    assert !peter.authenticated?('12345')
  end
  
  def test_virtual_attributes
    peter = users(:peter)
    
    # value presence
    t = peter.login
    assert peter.login?
    peter.login = ''
    assert !peter.login?
    peter.login = t
    
    # same for all attributes    
    UserProfileType.cached_list.each do |name, id|
      assert_equal !peter.send(name.to_sym).blank?, peter.send("#{name}?".to_sym)
    end
    
    # user profiles reader
    first_name = peter.user_profiles.detect {|p| p.user_profile_type.name == 'first_name'}.field_body
    assert_equal first_name, peter.first_name
    
    # user profiles writer
    peter.first_name = 'František'
    peter.save
    peter.reload
    assert_equal 'František', peter.user_profiles.detect {|p| p.user_profile_type.name == 'first_name'}.field_body
    
    # name
    assert_equal 'František Kůň', peter.name
    peter.first_name = ''
    assert_equal peter.login, peter.name
    peter.first_name = 'Peter'
    
    # address reader
    assert peter.address.is_a?(Hash)
    assert peter.address.has_key?(:home)
    assert !peter.address.has_key?(:delivery)
    assert_equal addresses(:peter_home).attributes, peter.address[:home].attributes
    
    # basket reader
    assert peter.basket.is_a?(Order)
    assert_equal peter.basket.state, 'basket'
    
    # roles
    roles = peter.groups.collect {|gr| gr.title}.join(', ')
    assert_equal roles, peter.roles
  end
  
  def test_change_password
    users(:peter).password = "12345"
    users(:peter).save_without_validation
    assert_equal User.encrypt("12345", users(:peter).salt), users(:peter).password_hash
    assert_equal users(:peter).encrypt("12345"), users(:peter).password_hash
  end
  
  def test_group_membership
    peter = users(:peter)
    martin = users(:martin)
    
    assert !peter.guest?
    
    assert !peter.belongs_to?('guests')
    assert !peter.belongs_to?(:guests)
    
    assert peter.belongs_to?('users')
    assert peter.belongs_to?(:users)
    
    assert peter.belongs_to?('customers')
    assert peter.belongs_to?(:customers)
    
    assert !peter.belongs_to?('admins')
    assert !peter.belongs_to?(:admins)
    
    assert martin.belongs_to?('admins')
    assert martin.belongs_to?(:admins)
  end
  
  def test_active_discounts
    peter = users(:peter)
    date1 = user_discounts(:peter_discount_1).start_at
    date2 = user_discounts(:peter_discount_1).expire_at
    date3 = date1 + (date2 - date1)/2
    
    assert_equal 1, peter.active_discounts(:date => date1, :item_type => 'meal').length
    peter.active_discounts(:date => date1, :item_type => 'meal').each do |discount|
      assert discount.start_at <= date1 
      assert discount.expire_at >= date1 || discount.expire_at.nil?
    end
    
    assert_equal 1, peter.active_discounts(:date => date2, :item_type => 'meal').length
    peter.active_discounts(:date => date2, :item_type => 'meal').each do |discount|
      assert discount.start_at <= date2 
      assert discount.expire_at >= date2 || discount.expire_at.nil?
    end
    
    assert_equal 1, peter.active_discounts(:date => date3, :item_type => 'meal').length
    peter.active_discounts(:date => date3, :item_type => 'meal').each do |discount|
      assert discount.start_at <= date3 
      assert discount.expire_at >= date3 || discount.expire_at.nil?
    end
  end
  
  def test_total_orders_price
    peter = users(:peter)
    total = OrderView.sum_for_user(peter) + peter.imported_orders_price
    
    assert_equal total, peter.total_orders_price
  end
end

