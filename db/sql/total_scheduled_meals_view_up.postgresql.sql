CREATE VIEW total_scheduled_meals_view AS SELECT
  scheduled_for,
  meals.id AS meal_id,
  meals.item_id,
  meals.name,
  sum(amount) AS amount
    FROM scheduled_meals
    NATURAL FULL JOIN scheduled_menus
    LEFT JOIN menus ON scheduled_menus.menu_id = menus.id
    LEFT JOIN courses ON courses.menu_id = menus.id
    LEFT JOIN meals ON (courses.meal_id = meals.id) OR (scheduled_meals.meal_id = meals.id)
    GROUP BY scheduled_for, meals.id, meals.item_id, meals.name;
