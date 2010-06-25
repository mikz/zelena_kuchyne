CREATE VIEW scheduled_items_view AS 
  SELECT scheduled_for, SUM(amount) AS amount, item_id, name FROM
  ( SELECT scheduled_for, amount, meals.item_id as item_id, meals.name from scheduled_menus
    LEFT JOIN courses using(menu_id)
    LEFT JOIN meals on meals.id = courses.meal_id
    GROUP by scheduled_for, amount, item_id, name
    UNION ALL
    SELECT scheduled_for, amount, meals.item_id as item_id, meals.name from scheduled_meals
    LEFT JOIN meals on meals.id = scheduled_meals.meal_id  
    GROUP by scheduled_for, amount, item_id, name
   ) AS scheduled_meals
  GROUP by scheduled_for, item_id, name
  UNION ALL
  SELECT scheduled_for, amount, item_id, name FROM scheduled_menus
  LEFT JOIN menus on menus.id = scheduled_menus.menu_id;