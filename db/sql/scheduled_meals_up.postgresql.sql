-- meals can be scheduled for certain day, and in certain amount
CREATE TABLE scheduled_meals (
  oid             serial NOT NULL UNIQUE, --activerecord needs this
  meal_id         integer NOT NULL REFERENCES meals (id) ON DELETE CASCADE,
  scheduled_for   date NOT NULL,
  amount          integer NOT NULL CHECK(amount > 0),
  invisible       boolean NOT NULL DEFAULT false,
  created_at      timestamp NOT NULL DEFAULT NOW(),
  PRIMARY KEY (meal_id, scheduled_for)
);
