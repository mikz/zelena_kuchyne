-- binds categories and products together
CREATE TABLE categorized_products (
  oid                   serial NOT NULL UNIQUE, --activerecord needs this
  product_id            integer REFERENCES products (id) ON DELETE CASCADE,
  product_category_id   integer REFERENCES product_categories (id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, product_category_id)
);