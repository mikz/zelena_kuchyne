-- show menus with a total price of all meals in them and the sum of their costs (price is what the meal is sold for, cost is what it cost to make)
CREATE VIEW menus_view AS
  SELECT menus.*, sum(meals_view.price) AS meals_price, COALESCE(sum(meals_view.cost),0) AS cost
  FROM menus
    LEFT JOIN courses ON courses.menu_id = menus.id
    LEFT JOIN meals_view ON courses.meal_id = meals_view.id
  GROUP BY menus.id, menus.item_id, menus.price, menus.name, menus.created_at, menus.updated_at, menus.image_flag, menus.updated_by, menus.item_type;
