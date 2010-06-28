CREATE TABLE dialy_menus (
  id          serial PRIMARY KEY,
  date        date NOT NULL UNIQUE,
  menu_price  numeric
);