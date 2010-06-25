CREATE TABLE ingredients_log_from_restaurant (
  id                  serial PRIMARY KEY,
  day                 date NOT NULL,
  amount              float NOT NULL,
  ingredient_id       integer NOT NULL REFERENCES ingredients (id) ON DELETE RESTRICT,
  ingredient_price    float NOT NULL,
  meal_id             integer NOT NULL REFERENCES meals (id) ON DELETE RESTRICT,
  restaurant_sale_id  integer NOT NULL REFERENCES restaurant_sales (id) ON DELETE CASCADE,
  consumption_id      integer REFERENCES ingredient_consumptions(id) ON DELETE SET NULL
);