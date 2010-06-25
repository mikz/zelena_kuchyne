class ProductsLogWarning < ActiveRecord::Base
  set_table_name 'products_log_warnings'
  belongs_to :ordered_item
end