CREATE TABLE meal_category_order (
  category_id   integer PRIMARY KEY REFERENCES meal_categories(id),
  order_id         integer NOT NULL
);