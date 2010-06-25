CREATE TRIGGER check_item_id_unique BEFORE INSERT ON products
  FOR EACH ROW EXECUTE PROCEDURE check_item_id_unique();

CREATE TRIGGER delete_item_profiles AFTER DELETE ON products
  FOR EACH ROW EXECUTE PROCEDURE delete_item_profiles();

CREATE TRIGGER delete_ordered_items AFTER DELETE ON products
  FOR EACH ROW EXECUTE PROCEDURE delete_ordered_items();