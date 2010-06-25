-- binds menus and meals together
CREATE TABLE courses (
  id        serial NOT NULL UNIQUE, --activerecord needs this
  meal_id   integer REFERENCES meals (id) ON DELETE CASCADE,
  menu_id   integer REFERENCES menus (id) ON DELETE CASCADE,
  PRIMARY KEY (meal_id, menu_id)
);