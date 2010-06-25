CREATE FUNCTION ingredient_cost(integer) RETURNS float AS $$ SELECT cost FROM ingredients WHERE id = $1 $$
  LANGUAGE SQL;