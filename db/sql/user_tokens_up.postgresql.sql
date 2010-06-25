CREATE TABLE user_tokens (
  id            serial PRIMARY KEY,
  user_id       integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token         varchar(32) NOT NULL,
  created_at    timestamp DEFAULT current_timestamp
);