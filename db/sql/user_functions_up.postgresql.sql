CREATE FUNCTION check_users_data() RETURNS trigger AS $check_users_data$
  BEGIN
    IF NEW.guest = true THEN
      RETURN NEW;
    END IF;
    
    IF NEW.login ISNULL THEN
      RAISE EXCEPTION 'users.login cannot be NULL';
    END IF;

    IF NEW.email ISNULL THEN
      RAISE EXCEPTION 'users.email cannot be NULL';
    END IF;

    RETURN NEW;
  END;
$check_users_data$ LANGUAGE plpgsql;

CREATE TRIGGER check_users_data BEFORE UPDATE OR INSERT ON users
  FOR EACH ROW EXECUTE PROCEDURE check_users_data();

CREATE FUNCTION delete_old_guests() RETURNS trigger AS $delete_old_guests$
  BEGIN
    DELETE FROM users
      WHERE age(users.created_at) > time '24:00'
        AND guest = true;
    RETURN NEW;
  END;
$delete_old_guests$ LANGUAGE plpgsql;

CREATE TRIGGER delete_old_guests BEFORE INSERT ON users
  FOR EACH ROW EXECUTE PROCEDURE delete_old_guests();

CREATE FUNCTION delete_old_user_tokens() RETURNS trigger AS $delete_old_user_tokens$
  BEGIN
    DELETE FROM user_tokens
      WHERE AGE(current_timestamp,created_at) > interval '24 hours';
    RETURN NEW;
  END;
$delete_old_user_tokens$ LANGUAGE plpgsql;

CREATE TRIGGER delete_old_user_tokens BEFORE INSERT OR UPDATE ON user_tokens
  FOR EACH ROW EXECUTE PROCEDURE delete_old_user_tokens();

CREATE FUNCTION add_to_sentence(varchar, varchar) RETURNS varchar AS $add_to_sentence$
  SELECT ($1 || ', ' || $2)
$add_to_sentence$ LANGUAGE SQL RETURNS NULL ON NULL INPUT;

CREATE AGGREGATE list(varchar) (
  SFUNC = add_to_sentence,
  STYPE = varchar);