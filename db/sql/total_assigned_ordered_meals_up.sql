CREATE VIEW total_assigned_ordered_meals AS SELECT 
  assigned_ordered_meals.delivery_man_id,
  assigned_ordered_meals.item_id,
  assigned_ordered_meals.date,
  COALESCE(SUM(sold_items.amount),0) AS sold_amount,
  COALESCE(SUM(lost_items.amount),0) AS lost_amount,
  COALESCE(SUM(items_in_trunk.amount),0) as trunk_amount,
  (COALESCE(SUM(sold_items.amount),0) + COALESCE(SUM(lost_items.amount),0) + COALESCE(SUM(items_in_trunk.amount),0) + assigned_ordered_meals.amount) as amount
FROM assigned_ordered_meals
LEFT JOIN lost_items ON lost_items.lost_at::date = date AND lost_items.user_id = assigned_ordered_meals.delivery_man_id AND lost_items.item_id = assigned_ordered_meals.item_id
LEFT JOIN sold_items ON sold_items.sold_at::date = date AND sold_items.user_id = assigned_ordered_meals.delivery_man_id AND sold_items.item_id = assigned_ordered_meals.item_id
LEFT JOIN items_in_trunk ON assigned_ordered_meals.delivery_man_id = items_in_trunk.delivery_man_id AND assigned_ordered_meals.item_id = items_in_trunk.item_id AND items_in_trunk.deliver_at::date = date
GROUP BY assigned_ordered_meals.delivery_man_id, assigned_ordered_meals.item_id, assigned_ordered_meals.date, assigned_ordered_meals.amount;