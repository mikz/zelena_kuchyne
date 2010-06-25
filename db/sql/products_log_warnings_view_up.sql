CREATE VIEW products_log_warnings_view AS SELECT
  products_log_warnings.*,
  amount,
  deliver_at,
  deliver_at::date AS day
  FROM products_log_warnings
  LEFT JOIN ordered_items ON ordered_item_id = ordered_items.oid
  LEFT JOIN products ON ordered_items.item_id = products.item_id
  LEFT JOIN orders ON ordered_items.order_id = orders.id
  