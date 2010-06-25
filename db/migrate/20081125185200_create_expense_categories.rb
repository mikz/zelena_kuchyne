class CreateExpenseCategories < ActiveRecord::Migration
  def self.up
    sql_script 'expense_categories_up'

  end

  def self.down
    sql_script 'expense_categories_down'
  end
end
