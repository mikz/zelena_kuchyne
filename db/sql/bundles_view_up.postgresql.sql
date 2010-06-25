-- same as menus_view and meals_view
CREATE VIEW bundles_view AS
  SELECT bundles.*, COALESCE(sum(meals_view.cost * bundles.amount),0) AS cost
  FROM bundles
    LEFT JOIN meals_view ON bundles.meal_id = meals_view.id
    GROUP BY bundles.item_id, bundles.price, bundles.name, bundles.created_at, bundles.updated_at, bundles.updated_by, bundles.image_flag, bundles.id, bundles.meal_id, bundles.amount, bundles.item_type ;