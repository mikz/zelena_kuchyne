CREATE TABLE items_in_trunk (
  oid               serial NOT NULL UNIQUE, --activerecord needs this
  item_id           integer NOT NULL,  -- REFERENCES items (item_id) but it's currently not supported by postgresql. #TODO: triggers
  delivery_man_id   integer REFERENCES users(id) NOT NULL,
  amount            integer NOT NULL DEFAULT 0,
  deliver_at        date NOT NULL
);