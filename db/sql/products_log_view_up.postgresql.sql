CREATE VIEW products_log_view AS SELECT
  *,
  product_cost*amount AS total_cost
  FROM products_log;

CREATE VIEW products_log_balance_view AS SELECT
  products.id AS product_id,
  -amount AS amount,
  deliver_at::date AS day
  FROM ordered_items
  LEFT JOIN orders ON orders.id = order_id
  LEFT JOIN products ON ordered_items.item_id = products.item_id
  WHERE item_type = 'product' AND orders.state IN ('order','expedited','closed') AND orders.cancelled IS NOT true
  UNION ALL
  SELECT product_id, amount, day FROM products_log;

CREATE VIEW products_with_stock_view AS SELECT
  products.*,
  stock.amount,
  (COALESCE(stock.amount,0) > 0) AS on_stock,
  (COALESCE(stock.amount,0) > 0 OR term_of_delivery IS NOT NULL) AS available
  FROM products
  LEFT JOIN 
    (SELECT product_id, SUM(amount) AS amount FROM products_log_balance_view GROUP BY product_id) AS stock 
  ON stock.product_id = products.id;
