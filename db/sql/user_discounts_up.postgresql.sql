CREATE TYPE discount_class AS ENUM ('meal', 'product');

CREATE TABLE user_discounts (
  id              serial NOT NULL UNIQUE,
  user_id         integer NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  amount          float NOT NULL DEFAULT 0.0 CHECK(amount BETWEEN 0.0 AND 1.0), -- value of discount in % (20% discount is 0.2)
  name            varchar(50) NOT NULL CHECK(length(name) > 2 ),
  discount_class  discount_class NOT NULL,
  start_at        timestamp NOT NULL DEFAULT current_date,
  expire_at       timestamp CHECK(COALESCE(expire_at,start_at) >= start_at),
  note            varchar(50)
);