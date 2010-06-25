CREATE TABLE ingredients (
  id            serial NOT NULL UNIQUE, --activerecord needs this
  supplier_id   integer REFERENCES suppliers (id) ON DELETE SET NULL,
  unit          varchar(25) NOT NULL CHECK(length(unit) > 0),
  name          varchar(50) PRIMARY KEY CHECK(length(name) > 1),
  code          varchar(50) NOT NULL DEFAULT '',
  supply_flag   boolean NOT NULL DEFAULT false,
  cost          float NOT NULL
);