CREATE TYPE order_state AS ENUM ('basket', 'order', 'expedited', 'closed');
CREATE TABLE orders (
  id                  serial PRIMARY KEY,
  user_id             integer NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  delivery_man_id     integer REFERENCES users (id) ON DELETE SET NULL,
  delivery_method_id  integer REFERENCES delivery_methods(id) ON DELETE SET NULL,
  state               order_state NOT NULL DEFAULT 'basket',
  paid                boolean NOT NULL DEFAULT false,
  cancelled           boolean NOT NULL DEFAULT false,
  notice              text,
  created_at          timestamp DEFAULT current_timestamp,
  updated_at          timestamp DEFAULT current_timestamp,
  deliver_at          timestamp NOT NULL
);