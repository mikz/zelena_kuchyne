CREATE FUNCTION update_ingredients_log_from_meals_entry() RETURNS trigger AS $update_ingredients_log_from_meals_entry$
  DECLARE
    v_recipe RECORD;
  BEGIN
    IF NEW.amount <> OLD.amount THEN
      FOR v_recipe IN SELECT * FROM recipes WHERE meal_id = NEW.meal_id LOOP
        UPDATE ingredients_log_from_meals SET amount = -v_recipe.amount * NEW.amount WHERE scheduled_meal_id = NEW.oid AND ingredient_id = v_recipe.ingredient_id;
      END LOOP;
    END IF;
    RETURN NEW;
  END;
$update_ingredients_log_from_meals_entry$ LANGUAGE plpgsql;

CREATE FUNCTION create_ingredients_log_from_meals_entry() RETURNS trigger AS $create_ingredients_log_from_meals_entry$
  DECLARE
    v_recipe RECORD;
  BEGIN
    FOR v_recipe IN SELECT * FROM recipes WHERE meal_id = NEW.meal_id LOOP
      PERFORM id FROM ingredients_log_from_meals WHERE scheduled_meal_id = NEW.oid AND ingredient_id = v_recipe.ingredient_id AND day = NEW.scheduled_for AND meal_id = NEW.meal_id;
      IF NOT FOUND THEN
        INSERT INTO ingredients_log_from_meals(day, amount, ingredient_id, ingredient_price, meal_id, scheduled_meal_id) VALUES(NEW.scheduled_for, -v_recipe.amount * NEW.amount, v_recipe.ingredient_id, ingredient_cost(v_recipe.ingredient_id), NEW.meal_id, NEW.oid);
      END IF;
    END LOOP;
    
    RETURN NEW;
  END;
$create_ingredients_log_from_meals_entry$ LANGUAGE plpgsql;

CREATE TRIGGER update_ingredients_log_from_meals_entry AFTER UPDATE ON scheduled_meals
  FOR EACH ROW EXECUTE PROCEDURE update_ingredients_log_from_meals_entry();

  CREATE TRIGGER create_ingredients_log_from_meals_entry AFTER INSERT ON scheduled_meals
    FOR EACH ROW EXECUTE PROCEDURE create_ingredients_log_from_meals_entry();