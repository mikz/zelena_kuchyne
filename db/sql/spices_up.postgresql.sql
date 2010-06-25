CREATE TABLE spices (
  id            serial PRIMARY KEY,
  supplier_id   integer REFERENCES suppliers (id) ON DELETE SET NULL,
  name          varchar(50) NOT NULL UNIQUE CHECK(length(name) > 1)
);