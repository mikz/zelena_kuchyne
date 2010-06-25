CREATE VIEW item_tables_view AS SELECT
  item_id,
  (item_type::text || 's'::text) AS table_name,
  CASE
    WHEN item_type = 'product' THEN 'product'::discount_class
    WHEN item_type = 'meal' THEN 'meal'::discount_class
    WHEN item_type = 'menu' THEN 'meal'::discount_class
    WHEN item_type = 'bundle' THEN 'meal'::discount_class
  END AS discount_class,
  item_type
  FROM items;