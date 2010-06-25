CREATE TYPE message_direction AS ENUM('sent', 'recieved');
CREATE TABLE mail_messages (
  message_id          serial UNIQUE,
  imap_id             integer NOT NULL, -- message UID on the server
  conversation_id     integer NOT NULL REFERENCES mail_conversations (conversation_id),
  from_address        varchar(100) NOT NULL,
  from_name           varchar(100),
  to_address          varchar(100) NOT NULL,
  subject             varchar(255) NOT NULL,
  body                text NOT NULL,
  flag_new            boolean NOT NULL DEFAULT true,
  direction           message_direction NOT NULL DEFAULT 'recieved',
  created_at          timestamp DEFAULT current_timestamp, -- recieved or sent
  updated_at          timestamp DEFAULT current_timestamp
);