CREATE FUNCTION validate_delete_user_discount() RETURNS trigger AS $validate_delete_user_discount$
  BEGIN
    IF OLD.expire_at IS NOT NULL THEN
      PERFORM id FROM orders WHERE user_id = OLD.user_id AND cancelled = false AND deliver_at BETWEEN OLD.start_at AND OLD.expire_at;
      IF FOUND THEN
        UPDATE user_discounts SET expire_at = (SELECT MAX(deliver_at) FROM orders WHERE user_id = OLD.user_id AND cancelled = false AND deliver_at <= OLD.expire_at) WHERE id=OLD.id;
        RETURN NULL;
      END IF;
    ELSE
      PERFORM id FROM orders WHERE user_id = OLD.user_id AND cancelled = false AND deliver_at > OLD.start_at;
      IF FOUND THEN
        UPDATE user_discounts SET expire_at = (SELECT MAX(deliver_at) FROM orders WHERE user_id = OLD.user_id AND cancelled = false ) WHERE id=OLD.id;
        RETURN NULL;
      END IF;
    END IF;

    RETURN OLD;
  END;
$validate_delete_user_discount$ LANGUAGE plpgsql;

CREATE FUNCTION validate_delete_item_discount() RETURNS trigger AS $validate_delete_item_discount$
  BEGIN
    PERFORM id FROM ordered_items LEFT JOIN orders ON orders.id = order_id WHERE item_id = OLD.item_id AND cancelled = false AND deliver_at BETWEEN OLD.start_at AND OLD.expire_at;
    IF FOUND THEN
      UPDATE item_discounts SET expire_at = (SELECT MAX(deliver_at) FROM ordered_items LEFT JOIN orders ON orders.id = order_id WHERE item_id = OLD.item_id AND cancelled = false AND deliver_at <= OLD.expire_at ) WHERE id=OLD.id;
      RETURN NULL;
    END IF;
    RETURN OLD;
  END;
$validate_delete_item_discount$ LANGUAGE plpgsql;

CREATE FUNCTION validate_insert_user_discount() RETURNS trigger AS $validate_insert_user_discount$
  DECLARE
   v_discount_id integer;
  BEGIN
    SELECT id INTO v_discount_id FROM user_discounts WHERE COALESCE(expire_at,NEW.start_at) >= NEW.start_at AND user_id = NEW.user_id AND NEW.discount_class = discount_class;
    IF COUNT(v_discount_id) > 0 THEN
      RAISE EXCEPTION ' One user cannot have two active discounts. Please turn off discount with ID #%. ', v_discount_id;
    END IF;
    RETURN NEW;
  END;
$validate_insert_user_discount$ LANGUAGE plpgsql;

CREATE TRIGGER validate_insert_user_discount BEFORE INSERT ON user_discounts
  FOR EACH ROW EXECUTE PROCEDURE validate_insert_user_discount();

CREATE TRIGGER validate_delete_user_discount BEFORE DELETE ON user_discounts
  FOR EACH ROW EXECUTE PROCEDURE validate_delete_user_discount();
  
CREATE TRIGGER validate_delete_item_discount BEFORE DELETE ON item_discounts
  FOR EACH ROW EXECUTE PROCEDURE validate_delete_item_discount();