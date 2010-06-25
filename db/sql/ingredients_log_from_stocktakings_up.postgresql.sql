CREATE TABLE ingredients_log_from_stocktakings (
  id                  serial PRIMARY KEY,
  day                 date NOT NULL,
  amount              float NOT NULL,
  ingredient_id       integer NOT NULL REFERENCES ingredients (id) ON DELETE CASCADE,
  stocktaking_id      integer NOT NULL REFERENCES stocktakings (id) ON DELETE CASCADE
);