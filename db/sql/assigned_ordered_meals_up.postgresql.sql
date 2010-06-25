CREATE VIEW assigned_ordered_meals AS SELECT
  users.id AS delivery_man_id,
  COALESCE(meals.item_id,bundles.item_id) AS item_id,
  SUM(ordered_items.amount) AS amount,
  orders.deliver_at::date AS date
  FROM users
LEFT JOIN orders ON delivery_man_id = users.id
LEFT JOIN ordered_items ON orders.id = ordered_items.order_id
LEFT JOIN menus ON menus.item_id = ordered_items.item_id
LEFT JOIN courses ON menus.id = courses.menu_id
LEFT JOIN meals ON courses.meal_id = meals.id OR ordered_items.item_id = meals.item_id
LEFT JOIN bundles ON bundles.item_id = ordered_items.item_id
WHERE orders.cancelled = false AND orders.state <> 'basket'
GROUP BY users.id, users.login, COALESCE(meals.item_id,bundles.item_id) , meals.id, meals.item_id, orders.deliver_at::date
ORDER BY orders.deliver_at::date, users.id