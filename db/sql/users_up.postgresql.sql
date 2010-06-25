CREATE TABLE users (
  id                      serial PRIMARY KEY,
  login                   varchar(50) UNIQUE CHECK(length(login) > 1),
  password_hash           varchar(255),
  salt                    varchar(255),
  guest                   boolean NOT NULL DEFAULT false,
  created_at              timestamp DEFAULT current_timestamp,
  updated_at              timestamp DEFAULT current_timestamp,
  email                   varchar(50) CHECK(length(email) > 4),
  imported_orders_price   float NOT NULL DEFAULT 0
);