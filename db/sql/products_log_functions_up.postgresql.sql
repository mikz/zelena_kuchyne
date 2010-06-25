CREATE FUNCTION product_cost(integer) RETURNS float AS $product_cost$
  BEGIN
    RETURN (SELECT cost FROM products WHERE id = $1);
  END;
$product_cost$ LANGUAGE plpgsql;

CREATE FUNCTION copy_product_cost() RETURNS trigger AS $copy_product_cost$
  BEGIN
    IF NEW.product_cost IS NULL THEN
      NEW.product_cost = product_cost(NEW.product_id);
    END IF;
    RETURN NEW;
  END;
$copy_product_cost$ LANGUAGE plpgsql;

CREATE TRIGGER copy_product_cost BEFORE INSERT ON products_log
  FOR EACH ROW EXECUTE PROCEDURE copy_product_cost();