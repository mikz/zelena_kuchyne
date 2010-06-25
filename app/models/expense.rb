class Expense < ActiveRecord::Base
  belongs_to :user
  belongs_to :expense_category
  
  validates_presence_of :name, :bought_at, :price, :user, :expense_category_id
  validates_inclusion_of :expense_owner, :in => %w{ delivery restaurant office}
  validates_presence_of :premise_id, :if => Proc.new {|e| e.expense_owner == "restaurant" }
  validates_inclusion_of :premise_id, :in => [nil], :if => Proc.new {|e| e.expense_owner != "restaurant" }
  
  def user_login= login
    self.user = User.find_by_login login
  end
    
  def user_login
    (self.user)? self.user.login : nil
  end
  
  def validate
    current_user = UserSystem.current_user
    unless current_user.belongs_to?("admins")
      errors.add("user", "this is not you") if self.user != UserSystem.current_user
    end
    
    err = errors.clone
    errors.clear
    err.each do |attr,msg|
      attr += "_login" if attr == "user"
      errors.add(attr,msg)
    end
  end
  
  def destroy
    current_user = UserSystem.current_user
    if current_user == self.user || current_user.belongs_to?("admins")
      super
    end
  end

  def self.expense_owners
    ["delivery","restaurant","office"].collect { |item|
      [LocalesSystem.locales["expense_owner_#{item}"], item]
    }
  end
  
  def self.find_values from_column, query = "", limit = 10, distinct = true
    raise "#{from_column} isn't allowed column." unless ["name", "note"].include?(from_column)
    query = %{
      SELECT #{'DISTINCT' if distinct} #{from_column} FROM #{self.table_name}
      WHERE #{from_column} ILIKE #{self.connection.quote "%#{query}%"}
      ORDER BY #{from_column}
      LIMIT #{limit.to_i}
    }
    self.connection.select_values query
  end
  def self.days
    self.connection.select_values "SELECT DISTINCT bought_at::date FROM expenses;"
  end
end