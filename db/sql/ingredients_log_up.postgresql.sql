CREATE TYPE ingredients_log_entry_owner AS ENUM ('delivery', 'restaurant');

CREATE TABLE ingredients_log (
  id                serial PRIMARY KEY,
  day               date NOT NULL,
  amount            float NOT NULL,
  ingredient_id     integer NOT NULL REFERENCES ingredients (id) ON DELETE RESTRICT,
  ingredient_price  float NOT NULL,
  entry_owner       ingredients_log_entry_owner NOT NULL DEFAULT 'delivery',
  notes             text
);

CREATE TABLE ingredients_log_from_meals (
  id                  serial PRIMARY KEY,
  day                 date NOT NULL,
  amount              float NOT NULL,
  ingredient_id       integer NOT NULL REFERENCES ingredients (id) ON DELETE RESTRICT,
  ingredient_price    float NOT NULL,
  meal_id             integer NOT NULL REFERENCES meals (id) ON DELETE RESTRICT,
  scheduled_meal_id   integer NOT NULL REFERENCES scheduled_meals (oid) ON DELETE CASCADE,
  consumption_id      integer REFERENCES ingredient_consumptions(id) ON DELETE SET NULL
);

CREATE TABLE ingredients_log_from_menus (
  id                  serial PRIMARY KEY,
  day                 date NOT NULL,
  amount              float NOT NULL,
  ingredient_id       integer NOT NULL REFERENCES ingredients (id) ON DELETE RESTRICT,
  ingredient_price    float NOT NULL,
  meal_id             integer NOT NULL REFERENCES meals (id) ON DELETE RESTRICT,
  scheduled_menu_id   integer NOT NULL REFERENCES scheduled_menus (oid) ON DELETE CASCADE,
  consumption_id      integer REFERENCES ingredient_consumptions(id) ON DELETE SET NULL
);