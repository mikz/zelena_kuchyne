class IngredientsLogFromMenusEntry < ActiveRecord::Base
  set_table_name 'ingredients_log_from_menus'
  set_primary_key 'id'
  belongs_to :ingredient
  belongs_to :meal
  belongs_to :scheduled_menu
end