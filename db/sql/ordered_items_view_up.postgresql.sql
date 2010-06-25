CREATE VIEW ordered_items_view AS SELECT
  oi.*,
  LEAST(COALESCE(ud.amount,0) + COALESCE(SUM(id.amount),0), 1) AS discount
  FROM ordered_items oi
  LEFT JOIN item_tables_view itv ON oi.item_id = itv.item_id
  LEFT JOIN orders o ON o.id = oi.order_id
  LEFT JOIN users u ON o.user_id = u.id
  LEFT JOIN user_discounts ud ON u.id = ud.user_id AND itv.discount_class = ud.discount_class AND o.deliver_at BETWEEN ud.start_at AND COALESCE(ud.expire_at,o.deliver_at)
  LEFT JOIN item_discounts id ON oi.item_id = id.item_id AND o.deliver_at BETWEEN id.start_at AND id.expire_at
  GROUP BY oi.oid, oi.item_id, oi.order_id, oi.amount, oi.price, ud.amount;