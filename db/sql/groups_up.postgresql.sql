CREATE TABLE groups (
  id              serial PRIMARY KEY,
  title           varchar(50) NOT NULL,
  default_group   boolean NOT NULL DEFAULT false, -- the application automatically adds default groups to new users
  system_name     varchar(50) CHECK(length(system_name) > 1)
);