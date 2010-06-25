CREATE FUNCTION check_valid_item_id(integer) RETURNS boolean AS $check_valid_item_id$
  BEGIN
    PERFORM item_id FROM items WHERE item_id = $1;
    RETURN FOUND;
  END;
$check_valid_item_id$ LANGUAGE plpgsql;

CREATE TABLE restaurant_sales(
  id          serial PRIMARY KEY,
  item_id     integer NOT NULL CHECK(check_valid_item_id(item_id)),
  premise_id  integer REFERENCES premises(id) ON DELETE RESTRICT NOT NULL,
  amount      integer NOT NULL,
  price       float   NOT NULL,
  buyer_id    integer REFERENCES users(id) ON DELETE SET NULL,
  note        varchar(100),
  sold_at     timestamp NOT NULL,
  created_at  timestamp NOT NULL DEFAULT NOW(),
  updated_at  timestamp NOT NULL DEFAULT NOW()
);

CREATE TRIGGER copy_item_price BEFORE INSERT ON restaurant_sales
  FOR EACH ROW EXECUTE PROCEDURE copy_item_price();
