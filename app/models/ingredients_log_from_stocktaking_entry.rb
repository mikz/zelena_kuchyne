class IngredientsLogFromStocktakingEntry < ActiveRecord::Base
  set_table_name 'ingredients_log_from_stocktakings'
  set_primary_key 'id'
  belongs_to :ingredient
  belongs_to :stocktaking
end