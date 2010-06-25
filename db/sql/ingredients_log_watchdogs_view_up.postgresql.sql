CREATE VIEW ingredients_log_watchdogs_view AS SELECT 
  ingredients_log_watchdogs.*,
  CASE
    WHEN operator = 100::bit(3)  THEN value <  COALESCE(amount,0)
    WHEN operator = 110::bit(3)  THEN value >= COALESCE(amount,0)
    WHEN operator = 010::bit(3)  THEN value =  COALESCE(amount,0)
    WHEN operator = 011::bit(3)  THEN value <= COALESCE(amount,0)
    WHEN operator = 001::bit(3)  THEN value <  COALESCE(amount,0)
    WHEN operator = 000::bit(3)  THEN value != COALESCE(amount,0)
  END AS state,
  day AS day,
  amount
FROM ingredients_log_watchdogs
LEFT JOIN ingredients_full_log_per_day_view ON ingredients_full_log_per_day_view.ingredient_id = ingredients_log_watchdogs.ingredient_id;
