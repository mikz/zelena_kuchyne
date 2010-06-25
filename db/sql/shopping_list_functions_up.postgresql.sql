CREATE TYPE shopping_list_between AS (
 amount          float,
 amount_with_consumption          float,
 ingredient_id   integer,
 name            varchar(50),
 code            varchar(50),
 unit            varchar(25),
 cost_per_unit   float,
 total_cost      float,
 total_cost_with_consumption      float,
 supply_flag     boolean,
 supplier_short  varchar(10),
 supplier        varchar(70)
);

CREATE FUNCTION get_shopping_list_between(date, date) RETURNS SETOF shopping_list_between AS $$
   SELECT
     @sum(amount) AS amount,
     @SUM(amount_with_consumption) AS amount_with_consumption,
     ingredient_id,
     name,
     code,
     unit,
     AVG(cost_per_unit) AS cost_per_unit,
     @sum(total_cost) AS total_cost,
     @sum(total_cost_with_consumption) AS total_cost_with_consumption,
     supply_flag,
     supplier_short,
     supplier
       FROM ingredients_per_day_view
         WHERE day BETWEEN $1 AND $2
         GROUP BY ingredient_id, name, code, unit, supply_flag, supplier_short, supplier;
 $$ LANGUAGE SQL STABLE;