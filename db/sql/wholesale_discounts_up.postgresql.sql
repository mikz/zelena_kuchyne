CREATE TABLE wholesale_discounts(
  id              serial PRIMARY KEY,
  user_id         integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  discount_price  float NOT NULL CHECK(discount_price >= 0.0),
  note            varchar(150) NOT NULL DEFAULT '',
  start_at        timestamp NOT NULL DEFAULT current_date,
  expire_at       timestamp CHECK(COALESCE(expire_at,start_at) >= start_at),
  created_at      timestamp NOT NULL,
  updated_at      timestamp NOT NULL,
  updated_by      integer REFERENCES users(id) ON DELETE RESTRICT
);