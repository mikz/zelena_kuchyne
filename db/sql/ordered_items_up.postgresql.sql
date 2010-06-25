CREATE TABLE ordered_items (
  oid       serial  NOT NULL UNIQUE, --activerecord needs this
  item_id   integer NOT NULL, -- REFERENCES items (item_id) but it's currently not supported by postgresql. There are triggers, though
  order_id  integer NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  amount    integer NOT NULL CHECK(amount > 0),
  price     float   NOT NULL,
  PRIMARY KEY (item_id, order_id)
);