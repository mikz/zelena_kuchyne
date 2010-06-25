CREATE TABLE country_codes (
  id                      serial PRIMARY KEY,
  name                    varchar(70) NOT NULL UNIQUE,
  code                    integer NOT NULL
);
