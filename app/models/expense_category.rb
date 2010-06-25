class ExpenseCategory < ActiveRecord::Base
  has_many :expenses
  
  def self.by_day(first_date, second_date)
    ExpenseCategory.find(:all, :select => "id, name, expense_owner, SUM(cost) AS cost", :from => "expense_categories_by_day_view", :group => "id, name, expense_owner", :conditions => ["date::date BETWEEN ? AND ?",first_date,  second_date])
  end
  
  def self.average_by_day(first_date, second_date)
    days = Day.between(first_date, second_date)
    self.by_day(first_date, second_date).collect { |category|
      category[:cost] = category[:cost].to_f/days.size
      category
    }
  end
end
