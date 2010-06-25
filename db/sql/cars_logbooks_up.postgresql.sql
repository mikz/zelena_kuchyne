CREATE TABLE cars_logbooks (
  id                  serial  PRIMARY KEY,
  car_id              integer NOT NULL REFERENCES cars(id) ON DELETE RESTRICT,
  user_id             integer NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  date                date NOT NULL,
  beginning           integer NOT NULL, -- in meters
  ending              integer NOT NULL, -- in meters
  business_distance   integer NOT NULL DEFAULT 0 CHECK(business_distance >= 0), -- in meters
  private_distance    integer NOT NULL DEFAULT 0 CHECK(private_distance >= 0), -- in meters
  logbook_category_id integer REFERENCES logbook_categories(id) CHECK((business_distance = 0) OR (business_distance > 0 AND logbook_category_id IS NOT NULL)),
  created_at          timestamp NOT NULL,
  updated_at          timestamp NOT NULL,
  updated_by          integer REFERENCES users(id),
  CONSTRAINT valid_distance CHECK((private_distance + business_distance) = (ending - beginning))
);
