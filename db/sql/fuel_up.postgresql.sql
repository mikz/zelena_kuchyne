CREATE TABLE fuel (
  id            serial NOT NULL PRIMARY KEY,
  user_id       integer NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
  car_id        integer NOT NULL REFERENCES cars(id) ON DELETE RESTRICT,
  cost          float NOT NULL,
  amount        float NOT NULL,
  note          varchar(100) NOT NULL DEFAULT '',
  date          timestamp NOT NULL,
  created_at    timestamp NOT NULL,
  updated_at    timestamp NOT NULL,
  updated_by    integer REFERENCES users(id)
);
