CREATE TABLE premises (
  id          serial PRIMARY KEY,
  name        varchar(100) NOT NULL,
  name_abbr   varchar(20) NOT NULL UNIQUE CHECK(length(name_abbr) > 1),
  address     text,
  description text
);