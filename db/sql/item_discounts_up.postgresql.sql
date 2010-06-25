CREATE TABLE item_discounts (
  id              serial NOT NULL PRIMARY KEY,
  item_id         integer NOT NULL, -- REFERENCES items (item_id) but it's currently not supported by postgresql. #TODO: write triggers
  amount          float NOT NULL DEFAULT 0.0 CHECK(amount BETWEEN 0.0 AND 1.0), -- value of discount in % (20% discount is 0.2)
  name            varchar(50) NOT NULL CHECK(length(name) > 2 ),
  start_at        timestamp NOT NULL DEFAULT current_date CHECK(start_at >= current_date),
  expire_at       timestamp NOT NULL CHECK(expire_at >= start_at),
  note          varchar(50)
);