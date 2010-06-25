CREATE TABLE sold_items (
  oid             serial PRIMARY KEY,
  item_id         integer NOT NULL,  -- REFERENCES items (item_id) but it's currently not supported by postgresql. #TODO: triggers
  user_id         integer NOT NULL REFERENCES users(id),
  amount          integer NOT NULL CHECK(amount > 0),
  price           float NOT NULL,
  sold_at         timestamp NOT NULL
);

CREATE TRIGGER copy_item_price BEFORE INSERT ON sold_items
  FOR EACH ROW EXECUTE PROCEDURE copy_item_price();