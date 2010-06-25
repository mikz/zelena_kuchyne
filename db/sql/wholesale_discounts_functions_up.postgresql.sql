CREATE FUNCTION apply_wholesale_discounts() RETURNS trigger AS $apply_wholesale_discounts$
  DECLARE
    v_discount_price  float;
    v_ordered_items   RECORD;
    v_order           RECORD;
  BEGIN
    SELECT * INTO v_order FROM orders WHERE id = NEW.order_id;
    SELECT discount_price INTO v_discount_price FROM wholesale_discounts WHERE user_id = v_order.user_id AND v_order.deliver_at::date BETWEEN start_at AND COALESCE(expire_at, v_order.deliver_at::date) ORDER BY start_at;
    IF v_discount_price IS NOT NULL THEN
      IF NEW.price IS NULL THEN
        NEW.price = item_price(NEW.item_id);
      END IF;
      SELECT (COUNT(oid) + 1) AS count, (COALESCE(SUM(price),0) + NEW.price) AS price INTO v_ordered_items FROM ordered_items WHERE order_id = v_order.id;
      IF v_ordered_items.price > v_discount_price THEN
        NEW.price = NEW.price  * v_discount_price /  v_ordered_items.price ;
        UPDATE ordered_items SET price = price * v_discount_price / v_ordered_items.price WHERE order_id = NEW.order_id;
      END IF;
    END IF;
    RETURN NEW;
  END;
$apply_wholesale_discounts$ LANGUAGE plpgsql;

CREATE TRIGGER apply_wholesale_discounts BEFORE INSERT ON ordered_items
  FOR EACH ROW EXECUTE PROCEDURE apply_wholesale_discounts();