CREATE TABLE used_spices (
  id              serial NOT NULL UNIQUE,
  spice_id        integer NOT NULL REFERENCES spices (id),
  meal_id         integer NOT NULL REFERENCES meals (id) ON DELETE CASCADE,
  PRIMARY KEY (spice_id, meal_id)
);