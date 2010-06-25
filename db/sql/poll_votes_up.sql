CREATE TABLE poll_votes (
  id              serial PRIMARY KEY,
  user_id         integer REFERENCES users(id),
  poll_answer_id  integer NOT NULL REFERENCES poll_answers(id) ON DELETE CASCADE
)