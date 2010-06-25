CREATE TABLE ingredients_log_watchdogs (
  id              serial PRIMARY KEY,
  ingredient_id   integer NOT NULL REFERENCES ingredients (id) ON DELETE CASCADE,
  operator        BIT(3) NOT NULL,
  value           float NOT NULL,
  created_at      timestamp NOT NULL,
  updated_at      timestamp NOT NULL  
);