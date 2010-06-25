CREATE TABLE snippets (
  name          varchar(50) PRIMARY KEY CHECK(length(name) > 1),
  content       text,
  cachable_flag boolean NOT NULL DEFAULT true
);