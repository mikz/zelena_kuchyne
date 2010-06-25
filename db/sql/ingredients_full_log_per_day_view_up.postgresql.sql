CREATE VIEW ingredients_full_log_per_day_view AS
  SELECT
    id, day, amount, ingredient_id, ingredient_price as cost, @amount*ingredient_price as total_cost, notes
      FROM ingredients_log
  UNION ALL
  SELECT
    NULL AS id, day, amount, ingredient_id, 0 as cost, 0 as total_cost, 'inventura' AS notes
      FROM ingredients_log_from_stocktakings
  UNION ALL
    SELECT
      NULL as id,
      day,
      amount,
      ingredient_id,
      cost_per_unit as cost,
      total_cost,
      'vareni' as notes
        FROM ingredients_per_day_view;