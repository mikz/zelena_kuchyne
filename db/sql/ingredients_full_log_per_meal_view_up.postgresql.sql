CREATE VIEW ingredients_full_log_per_meal_view AS
 SELECT
    NULL as id,
    day,
    SUM(amount) as amount,
    ingredient_id,
    ingredient_price as cost,
    @SUM(amount)*ingredient_price as total_cost,
    meal_id,
    meals.name as notes
  FROM ingredients_log_view
  LEFT JOIN meals ON meal_id = meals.id
  WHERE meal_id IS NOT NULL
  GROUP BY ingredients_log_view.day, ingredients_log_view.ingredient_id, ingredients_log_view.ingredient_price, ingredients_log_view.meal_id, meals.name;