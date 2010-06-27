CREATE TABLE dialy_menu_scheduled (
  id              serial PRIMARY KEY,
  dialy_menu_id   integer NOT NULL REFERENCES dialy_menus(id), 
  item_id         integer NOT NULL,  -- REFERENCES items (item_id)
  disabled        boolean NOT NULL DEFAULT true
);