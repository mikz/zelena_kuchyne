CREATE TYPE get_days AS (
  scheduled_for date
);
  
CREATE FUNCTION get_days(boolean) RETURNS setof get_days AS $$
  SELECT DISTINCT COALESCE(scheduled_for, lost_at)::date as scheduled_for
   FROM scheduled_meals
   NATURAL FULL JOIN scheduled_menus
   NATURAL FULL JOIN lost_items
   WHERE COALESCE(invisible,false) = false OR $1
$$
LANGUAGE SQL;