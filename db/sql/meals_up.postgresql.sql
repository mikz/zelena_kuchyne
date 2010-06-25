CREATE TABLE meals (
  id                serial PRIMARY KEY,
  meal_category_id  integer NOT NULL REFERENCES meal_categories (id) ON DELETE CASCADE,
  always_available  boolean NOT NULL DEFAULT false,
  item_type   item_type NOT NULL DEFAULT 'meal',
  restaurant_flag   boolean NOT NULL DEFAULT false
) INHERITS (items);
