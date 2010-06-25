CREATE TABLE addresses (
  id            serial NOT NULL UNIQUE, -- for ActiveRecord
  user_id       integer NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  address_type  varchar(8) NOT NULL CHECK(address_type IN ('home', 'delivery', 'billing')) DEFAULT 'home',
  country_code  varchar(3) NOT NULL DEFAULT 'CZE',
  city          varchar(70) NOT NULL,
  house_no      varchar(15) NOT NULL,
  district      varchar(70) NOT NULL,
  street        varchar(70) NOT NULL,
  zip           varchar(30) NOT NULL,
  note          varchar(100),
  first_name    varchar(100),
  family_name   varchar(100),
  company_name  varchar(100),
  PRIMARY KEY (user_id, address_type)
);
