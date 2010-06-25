CREATE TYPE assigned_meals AS (
  delivery_man_id integer,
  item_id         integer,
  assigned_amount bigint,
  sold_amount     bigint,
  trunk_amount    bigint,
  lost_amount     bigint,
  amount          bigint
);

CREATE FUNCTION total_assigned_ordered_meals_for(date) RETURNS SETOF assigned_meals AS $$
  SELECT 
    COALESCE(assigned_trunk_sold.delivery_man_id, lost_items.user_id) AS delivery_man_id,
    COALESCE(assigned_trunk_sold.item_id, lost_items.item_id) AS item_id,
    COALESCE(assigned_amount,0) AS assigned_amount,
    COALESCE(sold_amount,0) AS sold_amount,
    COALESCE(trunk_amount,0) AS trunk_amount,
    COALESCE(lost_items.amount,0) as lost_amount,
    (COALESCE(assigned_amount,0) + COALESCE(sold_amount,0) + COALESCE(trunk_amount,0) + COALESCE(lost_items.amount,0)) AS amount
  FROM (
    SELECT 
      COALESCE(assigned_trunk.delivery_man_id, sold_items.user_id) AS delivery_man_id,
      COALESCE(assigned_trunk.item_id, sold_items.item_id) AS item_id,
      COALESCE(assigned_amount,0) AS assigned_amount,
      COALESCE(sold_items.amount,0) as sold_amount,
      COALESCE(trunk_amount,0) as trunk_amount
    FROM (
      SELECT 
        COALESCE(assigned_meals.delivery_man_id, items_in_trunk.delivery_man_id) AS delivery_man_id,
        COALESCE(assigned_meals.item_id, items_in_trunk.item_id) AS item_id,
        COALESCE(assigned_meals.amount,0) AS assigned_amount,
        COALESCE(items_in_trunk.amount,0) AS trunk_amount
        FROM (
          SELECT delivery_man_id, item_id, amount
  	  FROM assigned_ordered_meals
  	  WHERE date = $1
        ) AS assigned_meals
        FULL JOIN (SELECT delivery_man_id, item_id, SUM(amount) AS amount FROM items_in_trunk WHERE deliver_at::date = $1 GROUP BY delivery_man_id, item_id) AS items_in_trunk ON assigned_meals.delivery_man_id = items_in_trunk.delivery_man_id AND assigned_meals.item_id = items_in_trunk.item_id
    ) AS assigned_trunk
    FULL JOIN (SELECT user_id, item_id, SUM(amount) AS amount FROM sold_items WHERE sold_at::date = $1 GROUP BY user_id, item_id) AS sold_items ON assigned_trunk.item_id = sold_items.item_id AND assigned_trunk.delivery_man_id = sold_items.user_id
  ) AS assigned_trunk_sold
  FULL JOIN (SELECT user_id, item_id, SUM(amount) AS amount FROM lost_items WHERE lost_at::date = $1 GROUP BY user_id, item_id) AS lost_items ON assigned_trunk_sold.item_id = lost_items.item_id AND assigned_trunk_sold.delivery_man_id = lost_items.user_id;
$$ LANGUAGE SQL STABLE;

