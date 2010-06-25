CREATE TABLE flagged_meals (
  oid                   serial NOT NULL UNIQUE, --activerecord needs this
  meal_id       integer NOT NULL REFERENCES meals (id),
  meal_flag_id  integer NOT NULL REFERENCES meal_flags (id) ON DELETE CASCADE,
  PRIMARY KEY (meal_id, meal_flag_id)
);
