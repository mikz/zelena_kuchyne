CREATE TABLE menus (
  id  serial  PRIMARY KEY,
  item_type   item_type NOT NULL DEFAULT 'menu'
) INHERITS (items);