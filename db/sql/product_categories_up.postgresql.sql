CREATE TABLE product_categories (
  id          serial PRIMARY KEY,
  parent_id   integer REFERENCES product_categories (id) ON DELETE CASCADE,
  lft         integer,
  rgt         integer,
  name        varchar(50) NOT NULL CHECK(length(name) > 1),
  description text
);
