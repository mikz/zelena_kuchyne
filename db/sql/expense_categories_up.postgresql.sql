CREATE TABLE expense_categories (
  id    serial UNIQUE NOT NULL ,
  name  varchar(70) PRIMARY KEY CHECK(length(name) > 1),
  description varchar(105) NOT NULL DEFAULT ''
);
