CREATE TABLE memberships (
  id          serial UNIQUE NOT NULL, -- for activerecord, that dumb fucker
  user_id     integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  group_id    integer NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  created_at  timestamp DEFAULT current_timestamp,
  updated_at  timestamp DEFAULT current_timestamp,
  PRIMARY KEY(user_id, group_id)
);
