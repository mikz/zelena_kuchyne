CREATE VIEW ingredients_log_view AS 
  SELECT ingredients_log_view.day, SUM(ingredients_log_view.amount) AS amount, SUM(ingredients_log_view.amount*COALESCE(o.consumption,1)) AS amount_with_consumption, ingredients_log_view.ingredient_id, ingredients_log_view.ingredient_price, ingredients_log_view.meal_id, ingredients_log_view.entry_owner FROM (
    SELECT
      day,
      amount,
      ingredient_id,
      ingredient_price,
      meal_id,
      'delivery'::ingredients_log_entry_owner as entry_owner,
      consumption_id
   FROM ingredients_log_from_meals
  UNION ALL
    SELECT
      day,
      amount,
      ingredient_id,
      ingredient_price,
      meal_id,
      'delivery'::ingredients_log_entry_owner,
      consumption_id
    FROM ingredients_log_from_menus
  UNION ALL
    SELECT
      day,
      amount,
      ingredient_id,
      ingredient_price,
      meal_id,
      'restaurant'::ingredients_log_entry_owner,
      consumption_id
    FROM ingredients_log_from_restaurant
  )
  AS ingredients_log_view
  LEFT JOIN ingredient_consumptions o ON o.id = consumption_id AND o.ingredient_id = ingredients_log_view.ingredient_id
  GROUP BY ingredients_log_view.day, ingredients_log_view.ingredient_id, ingredients_log_view.ingredient_price, ingredients_log_view.meal_id, ingredients_log_view.entry_owner;
