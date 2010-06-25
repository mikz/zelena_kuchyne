CREATE TABLE poll_answers(
  id        serial PRIMARY KEY,
  poll_id   integer NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
  text      varchar(100) NOT NULL CHECK(length(text) > 0)
);