CREATE TABLE cars (
  id serial         PRIMARY KEY,
  registration_no   VARCHAR(10) NOT NULL,
  fuel_consumption  float NOT NULL, -- in litres per 100km
  note              varchar(50) NOT NULL DEFAULT ''
);
