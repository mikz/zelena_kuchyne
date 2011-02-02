require 'digest/sha2' 

class User < ActiveRecord::Base
  has_many :orders
  has_many :groups, :through => :memberships, :order => "groups.title ASC"
  has_many :memberships
  has_many :user_profiles
  has_many :addresses
  has_many :user_discounts
  has_one  :active_user_discount, :class_name => "UserDiscount", :conditions => "now() BETWEEN user_discounts.start_at AND COALESCE(user_discounts.expire_at, now())"
  has_one  :user_token
  has_one  :user_import
  has_many :poll_votes
  has_many :poll_answers, :through => :poll_votes
  belongs_to :zone
  belongs_to :user_view, :foreign_key => 'id', :class_name => "UsersView"
  
  attr_accessor :password
  attr_accessor :user_agreement
  attr_accessor :basket
  
  before_save :encrypt_password
  before_validation :disable_addresses
  after_create :add_default_groups
  after_save   :update_profiles, :update_groups, :create_addresses, :save_addresses
  
  validates_presence_of :password, :password_confirmation, :on => :create, :message => "Toto pole je povinné. "
  validates_presence_of :login, :message => "Toto pole je povinné. "
  validates_length_of :login, :within => 2..50, :too_short => "Minimální délka jsou %d znaky. ", :too_long => "Maximální délka je %d znaků. "
  validates_length_of :email, :within => 5..50, :too_short => "Minimální délka je %d znaků. ", :too_long => "Maximální délka je %d znaků. "
  validates_length_of :family_name, :company_name, :first_name, :allow_nil => true, :allow_blank => true, :maximum => 100, :too_long => "Maximální délka je %d znaků. "
  validates_length_of :password, :within => 5..32, :if => :password?, :too_short => "Minimální délka je %d znaků. ", :too_long => "Maximální délka je %d znaků. "
  validates_confirmation_of :password, :message => "Musíte potvrdit heslo. ", :if => :password?
  validates_presence_of :password_confirmation, :if => :password?, :message => "Musíte potvrdit heslo. "
  validates_uniqueness_of :login, :case_sensitive => false, :message => "Přihlašovací jméno již existuje. "
  validates_format_of :login, :with => /^[a-z]+([\._]?[a-z]+)+[0-9]*$/, :if => :login?, :message => "Špatný formát přihlašovacího jména. "
  validates_associated :addresses
  validates_format_of :email, :with => /^[a-z0-9\.\_\%\+\-]+@[a-z0-9\-\.\_]+\.[a-z]{2,4}$/i, :if => :email?, :message => "Špatný formát emailu. "
  validates_format_of :phone_number, :with =>/^[\d]{5,15}$/, :if=> :phone_number?, :message => "Špatný formát tel. čísla. "
  validates_length_of :company_registration_no, :minimum => 1, :if => :company_name? , :message => "Toto pole je povinné pokud vyplníte název společnosti. "
  validates_length_of :first_name, :minimum => 1, :if => :family_name?, :message => "Toto pole je povinné pokud vyplníte přijmení. "
  validates_length_of :family_name, :minimum => 1, :if => :first_name?, :message => "Toto pole je povinné pokud vyplníte křestní jméno. "
  validates_length_of :first_name, :minimum => 1, :unless => :name_or_company, :message => "Musíte vyplnit jméno a přijmení nebo název společnosti. "
  validates_length_of :family_name,:minimum => 1, :unless => :name_or_company, :message => "Musíte vyplnit jméno a přijmení nebo název společnosti. "
  validates_length_of :company_name ,:minimum => 1, :unless => :name_or_company, :message => "Musíte vyplnit jméno a přijmení nebo název společnosti. "
  validates_format_of :company_registration_no, :with => /^\d{5,15}$/,:if => :company_registration_no?, :message => "IČ musí být 5 až 15 číslic. "
  validates_acceptance_of :user_agreement, :accept => true, :message => "Musíte schválit podmínky použití. ", :on => :create
  validates_format_of :company_tax_no, :with => /^[A-Z]{2}.{5,15}$/, :if => :company_tax_no?, :message => "Špatný formát."
  
  attr_protected :imported_orders_price, :admin_note #FIXME: problems with user_profiles when using attr_accessible
  

  
  def validate
    err = []
    for address in addresses
      address.valid?
    end  
    errors.each do |attr, msg|
        err.push [attr,msg]
    end
    errors.clear
    err.each do |attr,msg|
      errors.add "user_#{attr}", msg
    end
    for address in addresses
      address.errors.each do |attr, msg|
        self.errors.add "#{address.address_type}_address_#{attr}", msg
      end
    end
  end
  
  # Login using name and password
  def self.authenticate(login, password)
    user = find_by_login(login) # need to get salt
    if(user and user.authenticated?(password))
      user
    else
      nil
    end
  end
  
  # Checks whether the user has the correct password
  def authenticated?(password)
    password_hash == encrypt(password)
  end
  
  # Encrypts data using instance salt.
  def encrypt(data)
    self.class.encrypt(data, salt)
  end
  
  # Encrypts data using a given salt.
  # Uses SHA256 for encryption.
  def self.encrypt(data, salt)
    Digest::SHA256.hexdigest("--#{salt}--#{data}--")
  end

  def method_missing(method, *args)
    attr = method.to_s
    list = UserProfileType.cached_list
    if(list.has_key?(attr.gsub('=', '')))
      return (attr.include?('=') ? self.set_profile(attr.gsub('=', ''), args[0]) : self.read_profile(attr))
    elsif(method.to_s == 'home_address=' || method.to_s == 'delivery_address=')
      return self.set_address(method.to_s.split('_')[0], *args)
    elsif (attr =~ /\?$/) && !(attr =~ /_changed\?$/)
      return !self.send(attr.chop).blank?
    else
      return super(method, *args)
    end
  end
  
  def read_profile(attr)
    list = UserProfileType.cached_list
    @profiles = {} unless(@profiles.is_a? Hash)
    if(@profiles[list[attr]])
      return @profiles[list[attr]]
    else
      self.user_profiles.each do |profile|
        @profiles[profile.field_type] ||= profile.field_body
      end
      return @profiles[list[attr]]
    end
  end
  
  def set_profile(attr, value)
    list = UserProfileType.cached_list
    @profiles = {} unless(@profiles.is_a? Hash)
    @profiles[list[attr]] = value
    @profiles_changed ||= [];
    @profiles_changed.push list[attr]
    @profiles_changed.uniq!
  end
  
  def set_address(type, data)
    for address in self.addresses
      if address.address_type == type
        address.attributes = data
        done = true
      end
    end
    unless done
      self.addresses << self.addresses.new(data) { |a| a.address_type = type }
    end
  end
  
  def activate_delivery_address=(val)
    @activate_delivery_address = !val.blank? && val.to_i == 1
  end
  
  def activate_delivery_address
    @activate_delivery_address
  end
  
  def mass_menu
    read_profile('mass_menu') == 't'
  end

  def mass_menu= val
    set_profile('mass_menu', (val.to_s.to_i == 1 || val == true)? true : false )
  end
  
  def update_profiles
    return unless @profiles_changed
    query = "DELETE FROM user_profiles WHERE user_id = #{self.id} AND field_type IN (#{@profiles_changed.join(',')});"
    self.connection.execute query
    @profiles_changed.each do |type_id|
      self.user_profiles.create({:field_type => type_id, :field_body => @profiles[type_id]})
    end
    true
  end
  
  def pagination_setting
    if read_profile("pagination_setting")
      return read_profile("pagination_setting").to_i
    else
      return Configuration.default_pagination.to_i
    end
  end
  
  def belongs_to?(group)
    return true if group.to_s == 'users'
    unless @roles.is_a? Array
      @roles = []
      for role in self.groups
        @roles.push role.system_name.to_s
      end
    end
    if(@roles.include? group.to_s)
      return true
    else
      return false
    end
  end
  
  def admin?
    self.belongs_to? :admins
  end
  
  def belongs_to_one_of?(*groups)
    groups.each do |g|
      return true if belongs_to? g
    end
    return false
  end
  
  def address    
    res = {}
    self.addresses.each {|addr| res[addr.address_type.to_sym] = addr}
    res
  end
  
  def basket
    @basket ||= Order.find :first, :conditions => "orders.user_id = #{self.id} AND state = 'basket'", :include => [:user,{:user=>:user_discounts}, :items]
    @basket
  end
  
  def active_discounts options={}
    @discounts = []
    if options[:item_type] and options[:item_type] != "product" 
      discount_class = "meal"
    else
      discount_class = "product"
    end
    for d in user_discounts
      if (d.start_at <= options[:date]) and ( (d.expire_at || options[:date]) >= options[:date] ) and (d.discount_class == discount_class)
        @discounts.push d
      end
    end
    return @discounts
  end

  def guest?
    false
  end
  
  def name
    if self.first_name? and self.family_name?
      "#{self.first_name} #{self.family_name}"
    else
      self.login
    end
  end
  
  def last_name
    self.family_name
  end
  
  def delivery_address
    arr = {}
    for address in self.addresses
      arr[address.address_type] = address
    end
    
    if arr.has_key? 'delivery'
      return arr['delivery']
    end
    
    if arr.has_key? 'home'
      return arr['home']
    end
    
    return nil
  end

  def roles
    roles = []
    self.groups.each do |group|
      roles.push group.title
    end
    roles.join ', '
  end
  
  def groups=(newgroups)
    @remove_groups = self.groups.collect {|group| group.id.to_s}
    @add_groups = newgroups
    newgroups.each do |group|
      if @remove_groups.include?(group)
        @remove_groups.delete(group)
        @add_groups.delete(group)
      end
    end
  end
  
  def interface_language
    super ? super : Configuration.default_language
  end
  
  def total_orders_price
    @total_orders_price = self.imported_orders_price + OrderView.sum_for_user(self)
    @total_orders_price
  end
  
  def delivery_times_limit
    limit = {}
    unless delivery_time_limit_from.blank?
      limit[:from_orig] = delivery_time_limit_from
      limit[:from] = Time.parse(limit[:from_orig])
    end
    unless delivery_time_limit_to.blank?
      limit[:to_orig] = delivery_time_limit_to
      limit[:to] = Time.parse(limit[:to_orig])
    end
    limit
  end
  
  def limited_delivery_times?
    !delivery_time_limit_from.blank? || !delivery_time_limit_to.blank?
  end
  
  # generates random password with default lenght 8 characters
  def self.random_password(size = 8)
    chars = (('a'..'z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l 0)
    (1..size).collect{|a| chars[rand(chars.size)] }.join
  end
  
  protected
  
  def disable_addresses
    self.addresses.each do |address|
      address.disabled = !activate_delivery_address if address.address_type == 'delivery'
    end
  end
  
  def add_default_groups
    default_groups = Group.find(:all, :conditions => 'default_group = true')
    self.groups << default_groups
  end
  
  def create_addresses  
    return if @new_addresses.nil? or @new_addresses.empty?
    @new_addresses.each do |addr|
      self.addresses.new(addr)
    end
  end
  
  def save_addresses
    for address in self.addresses
      address.disabled ? address.destroy : address.save
    end
    update_basket
  end

  def update_groups
    @remove_groups.each do |group|
      Membership.delete_all("group_id = #{group} AND user_id = #{id}")
    end unless @remove_groups.nil?
    
    return if @add_groups.nil? or @add_groups.empty?
    @add_groups.each do |group|
      self.memberships.create({:group_id => group})
    end
  end
  
  # Encrypts password and generates salt.
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA256.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.password_hash = encrypt(password)
  end
  
  private
  
  def update_basket
    return unless self.basket
    self.basket.update_delivery_method(true) if self.basket.delivery_method_without_autoload.nil? || self.basket.delivery_method_without_autoload.zone != self.delivery_address.zone
  end
  
  def name_or_company
     return (first_name? && family_name?) || company_name?
  end
  
end
