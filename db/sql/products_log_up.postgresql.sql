CREATE TABLE products_log(
  id            serial PRIMARY KEY,
  day           date NOT NULL,
  product_id    integer NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  amount        integer NOT NULL,
  product_cost  float NOT NULL,
  note          varchar(200) NOT NULL DEFAULT '',
  created_at    timestamp NOT NULL,
  updated_at    timestamp NOT NULL,
  updated_by    integer REFERENCES users(id) ON DELETE RESTRICT
)