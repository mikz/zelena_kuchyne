CREATE VIEW total_ordered_meals_view AS SELECT 
  orders.deliver_at::date AS deliver_on,
  meals.id AS meal_id,
  meals.item_id,
  meals.name,
  sum(ordered_items.amount * COALESCE(bundles.amount,1)) AS amount
     FROM ordered_items
     LEFT JOIN orders ON orders.id = ordered_items.order_id
     LEFT JOIN menus ON ordered_items.item_id = menus.item_id
     LEFT JOIN courses ON menus.id = courses.menu_id
     LEFT JOIN bundles ON ordered_items.item_id = bundles.item_id
     LEFT JOIN meals ON courses.meal_id = meals.id OR meals.item_id = ordered_items.item_id OR bundles.meal_id = meals.id
     WHERE orders.cancelled = false AND orders.state <> 'basket'::order_state
     GROUP BY orders.deliver_at::date, meals.name, meals.item_id, meals.id;