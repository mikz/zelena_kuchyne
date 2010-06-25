CREATE TABLE page_histories (
  id        serial UNIQUE,
  page_id   integer NOT NULL REFERENCES pages (id) ON DELETE CASCADE,
  url       varchar(50) PRIMARY KEY CHECK(length(url) > 1)
);