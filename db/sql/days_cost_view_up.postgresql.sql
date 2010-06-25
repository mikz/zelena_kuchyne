-- this view lists cost of ingredients for any given day, based on the meals and menus scheduled for that day
-- unlike ingredients_per_day_view, this view utilizes already calculated values from menus_view and meals_view, which makes it a little less flexible
CREATE VIEW days_cost_view AS
  SELECT days_view.scheduled_for, ( sum(COALESCE(scheduled_meals.amount, 0) * COALESCE(meals_view.cost, 0)) + sum(COALESCE(scheduled_menus.amount, 0) * COALESCE(menus_view.cost, 0)) ) AS cost
    FROM days_view
    LEFT JOIN scheduled_meals ON scheduled_meals.scheduled_for = days_view.scheduled_for
      LEFT JOIN meals_view ON scheduled_meals.meal_id = meals_view.id
    LEFT JOIN scheduled_menus ON scheduled_menus.scheduled_for = days_view.scheduled_for
      LEFT JOIN menus_view ON scheduled_menus.menu_id = menus_view.id
    GROUP BY days_view.scheduled_for;
