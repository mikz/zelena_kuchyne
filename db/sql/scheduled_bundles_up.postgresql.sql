CREATE TABLE scheduled_bundles (
  oid             serial NOT NULL UNIQUE, --activerecord needs this
  bundle_id         integer NOT NULL REFERENCES bundles (id) ON DELETE CASCADE,
  scheduled_for   date NOT NULL,
  invisible       boolean NOT NULL DEFAULT false,
  PRIMARY KEY (bundle_id, scheduled_for)
);