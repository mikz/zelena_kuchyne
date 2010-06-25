CREATE VIEW lost_items_view AS SELECT
      COALESCE(meals.item_id, lost_items.item_id) AS item_id,
      SUM(COALESCE(bundles.amount, 1)*lost_items.amount) AS amount,
      lost_items.cost,
      SUM(COALESCE(bundles.amount, 1)*lost_items.cost*lost_items.amount) as total_cost,
      user_id,
      lost_at::date AS date
        FROM lost_items
        LEFT JOIN bundles ON bundles.item_id = lost_items.item_id
        LEFT JOIN meals ON meal_id = meals.id
        GROUP BY COALESCE(meals.item_id, lost_items.item_id), lost_at, lost_items.cost, user_id;