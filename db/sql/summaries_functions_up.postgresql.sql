CREATE TYPE orders_sum AS (
  total_price     float,
  total_delivery  float,
  total_discounts float
);

CREATE FUNCTION get_orders_sum_between(date, date) RETURNS SETOF orders_sum AS $$
  SELECT
    SUM(price) AS total_price,
    SUM(delivery_price) as total_delivery,
    (SUM(original_price) - SUM(discount_price)) as total_discounts
      FROM orders_view
        WHERE deliver_at::date BETWEEN $1 AND $2
        AND cancelled = false
        AND state != 'basket';
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION get_delivery_bought_ingredients_cost_between(date, date) RETURNS float AS $$
  SELECT SUM(amount*ingredient_price) FROM ingredients_log WHERE day BETWEEN $1 AND $2 AND entry_owner = 'delivery' AND amount > 0;
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION get_restaurant_bought_ingredients_cost_bewteen(date, date) RETURNS float AS $$
  SELECT SUM(amount*ingredient_price) FROM ingredients_log WHERE day BETWEEN $1 AND $2 AND entry_owner = 'restaurant' AND amount > 0;
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION get_restaurant_cooking_ingredients_cost_bewteen(date, date) RETURNS float AS $$
  SELECT SUM(@amount_with_consumption*ingredient_price) FROM ingredients_log_view WHERE day BETWEEN $1 AND $2 AND entry_owner = 'restaurant';
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION get_delivery_cooking_ingredients_cost_bewteen(date, date) RETURNS float AS $$
  SELECT SUM(@amount_with_consumption*ingredient_price) FROM ingredients_log_view WHERE day BETWEEN $1 AND $2 AND entry_owner = 'delivery';
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION get_lost_items_cost_between(date, date) RETURNS float AS $$
  SELECT SUM(total_cost) FROM lost_items_view  WHERE date BETWEEN $1 AND $2;
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION get_delivery_sold_items_sum_between(date, date) RETURNS float AS $$
  SELECT SUM(@amount*price) FROM sold_items_view  WHERE date BETWEEN $1 AND $2 AND user_id <> (SELECT id FROM users WHERE login = 'zelena_kuchyne');
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION get_restaurant_sold_items_sum_between(date, date) RETURNS float AS $$
  SELECT SUM(@amount*price) FROM sold_items_view  WHERE date BETWEEN $1 AND $2 AND user_id = (SELECT id FROM users WHERE login = 'zelena_kuchyne');
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION get_fuel_sum_between(date, date) RETURNS float AS $$
  SELECT SUM(cost) FROM fuel WHERE date::date BETWEEN $1 AND $2;
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION get_delivery_expenses_sum_between(date, date) RETURNS float AS $$
  SELECT SUM(price) FROM expenses WHERE bought_at::date BETWEEN $1 AND $2 AND expense_owner = 'delivery';
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION get_office_expenses_sum_between(date, date) RETURNS float AS $$
  SELECT SUM(price) FROM expenses WHERE bought_at::date BETWEEN $1 AND $2 AND expense_owner = 'office';
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION get_restaurant_expenses_sum_between(date, date) RETURNS float AS $$
  SELECT SUM(price) FROM expenses WHERE bought_at::date BETWEEN $1 AND $2 AND expense_owner = 'restaurant';
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION get_restaurant_sales_sum_between(date, date) RETURNS float AS $$
  SELECT SUM(@amount*price) FROM restaurant_sales WHERE sold_at::date BETWEEN $1 AND $2;
$$ LANGUAGE SQL STABLE;


CREATE TYPE summary AS (
  orders_price      float,
  orders_delivery   float,
  orders_discount   float,
  delivery_bought_ingredients    float,
  restaurant_bought_ingredients  float,
  restaurant_cooking_ingredients float,
  delivery_cooking_ingredients   float,
  delivery_sold     float,
  restaurant_sold   float,
  fuel              float,
  delivery_expenses float,
  office_expenses   float,
  restaurant_expenses float,
  restaurant_sales  float
);

CREATE FUNCTION get_summary_between(date, date) RETURNS summary AS $$
  SELECT * FROM get_orders_sum_between($1, $2)
  LEFT JOIN get_delivery_bought_ingredients_cost_between($1, $2) ON true
  LEFT JOIN get_restaurant_bought_ingredients_cost_bewteen($1, $2) ON true
  LEFT JOIN get_restaurant_cooking_ingredients_cost_bewteen($1, $2) ON true
  LEFT JOIN get_delivery_cooking_ingredients_cost_bewteen($1, $2) ON true
  LEFT JOIN get_delivery_sold_items_sum_between($1, $2) ON true
  LEFT JOIN get_restaurant_sold_items_sum_between($1, $2) ON true
  LEFT JOIN get_fuel_sum_between($1, $2) ON true
  LEFT JOIN get_delivery_expenses_sum_between($1, $2) ON true
  LEFT JOIN get_office_expenses_sum_between($1, $2) ON true
  LEFT JOIN get_restaurant_expenses_sum_between($1, $2) ON true
  LEFT JOIN get_restaurant_sales_sum_between($1, $2) ON true
$$ LANGUAGE SQL STABLE;