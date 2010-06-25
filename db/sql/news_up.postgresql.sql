CREATE TABLE news (
  id          serial PRIMARY KEY,
  title       varchar(80) NOT NULL CHECK(length(title) > 2),
  body        text,
  publish_at  timestamp NOT NULL DEFAULT current_timestamp,
  expire_at   timestamp
);