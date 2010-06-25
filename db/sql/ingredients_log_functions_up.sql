CREATE FUNCTION copy_ingredient_price() RETURNS trigger AS $copy_ingredient_price$
  BEGIN
    IF NEW.ingredient_price IS NULL THEN
      NEW.ingredient_price = ingredient_cost(NEW.ingredient_id);
    END IF;
    RETURN NEW;
  END;
$copy_ingredient_price$ LANGUAGE plpgsql;

CREATE TRIGGER copy_ingredient_price BEFORE INSERT ON ingredients_log
  FOR EACH ROW EXECUTE PROCEDURE copy_ingredient_price();

CREATE FUNCTION copy_consumption_id() RETURNS trigger AS $copy_consumption_id$
  BEGIN
    IF NEW.consumption_id IS NULL THEN
      NEW.consumption_id = (SELECT ingredient_consumptions.id FROM ingredient_consumptions LEFT JOIN stocktakings ON stocktakings.id = stocktaking_id WHERE date < NEW.day AND ingredient_id = NEW.ingredient_id ORDER BY date DESC LIMIT 1);
    END IF;
    RETURN NEW;
  END;
$copy_consumption_id$ LANGUAGE plpgsql;

CREATE TRIGGER copy_consumption_id BEFORE INSERT ON ingredients_log_from_meals
  FOR EACH ROW EXECUTE PROCEDURE copy_consumption_id();
CREATE TRIGGER copy_consumption_id BEFORE INSERT ON ingredients_log_from_menus
  FOR EACH ROW EXECUTE PROCEDURE copy_consumption_id();
CREATE TRIGGER copy_consumption_id BEFORE INSERT ON ingredients_log_from_restaurant
  FOR EACH ROW EXECUTE PROCEDURE copy_consumption_id();


CREATE FUNCTION check_consumptions_ingredient_id() RETURNS trigger AS $check_consumptions_ingredient_id$
  BEGIN
    IF NEW.consumption_id IS NOT NULL AND NEW.ingredient_id <> (SELECT ingredient_id FROM ingredient_consumptions WHERE id = NEW.consumption_id ) THEN
      RAISE EXCEPTION 'Ingredient consumption mismatch.';
    END IF;
    RETURN NEW;
  END;
$check_consumptions_ingredient_id$ LANGUAGE plpgsql;

CREATE TRIGGER check_consumptions_ingredient_id BEFORE INSERT ON ingredients_log_from_meals
  FOR EACH ROW EXECUTE PROCEDURE check_consumptions_ingredient_id();
CREATE TRIGGER check_consumptions_ingredient_id BEFORE INSERT ON ingredients_log_from_menus
  FOR EACH ROW EXECUTE PROCEDURE check_consumptions_ingredient_id();
CREATE TRIGGER check_consumptions_ingredient_id BEFORE INSERT ON ingredients_log_from_restaurant
  FOR EACH ROW EXECUTE PROCEDURE check_consumptions_ingredient_id();
  