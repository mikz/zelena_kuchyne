CREATE VIEW mail_conversations_view AS SELECT
  conversation_id, max(updated_at) AS updated_at, bool_or(flag_new) AS unread, subject, mailbox_id, handled_by, flag_closed 
  FROM mail_conversations NATURAL LEFT JOIN mail_messages 
  GROUP BY conversation_id, subject, mailbox_id, handled_by, flag_closed;