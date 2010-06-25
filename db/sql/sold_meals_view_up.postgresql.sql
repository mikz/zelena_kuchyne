CREATE VIEW sold_meals_view AS SELECT
      oid,
      meals.item_id,
      sold_items.user_id,
      COALESCE(bundles.amount,1) * sold_items.amount AS amount,
      sold_at::date AS date
        FROM sold_items
        LEFT JOIN bundles ON bundles.item_id = sold_items.item_id
        LEFT JOIN menus ON sold_items.item_id = menus.item_id
        LEFT JOIN courses ON menus.id = courses.menu_id
        LEFT JOIN meals ON bundles.meal_id = meals.id OR sold_items.item_id = meals.item_id OR courses.meal_id = meals.id;