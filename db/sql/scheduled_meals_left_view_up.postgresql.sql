CREATE VIEW scheduled_meals_left_view AS  SELECT
    scheduled.meal_id,
    scheduled.item_id,
    scheduled.name,
    COALESCE(ordered.amount, 0::bigint) AS ordered_amount,
    scheduled.amount AS scheduled_amount,
    scheduled.amount - COALESCE(ordered.amount, 0::bigint) - COALESCE(lost.amount,0) - COALESCE(sold.amount, 0) AS amount_left,
    (scheduled.amount - COALESCE(ordered.amount, 0::bigint) - COALESCE(lost.amount,0) - COALESCE(sold.amount, 0) - COALESCE(SUM(trunk.amount),0)) AS amount_left_without_trunk,
    COALESCE(SUM(trunk.amount),0) AS in_trunk,
    COALESCE(lost.amount, 0) AS lost_amount,
    COALESCE(sold.amount, 0) AS sold_amount,
    scheduled.scheduled_for
      FROM total_scheduled_meals_view scheduled
      LEFT JOIN total_ordered_meals_view ordered ON ordered.deliver_on = scheduled.scheduled_for AND ordered.item_id = scheduled.item_id
      LEFT JOIN items_in_trunk trunk ON trunk.item_id = scheduled.item_id AND scheduled.scheduled_for = trunk.deliver_at
      LEFT JOIN (SELECT item_id, date, SUM(amount)::bigint AS amount FROM lost_meals_view GROUP BY item_id, date) lost ON lost.item_id = scheduled.item_id AND scheduled.scheduled_for = lost.date
      LEFT JOIN (SELECT item_id, date, SUM(amount)::bigint AS amount FROM sold_meals_view GROUP BY item_id, date) sold ON sold.item_id = scheduled.item_id AND scheduled.scheduled_for = sold.date
      GROUP BY scheduled.meal_id, scheduled.item_id, scheduled.name, scheduled.amount, ordered.amount, scheduled.scheduled_for, lost.amount, lost.date, sold.amount, sold.date;