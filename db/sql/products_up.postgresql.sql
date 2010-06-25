CREATE TABLE products (
  id                serial PRIMARY KEY,
  item_type         item_type NOT NULL DEFAULT 'product',
  cost              float NOT NULL DEFAULT 0.0,
  short_description varchar(250) NOT NULL DEFAULT '',
  disabled          boolean NOT NULL DEFAULT FALSE,
  term_of_delivery  interval, -- http://www.postgresql.org/docs/8.3/static/datatype-datetime.html#AEN4978
  UNIQUE (item_id)
) INHERITS (items);
