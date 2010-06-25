CREATE TYPE poll_type AS ENUM('single','multi');
CREATE TABLE polls (
  id        serial PRIMARY KEY,
  question  varchar(100) NOT NULL CHECK(length(question) > 3),
  poll_type poll_type NOT NULL,
  active    boolean NOT NULL DEFAULT false,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL
);