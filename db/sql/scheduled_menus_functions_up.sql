CREATE FUNCTION update_ingredients_log_from_menus_entry() RETURNS trigger AS $update_ingredients_log_from_menus_entry$
  DECLARE
    v_recipe RECORD;
    v_course RECORD;
  BEGIN
    IF NEW.amount <> OLD.amount THEN
      FOR v_course IN SELECT * FROM courses WHERE menu_id = NEW.menu_id LOOP
        FOR v_recipe IN SELECT * FROM recipes WHERE meal_id = v_course.meal_id LOOP
          UPDATE ingredients_log_from_menus SET amount = -v_recipe.amount * NEW.amount WHERE v_course.meal_id = meal_id AND scheduled_menu_id = NEW.oid AND ingredient_id = v_recipe.ingredient_id;
        END LOOP;
      END LOOP;
    END IF;
    RETURN NEW;
  END;
$update_ingredients_log_from_menus_entry$ LANGUAGE plpgsql;

CREATE FUNCTION create_ingredients_log_from_menus_entry() RETURNS trigger AS $create_ingredients_log_from_menus_entry$
  DECLARE
    v_recipe RECORD;
    v_course RECORD;
  BEGIN
    FOR v_course IN SELECT * FROM courses WHERE menu_id = NEW.menu_id LOOP
      FOR v_recipe IN SELECT * FROM recipes WHERE meal_id = v_course.meal_id LOOP
        PERFORM id FROM ingredients_log_from_menus WHERE day = NEW.scheduled_for AND scheduled_menu_id = NEW.oid AND meal_id = v_course.meal_id AND ingredient_id = v_recipe.ingredient_id;
        IF NOT FOUND THEN
          INSERT INTO ingredients_log_from_menus(day, amount, ingredient_id, ingredient_price, meal_id, scheduled_menu_id) VALUES(NEW.scheduled_for, -v_recipe.amount * NEW.amount, v_recipe.ingredient_id, ingredient_cost(v_recipe.ingredient_id), v_course.meal_id, NEW.oid);
        END IF;
      END LOOP;
    END LOOP;
    
    RETURN NEW;
  END;
$create_ingredients_log_from_menus_entry$ LANGUAGE plpgsql;

CREATE TRIGGER update_ingredients_log_from_menus_entry AFTER UPDATE ON scheduled_menus
  FOR EACH ROW EXECUTE PROCEDURE update_ingredients_log_from_menus_entry();

CREATE TRIGGER create_ingredients_log_from_menus_entry AFTER INSERT ON scheduled_menus
  FOR EACH ROW EXECUTE PROCEDURE create_ingredients_log_from_menus_entry();