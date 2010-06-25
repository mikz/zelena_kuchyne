-- additional information on users; this is kind of a misnomer, since each row in this table is actually only one field in a user profile
CREATE TABLE user_profiles (
  id          serial NOT NULL UNIQUE, --activerecord needs this
  user_id     integer REFERENCES users (id) ON DELETE CASCADE,
  field_type  integer REFERENCES user_profile_types (id) ON DELETE CASCADE,
  field_body  text,
  updated_at  timestamp DEFAULT current_timestamp,
  created_at  timestamp DEFAULT current_timestamp,
  PRIMARY KEY (user_id, field_type)
);