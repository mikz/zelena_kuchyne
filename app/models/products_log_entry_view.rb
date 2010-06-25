class ProductsLogEntryView < ProductsLogEntry
  set_table_name 'products_log_view'
  
  def total_cost
    # i love private methods
    # i hate ruby, i hate ruby, i hate ruby
    super(true)
  end
end