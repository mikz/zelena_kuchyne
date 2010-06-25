CREATE VIEW lost_meals_view AS SELECT
      oid,
      meals.item_id,
      lost_items.user_id,
      COALESCE(bundles.amount,1) * lost_items.amount AS amount,
      lost_at::date AS date
        FROM lost_items
        LEFT JOIN bundles ON bundles.item_id = lost_items.item_id
        LEFT JOIN menus ON lost_items.item_id = menus.item_id
        LEFT JOIN courses ON menus.id = courses.menu_id
        LEFT JOIN meals ON bundles.meal_id = meals.id OR lost_items.item_id = meals.item_id OR courses.meal_id = meals.id;
