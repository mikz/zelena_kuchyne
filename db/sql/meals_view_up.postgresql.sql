-- a convenience view that shows each meal with a total cost of its ingredients
CREATE VIEW meals_view AS SELECT meals.*, COALESCE(sum(ingredients.cost * recipes.amount),0) AS cost
  FROM meals
    LEFT JOIN recipes ON recipes.meal_id = meals.id
    LEFT JOIN ingredients ON recipes.ingredient_id = ingredients.id
  GROUP BY meals.id, meals.price, meals.name, meals.meal_category_id, meals.created_at, meals.updated_at, meals.item_id, meals.always_available, meals.image_flag, meals.updated_by, meals.item_type, meals.restaurant_flag;
