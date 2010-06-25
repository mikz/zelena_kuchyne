CREATE FUNCTION check_item_id_exists() RETURNS trigger AS $check_item_id_exists$
  BEGIN
    PERFORM item_id FROM items WHERE item_id = NEW.item_id;
    IF NOT found THEN
      RAISE EXCEPTION 'item_id % does not exists in table items', NEW.item_id;
    END IF;
    RETURN NEW;
  END;
$check_item_id_exists$ LANGUAGE plpgsql;

CREATE TRIGGER check_item_id_exists BEFORE INSERT OR UPDATE ON item_profiles
  FOR EACH ROW EXECUTE PROCEDURE check_item_id_exists();
  
CREATE TRIGGER check_item_id_exists BEFORE INSERT OR UPDATE ON item_discounts
  FOR EACH ROW EXECUTE PROCEDURE check_item_id_exists();

CREATE FUNCTION delete_item_profiles() RETURNS trigger AS $delete_item_profiles$
  BEGIN
    DELETE FROM item_profiles WHERE item_id = OLD.id;
    RETURN OLD;
  END;
$delete_item_profiles$ LANGUAGE plpgsql;

CREATE TRIGGER delete_item_profiles AFTER DELETE ON items
  FOR EACH ROW EXECUTE PROCEDURE delete_item_profiles();
  
CREATE FUNCTION delete_item_discounts() RETURNS trigger AS $delete_item_discounts$
  BEGIN
    DELETE FROM item_discounts WHERE item_id = OLD.id;
    RETURN OLD;
  END;
$delete_item_discounts$ LANGUAGE plpgsql;

CREATE TRIGGER delete_item_discounts AFTER DELETE ON items
  FOR EACH ROW EXECUTE PROCEDURE delete_item_discounts();
  
-- in some cases, it might be possible to insert two records into the table items that would violate the UNIQUE constraint on item_id

CREATE FUNCTION check_item_id_unique() RETURNS trigger AS $check_item_id_unique$
  BEGIN
    PERFORM item_id FROM items WHERE item_id = NEW.item_id;
    IF found THEN
      RAISE EXCEPTION 'item_id % already exists', NEW.item_id;
    END IF;
    RETURN NEW;
  END;
$check_item_id_unique$ LANGUAGE plpgsql;

-- TODO: change the triggers to check the item_id on update, if and only if it's been changed

CREATE TRIGGER check_item_id_unique BEFORE INSERT ON items
  FOR EACH ROW EXECUTE PROCEDURE check_item_id_unique();

CREATE FUNCTION delete_ordered_items() RETURNS trigger AS $delete_ordered_items$
  BEGIN
    DELETE FROM ordered_items WHERE item_id = OLD.item_id;
    RETURN OLD;
  END;
$delete_ordered_items$ LANGUAGE plpgsql;

CREATE TRIGGER delete_ordered_items AFTER DELETE ON items
  FOR EACH ROW EXECUTE PROCEDURE delete_ordered_items();
  
CREATE FUNCTION item_price(integer) RETURNS float AS $$ SELECT price FROM items WHERE item_id = $1 $$
  LANGUAGE SQL;


CREATE FUNCTION copy_item_price() RETURNS trigger AS $copy_item_price$
  BEGIN
    IF NEW.price IS NULL THEN
      NEW.price = item_price(NEW.item_id);
    END IF;
    RETURN NEW;
  END;
$copy_item_price$ LANGUAGE plpgsql;

CREATE FUNCTION item_cost(integer) RETURNS float AS $item_cost$
  DECLARE
  v_item_type item_type;
  BEGIN
    SELECT item_type INTO v_item_type FROM items WHERE item_id = $1;
    IF v_item_type = 'meal' THEN
        RETURN (SELECT cost FROM meals_view WHERE item_id = $1);
    ELSIF v_item_type = 'menu' THEN
        RETURN (SELECT cost FROM menus_view WHERE item_id = $1);
    ELSIF v_item_type = 'bundle' THEN
        RETURN (SELECT cost FROM bundles_view WHERE item_id = $1);
    ELSIF v_item_type = 'product' THEN
        RETURN (SELECT cost FROM products WHERE item_id = $1);
    END IF;
  END;
$item_cost$ LANGUAGE plpgsql;

CREATE FUNCTION copy_item_cost() RETURNS trigger AS $copy_item_cost$
  BEGIN
    IF NEW.cost IS NULL THEN
      NEW.cost = item_cost(NEW.item_id);
    END IF;
    RETURN NEW;
  END;
$copy_item_cost$ LANGUAGE plpgsql;