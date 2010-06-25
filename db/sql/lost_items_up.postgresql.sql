CREATE TABLE lost_items (
  oid             serial NOT NULL UNIQUE,
  item_id         integer NOT NULL,  -- REFERENCES items (item_id) but it's currently not supported by postgresql. #TODO: triggers
  user_id         integer NOT NULL REFERENCES users(id),
  amount          integer NOT NULL DEFAULT 0,
  cost            float NOT NULL,
  lost_at         timestamp NOT NULL,
  PRIMARY KEY (item_id, user_id, lost_at)
);


CREATE TRIGGER copy_item_cost BEFORE INSERT ON lost_items
  FOR EACH ROW EXECUTE PROCEDURE copy_item_cost();