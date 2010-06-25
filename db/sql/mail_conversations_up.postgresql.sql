CREATE TABLE mail_conversations (
  conversation_id   serial UNIQUE,
  mailbox_id        integer NOT NULL REFERENCES mail_mailboxes (mailbox_id) ON DELETE CASCADE,
  handled_by        integer REFERENCES users (id) ON DELETE SET NULL,
  tracker           char(10) NOT NULL CHECK(length(tracker) = 10),
  note              text,
  flag_closed       boolean NOT NULL DEFAULT false
);