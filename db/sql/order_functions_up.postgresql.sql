CREATE FUNCTION no_guest_orders() RETURNS trigger AS $no_guest_orders$
  BEGIN
    IF NEW.state = 'basket' THEN
      RETURN NEW;
    END IF;
    PERFORM id FROM users WHERE guest = true AND id = NEW.user_id;
    IF FOUND THEN
      RAISE EXCEPTION 'Guests cannot have orders other than basket.';
    END IF;
    RETURN NEW;
  END;
$no_guest_orders$ LANGUAGE plpgsql;

CREATE TRIGGER no_guest_orders BEFORE UPDATE OR INSERT ON orders
  FOR EACH ROW EXECUTE PROCEDURE no_guest_orders();

CREATE FUNCTION check_basket() RETURNS trigger AS $check_basket$
  BEGIN
    IF NEW.state != 'basket' THEN
      RETURN NEW;
    END IF;
    IF TG_OP = 'INSERT' THEN
      PERFORM id FROM orders WHERE user_id = NEW.user_id AND state = 'basket';
    ELSE
      PERFORM id FROM orders WHERE user_id = NEW.user_id AND state = 'basket' AND id != NEW.id;
    END IF;
    IF FOUND THEN
      RAISE EXCEPTION 'There can be only one basket per user.';
    END IF;
    RETURN NEW;
  END;
$check_basket$ LANGUAGE plpgsql;

CREATE TRIGGER check_basket BEFORE UPDATE OR INSERT ON orders
  FOR EACH ROW EXECUTE PROCEDURE check_basket();

CREATE FUNCTION delete_items_from_order() RETURNS trigger AS $delete_items_from_order$
  BEGIN
    IF NEW.deliver_at::date = OLD.deliver_at::date THEN
      RETURN NEW;
    END IF;
    
    DELETE FROM ordered_items WHERE order_id = OLD.id AND item_id NOT IN (SELECT item_id FROM products);
    RETURN NEW;
  END;
$delete_items_from_order$ LANGUAGE plpgsql;

CREATE TRIGGER delete_items_from_order BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE PROCEDURE delete_items_from_order();

CREATE FUNCTION check_order_dates_match() RETURNS trigger AS $check_order_dates_match$
  DECLARE
    v_item_type varchar(50);
    v_meal_id integer;
  BEGIN
    SELECT item_type INTO v_item_type FROM items WHERE item_id = NEW.item_id;
    IF v_item_type = 'product' THEN
      RETURN NEW;
    END IF;
    
    IF v_item_type = 'meal' THEN
      IF (SELECT always_available FROM meals WHERE item_id = NEW.item_id) THEN
        RETURN NEW;
      END IF;
    END IF;
    
    IF v_item_type = 'bundle' THEN
      SELECT meal_id INTO v_meal_id FROM bundles WHERE item_id = NEW.item_id;
      PERFORM item_id FROM scheduled_items_view WHERE item_id = (SELECT item_id FROM meals WHERE id = v_meal_id) AND CAST(scheduled_for AS date) = CAST( (SELECT deliver_at FROM orders WHERE id = NEW.order_id) AS date);
      IF FOUND THEN
        RETURN NEW;
      END IF;
    END IF;
    
    PERFORM item_id FROM scheduled_items_view WHERE item_id = NEW.item_id AND CAST(scheduled_for AS date) = CAST( (SELECT deliver_at FROM orders WHERE id = NEW.order_id) AS date);
    IF FOUND THEN
      RETURN NEW;
    END IF;

    RAISE EXCEPTION 'Adding item #% to order #% would cause the order to be undeliverable.', NEW.item_id, NEW.order_id;
  END;
$check_order_dates_match$ LANGUAGE plpgsql;

CREATE TRIGGER check_order_dates_match BEFORE INSERT OR UPDATE ON ordered_items
  FOR EACH ROW EXECUTE PROCEDURE check_order_dates_match();
  
CREATE FUNCTION check_order_delivery_method() RETURNS trigger AS $check_order_delivery_method$
  DECLARE
    v_delivery_method_has_delivery_man  boolean;
  BEGIN
    SELECT flag_has_delivery_man INTO v_delivery_method_has_delivery_man FROM delivery_methods WHERE id = NEW.delivery_method_id;
    IF v_delivery_method_has_delivery_man IS FALSE AND NEW.delivery_man_id IS NOT NULL THEN
      RAISE EXCEPTION 'Cannot have delivery man when not using our delivery method.';
      RETURN NULL;
    END IF;
    RETURN NEW;
  END;
$check_order_delivery_method$ LANGUAGE plpgsql;

CREATE TRIGGER check_order_delivery_method BEFORE INSERT OR UPDATE ON orders
  FOR EACH ROW EXECUTE PROCEDURE check_order_delivery_method();
