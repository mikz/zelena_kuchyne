CREATE TABLE zones (
  id                      serial PRIMARY KEY,
  name                    varchar(70) NOT NULL UNIQUE,
  disabled                boolean NOT NULL DEFAULT false,
  hidden                  boolean NOT NULL DEFAULT false
);

ALTER TABLE delivery_methods ADD COLUMN zone_id integer REFERENCES zones (id);

ALTER TABLE delivery_methods ALTER COLUMN zone_id SET NOT NULL;

ALTER TABLE addresses ADD COLUMN zone_id integer REFERENCES zones (id);
ALTER TABLE addresses ADD COLUMN zone_reviewed boolean DEFAULT false;


