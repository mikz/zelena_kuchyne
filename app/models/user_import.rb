class UserImport < ActiveRecord::Base
  set_table_name "user_import"
  set_primary_key "iduziv"
  belongs_to :user
  
  attr_accessor :duplicity
  
  def method_missing attr, *args
    method = attr.to_s.split(/^(.+)?_fix$/)
    if method.is_a?(Array) && method.size == 2
      val = self.send method[1]
      return val.gsub("ą","š").gsub("ľ","ž").gsub("®","Š")
    end
    super
  end
  
  def self.find_bad_associations
    emails = self.find_by_sql "SELECT email, count(*) as count FROM user_import GROUP BY email"
    emails.delete_if do |e|
      !(e.count.to_i > 1)
    end
    imports = self.find :all, :conditions => ["email IN (?)", emails.collect {|e| e.email }], :include => :user
    @bad_associations = {}
    imports.each do |i|
      @bad_associations[i.email] = {:imports => [], :users => [] } unless @bad_associations.has_key? i.email
      if i.user
        @bad_associations[i.email][:users].push i.user unless @bad_associations[i.email][:users].include?(i.user)
      end
      @bad_associations[i.email][:imports].push i
    end
    @bad_associations.each_pair do |email,data|
      data[:users] = User.find :all, :conditions => ["email = ?", email] if data[:users].blank?
    end
    @bad_associations
  end
  
  def match_user(options={})
    return if user
    options[:method] ||= :email
    duplicty = false
    case options[:method]
      when :email
        users = User.find :all, :conditions => ["email = ?", self.email] , :include => :user_profiles
        if users.size == 1
          self.user = users.first
        else
          duplicity = true
        end
      when :login
        users = User.find :all, :conditions => ["login = ?", self.loginname] , :include => :user_profiles
         if users.size == 1
           self.user = users.first
         else
           duplicity = true
         end
    end
    match_user(:method => :login) if duplicity && options[:method] == :email
  end
  
  def inspect_html
    attributes_as_list = self.class.column_names.collect { |name|
      if has_attribute?(name) && !self.send(name).blank?
        "<li><strong>#{name}</strong>: #{attribute_for_inspect(name)}</li>"
      end
    }
    %{
      <ul>#{attributes_as_list}</ul>
    }
  end
  
  def translate_attributes
    {
      :loginname => :user_login,
      :passwduziv => :password,
      :jmeno => :first_name,
      :prijmeni => :family_name,
      :email => :email,
      :telefon => :phone_number,
      :adresa => :home_address,
      :mesto => :city,
      :psc => :zip,
      :dodani => :activate_delivery_address,
      :jmenodod => :first_name,
      :prijmenidod => :family_name,
      :adresadod => :delivery_address,
      :mestodod => :city,
      :pscdod => :zip,
      :firma => :company_name,
      :ico => :company_registration_no,
      :dic => :company_tax_no,
      :objednavek => :users_orders,
      :cena_objednavek => :imported_orders_price,
      :sleva => :discount,
      :last_order => :last_order
    }
  end
  

  protected
  
  
  def validate
    if !user
      if duplicity
        errors.add("user","Duplicitní email.")
      else
        errors.add("user","Uživatel nenalezen.")
      end
    end
    
  end
end