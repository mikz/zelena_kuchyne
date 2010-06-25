CREATE TABLE products_log_warnings(
  id              serial PRIMARY KEY,
  ordered_item_id integer UNIQUE REFERENCES ordered_items(oid) ON DELETE CASCADE,
  created_at      timestamp NOT NULL DEFAULT now()
);