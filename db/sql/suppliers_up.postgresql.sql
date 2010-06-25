CREATE TABLE suppliers (
  id        serial NOT NULL UNIQUE, --activerecord needs this
  name      varchar(70) PRIMARY KEY CHECK(length(name) > 1),
  name_abbr varchar(10) NOT NULL UNIQUE CHECK(length(name_abbr) > 1),
  address   text
);