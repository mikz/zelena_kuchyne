CREATE TABLE logbook_categories (
  id serial PRIMARY KEY,
  name varchar(50) NOT NULL CHECK(length(name) > 0)
);