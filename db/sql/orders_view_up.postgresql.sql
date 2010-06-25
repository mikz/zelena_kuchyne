CREATE VIEW orders_view AS SELECT
  orders.id,
  orders.user_id,
  orders.delivery_man_id,
  orders.delivery_method_id,
  orders.state,
  orders.paid,
  orders.cancelled,
  orders.notice,
  orders.created_at,
  orders.updated_at,
  orders.deliver_at,
  COALESCE(sum(ordered_items_view.price * ordered_items_view.amount * (1 - ordered_items_view.discount)),0) + COALESCE(delivery_methods.price,0)  AS price,
  COALESCE(sum(ordered_items_view.price * ordered_items_view.amount * (1 - ordered_items_view.discount)),0) AS discount_price,
  COALESCE(sum(ordered_items_view.price * ordered_items_view.amount),0) AS original_price,
  COALESCE(delivery_methods.price,0) AS delivery_price
    FROM orders
      LEFT JOIN ordered_items_view ON ordered_items_view.order_id = orders.id
      LEFT JOIN delivery_methods ON orders.delivery_method_id = delivery_methods.id
    GROUP BY orders.id, orders.user_id, orders.delivery_man_id, orders.delivery_method_id, orders.state, orders.paid, orders.cancelled, orders.notice, orders.created_at, orders.updated_at, orders.deliver_at, delivery_methods.price;