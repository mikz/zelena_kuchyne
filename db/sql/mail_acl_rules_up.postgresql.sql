CREATE TABLE mail_acl_rules (
  rule_id       serial UNIQUE,
  mailbox_id    integer NOT NULL REFERENCES mail_mailboxes (mailbox_id) ON DELETE CASCADE,
  group_id      integer NOT NULL REFERENCES groups (id) ON DELETE CASCADE,
  action        varchar(15) NOT NULL CHECK (action IN ('read', 'handle', 'admin')),
  PRIMARY KEY (mailbox_id, group_id, action)
)