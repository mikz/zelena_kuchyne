DROP FUNCTION IF EXISTS check_users_data() CASCADE;
DROP FUNCTION IF EXISTS delete_old_guests() CASCADE;
DROP FUNCTION IF EXISTS delete_old_user_tokens() CASCADE;
DROP FUNCTION IF EXISTS add_to_sentence(varchar, varchar) CASCADE;
DROP AGGREGATE IF EXISTS list(varchar) CASCADE;
