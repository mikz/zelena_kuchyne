CREATE TABLE meal_flags (
  id            serial PRIMARY KEY,
  name          varchar(30) NOT NULL UNIQUE CHECK(length(name) > 1),
  description   varchar(255),
  icon_path     varchar(255)
);