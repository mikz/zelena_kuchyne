CREATE TABLE bundles (
  id                serial PRIMARY KEY,
  meal_id       integer NOT NULL REFERENCES meals (id),
  amount            integer NOT NULL DEFAULT 0,
  item_type   item_type NOT NULL DEFAULT 'bundle'
) INHERITS (items);
