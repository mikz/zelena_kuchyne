CREATE TABLE mail_mailboxes (
  mailbox_id      serial PRIMARY KEY,
  address         varchar(100) UNIQUE NOT NULL CHECK (length(address) > 4),
  from_name       varchar(255),
  human_name      varchar(100),
  description     text,
  imap_server     varchar(100) NOT NULL,
  imap_login      varchar(100) NOT NULL,
  imap_password   varchar(100) NOT NULL
);