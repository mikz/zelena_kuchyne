CREATE VIEW ingredients_log_full_view AS 
  SELECT day,  amount,  ingredient_id,  ingredient_price, entry_owner FROM ingredients_log_view
  UNION ALL
  SELECT day,  amount,  ingredient_id,  ingredient_price, entry_owner FROM ingredients_log
  UNION ALL
  SELECT day,  amount,  ingredient_id,  0 AS ingredient_price, NULL AS entry_owner FROM ingredients_log_from_stocktakings;
