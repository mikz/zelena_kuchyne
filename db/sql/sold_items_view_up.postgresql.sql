CREATE VIEW sold_items_view AS SELECT
      COALESCE(meals.item_id, sold_items.item_id) AS item_id,
      SUM(COALESCE(bundles.amount, 1)*sold_items.amount) AS amount,
      sold_items.price,
      user_id,
      sold_at::date AS date
        FROM sold_items
        LEFT JOIN bundles ON bundles.item_id = sold_items.item_id
        LEFT JOIN meals ON meal_id = meals.id
        GROUP BY COALESCE(meals.item_id, sold_items.item_id), sold_at, sold_items.price, user_id;
