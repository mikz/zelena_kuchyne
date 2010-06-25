CREATE TABLE meal_categories (
  id    serial NOT NULL UNIQUE, --activerecord needs this
  name  varchar(70) PRIMARY KEY CHECK(length(name) > 1)
);
