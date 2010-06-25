CREATE TABLE pages (
  id          serial NOT NULL UNIQUE, --activerecord needs this
  title       varchar(80) NOT NULL,
  body        text,
  url         varchar(50) PRIMARY KEY CHECK(length(url) > 1),
  editable    boolean NOT NULL DEFAULT true,
  created_at  timestamp DEFAULT current_timestamp,
  updated_at  timestamp DEFAULT current_timestamp
);
