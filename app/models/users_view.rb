class UsersView < ActiveRecord::Base
  has_many :orders, :foreign_key => :user_id
  has_many :groups, :through => :memberships, :order => "groups.title ASC", :foreign_key => "user_id"
  has_many :memberships, :foreign_key => :user_id
  has_many :user_profiles, :foreign_key => :user_id
  has_many :addresses, :foreign_key => :user_id
  has_many :user_discounts, :foreign_key => :user_id
  
  set_table_name 'users_view'
  #
  #is_indexed :fields => [
  #  {:field => :login, :sortable => true }, :email, :user_discount, :spent_money ],
  #  :concatenate => [
  #    {:fields => [:addr_first_name, :addr_family_name, :addr_company_name, :street, :house_no, :city, :zip], :as => "address"},
  #    {:fields => [:first_name, :family_name, :company_name], :as => "name"},
  #    {:class_name => "Group", :association_sql => 'LEFT JOIN memberships ON users_view.id = memberships.user_id LEFT JOIN groups ON memberships.group_id = groups.id', :field => "system_name", :as => 'group'}
  #  ], :conditions => "users_view.guest = false"
  #
  
  def name
    if self.first_name or self.family_name
      "#{self.first_name} #{self.family_name}"
    else
      self.login
    end
  end
  
  def zone_name
    self.address.zone.name if address && address.zone
  end
  
  def delivery_address
    %{#{self.street} #{self.house_no} <br/>
      #{self.city}, #{self.district}} if self.street and self.house_no and self.city and self.district
  end
  
  def address
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
end
