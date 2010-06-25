CREATE TABLE item_profiles (
  id          serial PRIMARY KEY,
  item_id     integer NOT NULL, -- references items, but propagation of that setting is currently not supported in postgresql; there're triggers
  field_type  integer NOT NULL REFERENCES item_profile_types (id) ON DELETE CASCADE,
  field_body  text, -- since we don't know what we're gonna be storing, might as well call it "text"
  updated_at  timestamp DEFAULT current_timestamp,
  created_at  timestamp DEFAULT current_timestamp
);
