CREATE TABLE delivery_methods (
  id                      serial PRIMARY KEY,
  name                    varchar(70) NOT NULL UNIQUE,
  basket_name             varchar(70) NOT NULL DEFAULT '',
  price                   float NOT NULL,
  minimal_order_price     float NOT NULL,
  flag_has_delivery_man   boolean NOT NULL DEFAULT false
);
