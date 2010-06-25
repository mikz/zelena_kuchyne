CREATE TYPE watchdog_balance AS (
  balance float,
  ingredient_id integer
);

CREATE TYPE ingredients_log_watchdog_state AS (
  id              integer,
  ingredient_id   integer,
  operator        BIT(3),
  value           float,
  state           boolean,
  balance         float
);

CREATE FUNCTION ingredients_log_watchdog_balance(date) RETURNS SETOF watchdog_balance AS $$
  SELECT SUM(amount) AS balance, ingredient_id FROM ingredients_log_full_view  WHERE day <= $1 GROUP BY ingredient_id;
$$ LANGUAGE SQL STABLE;

CREATE FUNCTION ingredients_log_watchdogs_view_for_day(date) RETURNS SETOF ingredients_log_watchdog_state AS $$
 SELECT 
   ingredients_log_watchdogs.id, ingredients_log_watchdogs.ingredient_id, ingredients_log_watchdogs.operator, ingredients_log_watchdogs.value, 
   CASE
     WHEN operator = 100::bit(3)  THEN value <  COALESCE(balance,0)
     WHEN operator = 110::bit(3)  THEN value >= COALESCE(balance,0)
     WHEN operator = 010::bit(3)  THEN value =  COALESCE(balance,0)
     WHEN operator = 011::bit(3)  THEN value <= COALESCE(balance,0)
     WHEN operator = 001::bit(3)  THEN value <  COALESCE(balance,0)
     WHEN operator = 000::bit(3)  THEN value != COALESCE(balance,0)
   END AS state,
   balance AS balance
 FROM ingredients_log_watchdogs
 LEFT JOIN ingredients_log_watchdog_balance($1) b ON b.ingredient_id = ingredients_log_watchdogs.ingredient_id;
 $$ LANGUAGE SQL STABLE;
 