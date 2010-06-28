CREATE TABLE dialy_menu_entries (
  id              serial PRIMARY KEY,
  dialy_menu_id   integer NOT NULL REFERENCES dialy_menus(id),
  category_id     integer NOT NULL REFERENCES meal_categories(id),
  name            varchar(255) NOT NULL,
  description     text NOT NULL DEFAULT '',
  in_menu         boolean NOT NULL DEFAULT false,
  price           numeric NOT NULL
);