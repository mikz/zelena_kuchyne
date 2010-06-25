CREATE TABLE ingredient_consumptions(
  id                serial PRIMARY KEY,
  ingredient_id     integer NOT NULL REFERENCES ingredients (id) ON DELETE CASCADE,
  stocktaking_id    integer NOT NULL REFERENCES stocktakings (id) ON DELETE RESTRICT,
  consumption   float NOT NULL CHECK(consumption > 0.0)
);