class IngredientsLogWatchdogView < IngredientsLogWatchdog
  set_table_name "ingredients_log_watchdogs_view"
  
  def self.check_date date
    IngredientsLogWatchdogView.find_by_sql "SELECT w.*,i.name as ingredient_name, i.unit as ingredient_unit, w.balance AS balance FROM ingredients_log_watchdogs_view_for_day(#{self.connection.quote(date.to_s)}) w LEFT JOIN ingredients i ON i.id = w.ingredient_id"
  end
end