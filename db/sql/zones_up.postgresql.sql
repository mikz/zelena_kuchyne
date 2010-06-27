CREATE TABLE zones (
  id                      serial PRIMARY KEY,
  name                    varchar(70) NOT NULL UNIQUE,
  disabled                boolean NOT NULL DEFAULT false,
  hidden                  boolean NOT NULL DEFAULT false
);

ALTER TABLE delivery_methods ADD COLUMN zone_id integer REFERENCES zones (id);
INSERT INTO zones(name, hidden) VALUES ('Archiv', true);
UPDATE delivery_methods SET zone_id = (SELECT id FROM zones LIMIT 1) WHERE zone_id IS NULL;

INSERT INTO zones(id, name) VALUES (2, 'Zelená zóna');
INSERT INTO zones(id, name) VALUES (3, 'Modrá zóna');
INSERT INTO zones(id, name) VALUES (4, 'Červená zóna');

ALTER TABLE delivery_methods ALTER COLUMN zone_id SET NOT NULL;

ALTER TABLE addresses ADD COLUMN zone_id integer REFERENCES zones (id);
ALTER TABLE addresses ADD COLUMN zone_reviewed boolean DEFAULT false;

INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 1 do 100 Kč', 'rozvoz do 100 Kč', 400, 0,   2, true);
INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 1 do 200 Kč', 'rozvoz do 200 Kč', 250, 100, 4, true);
INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 1 do 275 Kč', 'rozvoz do 275 Kč', 150, 200, 4, true);
INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 1 do 350 Kč', 'rozvoz do 350 Kč', 50,  275, 4, true);
INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 1 zdarma', 'rozvoz zdarma', 0,   350, 4, true);

INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 2 do 100 Kč', 'rozvoz do 100 Kč', 600, 0,   3, true);
INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 2 do 200 Kč', 'rozvoz do 200 Kč', 400, 100, 4, true);
INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 2 do 350 Kč', 'rozvoz do 350 Kč', 300, 200, 4, true);
INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 2 do 500 Kč', 'rozvoz do 500 Kč', 150, 350, 4, true);
INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 2 zdarma', 'rozvoz zdarma',    0,   500, 4, true);

INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 3 do 100 Kč', 'rozvoz do 100 Kč', 800, 0,   4, true);
INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 3 do 350 Kč', 'rozvoz do 350 Kč', 650, 100, 4, true);
INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 3 do 500 Kč', 'rozvoz do 500 Kč', 400, 350, 4, true);
INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 3 do 750 Kč', 'rozvoz do 750 Kč', 250, 500, 4, true);
INSERT INTO delivery_methods (name, basket_name, price, minimal_order_price, zone_id, flag_has_delivery_man) VALUES ('zóna 3 zdarma', 'rozvoz zdarma',    0,   750, 4, true);

INSERT INTO user_profile_types (name, data_type, visible, editable, required) VALUES('preferred_delivery_method_id', 'hidden', false, false, false);
