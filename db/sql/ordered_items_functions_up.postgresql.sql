CREATE TRIGGER copy_item_price BEFORE INSERT ON ordered_items
  FOR EACH ROW EXECUTE PROCEDURE copy_item_price();