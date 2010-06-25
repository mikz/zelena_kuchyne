class ProductWithStock < Product
  set_table_name 'products_with_stock_view'
  
  def on_stock?
    on_stock
  end
  
  def disabled?
    disabled
  end
  
  def available?
    !disabled? && available 
  end
end