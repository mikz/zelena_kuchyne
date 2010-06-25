class ProductsLogWarningView < ProductsLogWarning
  set_table_name 'products_log_warnings_view'
  belongs_to :ordered_item
end