CREATE TRIGGER check_item_id_unique BEFORE INSERT ON menus
  FOR EACH ROW EXECUTE PROCEDURE check_item_id_unique();

CREATE TRIGGER check_item_id_unique BEFORE INSERT ON meals
  FOR EACH ROW EXECUTE PROCEDURE check_item_id_unique();

CREATE TRIGGER check_item_id_unique BEFORE INSERT ON bundles
  FOR EACH ROW EXECUTE PROCEDURE check_item_id_unique();

CREATE TRIGGER delete_item_profiles AFTER DELETE ON meals
  FOR EACH ROW EXECUTE PROCEDURE delete_item_profiles();

CREATE TRIGGER delete_item_profiles AFTER DELETE ON menus
  FOR EACH ROW EXECUTE PROCEDURE delete_item_profiles();

CREATE TRIGGER delete_item_profiles AFTER DELETE ON bundles
  FOR EACH ROW EXECUTE PROCEDURE delete_item_profiles();

CREATE TRIGGER delete_ordered_items AFTER DELETE ON menus
  FOR EACH ROW EXECUTE PROCEDURE delete_ordered_items();

CREATE TRIGGER delete_ordered_items AFTER DELETE ON meals
  FOR EACH ROW EXECUTE PROCEDURE delete_ordered_items();

CREATE TRIGGER delete_ordered_items AFTER DELETE ON bundles
  FOR EACH ROW EXECUTE PROCEDURE delete_ordered_items();

CREATE FUNCTION delete_scheduled_bundles() RETURNS trigger AS $delete_scheduled_bundles$
  BEGIN
    DELETE FROM scheduled_bundles WHERE scheduled_for = OLD.scheduled_for AND bundle_id IN (SELECT id FROM bundles WHERE OLD.meal_id = meal_id);
    RETURN OLD;
  END;
$delete_scheduled_bundles$ LANGUAGE plpgsql;

CREATE TRIGGER delete_scheduled_bundles AFTER DELETE ON scheduled_meals
FOR EACH ROW EXECUTE PROCEDURE delete_scheduled_bundles();

CREATE FUNCTION check_scheduled_bundle() RETURNS trigger AS $check_scheduled_bundle$
  BEGIN
    PERFORM meal_id FROM scheduled_meals WHERE meal_id = (SELECT meal_id FROM bundles WHERE bundles.id = NEW.bundle_id);
    IF NOT found THEN
      RAISE EXCEPTION 'cannot schedule bundle without scheduling its meal';
    END IF;
    RETURN NEW;
  END;
$check_scheduled_bundle$ LANGUAGE plpgsql;

CREATE TRIGGER check_scheduled_bundle BEFORE INSERT ON scheduled_bundles
FOR EACH ROW EXECUTE PROCEDURE check_scheduled_bundle();

CREATE FUNCTION meal_price(integer) RETURNS float AS $$ SELECT price FROM meals WHERE id = $1 $$
  LANGUAGE SQL;
  
CREATE FUNCTION copy_meal_price() RETURNS trigger AS $copy_meal_price$
  BEGIN
    IF NEW.price IS NULL THEN
      NEW.price = meal_price(NEW.meal_id);
    END IF;
    RETURN NEW;
  END;
$copy_meal_price$ LANGUAGE plpgsql;

CREATE FUNCTION get_meal_item_id(integer) RETURNS integer AS $get_meal_item_id$
    SELECT item_id FROM meals WHERE id = $1;
$get_meal_item_id$ LANGUAGE SQL STABLE;