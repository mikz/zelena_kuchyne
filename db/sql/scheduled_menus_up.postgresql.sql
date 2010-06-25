CREATE TABLE scheduled_menus (
  oid             serial NOT NULL UNIQUE, --activerecord needs this
  menu_id         integer NOT NULL REFERENCES menus (id) ON DELETE CASCADE,
  scheduled_for   date NOT NULL,
  amount          integer NOT NULL CHECK(amount > 0),
  invisible       boolean NOT NULL DEFAULT false,
  created_at      timestamp NOT NULL DEFAULT NOW(),
  PRIMARY KEY (menu_id, scheduled_for)
);