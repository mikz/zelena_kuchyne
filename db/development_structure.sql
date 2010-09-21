--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: -
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plpgsql;


SET search_path = public, pg_catalog;

--
-- Name: assigned_meals; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE assigned_meals AS (
	delivery_man_id integer,
	item_id integer,
	assigned_amount bigint,
	sold_amount bigint,
	trunk_amount bigint,
	lost_amount bigint,
	amount bigint
);


--
-- Name: discount_class; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE discount_class AS ENUM (
    'meal',
    'product'
);


--
-- Name: expense_owner; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE expense_owner AS ENUM (
    'delivery',
    'restaurant',
    'office'
);


--
-- Name: expense_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE expense_type AS ENUM (
    'investment',
    'other'
);


--
-- Name: get_days; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE get_days AS (
	scheduled_for date
);


--
-- Name: gtrgm; Type: SHELL TYPE; Schema: public; Owner: -
--

CREATE TYPE gtrgm;


--
-- Name: gtrgm_in(cstring); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_in(cstring) RETURNS gtrgm
    LANGUAGE c STRICT
    AS '$libdir/pg_trgm', 'gtrgm_in';


--
-- Name: gtrgm_out(gtrgm); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_out(gtrgm) RETURNS cstring
    LANGUAGE c STRICT
    AS '$libdir/pg_trgm', 'gtrgm_out';


--
-- Name: gtrgm; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE gtrgm (
    INTERNALLENGTH = variable,
    INPUT = gtrgm_in,
    OUTPUT = gtrgm_out,
    ALIGNMENT = int4,
    STORAGE = plain
);


--
-- Name: ingredients_between; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE ingredients_between AS (
	amount double precision,
	amount_with_consumption double precision,
	ingredient_id integer,
	name character varying(50),
	code character varying(50),
	unit character varying(25),
	cost_per_unit double precision,
	total_cost double precision,
	total_cost_with_consumption double precision,
	supply_flag boolean,
	supplier_short character varying(10),
	supplier character varying(70)
);


--
-- Name: ingredients_log_entry_owner; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE ingredients_log_entry_owner AS ENUM (
    'delivery',
    'restaurant'
);


--
-- Name: ingredients_log_watchdog_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE ingredients_log_watchdog_state AS (
	id integer,
	ingredient_id integer,
	operator bit(3),
	value double precision,
	state boolean,
	balance double precision
);


--
-- Name: item_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE item_type AS ENUM (
    'meal',
    'product',
    'bundle',
    'menu'
);


--
-- Name: message_direction; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE message_direction AS ENUM (
    'sent',
    'recieved'
);


--
-- Name: order_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE order_state AS ENUM (
    'basket',
    'order',
    'expedited',
    'closed'
);


--
-- Name: orders_sum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE orders_sum AS (
	total_price double precision,
	total_delivery double precision,
	total_discounts double precision
);


--
-- Name: poll_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE poll_type AS ENUM (
    'single',
    'multi'
);


--
-- Name: shopping_list_between; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE shopping_list_between AS (
	amount double precision,
	amount_with_consumption double precision,
	ingredient_id integer,
	name character varying(50),
	code character varying(50),
	unit character varying(25),
	cost_per_unit double precision,
	total_cost double precision,
	total_cost_with_consumption double precision,
	supply_flag boolean,
	supplier_short character varying(10),
	supplier character varying(70)
);


--
-- Name: summary; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE summary AS (
	orders_price double precision,
	orders_delivery double precision,
	orders_discount double precision,
	delivery_bought_ingredients double precision,
	restaurant_bought_ingredients double precision,
	restaurant_cooking_ingredients double precision,
	delivery_cooking_ingredients double precision,
	delivery_sold double precision,
	restaurant_sold double precision,
	fuel double precision,
	delivery_expenses double precision,
	office_expenses double precision,
	restaurant_expenses double precision,
	restaurant_sales double precision
);


--
-- Name: watchdog_balance; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE watchdog_balance AS (
	balance double precision,
	ingredient_id integer
);


--
-- Name: _group_concat(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION _group_concat(text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT CASE
    WHEN $2 IS NULL THEN $1
    WHEN $1 IS NULL THEN $2
    ELSE $1 operator(pg_catalog.||) ' ' operator(pg_catalog.||) $2
  END
$_$;


--
-- Name: add_to_sentence(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION add_to_sentence(character varying, character varying) RETURNS character varying
    LANGUAGE sql STRICT
    AS $_$
  SELECT ($1 || ', ' || $2)
$_$;


--
-- Name: apply_wholesale_discounts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION apply_wholesale_discounts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    v_discount_price  float;
    v_ordered_items   RECORD;
    v_order           RECORD;
  BEGIN
    SELECT * INTO v_order FROM orders WHERE id = NEW.order_id;
    SELECT discount_price INTO v_discount_price FROM wholesale_discounts WHERE user_id = v_order.user_id AND v_order.deliver_at::date BETWEEN start_at AND COALESCE(expire_at, v_order.deliver_at::date) ORDER BY start_at;
    IF v_discount_price IS NOT NULL THEN
      IF NEW.price IS NULL THEN
        NEW.price = item_price(NEW.item_id);
      END IF;
      SELECT (COUNT(oid) + 1) AS count, (COALESCE(SUM(price),0) + NEW.price) AS price INTO v_ordered_items FROM ordered_items WHERE order_id = v_order.id;
      IF v_ordered_items.price > v_discount_price THEN
        NEW.price = NEW.price  * v_discount_price /  v_ordered_items.price ;
        UPDATE ordered_items SET price = price * v_discount_price / v_ordered_items.price WHERE order_id = NEW.order_id;
      END IF;
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: check_basket(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_basket() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF NEW.state != 'basket' THEN
      RETURN NEW;
    END IF;
    IF TG_OP = 'INSERT' THEN
      PERFORM id FROM orders WHERE user_id = NEW.user_id AND state = 'basket';
    ELSE
      PERFORM id FROM orders WHERE user_id = NEW.user_id AND state = 'basket' AND id != NEW.id;
    END IF;
    IF FOUND THEN
      RAISE EXCEPTION 'There can be only one basket per user.';
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: check_consumptions_ingredient_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_consumptions_ingredient_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF NEW.consumption_id IS NOT NULL AND NEW.ingredient_id <> (SELECT ingredient_id FROM ingredient_consumptions WHERE id = NEW.consumption_id ) THEN
      RAISE EXCEPTION 'Ingredient consumption mismatch.';
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: check_item_id_exists(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_item_id_exists() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    PERFORM item_id FROM items WHERE item_id = NEW.item_id;
    IF NOT found THEN
      RAISE EXCEPTION 'item_id % does not exists in table items', NEW.item_id;
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: check_item_id_unique(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_item_id_unique() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    PERFORM item_id FROM items WHERE item_id = NEW.item_id;
    IF found THEN
      RAISE EXCEPTION 'item_id % already exists', NEW.item_id;
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: check_order_dates_match(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_order_dates_match() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    v_item_type varchar(50);
    v_meal_id integer;
  BEGIN
    SELECT item_type INTO v_item_type FROM items WHERE item_id = NEW.item_id;
    IF v_item_type = 'product' THEN
      RETURN NEW;
    END IF;
    
    IF v_item_type = 'meal' THEN
      IF (SELECT always_available FROM meals WHERE item_id = NEW.item_id) THEN
        RETURN NEW;
      END IF;
    END IF;
    
    IF v_item_type = 'bundle' THEN
      SELECT meal_id INTO v_meal_id FROM bundles WHERE item_id = NEW.item_id;
      PERFORM item_id FROM scheduled_items_view WHERE item_id = (SELECT item_id FROM meals WHERE id = v_meal_id) AND CAST(scheduled_for AS date) = CAST( (SELECT deliver_at FROM orders WHERE id = NEW.order_id) AS date);
      IF FOUND THEN
        RETURN NEW;
      END IF;
    END IF;
    
    PERFORM item_id FROM scheduled_items_view WHERE item_id = NEW.item_id AND CAST(scheduled_for AS date) = CAST( (SELECT deliver_at FROM orders WHERE id = NEW.order_id) AS date);
    IF FOUND THEN
      RETURN NEW;
    END IF;

    RAISE EXCEPTION 'Adding item #% to order #% would cause the order to be undeliverable.', NEW.item_id, NEW.order_id;
  END;
$$;


--
-- Name: check_order_delivery_method(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_order_delivery_method() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    v_delivery_method_has_delivery_man  boolean;
  BEGIN
    SELECT flag_has_delivery_man INTO v_delivery_method_has_delivery_man FROM delivery_methods WHERE id = NEW.delivery_method_id;
    IF v_delivery_method_has_delivery_man IS FALSE AND NEW.delivery_man_id IS NOT NULL THEN
      RAISE EXCEPTION 'Cannot have delivery man when not using our delivery method.';
      RETURN NULL;
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: check_scheduled_bundle(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_scheduled_bundle() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    PERFORM meal_id FROM scheduled_meals WHERE meal_id = (SELECT meal_id FROM bundles WHERE bundles.id = NEW.bundle_id);
    IF NOT found THEN
      RAISE EXCEPTION 'cannot schedule bundle without scheduling its meal';
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: check_users_data(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_users_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: check_valid_item_id(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_valid_item_id(integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
  BEGIN
    PERFORM item_id FROM items WHERE item_id = $1;
    RETURN FOUND;
  END;
$_$;


--
-- Name: concat_ws(text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CASE WHEN $1 IS NULL THEN NULL WHEN $3 IS NULL THEN $2 ELSE $2 || $1 || $3 END$_$;


--
-- Name: concat_ws(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3),$4)$_$;


--
-- Name: concat_ws(text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4),$5)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5),$6)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6),$7)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7),$8)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8),$9)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9),$10)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10),$11)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11),$12)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12),$13)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13),$14)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14),$15)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15),$16)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16),$17)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17),$18)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18),$19)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19),$20)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20),$21)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21),$22)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22),$23)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23),$24)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24),$25)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25),$26)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26),$27)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27),$28)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28),$29)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29),$30)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30),$31)$_$;


--
-- Name: concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION concat_ws(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CONCAT_WS($1,CONCAT_WS($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31),$32)$_$;


--
-- Name: copy_consumption_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION copy_consumption_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF NEW.consumption_id IS NULL THEN
      NEW.consumption_id = (SELECT ingredient_consumptions.id FROM ingredient_consumptions LEFT JOIN stocktakings ON stocktakings.id = stocktaking_id WHERE date < NEW.day AND ingredient_id = NEW.ingredient_id ORDER BY date DESC LIMIT 1);
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: copy_ingredient_price(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION copy_ingredient_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF NEW.ingredient_price IS NULL THEN
      NEW.ingredient_price = ingredient_cost(NEW.ingredient_id);
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: copy_item_cost(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION copy_item_cost() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF NEW.cost IS NULL THEN
      NEW.cost = item_cost(NEW.item_id);
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: copy_item_price(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION copy_item_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF NEW.price IS NULL THEN
      NEW.price = item_price(NEW.item_id);
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: copy_meal_price(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION copy_meal_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF NEW.price IS NULL THEN
      NEW.price = meal_price(NEW.meal_id);
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: copy_product_cost(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION copy_product_cost() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF NEW.product_cost IS NULL THEN
      NEW.product_cost = product_cost(NEW.product_id);
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: crc32(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION crc32(text) RETURNS bigint
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $_$
  DECLARE
    tmp bigint;
  BEGIN
    tmp = (hex_to_int(SUBSTRING(MD5($1) FROM 1 FOR 8))::bigint);
    IF tmp < 0 THEN
      tmp = 4294967296 + tmp;
    END IF;
    return tmp;
  END
$_$;


--
-- Name: create_ingredients_log_from_meals_entry(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION create_ingredients_log_from_meals_entry() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    v_recipe RECORD;
  BEGIN
    FOR v_recipe IN SELECT * FROM recipes WHERE meal_id = NEW.meal_id LOOP
      PERFORM id FROM ingredients_log_from_meals WHERE scheduled_meal_id = NEW.oid AND ingredient_id = v_recipe.ingredient_id AND day = NEW.scheduled_for AND meal_id = NEW.meal_id;
      IF NOT FOUND THEN
        INSERT INTO ingredients_log_from_meals(day, amount, ingredient_id, ingredient_price, meal_id, scheduled_meal_id) VALUES(NEW.scheduled_for, -v_recipe.amount * NEW.amount, v_recipe.ingredient_id, ingredient_cost(v_recipe.ingredient_id), NEW.meal_id, NEW.oid);
      END IF;
    END LOOP;
    
    RETURN NEW;
  END;
$$;


--
-- Name: create_ingredients_log_from_menus_entry(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION create_ingredients_log_from_menus_entry() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    v_recipe RECORD;
    v_course RECORD;
  BEGIN
    FOR v_course IN SELECT * FROM courses WHERE menu_id = NEW.menu_id LOOP
      FOR v_recipe IN SELECT * FROM recipes WHERE meal_id = v_course.meal_id LOOP
        PERFORM id FROM ingredients_log_from_menus WHERE day = NEW.scheduled_for AND scheduled_menu_id = NEW.oid AND meal_id = v_course.meal_id AND ingredient_id = v_recipe.ingredient_id;
        IF NOT FOUND THEN
          INSERT INTO ingredients_log_from_menus(day, amount, ingredient_id, ingredient_price, meal_id, scheduled_menu_id) VALUES(NEW.scheduled_for, -v_recipe.amount * NEW.amount, v_recipe.ingredient_id, ingredient_cost(v_recipe.ingredient_id), v_course.meal_id, NEW.oid);
        END IF;
      END LOOP;
    END LOOP;
    
    RETURN NEW;
  END;
$$;


--
-- Name: delete_item_discounts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_item_discounts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM item_discounts WHERE item_id = OLD.id;
    RETURN OLD;
  END;
$$;


--
-- Name: delete_item_profiles(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_item_profiles() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM item_profiles WHERE item_id = OLD.id;
    RETURN OLD;
  END;
$$;


--
-- Name: delete_items_from_order(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_items_from_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF NEW.deliver_at::date = OLD.deliver_at::date THEN
      RETURN NEW;
    END IF;
    
    DELETE FROM ordered_items WHERE order_id = OLD.id AND item_id NOT IN (SELECT item_id FROM products);
    RETURN NEW;
  END;
$$;


--
-- Name: delete_old_guests(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_old_guests() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM users
      WHERE age(users.created_at) > time '24:00'
        AND guest = true;
    RETURN NEW;
  END;
$$;


--
-- Name: delete_old_user_tokens(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_old_user_tokens() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM user_tokens
      WHERE AGE(current_timestamp,created_at) > interval '24 hours';
    RETURN NEW;
  END;
$$;


--
-- Name: delete_ordered_items(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_ordered_items() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM ordered_items WHERE item_id = OLD.item_id;
    RETURN OLD;
  END;
$$;


--
-- Name: delete_scheduled_bundles(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_scheduled_bundles() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    DELETE FROM scheduled_bundles WHERE scheduled_for = OLD.scheduled_for AND bundle_id IN (SELECT id FROM bundles WHERE OLD.meal_id = meal_id);
    RETURN OLD;
  END;
$$;


--
-- Name: difference(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION difference(text, text) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'difference';


--
-- Name: dmetaphone(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION dmetaphone(text) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'dmetaphone';


--
-- Name: dmetaphone_alt(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION dmetaphone_alt(text) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'dmetaphone_alt';


--
-- Name: get_days(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_days(boolean) RETURNS SETOF get_days
    LANGUAGE sql
    AS $_$
  SELECT DISTINCT COALESCE(scheduled_for, lost_at)::date as scheduled_for
   FROM scheduled_meals
   NATURAL FULL JOIN scheduled_menus
   NATURAL FULL JOIN lost_items
   WHERE COALESCE(invisible,false) = false OR $1
$_$;


--
-- Name: get_delivery_bought_ingredients_cost_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_delivery_bought_ingredients_cost_between(date, date) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(amount*ingredient_price) FROM ingredients_log WHERE day BETWEEN $1 AND $2 AND entry_owner = 'delivery' AND amount > 0;
$_$;


--
-- Name: get_delivery_cooking_ingredients_cost_bewteen(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_delivery_cooking_ingredients_cost_bewteen(date, date) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(@amount_with_consumption*ingredient_price) FROM ingredients_log_view WHERE day BETWEEN $1 AND $2 AND entry_owner = 'delivery';
$_$;


--
-- Name: get_delivery_expenses_sum_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_delivery_expenses_sum_between(date, date) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(price) FROM expenses WHERE bought_at::date BETWEEN $1 AND $2 AND expense_owner = 'delivery';
$_$;


--
-- Name: get_delivery_sold_items_sum_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_delivery_sold_items_sum_between(date, date) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(@amount*price) FROM sold_items_view  WHERE date BETWEEN $1 AND $2 AND user_id <> (SELECT id FROM users WHERE login = 'zelena_kuchyne');
$_$;


--
-- Name: get_fuel_sum_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_fuel_sum_between(date, date) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(cost) FROM fuel WHERE date::date BETWEEN $1 AND $2;
$_$;


--
-- Name: get_ingredients_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_ingredients_between(date, date) RETURNS SETOF ingredients_between
    LANGUAGE sql STABLE
    AS $_$
   SELECT
     @sum(amount) AS amount,
     @SUM(amount_with_consumption) AS amount_with_consumption,
     ingredient_id,
     name,
     code,
     unit,
     cost_per_unit,
     @sum(total_cost) AS total_cost,
     @sum(total_cost_with_consumption) AS total_cost_with_consumption,
     supply_flag,
     supplier_short,
     supplier
       FROM ingredients_per_day_view
         WHERE day BETWEEN $1 AND $2
         GROUP BY ingredient_id, name, code, unit, supply_flag, cost_per_unit, supplier_short, supplier;
 $_$;


--
-- Name: get_lost_items_cost_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_lost_items_cost_between(date, date) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(total_cost) FROM lost_items_view  WHERE date BETWEEN $1 AND $2;
$_$;


--
-- Name: get_meal_item_id(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_meal_item_id(integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $_$
    SELECT item_id FROM meals WHERE id = $1;
$_$;


--
-- Name: get_office_expenses_sum_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_office_expenses_sum_between(date, date) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(price) FROM expenses WHERE bought_at::date BETWEEN $1 AND $2 AND expense_owner = 'office';
$_$;


--
-- Name: get_orders_sum_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_orders_sum_between(date, date) RETURNS SETOF orders_sum
    LANGUAGE sql STABLE
    AS $_$
  SELECT
    SUM(price) AS total_price,
    SUM(delivery_price) as total_delivery,
    (SUM(original_price) - SUM(discount_price)) as total_discounts
      FROM orders_view
        WHERE deliver_at::date BETWEEN $1 AND $2
        AND cancelled = false
        AND state != 'basket';
$_$;


--
-- Name: get_restaurant_bought_ingredients_cost_bewteen(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_restaurant_bought_ingredients_cost_bewteen(date, date) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(amount*ingredient_price) FROM ingredients_log WHERE day BETWEEN $1 AND $2 AND entry_owner = 'restaurant' AND amount > 0;
$_$;


--
-- Name: get_restaurant_cooking_ingredients_cost_bewteen(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_restaurant_cooking_ingredients_cost_bewteen(date, date) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(@amount_with_consumption*ingredient_price) FROM ingredients_log_view WHERE day BETWEEN $1 AND $2 AND entry_owner = 'restaurant';
$_$;


--
-- Name: get_restaurant_expenses_sum_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_restaurant_expenses_sum_between(date, date) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(price) FROM expenses WHERE bought_at::date BETWEEN $1 AND $2 AND expense_owner = 'restaurant';
$_$;


--
-- Name: get_restaurant_sales_sum_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_restaurant_sales_sum_between(date, date) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(@amount*price) FROM restaurant_sales WHERE sold_at::date BETWEEN $1 AND $2;
$_$;


--
-- Name: get_restaurant_sold_items_sum_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_restaurant_sold_items_sum_between(date, date) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(@amount*price) FROM sold_items_view  WHERE date BETWEEN $1 AND $2 AND user_id = (SELECT id FROM users WHERE login = 'zelena_kuchyne');
$_$;


--
-- Name: get_shopping_list_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_shopping_list_between(date, date) RETURNS SETOF shopping_list_between
    LANGUAGE sql STABLE
    AS $_$
   SELECT
     @sum(amount) AS amount,
     @SUM(amount_with_consumption) AS amount_with_consumption,
     ingredient_id,
     name,
     code,
     unit,
     AVG(cost_per_unit) AS cost_per_unit,
     @sum(total_cost) AS total_cost,
     @sum(total_cost_with_consumption) AS total_cost_with_consumption,
     supply_flag,
     supplier_short,
     supplier
       FROM ingredients_per_day_view
         WHERE day BETWEEN $1 AND $2
         GROUP BY ingredient_id, name, code, unit, supply_flag, supplier_short, supplier;
 $_$;


--
-- Name: get_summary_between(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_summary_between(date, date) RETURNS summary
    LANGUAGE sql STABLE
    AS $_$
  SELECT * FROM get_orders_sum_between($1, $2)
  LEFT JOIN get_delivery_bought_ingredients_cost_between($1, $2) ON true
  LEFT JOIN get_restaurant_bought_ingredients_cost_bewteen($1, $2) ON true
  LEFT JOIN get_restaurant_cooking_ingredients_cost_bewteen($1, $2) ON true
  LEFT JOIN get_delivery_cooking_ingredients_cost_bewteen($1, $2) ON true
  LEFT JOIN get_delivery_sold_items_sum_between($1, $2) ON true
  LEFT JOIN get_restaurant_sold_items_sum_between($1, $2) ON true
  LEFT JOIN get_fuel_sum_between($1, $2) ON true
  LEFT JOIN get_delivery_expenses_sum_between($1, $2) ON true
  LEFT JOIN get_office_expenses_sum_between($1, $2) ON true
  LEFT JOIN get_restaurant_expenses_sum_between($1, $2) ON true
  LEFT JOIN get_restaurant_sales_sum_between($1, $2) ON true
$_$;


--
-- Name: gin_extract_trgm(text, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gin_extract_trgm(text, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gin_extract_trgm';


--
-- Name: gin_extract_trgm(text, internal, smallint, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gin_extract_trgm(text, internal, smallint, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gin_extract_trgm';


--
-- Name: gin_trgm_consistent(internal, smallint, text, integer, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gin_trgm_consistent(internal, smallint, text, integer, internal, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gin_trgm_consistent';


--
-- Name: gtrgm_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_compress';


--
-- Name: gtrgm_consistent(internal, text, integer, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_consistent(internal, text, integer, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_consistent';


--
-- Name: gtrgm_decompress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_decompress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_decompress';


--
-- Name: gtrgm_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_penalty';


--
-- Name: gtrgm_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_picksplit';


--
-- Name: gtrgm_same(gtrgm, gtrgm, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_same(gtrgm, gtrgm, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_same';


--
-- Name: gtrgm_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_union(bytea, internal) RETURNS integer[]
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_union';


--
-- Name: hex_to_int(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION hex_to_int(character varying) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $_$
  DECLARE
    h alias for $1;
    exec varchar;
    curs refcursor;
    res int;
  BEGIN
    exec := 'SELECT x''' || h || '''::int4';
    OPEN curs FOR EXECUTE exec;
    FETCH curs INTO res;
    CLOSE curs;
    return res;
  END;$_$;


--
-- Name: ingredient_cost(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION ingredient_cost(integer) RETURNS double precision
    LANGUAGE sql
    AS $_$ SELECT cost FROM ingredients WHERE id = $1 $_$;


--
-- Name: ingredients_log_watchdog_balance(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION ingredients_log_watchdog_balance(date) RETURNS SETOF watchdog_balance
    LANGUAGE sql STABLE
    AS $_$
  SELECT SUM(amount) AS balance, ingredient_id FROM ingredients_log_full_view  WHERE day <= $1 GROUP BY ingredient_id;
$_$;


--
-- Name: ingredients_log_watchdogs_view_for_day(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION ingredients_log_watchdogs_view_for_day(date) RETURNS SETOF ingredients_log_watchdog_state
    LANGUAGE sql STABLE
    AS $_$
 SELECT 
   ingredients_log_watchdogs.id, ingredients_log_watchdogs.ingredient_id, ingredients_log_watchdogs.operator, ingredients_log_watchdogs.value, 
   CASE
     WHEN operator = 100::bit(3)  THEN value <  COALESCE(balance,0)
     WHEN operator = 110::bit(3)  THEN value >= COALESCE(balance,0)
     WHEN operator = 010::bit(3)  THEN value =  COALESCE(balance,0)
     WHEN operator = 011::bit(3)  THEN value <= COALESCE(balance,0)
     WHEN operator = 001::bit(3)  THEN value <  COALESCE(balance,0)
     WHEN operator = 000::bit(3)  THEN value != COALESCE(balance,0)
   END AS state,
   balance AS balance
 FROM ingredients_log_watchdogs
 LEFT JOIN ingredients_log_watchdog_balance($1) b ON b.ingredient_id = ingredients_log_watchdogs.ingredient_id;
 $_$;


--
-- Name: item_cost(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION item_cost(integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
  DECLARE
  v_item_type item_type;
  BEGIN
    SELECT item_type INTO v_item_type FROM items WHERE item_id = $1;
    IF v_item_type = 'meal' THEN
        RETURN (SELECT cost FROM meals_view WHERE item_id = $1);
    ELSIF v_item_type = 'menu' THEN
        RETURN (SELECT cost FROM menus_view WHERE item_id = $1);
    ELSIF v_item_type = 'bundle' THEN
        RETURN (SELECT cost FROM bundles_view WHERE item_id = $1);
    ELSIF v_item_type = 'product' THEN
        RETURN (SELECT cost FROM products WHERE item_id = $1);
    END IF;
  END;
$_$;


--
-- Name: item_price(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION item_price(integer) RETURNS double precision
    LANGUAGE sql
    AS $_$ SELECT price FROM items WHERE item_id = $1 $_$;


--
-- Name: levenshtein(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION levenshtein(text, text) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'levenshtein';


--
-- Name: levenshtein(text, text, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION levenshtein(text, text, integer, integer, integer) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'levenshtein_with_costs';


--
-- Name: make_concat_ws(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION make_concat_ws() RETURNS text
    LANGUAGE plpgsql
    AS $_$
declare
  v_args int := 32;
  v_first text := 'CREATE FUNCTION CONCAT_WS(text,text,text) RETURNS text AS ''SELECT CASE WHEN $1 IS NULL THEN NULL WHEN $3 IS NULL THEN $2 ELSE $2 || $1 || $3 END'' LANGUAGE sql IMMUTABLE';
  v_part1 text := 'CREATE FUNCTION CONCAT_WS(text,text';
  v_part2 text := ') RETURNS text AS ''SELECT CONCAT_WS($1,CONCAT_WS($1,$2';
  v_part3 text := ')'' LANGUAGE sql IMMUTABLE';  
  v_sql text;
  
BEGIN
  EXECUTE v_first;
  FOR i IN 4 .. v_args loop
    v_sql := v_part1;
    FOR j IN 3 .. i loop
      v_sql := v_sql || ',text';
    END loop;

    v_sql := v_sql || v_part2;

    FOR j IN 3 .. i - 1 loop
      v_sql := v_sql || ',$' || j::text;
    END loop;
    v_sql := v_sql || '),$' || i::text;

    v_sql := v_sql || v_part3;
    EXECUTE v_sql;
  END loop;
  RETURN 'OK';
END;
$_$;


--
-- Name: meal_price(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION meal_price(integer) RETURNS double precision
    LANGUAGE sql
    AS $_$ SELECT price FROM meals WHERE id = $1 $_$;


--
-- Name: metaphone(text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION metaphone(text, integer) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'metaphone';


--
-- Name: no_guest_orders(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION no_guest_orders() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF NEW.state = 'basket' THEN
      RETURN NEW;
    END IF;
    PERFORM id FROM users WHERE guest = true AND id = NEW.user_id;
    IF FOUND THEN
      RAISE EXCEPTION 'Guests cannot have orders other than basket.';
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: product_cost(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION product_cost(integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
  BEGIN
    RETURN (SELECT cost FROM products WHERE id = $1);
  END;
$_$;


--
-- Name: set_limit(real); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION set_limit(real) RETURNS real
    LANGUAGE c STRICT
    AS '$libdir/pg_trgm', 'set_limit';


--
-- Name: show_limit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION show_limit() RETURNS real
    LANGUAGE c STABLE STRICT
    AS '$libdir/pg_trgm', 'show_limit';


--
-- Name: show_trgm(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION show_trgm(text) RETURNS text[]
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'show_trgm';


--
-- Name: similarity(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION similarity(text, text) RETURNS real
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'similarity';


--
-- Name: similarity_op(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION similarity_op(text, text) RETURNS boolean
    LANGUAGE c STABLE STRICT
    AS '$libdir/pg_trgm', 'similarity_op';


--
-- Name: soundex(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION soundex(text) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'soundex';


--
-- Name: text_soundex(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION text_soundex(text) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'soundex';


--
-- Name: total_assigned_ordered_meals_for(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION total_assigned_ordered_meals_for(date) RETURNS SETOF assigned_meals
    LANGUAGE sql STABLE
    AS $_$
  SELECT 
    COALESCE(assigned_trunk_sold.delivery_man_id, lost_items.user_id) AS delivery_man_id,
    COALESCE(assigned_trunk_sold.item_id, lost_items.item_id) AS item_id,
    COALESCE(assigned_amount,0) AS assigned_amount,
    COALESCE(sold_amount,0) AS sold_amount,
    COALESCE(trunk_amount,0) AS trunk_amount,
    COALESCE(lost_items.amount,0) as lost_amount,
    (COALESCE(assigned_amount,0) + COALESCE(sold_amount,0) + COALESCE(trunk_amount,0) + COALESCE(lost_items.amount,0)) AS amount
  FROM (
    SELECT 
      COALESCE(assigned_trunk.delivery_man_id, sold_items.user_id) AS delivery_man_id,
      COALESCE(assigned_trunk.item_id, sold_items.item_id) AS item_id,
      COALESCE(assigned_amount,0) AS assigned_amount,
      COALESCE(sold_items.amount,0) as sold_amount,
      COALESCE(trunk_amount,0) as trunk_amount
    FROM (
      SELECT 
        COALESCE(assigned_meals.delivery_man_id, items_in_trunk.delivery_man_id) AS delivery_man_id,
        COALESCE(assigned_meals.item_id, items_in_trunk.item_id) AS item_id,
        COALESCE(assigned_meals.amount,0) AS assigned_amount,
        COALESCE(items_in_trunk.amount,0) AS trunk_amount
        FROM (
          SELECT delivery_man_id, item_id, amount
  	  FROM assigned_ordered_meals
  	  WHERE date = $1
        ) AS assigned_meals
        FULL JOIN (SELECT delivery_man_id, item_id, SUM(amount) AS amount FROM items_in_trunk WHERE deliver_at::date = $1 GROUP BY delivery_man_id, item_id) AS items_in_trunk ON assigned_meals.delivery_man_id = items_in_trunk.delivery_man_id AND assigned_meals.item_id = items_in_trunk.item_id
    ) AS assigned_trunk
    FULL JOIN (SELECT user_id, item_id, SUM(amount) AS amount FROM sold_items WHERE sold_at::date = $1 GROUP BY user_id, item_id) AS sold_items ON assigned_trunk.item_id = sold_items.item_id AND assigned_trunk.delivery_man_id = sold_items.user_id
  ) AS assigned_trunk_sold
  FULL JOIN (SELECT user_id, item_id, SUM(amount) AS amount FROM lost_items WHERE lost_at::date = $1 GROUP BY user_id, item_id) AS lost_items ON assigned_trunk_sold.item_id = lost_items.item_id AND assigned_trunk_sold.delivery_man_id = lost_items.user_id;
$_$;


--
-- Name: unix_timestamp(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION unix_timestamp(timestamp without time zone) RETURNS bigint
    LANGUAGE sql
    AS $_$
  SELECT EXTRACT(EPOCH FROM $1)::bigint
$_$;


--
-- Name: update_ingredients_log_from_meals_entry(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_ingredients_log_from_meals_entry() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    v_recipe RECORD;
  BEGIN
    IF NEW.amount <> OLD.amount THEN
      FOR v_recipe IN SELECT * FROM recipes WHERE meal_id = NEW.meal_id LOOP
        UPDATE ingredients_log_from_meals SET amount = -v_recipe.amount * NEW.amount WHERE scheduled_meal_id = NEW.oid AND ingredient_id = v_recipe.ingredient_id;
      END LOOP;
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: update_ingredients_log_from_menus_entry(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_ingredients_log_from_menus_entry() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    v_recipe RECORD;
    v_course RECORD;
  BEGIN
    IF NEW.amount <> OLD.amount THEN
      FOR v_course IN SELECT * FROM courses WHERE menu_id = NEW.menu_id LOOP
        FOR v_recipe IN SELECT * FROM recipes WHERE meal_id = v_course.meal_id LOOP
          UPDATE ingredients_log_from_menus SET amount = -v_recipe.amount * NEW.amount WHERE v_course.meal_id = meal_id AND scheduled_menu_id = NEW.oid AND ingredient_id = v_recipe.ingredient_id;
        END LOOP;
      END LOOP;
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: validate_delete_item_discount(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION validate_delete_item_discount() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    PERFORM id FROM ordered_items LEFT JOIN orders ON orders.id = order_id WHERE item_id = OLD.item_id AND cancelled = false AND deliver_at BETWEEN OLD.start_at AND OLD.expire_at;
    IF FOUND THEN
      UPDATE item_discounts SET expire_at = (SELECT MAX(deliver_at) FROM ordered_items LEFT JOIN orders ON orders.id = order_id WHERE item_id = OLD.item_id AND cancelled = false AND deliver_at <= OLD.expire_at ) WHERE id=OLD.id;
      RETURN NULL;
    END IF;
    RETURN OLD;
  END;
$$;


--
-- Name: validate_delete_user_discount(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION validate_delete_user_discount() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF OLD.expire_at IS NOT NULL THEN
      PERFORM id FROM orders WHERE user_id = OLD.user_id AND cancelled = false AND deliver_at BETWEEN OLD.start_at AND OLD.expire_at;
      IF FOUND THEN
        UPDATE user_discounts SET expire_at = (SELECT MAX(deliver_at) FROM orders WHERE user_id = OLD.user_id AND cancelled = false AND deliver_at <= OLD.expire_at) WHERE id=OLD.id;
        RETURN NULL;
      END IF;
    ELSE
      PERFORM id FROM orders WHERE user_id = OLD.user_id AND cancelled = false AND deliver_at > OLD.start_at;
      IF FOUND THEN
        UPDATE user_discounts SET expire_at = (SELECT MAX(deliver_at) FROM orders WHERE user_id = OLD.user_id AND cancelled = false ) WHERE id=OLD.id;
        RETURN NULL;
      END IF;
    END IF;

    RETURN OLD;
  END;
$$;


--
-- Name: validate_insert_user_discount(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION validate_insert_user_discount() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
   v_discount_id integer;
  BEGIN
    SELECT id INTO v_discount_id FROM user_discounts WHERE COALESCE(expire_at,NEW.start_at) >= NEW.start_at AND user_id = NEW.user_id AND NEW.discount_class = discount_class;
    IF COUNT(v_discount_id) > 0 THEN
      RAISE EXCEPTION ' One user cannot have two active discounts. Please turn off discount with ID #%. ', v_discount_id;
    END IF;
    RETURN NEW;
  END;
$$;


--
-- Name: group_concat(text); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE group_concat(text) (
    SFUNC = _group_concat,
    STYPE = text
);


--
-- Name: list(character varying); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE list(character varying) (
    SFUNC = add_to_sentence,
    STYPE = character varying
);


--
-- Name: %; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR % (
    PROCEDURE = similarity_op,
    LEFTARG = text,
    RIGHTARG = text,
    COMMUTATOR = %,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


--
-- Name: gin_trgm_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gin_trgm_ops
    FOR TYPE text USING gin AS
    STORAGE integer ,
    OPERATOR 1 %(text,text) ,
    FUNCTION 1 btint4cmp(integer,integer) ,
    FUNCTION 2 gin_extract_trgm(text,internal) ,
    FUNCTION 3 gin_extract_trgm(text,internal,smallint,internal,internal) ,
    FUNCTION 4 gin_trgm_consistent(internal,smallint,text,integer,internal,internal);


--
-- Name: gist_trgm_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_trgm_ops
    FOR TYPE text USING gist AS
    STORAGE gtrgm ,
    OPERATOR 1 %(text,text) ,
    FUNCTION 1 gtrgm_consistent(internal,text,integer,oid,internal) ,
    FUNCTION 2 gtrgm_union(bytea,internal) ,
    FUNCTION 3 gtrgm_compress(internal) ,
    FUNCTION 4 gtrgm_decompress(internal) ,
    FUNCTION 5 gtrgm_penalty(internal,internal,internal) ,
    FUNCTION 6 gtrgm_picksplit(internal,internal) ,
    FUNCTION 7 gtrgm_same(gtrgm,gtrgm,internal);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE addresses (
    id integer NOT NULL,
    user_id integer NOT NULL,
    address_type character varying(8) DEFAULT 'home'::character varying NOT NULL,
    country_code character varying(3) DEFAULT 'CZE'::character varying NOT NULL,
    city character varying(70) NOT NULL,
    house_no character varying(15) NOT NULL,
    district character varying(70) NOT NULL,
    street character varying(70) NOT NULL,
    zip character varying(30) NOT NULL,
    note character varying(100),
    first_name character varying(100),
    family_name character varying(100),
    company_name character varying(100),
    zone_id integer,
    zone_reviewed boolean DEFAULT false,
    CONSTRAINT addresses_address_type_check CHECK (((address_type)::text = ANY ((ARRAY['home'::character varying, 'delivery'::character varying, 'billing'::character varying])::text[])))
);


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE addresses_id_seq OWNED BY addresses.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE items (
    item_id integer NOT NULL,
    price double precision NOT NULL,
    name character varying(100) NOT NULL,
    item_type item_type NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    updated_by integer,
    image_flag boolean DEFAULT false NOT NULL,
    CONSTRAINT items_name_check CHECK ((length((name)::text) > 1))
);


--
-- Name: items_item_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE items_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: items_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE items_item_id_seq OWNED BY items.item_id;


--
-- Name: bundles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bundles (
    item_type item_type DEFAULT 'bundle'::item_type,
    id integer NOT NULL,
    meal_id integer NOT NULL,
    amount integer DEFAULT 0 NOT NULL
)
INHERITS (items);


--
-- Name: courses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE courses (
    id integer NOT NULL,
    meal_id integer NOT NULL,
    menu_id integer NOT NULL
);


--
-- Name: meals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE meals (
    item_type item_type DEFAULT 'meal'::item_type,
    id integer NOT NULL,
    meal_category_id integer NOT NULL,
    always_available boolean DEFAULT false NOT NULL,
    restaurant_flag boolean DEFAULT false NOT NULL
)
INHERITS (items);


--
-- Name: menus; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE menus (
    item_type item_type DEFAULT 'menu'::item_type,
    id integer NOT NULL
)
INHERITS (items);


--
-- Name: ordered_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ordered_items (
    oid integer NOT NULL,
    item_id integer NOT NULL,
    order_id integer NOT NULL,
    amount integer NOT NULL,
    price double precision NOT NULL,
    CONSTRAINT ordered_items_amount_check CHECK ((amount > 0))
);


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE orders (
    id integer NOT NULL,
    user_id integer NOT NULL,
    delivery_man_id integer,
    delivery_method_id integer,
    state order_state DEFAULT 'basket'::order_state NOT NULL,
    paid boolean DEFAULT false NOT NULL,
    cancelled boolean DEFAULT false NOT NULL,
    notice text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    deliver_at timestamp without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    login character varying(50),
    password_hash character varying(255),
    salt character varying(255),
    guest boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    email character varying(50),
    imported_orders_price double precision DEFAULT 0 NOT NULL,
    CONSTRAINT users_email_check CHECK ((length((email)::text) > 4)),
    CONSTRAINT users_login_check CHECK ((length((login)::text) > 1))
);


--
-- Name: assigned_ordered_meals; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW assigned_ordered_meals AS
    SELECT users.id AS delivery_man_id, COALESCE(meals.item_id, bundles.item_id) AS item_id, sum(ordered_items.amount) AS amount, (orders.deliver_at)::date AS date FROM ((((((users LEFT JOIN orders ON ((orders.delivery_man_id = users.id))) LEFT JOIN ordered_items ON ((orders.id = ordered_items.order_id))) LEFT JOIN menus ON ((menus.item_id = ordered_items.item_id))) LEFT JOIN courses ON ((menus.id = courses.menu_id))) LEFT JOIN meals ON (((courses.meal_id = meals.id) OR (ordered_items.item_id = meals.item_id)))) LEFT JOIN bundles ON ((bundles.item_id = ordered_items.item_id))) WHERE ((orders.cancelled = false) AND (orders.state <> 'basket'::order_state)) GROUP BY users.id, users.login, COALESCE(meals.item_id, bundles.item_id), meals.id, meals.item_id, (orders.deliver_at)::date ORDER BY (orders.deliver_at)::date, users.id;


--
-- Name: bundles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bundles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bundles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bundles_id_seq OWNED BY bundles.id;


--
-- Name: ingredients; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ingredients (
    id integer NOT NULL,
    supplier_id integer,
    unit character varying(25) NOT NULL,
    name character varying(50) NOT NULL,
    code character varying(50) DEFAULT ''::character varying NOT NULL,
    supply_flag boolean DEFAULT false NOT NULL,
    cost double precision NOT NULL,
    CONSTRAINT ingredients_name_check CHECK ((length((name)::text) > 1)),
    CONSTRAINT ingredients_unit_check CHECK ((length((unit)::text) > 0))
);


--
-- Name: recipes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE recipes (
    id integer NOT NULL,
    amount double precision NOT NULL,
    ingredient_id integer NOT NULL,
    meal_id integer NOT NULL,
    CONSTRAINT recipes_amount_check CHECK ((amount > (0)::double precision))
);


--
-- Name: meals_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW meals_view AS
    SELECT meals.item_id, meals.price, meals.name, meals.item_type, meals.created_at, meals.updated_at, meals.updated_by, meals.image_flag, meals.id, meals.meal_category_id, meals.always_available, meals.restaurant_flag, COALESCE(sum((ingredients.cost * recipes.amount)), (0)::double precision) AS cost FROM ((meals LEFT JOIN recipes ON ((recipes.meal_id = meals.id))) LEFT JOIN ingredients ON ((recipes.ingredient_id = ingredients.id))) GROUP BY meals.id, meals.price, meals.name, meals.meal_category_id, meals.created_at, meals.updated_at, meals.item_id, meals.always_available, meals.image_flag, meals.updated_by, meals.item_type, meals.restaurant_flag;


--
-- Name: bundles_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW bundles_view AS
    SELECT bundles.item_id, bundles.price, bundles.name, bundles.item_type, bundles.created_at, bundles.updated_at, bundles.updated_by, bundles.image_flag, bundles.id, bundles.meal_id, bundles.amount, COALESCE(sum((meals_view.cost * (bundles.amount)::double precision)), (0)::double precision) AS cost FROM (bundles LEFT JOIN meals_view ON ((bundles.meal_id = meals_view.id))) GROUP BY bundles.item_id, bundles.price, bundles.name, bundles.created_at, bundles.updated_at, bundles.updated_by, bundles.image_flag, bundles.id, bundles.meal_id, bundles.amount, bundles.item_type;


--
-- Name: cars; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cars (
    id integer NOT NULL,
    registration_no character varying(10) NOT NULL,
    fuel_consumption double precision NOT NULL,
    note character varying(50) DEFAULT ''::character varying NOT NULL
);


--
-- Name: cars_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cars_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cars_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cars_id_seq OWNED BY cars.id;


--
-- Name: cars_logbooks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cars_logbooks (
    id integer NOT NULL,
    car_id integer NOT NULL,
    user_id integer NOT NULL,
    date date NOT NULL,
    beginning integer NOT NULL,
    ending integer NOT NULL,
    business_distance integer DEFAULT 0 NOT NULL,
    private_distance integer DEFAULT 0 NOT NULL,
    logbook_category_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by integer,
    CONSTRAINT cars_logbooks_business_distance_check CHECK ((business_distance >= 0)),
    CONSTRAINT cars_logbooks_check CHECK (((business_distance = 0) OR ((business_distance > 0) AND (logbook_category_id IS NOT NULL)))),
    CONSTRAINT cars_logbooks_private_distance_check CHECK ((private_distance >= 0)),
    CONSTRAINT valid_distance CHECK (((private_distance + business_distance) = (ending - beginning)))
);


--
-- Name: cars_logbooks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cars_logbooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cars_logbooks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cars_logbooks_id_seq OWNED BY cars_logbooks.id;


--
-- Name: categorized_products; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE categorized_products (
    oid integer NOT NULL,
    product_id integer NOT NULL,
    product_category_id integer NOT NULL
);


--
-- Name: categorized_products_oid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE categorized_products_oid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categorized_products_oid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE categorized_products_oid_seq OWNED BY categorized_products.oid;


--
-- Name: configuration; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE configuration (
    key character varying(20) NOT NULL,
    value character varying(50)
);


--
-- Name: country_codes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE country_codes (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    code integer NOT NULL
);


--
-- Name: country_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE country_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: country_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE country_codes_id_seq OWNED BY country_codes.id;


--
-- Name: courses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE courses_id_seq OWNED BY courses.id;


--
-- Name: lost_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lost_items (
    oid integer NOT NULL,
    item_id integer NOT NULL,
    user_id integer NOT NULL,
    amount integer DEFAULT 0 NOT NULL,
    cost double precision NOT NULL,
    lost_at timestamp without time zone NOT NULL
);


--
-- Name: scheduled_meals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE scheduled_meals (
    oid integer NOT NULL,
    meal_id integer NOT NULL,
    scheduled_for date NOT NULL,
    amount integer NOT NULL,
    invisible boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT scheduled_meals_amount_check CHECK ((amount > 0))
);


--
-- Name: scheduled_menus; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE scheduled_menus (
    oid integer NOT NULL,
    menu_id integer NOT NULL,
    scheduled_for date NOT NULL,
    amount integer NOT NULL,
    invisible boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT scheduled_menus_amount_check CHECK ((amount > 0))
);


--
-- Name: days_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW days_view AS
    SELECT DISTINCT (COALESCE((scheduled_for)::timestamp without time zone, lost_items.lost_at))::date AS scheduled_for FROM ((scheduled_meals NATURAL FULL JOIN scheduled_menus) NATURAL FULL JOIN lost_items) WHERE (COALESCE(invisible, false) = false) ORDER BY (COALESCE((scheduled_for)::timestamp without time zone, lost_items.lost_at))::date;


--
-- Name: menus_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW menus_view AS
    SELECT menus.item_id, menus.price, menus.name, menus.item_type, menus.created_at, menus.updated_at, menus.updated_by, menus.image_flag, menus.id, sum(meals_view.price) AS meals_price, COALESCE(sum(meals_view.cost), (0)::double precision) AS cost FROM ((menus LEFT JOIN courses ON ((courses.menu_id = menus.id))) LEFT JOIN meals_view ON ((courses.meal_id = meals_view.id))) GROUP BY menus.id, menus.item_id, menus.price, menus.name, menus.created_at, menus.updated_at, menus.image_flag, menus.updated_by, menus.item_type;


--
-- Name: days_cost_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW days_cost_view AS
    SELECT days_view.scheduled_for, (sum(((COALESCE(scheduled_meals.amount, 0))::double precision * COALESCE(meals_view.cost, (0)::double precision))) + sum(((COALESCE(scheduled_menus.amount, 0))::double precision * COALESCE(menus_view.cost, (0)::double precision)))) AS cost FROM ((((days_view LEFT JOIN scheduled_meals ON ((scheduled_meals.scheduled_for = days_view.scheduled_for))) LEFT JOIN meals_view ON ((scheduled_meals.meal_id = meals_view.id))) LEFT JOIN scheduled_menus ON ((scheduled_menus.scheduled_for = days_view.scheduled_for))) LEFT JOIN menus_view ON ((scheduled_menus.menu_id = menus_view.id))) GROUP BY days_view.scheduled_for;


--
-- Name: delivery_items_basic_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW delivery_items_basic_view AS
    SELECT ordered_items.item_id, sum(ordered_items.amount) AS amount, orders.delivery_man_id, (orders.deliver_at)::date AS scheduled_for FROM (ordered_items LEFT JOIN orders ON ((orders.id = ordered_items.order_id))) WHERE ((orders.delivery_man_id IS NOT NULL) AND (orders.state = ANY (ARRAY['order'::order_state, 'expedited'::order_state]))) GROUP BY ordered_items.item_id, orders.delivery_man_id, (orders.deliver_at)::date;


--
-- Name: items_in_trunk; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE items_in_trunk (
    oid integer NOT NULL,
    item_id integer NOT NULL,
    delivery_man_id integer NOT NULL,
    amount integer DEFAULT 0 NOT NULL,
    deliver_at date NOT NULL
);


--
-- Name: delivery_items_basic_with_trunk_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW delivery_items_basic_with_trunk_view AS
    SELECT COALESCE(delivery_items_basic_view.item_id, items_in_trunk.item_id) AS item_id, (COALESCE(delivery_items_basic_view.amount, (0)::bigint) + COALESCE(items_in_trunk.amount, 0)) AS amount, COALESCE(delivery_items_basic_view.amount, (0)::bigint) AS in_orders, COALESCE(items_in_trunk.amount, 0) AS additional, COALESCE(delivery_items_basic_view.delivery_man_id, items_in_trunk.delivery_man_id) AS delivery_man_id, COALESCE(delivery_items_basic_view.scheduled_for, items_in_trunk.deliver_at) AS scheduled_for FROM (delivery_items_basic_view FULL JOIN items_in_trunk ON ((((delivery_items_basic_view.item_id = items_in_trunk.item_id) AND (delivery_items_basic_view.delivery_man_id = items_in_trunk.delivery_man_id)) AND (delivery_items_basic_view.scheduled_for = items_in_trunk.deliver_at))));


--
-- Name: lost_meals_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW lost_meals_view AS
    SELECT lost_items.oid, meals.item_id, lost_items.user_id, (COALESCE(bundles.amount, 1) * lost_items.amount) AS amount, (lost_items.lost_at)::date AS date FROM ((((lost_items LEFT JOIN bundles ON ((bundles.item_id = lost_items.item_id))) LEFT JOIN menus ON ((lost_items.item_id = menus.item_id))) LEFT JOIN courses ON ((menus.id = courses.menu_id))) LEFT JOIN meals ON ((((bundles.meal_id = meals.id) OR (lost_items.item_id = meals.item_id)) OR (courses.meal_id = meals.id))));


--
-- Name: scheduled_items_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW scheduled_items_view AS
    SELECT scheduled_meals.scheduled_for, sum(scheduled_meals.amount) AS amount, scheduled_meals.item_id, scheduled_meals.name FROM (SELECT scheduled_menus.scheduled_for, scheduled_menus.amount, meals.item_id, meals.name FROM ((scheduled_menus LEFT JOIN courses USING (menu_id)) LEFT JOIN meals ON ((meals.id = courses.meal_id))) GROUP BY scheduled_menus.scheduled_for, scheduled_menus.amount, meals.item_id, meals.name UNION ALL SELECT scheduled_meals.scheduled_for, scheduled_meals.amount, meals.item_id, meals.name FROM (scheduled_meals LEFT JOIN meals ON ((meals.id = scheduled_meals.meal_id))) GROUP BY scheduled_meals.scheduled_for, scheduled_meals.amount, meals.item_id, meals.name) scheduled_meals GROUP BY scheduled_meals.scheduled_for, scheduled_meals.item_id, scheduled_meals.name UNION ALL SELECT scheduled_menus.scheduled_for, scheduled_menus.amount, menus.item_id, menus.name FROM (scheduled_menus LEFT JOIN menus ON ((menus.id = scheduled_menus.menu_id)));


--
-- Name: sold_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sold_items (
    oid integer NOT NULL,
    item_id integer NOT NULL,
    user_id integer NOT NULL,
    amount integer NOT NULL,
    price double precision NOT NULL,
    sold_at timestamp without time zone NOT NULL,
    CONSTRAINT sold_items_amount_check CHECK ((amount > 0))
);


--
-- Name: sold_meals_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW sold_meals_view AS
    SELECT sold_items.oid, meals.item_id, sold_items.user_id, (COALESCE(bundles.amount, 1) * sold_items.amount) AS amount, (sold_items.sold_at)::date AS date FROM ((((sold_items LEFT JOIN bundles ON ((bundles.item_id = sold_items.item_id))) LEFT JOIN menus ON ((sold_items.item_id = menus.item_id))) LEFT JOIN courses ON ((menus.id = courses.menu_id))) LEFT JOIN meals ON ((((bundles.meal_id = meals.id) OR (sold_items.item_id = meals.item_id)) OR (courses.meal_id = meals.id))));


--
-- Name: total_ordered_meals_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW total_ordered_meals_view AS
    SELECT (orders.deliver_at)::date AS deliver_on, meals.id AS meal_id, meals.item_id, meals.name, sum((ordered_items.amount * COALESCE(bundles.amount, 1))) AS amount FROM (((((ordered_items LEFT JOIN orders ON ((orders.id = ordered_items.order_id))) LEFT JOIN menus ON ((ordered_items.item_id = menus.item_id))) LEFT JOIN courses ON ((menus.id = courses.menu_id))) LEFT JOIN bundles ON ((ordered_items.item_id = bundles.item_id))) LEFT JOIN meals ON ((((courses.meal_id = meals.id) OR (meals.item_id = ordered_items.item_id)) OR (bundles.meal_id = meals.id)))) WHERE ((orders.cancelled = false) AND (orders.state <> 'basket'::order_state)) GROUP BY (orders.deliver_at)::date, meals.name, meals.item_id, meals.id;


--
-- Name: total_scheduled_meals_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW total_scheduled_meals_view AS
    SELECT scheduled_for, meals.id AS meal_id, meals.item_id, meals.name, sum(amount) AS amount FROM ((((scheduled_meals NATURAL FULL JOIN scheduled_menus) LEFT JOIN menus ON ((scheduled_menus.menu_id = menus.id))) LEFT JOIN courses ON ((courses.menu_id = menus.id))) LEFT JOIN meals ON (((courses.meal_id = meals.id) OR (scheduled_meals.meal_id = meals.id)))) GROUP BY scheduled_for, meals.id, meals.item_id, meals.name;


--
-- Name: scheduled_meals_left_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW scheduled_meals_left_view AS
    SELECT scheduled.meal_id, scheduled.item_id, scheduled.name, COALESCE(ordered.amount, (0)::bigint) AS ordered_amount, scheduled.amount AS scheduled_amount, (((scheduled.amount - COALESCE(ordered.amount, (0)::bigint)) - COALESCE(lost.amount, (0)::bigint)) - COALESCE(sold.amount, (0)::bigint)) AS amount_left, ((((scheduled.amount - COALESCE(ordered.amount, (0)::bigint)) - COALESCE(lost.amount, (0)::bigint)) - COALESCE(sold.amount, (0)::bigint)) - COALESCE(sum(trunk.amount), (0)::bigint)) AS amount_left_without_trunk, COALESCE(sum(trunk.amount), (0)::bigint) AS in_trunk, COALESCE(lost.amount, (0)::bigint) AS lost_amount, COALESCE(sold.amount, (0)::bigint) AS sold_amount, scheduled.scheduled_for FROM ((((total_scheduled_meals_view scheduled LEFT JOIN total_ordered_meals_view ordered ON (((ordered.deliver_on = scheduled.scheduled_for) AND (ordered.item_id = scheduled.item_id)))) LEFT JOIN items_in_trunk trunk ON (((trunk.item_id = scheduled.item_id) AND (scheduled.scheduled_for = trunk.deliver_at)))) LEFT JOIN (SELECT lost_meals_view.item_id, lost_meals_view.date, sum(lost_meals_view.amount) AS amount FROM lost_meals_view GROUP BY lost_meals_view.item_id, lost_meals_view.date) lost ON (((lost.item_id = scheduled.item_id) AND (scheduled.scheduled_for = lost.date)))) LEFT JOIN (SELECT sold_meals_view.item_id, sold_meals_view.date, sum(sold_meals_view.amount) AS amount FROM sold_meals_view GROUP BY sold_meals_view.item_id, sold_meals_view.date) sold ON (((sold.item_id = scheduled.item_id) AND (scheduled.scheduled_for = sold.date)))) GROUP BY scheduled.meal_id, scheduled.item_id, scheduled.name, scheduled.amount, ordered.amount, scheduled.scheduled_for, lost.amount, lost.date, sold.amount, sold.date;


--
-- Name: delivery_items_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW delivery_items_view AS
    SELECT delivery_items_basic_with_trunk_view.item_id, delivery_items_basic_with_trunk_view.amount, delivery_items_basic_with_trunk_view.in_orders, delivery_items_basic_with_trunk_view.additional, delivery_items_basic_with_trunk_view.delivery_man_id, delivery_items_basic_with_trunk_view.scheduled_for, scheduled_items_view.amount AS scheduled_amount, scheduled_meals_left_view.ordered_amount, scheduled_meals_left_view.amount_left_without_trunk, scheduled_meals_left_view.lost_amount, scheduled_meals_left_view.sold_amount, scheduled_meals_left_view.amount_left, (scheduled_meals_left_view.amount_left IS NOT NULL) AS meal_flag FROM ((delivery_items_basic_with_trunk_view LEFT JOIN scheduled_items_view ON (((delivery_items_basic_with_trunk_view.item_id = scheduled_items_view.item_id) AND (delivery_items_basic_with_trunk_view.scheduled_for = scheduled_items_view.scheduled_for)))) LEFT JOIN scheduled_meals_left_view ON (((delivery_items_basic_with_trunk_view.item_id = scheduled_meals_left_view.item_id) AND (delivery_items_basic_with_trunk_view.scheduled_for = scheduled_meals_left_view.scheduled_for))));


--
-- Name: delivery_methods; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delivery_methods (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    basket_name character varying(70) DEFAULT ''::character varying NOT NULL,
    price double precision NOT NULL,
    minimal_order_price double precision NOT NULL,
    flag_has_delivery_man boolean DEFAULT false NOT NULL,
    zone_id integer NOT NULL
);


--
-- Name: delivery_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delivery_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delivery_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delivery_methods_id_seq OWNED BY delivery_methods.id;


--
-- Name: dialy_menu_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE dialy_menu_entries (
    id integer NOT NULL,
    dialy_menu_id integer NOT NULL,
    category_id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    in_menu boolean DEFAULT false NOT NULL,
    price numeric NOT NULL
);


--
-- Name: dialy_menu_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE dialy_menu_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dialy_menu_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE dialy_menu_entries_id_seq OWNED BY dialy_menu_entries.id;


--
-- Name: dialy_menus; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE dialy_menus (
    id integer NOT NULL,
    date date NOT NULL,
    menu_price numeric
);


--
-- Name: dialy_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE dialy_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dialy_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE dialy_menus_id_seq OWNED BY dialy_menus.id;


--
-- Name: expense_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE expense_categories (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    description character varying(105) DEFAULT ''::character varying NOT NULL,
    CONSTRAINT expense_categories_name_check CHECK ((length((name)::text) > 1))
);


--
-- Name: expenses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE expenses (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    price double precision NOT NULL,
    user_id integer NOT NULL,
    bought_at timestamp without time zone NOT NULL,
    expense_category_id integer NOT NULL,
    expense_owner expense_owner NOT NULL,
    premise_id integer,
    note character varying(100),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by integer,
    CONSTRAINT expenses_check CHECK ((((expense_owner <> 'restaurant'::expense_owner) AND (premise_id IS NULL)) OR (expense_owner = 'restaurant'::expense_owner))),
    CONSTRAINT expenses_check1 CHECK ((((expense_owner = 'restaurant'::expense_owner) AND (premise_id IS NOT NULL)) OR (expense_owner <> 'restaurant'::expense_owner)))
);


--
-- Name: expense_categories_by_day_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW expense_categories_by_day_view AS
    SELECT expense_categories.id, expense_categories.name, expense_categories.description, expenses.expense_owner, sum(expenses.price) AS cost, (expenses.bought_at)::date AS date FROM (expense_categories LEFT JOIN expenses ON ((expenses.expense_category_id = expense_categories.id))) GROUP BY expense_categories.id, expense_categories.name, expense_categories.description, expenses.expense_owner, (expenses.bought_at)::date;


--
-- Name: expense_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE expense_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: expense_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE expense_categories_id_seq OWNED BY expense_categories.id;


--
-- Name: expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE expenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE expenses_id_seq OWNED BY expenses.id;


--
-- Name: flagged_meals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE flagged_meals (
    oid integer NOT NULL,
    meal_id integer NOT NULL,
    meal_flag_id integer NOT NULL
);


--
-- Name: flagged_meals_oid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flagged_meals_oid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flagged_meals_oid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flagged_meals_oid_seq OWNED BY flagged_meals.oid;


--
-- Name: fuel; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE fuel (
    id integer NOT NULL,
    user_id integer NOT NULL,
    car_id integer NOT NULL,
    cost double precision NOT NULL,
    amount double precision NOT NULL,
    note character varying(100) DEFAULT ''::character varying NOT NULL,
    date timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by integer
);


--
-- Name: fuel_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE fuel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fuel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE fuel_id_seq OWNED BY fuel.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups (
    id integer NOT NULL,
    title character varying(50) NOT NULL,
    default_group boolean DEFAULT false NOT NULL,
    system_name character varying(50),
    CONSTRAINT groups_system_name_check CHECK ((length((system_name)::text) > 1))
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_id_seq OWNED BY groups.id;


--
-- Name: ingredient_consumptions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ingredient_consumptions (
    id integer NOT NULL,
    ingredient_id integer NOT NULL,
    stocktaking_id integer NOT NULL,
    consumption double precision NOT NULL,
    CONSTRAINT ingredient_consumptions_consumption_check CHECK ((consumption > (0.0)::double precision))
);


--
-- Name: ingredient_consumptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ingredient_consumptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredient_consumptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ingredient_consumptions_id_seq OWNED BY ingredient_consumptions.id;


--
-- Name: ingredients_log; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ingredients_log (
    id integer NOT NULL,
    day date NOT NULL,
    amount double precision NOT NULL,
    ingredient_id integer NOT NULL,
    ingredient_price double precision NOT NULL,
    entry_owner ingredients_log_entry_owner DEFAULT 'delivery'::ingredients_log_entry_owner NOT NULL,
    notes text
);


--
-- Name: ingredients_log_from_meals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ingredients_log_from_meals (
    id integer NOT NULL,
    day date NOT NULL,
    amount double precision NOT NULL,
    ingredient_id integer NOT NULL,
    ingredient_price double precision NOT NULL,
    meal_id integer NOT NULL,
    scheduled_meal_id integer NOT NULL,
    consumption_id integer
);


--
-- Name: ingredients_log_from_menus; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ingredients_log_from_menus (
    id integer NOT NULL,
    day date NOT NULL,
    amount double precision NOT NULL,
    ingredient_id integer NOT NULL,
    ingredient_price double precision NOT NULL,
    meal_id integer NOT NULL,
    scheduled_menu_id integer NOT NULL,
    consumption_id integer
);


--
-- Name: ingredients_log_from_restaurant; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ingredients_log_from_restaurant (
    id integer NOT NULL,
    day date NOT NULL,
    amount double precision NOT NULL,
    ingredient_id integer NOT NULL,
    ingredient_price double precision NOT NULL,
    meal_id integer NOT NULL,
    restaurant_sale_id integer NOT NULL,
    consumption_id integer
);


--
-- Name: ingredients_log_from_stocktakings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ingredients_log_from_stocktakings (
    id integer NOT NULL,
    day date NOT NULL,
    amount double precision NOT NULL,
    ingredient_id integer NOT NULL,
    stocktaking_id integer NOT NULL
);


--
-- Name: ingredients_log_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW ingredients_log_view AS
    SELECT ingredients_log_view.day, sum(ingredients_log_view.amount) AS amount, sum((ingredients_log_view.amount * COALESCE(o.consumption, (1)::double precision))) AS amount_with_consumption, ingredients_log_view.ingredient_id, ingredients_log_view.ingredient_price, ingredients_log_view.meal_id, ingredients_log_view.entry_owner FROM (((SELECT ingredients_log_from_meals.day, ingredients_log_from_meals.amount, ingredients_log_from_meals.ingredient_id, ingredients_log_from_meals.ingredient_price, ingredients_log_from_meals.meal_id, 'delivery'::ingredients_log_entry_owner AS entry_owner, ingredients_log_from_meals.consumption_id FROM ingredients_log_from_meals UNION ALL SELECT ingredients_log_from_menus.day, ingredients_log_from_menus.amount, ingredients_log_from_menus.ingredient_id, ingredients_log_from_menus.ingredient_price, ingredients_log_from_menus.meal_id, 'delivery'::ingredients_log_entry_owner AS ingredients_log_entry_owner, ingredients_log_from_menus.consumption_id FROM ingredients_log_from_menus) UNION ALL SELECT ingredients_log_from_restaurant.day, ingredients_log_from_restaurant.amount, ingredients_log_from_restaurant.ingredient_id, ingredients_log_from_restaurant.ingredient_price, ingredients_log_from_restaurant.meal_id, 'restaurant'::ingredients_log_entry_owner AS ingredients_log_entry_owner, ingredients_log_from_restaurant.consumption_id FROM ingredients_log_from_restaurant) ingredients_log_view LEFT JOIN ingredient_consumptions o ON (((o.id = ingredients_log_view.consumption_id) AND (o.ingredient_id = ingredients_log_view.ingredient_id)))) GROUP BY ingredients_log_view.day, ingredients_log_view.ingredient_id, ingredients_log_view.ingredient_price, ingredients_log_view.meal_id, ingredients_log_view.entry_owner;


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE suppliers (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    name_abbr character varying(10) NOT NULL,
    address text,
    CONSTRAINT suppliers_name_abbr_check CHECK ((length((name_abbr)::text) > 1)),
    CONSTRAINT suppliers_name_check CHECK ((length((name)::text) > 1))
);


--
-- Name: ingredients_per_day_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW ingredients_per_day_view AS
    SELECT ingredients_log_view.day, sum(ingredients_log_view.amount) AS amount, sum(ingredients_log_view.amount_with_consumption) AS amount_with_consumption, ingredients_log_view.ingredient_id, ingredients_log_view.ingredient_price AS cost_per_unit, (@ (sum(ingredients_log_view.amount) * ingredients_log_view.ingredient_price)) AS total_cost, (@ (sum(ingredients_log_view.amount_with_consumption) * ingredients_log_view.ingredient_price)) AS total_cost_with_consumption, ingredients.name, ingredients.code, ingredients.unit, ingredients.supply_flag, suppliers.name_abbr AS supplier_short, suppliers.name AS supplier FROM ((ingredients_log_view LEFT JOIN ingredients ON ((ingredients.id = ingredients_log_view.ingredient_id))) LEFT JOIN suppliers ON ((suppliers.id = ingredients.supplier_id))) GROUP BY ingredients_log_view.day, ingredients_log_view.ingredient_id, ingredients_log_view.ingredient_price, ingredients.name, ingredients.code, ingredients.supply_flag, ingredients.unit, ingredients.cost, suppliers.name, suppliers.name_abbr;


--
-- Name: ingredients_full_log_per_day_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW ingredients_full_log_per_day_view AS
    (SELECT ingredients_log.id, ingredients_log.day, ingredients_log.amount, ingredients_log.ingredient_id, ingredients_log.ingredient_price AS cost, (@ (ingredients_log.amount * ingredients_log.ingredient_price)) AS total_cost, ingredients_log.notes FROM ingredients_log UNION ALL SELECT NULL::unknown AS id, ingredients_log_from_stocktakings.day, ingredients_log_from_stocktakings.amount, ingredients_log_from_stocktakings.ingredient_id, 0 AS cost, 0 AS total_cost, 'inventura' AS notes FROM ingredients_log_from_stocktakings) UNION ALL SELECT NULL::unknown AS id, ingredients_per_day_view.day, ingredients_per_day_view.amount, ingredients_per_day_view.ingredient_id, ingredients_per_day_view.cost_per_unit AS cost, ingredients_per_day_view.total_cost, 'vareni' AS notes FROM ingredients_per_day_view;


--
-- Name: ingredients_full_log_per_meal_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW ingredients_full_log_per_meal_view AS
    SELECT NULL::unknown AS id, ingredients_log_view.day, sum(ingredients_log_view.amount) AS amount, ingredients_log_view.ingredient_id, ingredients_log_view.ingredient_price AS cost, (@ (sum(ingredients_log_view.amount) * ingredients_log_view.ingredient_price)) AS total_cost, ingredients_log_view.meal_id, meals.name AS notes FROM (ingredients_log_view LEFT JOIN meals ON ((ingredients_log_view.meal_id = meals.id))) WHERE (ingredients_log_view.meal_id IS NOT NULL) GROUP BY ingredients_log_view.day, ingredients_log_view.ingredient_id, ingredients_log_view.ingredient_price, ingredients_log_view.meal_id, meals.name;


--
-- Name: ingredients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ingredients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ingredients_id_seq OWNED BY ingredients.id;


--
-- Name: ingredients_log_from_meals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ingredients_log_from_meals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredients_log_from_meals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ingredients_log_from_meals_id_seq OWNED BY ingredients_log_from_meals.id;


--
-- Name: ingredients_log_from_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ingredients_log_from_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredients_log_from_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ingredients_log_from_menus_id_seq OWNED BY ingredients_log_from_menus.id;


--
-- Name: ingredients_log_from_restaurant_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ingredients_log_from_restaurant_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredients_log_from_restaurant_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ingredients_log_from_restaurant_id_seq OWNED BY ingredients_log_from_restaurant.id;


--
-- Name: ingredients_log_from_stocktakings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ingredients_log_from_stocktakings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredients_log_from_stocktakings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ingredients_log_from_stocktakings_id_seq OWNED BY ingredients_log_from_stocktakings.id;


--
-- Name: ingredients_log_full_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW ingredients_log_full_view AS
    (SELECT ingredients_log_view.day, ingredients_log_view.amount, ingredients_log_view.ingredient_id, ingredients_log_view.ingredient_price, ingredients_log_view.entry_owner FROM ingredients_log_view UNION ALL SELECT ingredients_log.day, ingredients_log.amount, ingredients_log.ingredient_id, ingredients_log.ingredient_price, ingredients_log.entry_owner FROM ingredients_log) UNION ALL SELECT ingredients_log_from_stocktakings.day, ingredients_log_from_stocktakings.amount, ingredients_log_from_stocktakings.ingredient_id, 0 AS ingredient_price, NULL::unknown AS entry_owner FROM ingredients_log_from_stocktakings;


--
-- Name: ingredients_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ingredients_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredients_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ingredients_log_id_seq OWNED BY ingredients_log.id;


--
-- Name: ingredients_log_watchdogs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ingredients_log_watchdogs (
    id integer NOT NULL,
    ingredient_id integer NOT NULL,
    operator bit(3) NOT NULL,
    value double precision NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ingredients_log_watchdogs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ingredients_log_watchdogs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredients_log_watchdogs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ingredients_log_watchdogs_id_seq OWNED BY ingredients_log_watchdogs.id;


--
-- Name: ingredients_log_watchdogs_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW ingredients_log_watchdogs_view AS
    SELECT ingredients_log_watchdogs.id, ingredients_log_watchdogs.ingredient_id, ingredients_log_watchdogs.operator, ingredients_log_watchdogs.value, ingredients_log_watchdogs.created_at, ingredients_log_watchdogs.updated_at, CASE WHEN (ingredients_log_watchdogs.operator = (100)::bit(3)) THEN (ingredients_log_watchdogs.value < COALESCE(ingredients_full_log_per_day_view.amount, (0)::double precision)) WHEN (ingredients_log_watchdogs.operator = (110)::bit(3)) THEN (ingredients_log_watchdogs.value >= COALESCE(ingredients_full_log_per_day_view.amount, (0)::double precision)) WHEN (ingredients_log_watchdogs.operator = (10)::bit(3)) THEN (ingredients_log_watchdogs.value = COALESCE(ingredients_full_log_per_day_view.amount, (0)::double precision)) WHEN (ingredients_log_watchdogs.operator = (11)::bit(3)) THEN (ingredients_log_watchdogs.value <= COALESCE(ingredients_full_log_per_day_view.amount, (0)::double precision)) WHEN (ingredients_log_watchdogs.operator = (1)::bit(3)) THEN (ingredients_log_watchdogs.value < COALESCE(ingredients_full_log_per_day_view.amount, (0)::double precision)) WHEN (ingredients_log_watchdogs.operator = (0)::bit(3)) THEN (ingredients_log_watchdogs.value <> COALESCE(ingredients_full_log_per_day_view.amount, (0)::double precision)) ELSE NULL::boolean END AS state, ingredients_full_log_per_day_view.day, ingredients_full_log_per_day_view.amount FROM (ingredients_log_watchdogs LEFT JOIN ingredients_full_log_per_day_view ON ((ingredients_full_log_per_day_view.ingredient_id = ingredients_log_watchdogs.ingredient_id)));


--
-- Name: item_discounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE item_discounts (
    id integer NOT NULL,
    item_id integer NOT NULL,
    amount double precision DEFAULT 0.0 NOT NULL,
    name character varying(50) NOT NULL,
    start_at timestamp without time zone DEFAULT ('now'::text)::date NOT NULL,
    expire_at timestamp without time zone NOT NULL,
    note character varying(50),
    CONSTRAINT item_discounts_amount_check CHECK (((amount >= (0.0)::double precision) AND (amount <= (1.0)::double precision))),
    CONSTRAINT item_discounts_check CHECK ((expire_at >= start_at)),
    CONSTRAINT item_discounts_name_check CHECK ((length((name)::text) > 2)),
    CONSTRAINT item_discounts_start_at_check CHECK ((start_at >= ('now'::text)::date))
);


--
-- Name: item_discounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE item_discounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_discounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE item_discounts_id_seq OWNED BY item_discounts.id;


--
-- Name: item_profile_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE item_profile_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    data_type character varying(50) NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    editable boolean DEFAULT true NOT NULL,
    required boolean DEFAULT false NOT NULL,
    CONSTRAINT item_profile_types_data_type_check CHECK (((data_type)::text = ANY ((ARRAY['text_field'::character varying, 'text_area'::character varying, 'hidden'::character varying, 'checkbox'::character varying])::text[]))),
    CONSTRAINT item_profile_types_name_check CHECK ((length((name)::text) > 1))
);


--
-- Name: item_profile_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE item_profile_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_profile_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE item_profile_types_id_seq OWNED BY item_profile_types.id;


--
-- Name: item_profiles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE item_profiles (
    id integer NOT NULL,
    item_id integer NOT NULL,
    field_type integer NOT NULL,
    field_body text,
    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: item_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE item_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE item_profiles_id_seq OWNED BY item_profiles.id;


--
-- Name: item_tables_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW item_tables_view AS
    SELECT items.item_id, ((items.item_type)::text || 's'::text) AS table_name, CASE WHEN (items.item_type = 'product'::item_type) THEN 'product'::discount_class WHEN (items.item_type = 'meal'::item_type) THEN 'meal'::discount_class WHEN (items.item_type = 'menu'::item_type) THEN 'meal'::discount_class WHEN (items.item_type = 'bundle'::item_type) THEN 'meal'::discount_class ELSE NULL::discount_class END AS discount_class, items.item_type FROM items;


--
-- Name: items_in_trunk_oid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE items_in_trunk_oid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: items_in_trunk_oid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE items_in_trunk_oid_seq OWNED BY items_in_trunk.oid;


--
-- Name: logbook_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE logbook_categories (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    CONSTRAINT logbook_categories_name_check CHECK ((length((name)::text) > 0))
);


--
-- Name: logbook_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE logbook_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logbook_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE logbook_categories_id_seq OWNED BY logbook_categories.id;


--
-- Name: lost_items_oid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lost_items_oid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lost_items_oid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lost_items_oid_seq OWNED BY lost_items.oid;


--
-- Name: lost_items_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW lost_items_view AS
    SELECT COALESCE(meals.item_id, lost_items.item_id) AS item_id, sum((COALESCE(bundles.amount, 1) * lost_items.amount)) AS amount, lost_items.cost, sum((((COALESCE(bundles.amount, 1))::double precision * lost_items.cost) * (lost_items.amount)::double precision)) AS total_cost, lost_items.user_id, (lost_items.lost_at)::date AS date FROM ((lost_items LEFT JOIN bundles ON ((bundles.item_id = lost_items.item_id))) LEFT JOIN meals ON ((bundles.meal_id = meals.id))) GROUP BY COALESCE(meals.item_id, lost_items.item_id), lost_items.lost_at, lost_items.cost, lost_items.user_id;


--
-- Name: mail_acl_rules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mail_acl_rules (
    rule_id integer NOT NULL,
    mailbox_id integer NOT NULL,
    group_id integer NOT NULL,
    action character varying(15) NOT NULL,
    CONSTRAINT mail_acl_rules_action_check CHECK (((action)::text = ANY ((ARRAY['read'::character varying, 'handle'::character varying, 'admin'::character varying])::text[])))
);


--
-- Name: mail_acl_rules_rule_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mail_acl_rules_rule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mail_acl_rules_rule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mail_acl_rules_rule_id_seq OWNED BY mail_acl_rules.rule_id;


--
-- Name: mail_conversations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mail_conversations (
    conversation_id integer NOT NULL,
    mailbox_id integer NOT NULL,
    handled_by integer,
    tracker character(10) NOT NULL,
    note text,
    flag_closed boolean DEFAULT false NOT NULL,
    CONSTRAINT mail_conversations_tracker_check CHECK ((length(tracker) = 10))
);


--
-- Name: mail_conversations_conversation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mail_conversations_conversation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mail_conversations_conversation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mail_conversations_conversation_id_seq OWNED BY mail_conversations.conversation_id;


--
-- Name: mail_messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mail_messages (
    message_id integer NOT NULL,
    imap_id integer NOT NULL,
    conversation_id integer NOT NULL,
    from_address character varying(100) NOT NULL,
    from_name character varying(100),
    to_address character varying(100) NOT NULL,
    subject character varying(255) NOT NULL,
    body text NOT NULL,
    flag_new boolean DEFAULT true NOT NULL,
    direction message_direction DEFAULT 'recieved'::message_direction NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: mail_conversations_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW mail_conversations_view AS
    SELECT mail_conversations.conversation_id, max(mail_messages.updated_at) AS updated_at, bool_or(mail_messages.flag_new) AS unread, mail_messages.subject, mail_conversations.mailbox_id, mail_conversations.handled_by, mail_conversations.flag_closed FROM (mail_conversations NATURAL LEFT JOIN mail_messages) GROUP BY mail_conversations.conversation_id, mail_messages.subject, mail_conversations.mailbox_id, mail_conversations.handled_by, mail_conversations.flag_closed;


--
-- Name: mail_mailboxes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mail_mailboxes (
    mailbox_id integer NOT NULL,
    address character varying(100) NOT NULL,
    from_name character varying(255),
    human_name character varying(100),
    description text,
    imap_server character varying(100) NOT NULL,
    imap_login character varying(100) NOT NULL,
    imap_password character varying(100) NOT NULL,
    CONSTRAINT mail_mailboxes_address_check CHECK ((length((address)::text) > 4))
);


--
-- Name: mail_mailboxes_mailbox_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mail_mailboxes_mailbox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mail_mailboxes_mailbox_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mail_mailboxes_mailbox_id_seq OWNED BY mail_mailboxes.mailbox_id;


--
-- Name: mail_messages_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mail_messages_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mail_messages_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mail_messages_message_id_seq OWNED BY mail_messages.message_id;


--
-- Name: meal_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE meal_categories (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    CONSTRAINT meal_categories_name_check CHECK ((length((name)::text) > 1))
);


--
-- Name: meal_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE meal_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meal_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE meal_categories_id_seq OWNED BY meal_categories.id;


--
-- Name: meal_category_order; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE meal_category_order (
    category_id integer NOT NULL,
    order_id integer NOT NULL
);


--
-- Name: meal_flags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE meal_flags (
    id integer NOT NULL,
    name character varying(30) NOT NULL,
    description character varying(255),
    icon_path character varying(255),
    CONSTRAINT meal_flags_name_check CHECK ((length((name)::text) > 1))
);


--
-- Name: meal_flags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE meal_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meal_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE meal_flags_id_seq OWNED BY meal_flags.id;


--
-- Name: meals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE meals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE meals_id_seq OWNED BY meals.id;


--
-- Name: memberships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE memberships (
    id integer NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE memberships_id_seq OWNED BY memberships.id;


--
-- Name: menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE menus_id_seq OWNED BY menus.id;


--
-- Name: news; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE news (
    id integer NOT NULL,
    title character varying(80) NOT NULL,
    body text,
    publish_at timestamp without time zone DEFAULT now() NOT NULL,
    expire_at timestamp without time zone,
    CONSTRAINT news_title_check CHECK ((length((title)::text) > 2))
);


--
-- Name: news_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE news_id_seq OWNED BY news.id;


--
-- Name: ordered_items_oid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ordered_items_oid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ordered_items_oid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ordered_items_oid_seq OWNED BY ordered_items.oid;


--
-- Name: user_discounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_discounts (
    id integer NOT NULL,
    user_id integer NOT NULL,
    amount double precision DEFAULT 0.0 NOT NULL,
    name character varying(50) NOT NULL,
    discount_class discount_class NOT NULL,
    start_at timestamp without time zone DEFAULT ('now'::text)::date NOT NULL,
    expire_at timestamp without time zone,
    note character varying(50),
    CONSTRAINT user_discounts_amount_check CHECK (((amount >= (0.0)::double precision) AND (amount <= (1.0)::double precision))),
    CONSTRAINT user_discounts_check CHECK ((COALESCE(expire_at, start_at) >= start_at)),
    CONSTRAINT user_discounts_name_check CHECK ((length((name)::text) > 2))
);


--
-- Name: ordered_items_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW ordered_items_view AS
    SELECT oi.oid, oi.item_id, oi.order_id, oi.amount, oi.price, LEAST((COALESCE(ud.amount, (0)::double precision) + COALESCE(sum(id.amount), (0)::double precision)), (1)::double precision) AS discount FROM (((((ordered_items oi LEFT JOIN item_tables_view itv ON ((oi.item_id = itv.item_id))) LEFT JOIN orders o ON ((o.id = oi.order_id))) LEFT JOIN users u ON ((o.user_id = u.id))) LEFT JOIN user_discounts ud ON ((((u.id = ud.user_id) AND (itv.discount_class = ud.discount_class)) AND ((o.deliver_at >= ud.start_at) AND (o.deliver_at <= COALESCE(ud.expire_at, o.deliver_at)))))) LEFT JOIN item_discounts id ON (((oi.item_id = id.item_id) AND ((o.deliver_at >= id.start_at) AND (o.deliver_at <= id.expire_at))))) GROUP BY oi.oid, oi.item_id, oi.order_id, oi.amount, oi.price, ud.amount;


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE orders_id_seq OWNED BY orders.id;


--
-- Name: orders_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW orders_view AS
    SELECT orders.id, orders.user_id, orders.delivery_man_id, orders.delivery_method_id, orders.state, orders.paid, orders.cancelled, orders.notice, orders.created_at, orders.updated_at, orders.deliver_at, (COALESCE(sum(((ordered_items_view.price * (ordered_items_view.amount)::double precision) * ((1)::double precision - ordered_items_view.discount))), (0)::double precision) + COALESCE(delivery_methods.price, (0)::double precision)) AS price, COALESCE(sum(((ordered_items_view.price * (ordered_items_view.amount)::double precision) * ((1)::double precision - ordered_items_view.discount))), (0)::double precision) AS discount_price, COALESCE(sum((ordered_items_view.price * (ordered_items_view.amount)::double precision)), (0)::double precision) AS original_price, COALESCE(delivery_methods.price, (0)::double precision) AS delivery_price FROM ((orders LEFT JOIN ordered_items_view ON ((ordered_items_view.order_id = orders.id))) LEFT JOIN delivery_methods ON ((orders.delivery_method_id = delivery_methods.id))) GROUP BY orders.id, orders.user_id, orders.delivery_man_id, orders.delivery_method_id, orders.state, orders.paid, orders.cancelled, orders.notice, orders.created_at, orders.updated_at, orders.deliver_at, delivery_methods.price;


--
-- Name: page_histories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE page_histories (
    id integer NOT NULL,
    page_id integer NOT NULL,
    url character varying(50) NOT NULL,
    CONSTRAINT page_histories_url_check CHECK ((length((url)::text) > 1))
);


--
-- Name: page_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE page_histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE page_histories_id_seq OWNED BY page_histories.id;


--
-- Name: pages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pages (
    id integer NOT NULL,
    title character varying(80) NOT NULL,
    body text,
    url character varying(50) NOT NULL,
    editable boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT pages_url_check CHECK ((length((url)::text) > 1))
);


--
-- Name: pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pages_id_seq OWNED BY pages.id;


--
-- Name: poll_answers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE poll_answers (
    id integer NOT NULL,
    poll_id integer NOT NULL,
    text character varying(100) NOT NULL,
    CONSTRAINT poll_answers_text_check CHECK ((length((text)::text) > 0))
);


--
-- Name: poll_answers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE poll_answers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poll_answers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE poll_answers_id_seq OWNED BY poll_answers.id;


--
-- Name: poll_votes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE poll_votes (
    id integer NOT NULL,
    user_id integer,
    poll_answer_id integer NOT NULL
);


--
-- Name: poll_answers_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW poll_answers_view AS
    SELECT poll_answers.id, poll_answers.poll_id, poll_answers.text, count(poll_votes.poll_answer_id) AS votes, total_votes.count AS total_votes, (((count(poll_votes.poll_answer_id))::double precision / (total_votes.count)::double precision) * (100)::double precision) AS percent FROM ((poll_answers LEFT JOIN poll_votes ON ((poll_answers.id = poll_votes.poll_answer_id))) LEFT JOIN (SELECT poll_answers.poll_id, count(poll_answers.poll_id) AS count FROM (poll_votes LEFT JOIN poll_answers ON ((poll_answers.id = poll_votes.poll_answer_id))) GROUP BY poll_answers.poll_id) total_votes ON ((poll_answers.poll_id = total_votes.poll_id))) GROUP BY poll_answers.id, poll_answers.poll_id, poll_answers.text, total_votes.count;


--
-- Name: poll_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE poll_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poll_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE poll_votes_id_seq OWNED BY poll_votes.id;


--
-- Name: polls; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE polls (
    id integer NOT NULL,
    question character varying(100) NOT NULL,
    poll_type poll_type NOT NULL,
    active boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT polls_question_check CHECK ((length((question)::text) > 3))
);


--
-- Name: polls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE polls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polls_id_seq OWNED BY polls.id;


--
-- Name: premises; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE premises (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    name_abbr character varying(20) NOT NULL,
    address text,
    description text,
    CONSTRAINT premises_name_abbr_check CHECK ((length((name_abbr)::text) > 1))
);


--
-- Name: premises_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE premises_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: premises_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE premises_id_seq OWNED BY premises.id;


--
-- Name: product_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE product_categories (
    id integer NOT NULL,
    parent_id integer,
    lft integer,
    rgt integer,
    name character varying(50) NOT NULL,
    description text,
    CONSTRAINT product_categories_name_check CHECK ((length((name)::text) > 1))
);


--
-- Name: product_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_categories_id_seq OWNED BY product_categories.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE products (
    item_type item_type DEFAULT 'product'::item_type,
    id integer NOT NULL,
    cost double precision DEFAULT 0.0 NOT NULL,
    short_description character varying(250) DEFAULT ''::character varying NOT NULL,
    disabled boolean DEFAULT false NOT NULL,
    term_of_delivery interval
)
INHERITS (items);


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE products_id_seq OWNED BY products.id;


--
-- Name: products_log; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE products_log (
    id integer NOT NULL,
    day date NOT NULL,
    product_id integer NOT NULL,
    amount integer NOT NULL,
    product_cost double precision NOT NULL,
    note character varying(200) DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by integer
);


--
-- Name: products_log_balance_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW products_log_balance_view AS
    SELECT products.id AS product_id, (- ordered_items.amount) AS amount, (orders.deliver_at)::date AS day FROM ((ordered_items LEFT JOIN orders ON ((orders.id = ordered_items.order_id))) LEFT JOIN products ON ((ordered_items.item_id = products.item_id))) WHERE (((products.item_type = 'product'::item_type) AND (orders.state = ANY (ARRAY['order'::order_state, 'expedited'::order_state, 'closed'::order_state]))) AND (orders.cancelled IS NOT TRUE)) UNION ALL SELECT products_log.product_id, products_log.amount, products_log.day FROM products_log;


--
-- Name: products_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE products_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE products_log_id_seq OWNED BY products_log.id;


--
-- Name: products_log_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW products_log_view AS
    SELECT products_log.id, products_log.day, products_log.product_id, products_log.amount, products_log.product_cost, products_log.note, products_log.created_at, products_log.updated_at, products_log.updated_by, (products_log.product_cost * (products_log.amount)::double precision) AS total_cost FROM products_log;


--
-- Name: products_log_warnings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE products_log_warnings (
    id integer NOT NULL,
    ordered_item_id integer,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: products_log_warnings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE products_log_warnings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_log_warnings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE products_log_warnings_id_seq OWNED BY products_log_warnings.id;


--
-- Name: products_log_warnings_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW products_log_warnings_view AS
    SELECT products_log_warnings.id, products_log_warnings.ordered_item_id, products_log_warnings.created_at, ordered_items.amount, orders.deliver_at, (orders.deliver_at)::date AS day FROM (((products_log_warnings LEFT JOIN ordered_items ON ((products_log_warnings.ordered_item_id = ordered_items.oid))) LEFT JOIN products ON ((ordered_items.item_id = products.item_id))) LEFT JOIN orders ON ((ordered_items.order_id = orders.id)));


--
-- Name: products_with_stock_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW products_with_stock_view AS
    SELECT products.item_id, products.price, products.name, products.item_type, products.created_at, products.updated_at, products.updated_by, products.image_flag, products.id, products.cost, products.short_description, products.disabled, products.term_of_delivery, stock.amount, (COALESCE(stock.amount, (0)::bigint) > 0) AS on_stock, ((COALESCE(stock.amount, (0)::bigint) > 0) OR (products.term_of_delivery IS NOT NULL)) AS available FROM (products LEFT JOIN (SELECT products_log_balance_view.product_id, sum(products_log_balance_view.amount) AS amount FROM products_log_balance_view GROUP BY products_log_balance_view.product_id) stock ON ((stock.product_id = products.id)));


--
-- Name: recipes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE recipes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recipes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE recipes_id_seq OWNED BY recipes.id;


--
-- Name: restaurant_sales; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE restaurant_sales (
    id integer NOT NULL,
    item_id integer NOT NULL,
    premise_id integer NOT NULL,
    amount integer NOT NULL,
    price double precision NOT NULL,
    buyer_id integer,
    note character varying(100),
    sold_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT restaurant_sales_item_id_check CHECK (check_valid_item_id(item_id))
);


--
-- Name: restaurant_sales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE restaurant_sales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: restaurant_sales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE restaurant_sales_id_seq OWNED BY restaurant_sales.id;


--
-- Name: scheduled_bundles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE scheduled_bundles (
    oid integer NOT NULL,
    bundle_id integer NOT NULL,
    scheduled_for date NOT NULL,
    invisible boolean DEFAULT false NOT NULL
);


--
-- Name: scheduled_bundles_oid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE scheduled_bundles_oid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scheduled_bundles_oid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE scheduled_bundles_oid_seq OWNED BY scheduled_bundles.oid;


--
-- Name: scheduled_meals_oid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE scheduled_meals_oid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scheduled_meals_oid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE scheduled_meals_oid_seq OWNED BY scheduled_meals.oid;


--
-- Name: scheduled_menus_oid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE scheduled_menus_oid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scheduled_menus_oid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE scheduled_menus_oid_seq OWNED BY scheduled_menus.oid;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: snippets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE snippets (
    name character varying(50) NOT NULL,
    content text,
    cachable_flag boolean DEFAULT true NOT NULL,
    CONSTRAINT snippets_name_check CHECK ((length((name)::text) > 1))
);


--
-- Name: sold_items_oid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sold_items_oid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sold_items_oid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sold_items_oid_seq OWNED BY sold_items.oid;


--
-- Name: sold_items_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW sold_items_view AS
    SELECT COALESCE(meals.item_id, sold_items.item_id) AS item_id, sum((COALESCE(bundles.amount, 1) * sold_items.amount)) AS amount, sold_items.price, sold_items.user_id, (sold_items.sold_at)::date AS date FROM ((sold_items LEFT JOIN bundles ON ((bundles.item_id = sold_items.item_id))) LEFT JOIN meals ON ((bundles.meal_id = meals.id))) GROUP BY COALESCE(meals.item_id, sold_items.item_id), sold_items.sold_at, sold_items.price, sold_items.user_id;


--
-- Name: spices; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE spices (
    id integer NOT NULL,
    supplier_id integer,
    name character varying(50) NOT NULL,
    CONSTRAINT spices_name_check CHECK ((length((name)::text) > 1))
);


--
-- Name: spices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE spices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: spices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE spices_id_seq OWNED BY spices.id;


--
-- Name: stocktakings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stocktakings (
    id integer NOT NULL,
    date date
);


--
-- Name: stocktakings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE stocktakings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stocktakings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE stocktakings_id_seq OWNED BY stocktakings.id;


--
-- Name: summary_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW summary_view AS
    SELECT get_summary_between.orders_price, get_summary_between.orders_delivery, get_summary_between.orders_discount, get_summary_between.delivery_bought_ingredients, get_summary_between.restaurant_bought_ingredients, get_summary_between.restaurant_cooking_ingredients, get_summary_between.delivery_cooking_ingredients, get_summary_between.delivery_sold, get_summary_between.restaurant_sold, get_summary_between.fuel, get_summary_between.delivery_expenses, get_summary_between.office_expenses, get_summary_between.restaurant_expenses, get_summary_between.restaurant_sales FROM get_summary_between(('now'::text)::date, ('now'::text)::date) get_summary_between(orders_price, orders_delivery, orders_discount, delivery_bought_ingredients, restaurant_bought_ingredients, restaurant_cooking_ingredients, delivery_cooking_ingredients, delivery_sold, restaurant_sold, fuel, delivery_expenses, office_expenses, restaurant_expenses, restaurant_sales);


--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE suppliers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE suppliers_id_seq OWNED BY suppliers.id;


--
-- Name: total_assigned_ordered_meals; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW total_assigned_ordered_meals AS
    SELECT assigned_ordered_meals.delivery_man_id, assigned_ordered_meals.item_id, assigned_ordered_meals.date, COALESCE(sum(sold_items.amount), (0)::bigint) AS sold_amount, COALESCE(sum(lost_items.amount), (0)::bigint) AS lost_amount, COALESCE(sum(items_in_trunk.amount), (0)::bigint) AS trunk_amount, (((COALESCE(sum(sold_items.amount), (0)::bigint) + COALESCE(sum(lost_items.amount), (0)::bigint)) + COALESCE(sum(items_in_trunk.amount), (0)::bigint)) + assigned_ordered_meals.amount) AS amount FROM (((assigned_ordered_meals LEFT JOIN lost_items ON (((((lost_items.lost_at)::date = assigned_ordered_meals.date) AND (lost_items.user_id = assigned_ordered_meals.delivery_man_id)) AND (lost_items.item_id = assigned_ordered_meals.item_id)))) LEFT JOIN sold_items ON (((((sold_items.sold_at)::date = assigned_ordered_meals.date) AND (sold_items.user_id = assigned_ordered_meals.delivery_man_id)) AND (sold_items.item_id = assigned_ordered_meals.item_id)))) LEFT JOIN items_in_trunk ON ((((assigned_ordered_meals.delivery_man_id = items_in_trunk.delivery_man_id) AND (assigned_ordered_meals.item_id = items_in_trunk.item_id)) AND (items_in_trunk.deliver_at = assigned_ordered_meals.date)))) GROUP BY assigned_ordered_meals.delivery_man_id, assigned_ordered_meals.item_id, assigned_ordered_meals.date, assigned_ordered_meals.amount;


--
-- Name: used_spices; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE used_spices (
    id integer NOT NULL,
    spice_id integer NOT NULL,
    meal_id integer NOT NULL
);


--
-- Name: used_spices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE used_spices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: used_spices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE used_spices_id_seq OWNED BY used_spices.id;


--
-- Name: user_discounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_discounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_discounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_discounts_id_seq OWNED BY user_discounts.id;


--
-- Name: user_import; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_import (
    iduziv integer NOT NULL,
    loginname character varying(50) NOT NULL,
    passwdmd5 character varying(150) NOT NULL,
    passwduziv character varying(150) NOT NULL,
    jmeno character varying(100) NOT NULL,
    prijmeni character varying(100) NOT NULL,
    email character varying(200) NOT NULL,
    telefon character varying(12) NOT NULL,
    adresa character varying(200) NOT NULL,
    mesto character varying(100) NOT NULL,
    psc character varying(7) NOT NULL,
    dodani integer NOT NULL,
    jmenodod character varying(100) NOT NULL,
    prijmenidod character varying(100) NOT NULL,
    adresadod character varying(200) NOT NULL,
    mestodod character varying(100) NOT NULL,
    pscdod character varying(7) NOT NULL,
    firma character varying(255) NOT NULL,
    ico character varying(25) NOT NULL,
    dic character varying(25) NOT NULL,
    objednavek integer NOT NULL,
    cena_objednavek integer NOT NULL,
    sleva integer NOT NULL,
    last_order timestamp without time zone,
    skip boolean DEFAULT false NOT NULL,
    updated boolean DEFAULT false NOT NULL,
    user_id integer
);


--
-- Name: user_profile_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_profile_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    data_type character varying(100) NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    editable boolean DEFAULT true NOT NULL,
    required boolean DEFAULT false NOT NULL,
    CONSTRAINT user_profile_types_data_type_check CHECK (((data_type)::text = ANY ((ARRAY['text_field'::character varying, 'text_area'::character varying, 'hidden'::character varying, 'checkbox'::character varying])::text[]))),
    CONSTRAINT user_profile_types_name_check CHECK ((length((name)::text) > 1))
);


--
-- Name: user_profile_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_profile_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profile_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_profile_types_id_seq OWNED BY user_profile_types.id;


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_profiles (
    id integer NOT NULL,
    user_id integer NOT NULL,
    field_type integer NOT NULL,
    field_body text,
    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: user_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_profiles_id_seq OWNED BY user_profiles.id;


--
-- Name: user_tokens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_tokens (
    id integer NOT NULL,
    user_id integer NOT NULL,
    token character varying(32) NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: user_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_tokens_id_seq OWNED BY user_tokens.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: users_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW users_view AS
    SELECT users.id, users.login, users.email, users.guest, list(groups.title) AS roles, addr.street, addr.city, addr.district, addr.house_no, addr.zip, addr.first_name AS addr_first_name, addr.family_name AS addr_family_name, addr.company_name AS addr_company_name, first_names.field_body AS first_name, family_names.field_body AS family_name, company_names.field_body AS company_name, (COALESCE(orders_view.price, (0)::double precision) + users.imported_orders_price) AS spent_money, user_discounts.amount AS user_discount FROM (((((((((users LEFT JOIN memberships ON ((users.id = memberships.user_id))) JOIN groups ON ((memberships.group_id = groups.id))) LEFT JOIN (SELECT addresses.address_type AS type, addresses.user_id FROM addresses WHERE ((addresses.address_type)::text = 'delivery'::text)) deliv_addr ON ((deliv_addr.user_id = users.id))) LEFT JOIN addresses addr ON (((addr.user_id = users.id) AND ((addr.address_type)::text = (COALESCE(deliv_addr.type, 'home'::character varying))::text)))) LEFT JOIN (SELECT user_profiles.field_body, user_profiles.field_type, user_profiles.user_id FROM (user_profiles JOIN user_profile_types ON ((user_profiles.field_type = user_profile_types.id))) WHERE ((user_profile_types.name)::text = 'first_name'::text)) first_names ON ((users.id = first_names.user_id))) LEFT JOIN (SELECT user_profiles.field_body, user_profiles.field_type, user_profiles.user_id FROM (user_profiles JOIN user_profile_types ON ((user_profiles.field_type = user_profile_types.id))) WHERE ((user_profile_types.name)::text = 'family_name'::text)) family_names ON ((users.id = family_names.user_id))) LEFT JOIN (SELECT user_profiles.field_body, user_profiles.field_type, user_profiles.user_id FROM (user_profiles JOIN user_profile_types ON ((user_profiles.field_type = user_profile_types.id))) WHERE ((user_profile_types.name)::text = 'company_name'::text)) company_names ON ((users.id = company_names.user_id))) LEFT JOIN (SELECT orders_view.user_id, sum(orders_view.price) AS price FROM orders_view WHERE ((orders_view.state <> 'basket'::order_state) AND (orders_view.cancelled = false)) GROUP BY orders_view.user_id) orders_view ON ((orders_view.user_id = users.id))) LEFT JOIN (SELECT user_discounts.user_id, user_discounts.amount FROM user_discounts WHERE ((('now'::text)::date >= (user_discounts.start_at)::date) AND (('now'::text)::date <= COALESCE((user_discounts.expire_at)::date, ('now'::text)::date)))) user_discounts ON ((user_discounts.user_id = users.id))) GROUP BY users.id, users.login, users.email, users.guest, addr.street, addr.city, addr.district, addr.house_no, addr.zip, addr.first_name, addr.family_name, addr.company_name, first_names.field_body, family_names.field_body, company_names.field_body, users.imported_orders_price, orders_view.user_id, orders_view.price, user_discounts.amount;


--
-- Name: wholesale_discounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE wholesale_discounts (
    id integer NOT NULL,
    user_id integer NOT NULL,
    discount_price double precision NOT NULL,
    note character varying(150) DEFAULT ''::character varying NOT NULL,
    start_at timestamp without time zone DEFAULT ('now'::text)::date NOT NULL,
    expire_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by integer,
    CONSTRAINT wholesale_discounts_check CHECK ((COALESCE(expire_at, start_at) >= start_at)),
    CONSTRAINT wholesale_discounts_discount_price_check CHECK ((discount_price >= (0.0)::double precision))
);


--
-- Name: wholesale_discounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wholesale_discounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wholesale_discounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE wholesale_discounts_id_seq OWNED BY wholesale_discounts.id;


--
-- Name: zones; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zones (
    id integer NOT NULL,
    name character varying(70) NOT NULL,
    disabled boolean DEFAULT false NOT NULL,
    hidden boolean DEFAULT false NOT NULL
);


--
-- Name: zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zones_id_seq OWNED BY zones.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bundles ALTER COLUMN id SET DEFAULT nextval('bundles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE cars ALTER COLUMN id SET DEFAULT nextval('cars_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE cars_logbooks ALTER COLUMN id SET DEFAULT nextval('cars_logbooks_id_seq'::regclass);


--
-- Name: oid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE categorized_products ALTER COLUMN oid SET DEFAULT nextval('categorized_products_oid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE country_codes ALTER COLUMN id SET DEFAULT nextval('country_codes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE courses ALTER COLUMN id SET DEFAULT nextval('courses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE delivery_methods ALTER COLUMN id SET DEFAULT nextval('delivery_methods_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE dialy_menu_entries ALTER COLUMN id SET DEFAULT nextval('dialy_menu_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE dialy_menus ALTER COLUMN id SET DEFAULT nextval('dialy_menus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE expense_categories ALTER COLUMN id SET DEFAULT nextval('expense_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE expenses ALTER COLUMN id SET DEFAULT nextval('expenses_id_seq'::regclass);


--
-- Name: oid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE flagged_meals ALTER COLUMN oid SET DEFAULT nextval('flagged_meals_oid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE fuel ALTER COLUMN id SET DEFAULT nextval('fuel_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE groups ALTER COLUMN id SET DEFAULT nextval('groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ingredient_consumptions ALTER COLUMN id SET DEFAULT nextval('ingredient_consumptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ingredients ALTER COLUMN id SET DEFAULT nextval('ingredients_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ingredients_log ALTER COLUMN id SET DEFAULT nextval('ingredients_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ingredients_log_from_meals ALTER COLUMN id SET DEFAULT nextval('ingredients_log_from_meals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ingredients_log_from_menus ALTER COLUMN id SET DEFAULT nextval('ingredients_log_from_menus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ingredients_log_from_restaurant ALTER COLUMN id SET DEFAULT nextval('ingredients_log_from_restaurant_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ingredients_log_from_stocktakings ALTER COLUMN id SET DEFAULT nextval('ingredients_log_from_stocktakings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ingredients_log_watchdogs ALTER COLUMN id SET DEFAULT nextval('ingredients_log_watchdogs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE item_discounts ALTER COLUMN id SET DEFAULT nextval('item_discounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE item_profile_types ALTER COLUMN id SET DEFAULT nextval('item_profile_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE item_profiles ALTER COLUMN id SET DEFAULT nextval('item_profiles_id_seq'::regclass);


--
-- Name: item_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE items ALTER COLUMN item_id SET DEFAULT nextval('items_item_id_seq'::regclass);


--
-- Name: oid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE items_in_trunk ALTER COLUMN oid SET DEFAULT nextval('items_in_trunk_oid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE logbook_categories ALTER COLUMN id SET DEFAULT nextval('logbook_categories_id_seq'::regclass);


--
-- Name: oid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE lost_items ALTER COLUMN oid SET DEFAULT nextval('lost_items_oid_seq'::regclass);


--
-- Name: rule_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mail_acl_rules ALTER COLUMN rule_id SET DEFAULT nextval('mail_acl_rules_rule_id_seq'::regclass);


--
-- Name: conversation_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mail_conversations ALTER COLUMN conversation_id SET DEFAULT nextval('mail_conversations_conversation_id_seq'::regclass);


--
-- Name: mailbox_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mail_mailboxes ALTER COLUMN mailbox_id SET DEFAULT nextval('mail_mailboxes_mailbox_id_seq'::regclass);


--
-- Name: message_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE mail_messages ALTER COLUMN message_id SET DEFAULT nextval('mail_messages_message_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE meal_categories ALTER COLUMN id SET DEFAULT nextval('meal_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE meal_flags ALTER COLUMN id SET DEFAULT nextval('meal_flags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE meals ALTER COLUMN id SET DEFAULT nextval('meals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE memberships ALTER COLUMN id SET DEFAULT nextval('memberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE menus ALTER COLUMN id SET DEFAULT nextval('menus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE news ALTER COLUMN id SET DEFAULT nextval('news_id_seq'::regclass);


--
-- Name: oid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ordered_items ALTER COLUMN oid SET DEFAULT nextval('ordered_items_oid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE orders ALTER COLUMN id SET DEFAULT nextval('orders_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE page_histories ALTER COLUMN id SET DEFAULT nextval('page_histories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE pages ALTER COLUMN id SET DEFAULT nextval('pages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE poll_answers ALTER COLUMN id SET DEFAULT nextval('poll_answers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE poll_votes ALTER COLUMN id SET DEFAULT nextval('poll_votes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE polls ALTER COLUMN id SET DEFAULT nextval('polls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE premises ALTER COLUMN id SET DEFAULT nextval('premises_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE product_categories ALTER COLUMN id SET DEFAULT nextval('product_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE products ALTER COLUMN id SET DEFAULT nextval('products_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE products_log ALTER COLUMN id SET DEFAULT nextval('products_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE products_log_warnings ALTER COLUMN id SET DEFAULT nextval('products_log_warnings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE recipes ALTER COLUMN id SET DEFAULT nextval('recipes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE restaurant_sales ALTER COLUMN id SET DEFAULT nextval('restaurant_sales_id_seq'::regclass);


--
-- Name: oid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE scheduled_bundles ALTER COLUMN oid SET DEFAULT nextval('scheduled_bundles_oid_seq'::regclass);


--
-- Name: oid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE scheduled_meals ALTER COLUMN oid SET DEFAULT nextval('scheduled_meals_oid_seq'::regclass);


--
-- Name: oid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE scheduled_menus ALTER COLUMN oid SET DEFAULT nextval('scheduled_menus_oid_seq'::regclass);


--
-- Name: oid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sold_items ALTER COLUMN oid SET DEFAULT nextval('sold_items_oid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE spices ALTER COLUMN id SET DEFAULT nextval('spices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE stocktakings ALTER COLUMN id SET DEFAULT nextval('stocktakings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE suppliers ALTER COLUMN id SET DEFAULT nextval('suppliers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE used_spices ALTER COLUMN id SET DEFAULT nextval('used_spices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE user_discounts ALTER COLUMN id SET DEFAULT nextval('user_discounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE user_profile_types ALTER COLUMN id SET DEFAULT nextval('user_profile_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE user_profiles ALTER COLUMN id SET DEFAULT nextval('user_profiles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE user_tokens ALTER COLUMN id SET DEFAULT nextval('user_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE wholesale_discounts ALTER COLUMN id SET DEFAULT nextval('wholesale_discounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zones ALTER COLUMN id SET DEFAULT nextval('zones_id_seq'::regclass);


--
-- Name: addresses_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_id_key UNIQUE (id);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (user_id, address_type);


--
-- Name: bundles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bundles
    ADD CONSTRAINT bundles_pkey PRIMARY KEY (id);


--
-- Name: cars_logbooks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cars_logbooks
    ADD CONSTRAINT cars_logbooks_pkey PRIMARY KEY (id);


--
-- Name: cars_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cars
    ADD CONSTRAINT cars_pkey PRIMARY KEY (id);


--
-- Name: categorized_products_oid_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY categorized_products
    ADD CONSTRAINT categorized_products_oid_key UNIQUE (oid);


--
-- Name: categorized_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY categorized_products
    ADD CONSTRAINT categorized_products_pkey PRIMARY KEY (product_id, product_category_id);


--
-- Name: configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY configuration
    ADD CONSTRAINT configuration_pkey PRIMARY KEY (key);


--
-- Name: country_codes_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY country_codes
    ADD CONSTRAINT country_codes_name_key UNIQUE (name);


--
-- Name: country_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY country_codes
    ADD CONSTRAINT country_codes_pkey PRIMARY KEY (id);


--
-- Name: courses_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT courses_id_key UNIQUE (id);


--
-- Name: courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (meal_id, menu_id);


--
-- Name: delivery_methods_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delivery_methods
    ADD CONSTRAINT delivery_methods_name_key UNIQUE (name);


--
-- Name: delivery_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delivery_methods
    ADD CONSTRAINT delivery_methods_pkey PRIMARY KEY (id);


--
-- Name: dialy_menu_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dialy_menu_entries
    ADD CONSTRAINT dialy_menu_entries_pkey PRIMARY KEY (id);


--
-- Name: dialy_menus_date_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dialy_menus
    ADD CONSTRAINT dialy_menus_date_key UNIQUE (date);


--
-- Name: dialy_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dialy_menus
    ADD CONSTRAINT dialy_menus_pkey PRIMARY KEY (id);


--
-- Name: expense_categories_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expense_categories
    ADD CONSTRAINT expense_categories_id_key UNIQUE (id);


--
-- Name: expense_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expense_categories
    ADD CONSTRAINT expense_categories_pkey PRIMARY KEY (name);


--
-- Name: expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- Name: flagged_meals_oid_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY flagged_meals
    ADD CONSTRAINT flagged_meals_oid_key UNIQUE (oid);


--
-- Name: flagged_meals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY flagged_meals
    ADD CONSTRAINT flagged_meals_pkey PRIMARY KEY (meal_id, meal_flag_id);


--
-- Name: fuel_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fuel
    ADD CONSTRAINT fuel_pkey PRIMARY KEY (id);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: ingredient_consumptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ingredient_consumptions
    ADD CONSTRAINT ingredient_consumptions_pkey PRIMARY KEY (id);


--
-- Name: ingredients_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ingredients
    ADD CONSTRAINT ingredients_id_key UNIQUE (id);


--
-- Name: ingredients_log_from_meals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ingredients_log_from_meals
    ADD CONSTRAINT ingredients_log_from_meals_pkey PRIMARY KEY (id);


--
-- Name: ingredients_log_from_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ingredients_log_from_menus
    ADD CONSTRAINT ingredients_log_from_menus_pkey PRIMARY KEY (id);


--
-- Name: ingredients_log_from_restaurant_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ingredients_log_from_restaurant
    ADD CONSTRAINT ingredients_log_from_restaurant_pkey PRIMARY KEY (id);


--
-- Name: ingredients_log_from_stocktakings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ingredients_log_from_stocktakings
    ADD CONSTRAINT ingredients_log_from_stocktakings_pkey PRIMARY KEY (id);


--
-- Name: ingredients_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ingredients_log
    ADD CONSTRAINT ingredients_log_pkey PRIMARY KEY (id);


--
-- Name: ingredients_log_watchdogs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ingredients_log_watchdogs
    ADD CONSTRAINT ingredients_log_watchdogs_pkey PRIMARY KEY (id);


--
-- Name: ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (name);


--
-- Name: item_discounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY item_discounts
    ADD CONSTRAINT item_discounts_pkey PRIMARY KEY (id);


--
-- Name: item_profile_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY item_profile_types
    ADD CONSTRAINT item_profile_types_name_key UNIQUE (name);


--
-- Name: item_profile_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY item_profile_types
    ADD CONSTRAINT item_profile_types_pkey PRIMARY KEY (id);


--
-- Name: item_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY item_profiles
    ADD CONSTRAINT item_profiles_pkey PRIMARY KEY (id);


--
-- Name: items_in_trunk_oid_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY items_in_trunk
    ADD CONSTRAINT items_in_trunk_oid_key UNIQUE (oid);


--
-- Name: items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_pkey PRIMARY KEY (item_id);


--
-- Name: logbook_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY logbook_categories
    ADD CONSTRAINT logbook_categories_pkey PRIMARY KEY (id);


--
-- Name: lost_items_oid_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY lost_items
    ADD CONSTRAINT lost_items_oid_key UNIQUE (oid);


--
-- Name: lost_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY lost_items
    ADD CONSTRAINT lost_items_pkey PRIMARY KEY (item_id, user_id, lost_at);


--
-- Name: mail_acl_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mail_acl_rules
    ADD CONSTRAINT mail_acl_rules_pkey PRIMARY KEY (mailbox_id, group_id, action);


--
-- Name: mail_acl_rules_rule_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mail_acl_rules
    ADD CONSTRAINT mail_acl_rules_rule_id_key UNIQUE (rule_id);


--
-- Name: mail_conversations_conversation_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mail_conversations
    ADD CONSTRAINT mail_conversations_conversation_id_key UNIQUE (conversation_id);


--
-- Name: mail_mailboxes_address_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mail_mailboxes
    ADD CONSTRAINT mail_mailboxes_address_key UNIQUE (address);


--
-- Name: mail_mailboxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mail_mailboxes
    ADD CONSTRAINT mail_mailboxes_pkey PRIMARY KEY (mailbox_id);


--
-- Name: mail_messages_message_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mail_messages
    ADD CONSTRAINT mail_messages_message_id_key UNIQUE (message_id);


--
-- Name: meal_categories_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY meal_categories
    ADD CONSTRAINT meal_categories_id_key UNIQUE (id);


--
-- Name: meal_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY meal_categories
    ADD CONSTRAINT meal_categories_pkey PRIMARY KEY (name);


--
-- Name: meal_category_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY meal_category_order
    ADD CONSTRAINT meal_category_order_pkey PRIMARY KEY (category_id);


--
-- Name: meal_flags_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY meal_flags
    ADD CONSTRAINT meal_flags_name_key UNIQUE (name);


--
-- Name: meal_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY meal_flags
    ADD CONSTRAINT meal_flags_pkey PRIMARY KEY (id);


--
-- Name: meals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY meals
    ADD CONSTRAINT meals_pkey PRIMARY KEY (id);


--
-- Name: memberships_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT memberships_id_key UNIQUE (id);


--
-- Name: memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (user_id, group_id);


--
-- Name: menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY menus
    ADD CONSTRAINT menus_pkey PRIMARY KEY (id);


--
-- Name: news_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY news
    ADD CONSTRAINT news_pkey PRIMARY KEY (id);


--
-- Name: ordered_items_oid_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ordered_items
    ADD CONSTRAINT ordered_items_oid_key UNIQUE (oid);


--
-- Name: ordered_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ordered_items
    ADD CONSTRAINT ordered_items_pkey PRIMARY KEY (item_id, order_id);


--
-- Name: orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: page_histories_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY page_histories
    ADD CONSTRAINT page_histories_id_key UNIQUE (id);


--
-- Name: page_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY page_histories
    ADD CONSTRAINT page_histories_pkey PRIMARY KEY (url);


--
-- Name: pages_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pages
    ADD CONSTRAINT pages_id_key UNIQUE (id);


--
-- Name: pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (url);


--
-- Name: poll_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY poll_answers
    ADD CONSTRAINT poll_answers_pkey PRIMARY KEY (id);


--
-- Name: poll_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY poll_votes
    ADD CONSTRAINT poll_votes_pkey PRIMARY KEY (id);


--
-- Name: polls_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_pkey PRIMARY KEY (id);


--
-- Name: premises_name_abbr_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY premises
    ADD CONSTRAINT premises_name_abbr_key UNIQUE (name_abbr);


--
-- Name: premises_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY premises
    ADD CONSTRAINT premises_pkey PRIMARY KEY (id);


--
-- Name: product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY product_categories
    ADD CONSTRAINT product_categories_pkey PRIMARY KEY (id);


--
-- Name: products_item_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_item_id_key UNIQUE (item_id);


--
-- Name: products_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products_log
    ADD CONSTRAINT products_log_pkey PRIMARY KEY (id);


--
-- Name: products_log_warnings_ordered_item_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products_log_warnings
    ADD CONSTRAINT products_log_warnings_ordered_item_id_key UNIQUE (ordered_item_id);


--
-- Name: products_log_warnings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products_log_warnings
    ADD CONSTRAINT products_log_warnings_pkey PRIMARY KEY (id);


--
-- Name: products_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: recipes_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY recipes
    ADD CONSTRAINT recipes_id_key UNIQUE (id);


--
-- Name: recipes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (ingredient_id, meal_id);


--
-- Name: restaurant_sales_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY restaurant_sales
    ADD CONSTRAINT restaurant_sales_pkey PRIMARY KEY (id);


--
-- Name: scheduled_bundles_oid_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scheduled_bundles
    ADD CONSTRAINT scheduled_bundles_oid_key UNIQUE (oid);


--
-- Name: scheduled_bundles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scheduled_bundles
    ADD CONSTRAINT scheduled_bundles_pkey PRIMARY KEY (bundle_id, scheduled_for);


--
-- Name: scheduled_meals_oid_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scheduled_meals
    ADD CONSTRAINT scheduled_meals_oid_key UNIQUE (oid);


--
-- Name: scheduled_meals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scheduled_meals
    ADD CONSTRAINT scheduled_meals_pkey PRIMARY KEY (meal_id, scheduled_for);


--
-- Name: scheduled_menus_oid_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scheduled_menus
    ADD CONSTRAINT scheduled_menus_oid_key UNIQUE (oid);


--
-- Name: scheduled_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scheduled_menus
    ADD CONSTRAINT scheduled_menus_pkey PRIMARY KEY (menu_id, scheduled_for);


--
-- Name: snippets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY snippets
    ADD CONSTRAINT snippets_pkey PRIMARY KEY (name);


--
-- Name: sold_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sold_items
    ADD CONSTRAINT sold_items_pkey PRIMARY KEY (oid);


--
-- Name: spices_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY spices
    ADD CONSTRAINT spices_name_key UNIQUE (name);


--
-- Name: spices_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY spices
    ADD CONSTRAINT spices_pkey PRIMARY KEY (id);


--
-- Name: stocktakings_date_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stocktakings
    ADD CONSTRAINT stocktakings_date_key UNIQUE (date);


--
-- Name: stocktakings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stocktakings
    ADD CONSTRAINT stocktakings_pkey PRIMARY KEY (id);


--
-- Name: suppliers_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY suppliers
    ADD CONSTRAINT suppliers_id_key UNIQUE (id);


--
-- Name: suppliers_name_abbr_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY suppliers
    ADD CONSTRAINT suppliers_name_abbr_key UNIQUE (name_abbr);


--
-- Name: suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (name);


--
-- Name: used_spices_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY used_spices
    ADD CONSTRAINT used_spices_id_key UNIQUE (id);


--
-- Name: used_spices_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY used_spices
    ADD CONSTRAINT used_spices_pkey PRIMARY KEY (spice_id, meal_id);


--
-- Name: user_discounts_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_discounts
    ADD CONSTRAINT user_discounts_id_key UNIQUE (id);


--
-- Name: user_profile_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_profile_types
    ADD CONSTRAINT user_profile_types_name_key UNIQUE (name);


--
-- Name: user_profile_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_profile_types
    ADD CONSTRAINT user_profile_types_pkey PRIMARY KEY (id);


--
-- Name: user_profiles_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_profiles
    ADD CONSTRAINT user_profiles_id_key UNIQUE (id);


--
-- Name: user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (user_id, field_type);


--
-- Name: user_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- Name: users_login_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_login_key UNIQUE (login);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: wholesale_discounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY wholesale_discounts
    ADD CONSTRAINT wholesale_discounts_pkey PRIMARY KEY (id);


--
-- Name: zones_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zones
    ADD CONSTRAINT zones_name_key UNIQUE (name);


--
-- Name: zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: apply_wholesale_discounts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER apply_wholesale_discounts BEFORE INSERT ON ordered_items FOR EACH ROW EXECUTE PROCEDURE apply_wholesale_discounts();


--
-- Name: check_basket; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_basket BEFORE INSERT OR UPDATE ON orders FOR EACH ROW EXECUTE PROCEDURE check_basket();


--
-- Name: check_consumptions_ingredient_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_consumptions_ingredient_id BEFORE INSERT ON ingredients_log_from_meals FOR EACH ROW EXECUTE PROCEDURE check_consumptions_ingredient_id();


--
-- Name: check_consumptions_ingredient_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_consumptions_ingredient_id BEFORE INSERT ON ingredients_log_from_menus FOR EACH ROW EXECUTE PROCEDURE check_consumptions_ingredient_id();


--
-- Name: check_consumptions_ingredient_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_consumptions_ingredient_id BEFORE INSERT ON ingredients_log_from_restaurant FOR EACH ROW EXECUTE PROCEDURE check_consumptions_ingredient_id();


--
-- Name: check_item_id_exists; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_item_id_exists BEFORE INSERT OR UPDATE ON item_profiles FOR EACH ROW EXECUTE PROCEDURE check_item_id_exists();


--
-- Name: check_item_id_exists; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_item_id_exists BEFORE INSERT OR UPDATE ON item_discounts FOR EACH ROW EXECUTE PROCEDURE check_item_id_exists();


--
-- Name: check_item_id_unique; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_item_id_unique BEFORE INSERT ON items FOR EACH ROW EXECUTE PROCEDURE check_item_id_unique();


--
-- Name: check_item_id_unique; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_item_id_unique BEFORE INSERT ON menus FOR EACH ROW EXECUTE PROCEDURE check_item_id_unique();


--
-- Name: check_item_id_unique; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_item_id_unique BEFORE INSERT ON meals FOR EACH ROW EXECUTE PROCEDURE check_item_id_unique();


--
-- Name: check_item_id_unique; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_item_id_unique BEFORE INSERT ON bundles FOR EACH ROW EXECUTE PROCEDURE check_item_id_unique();


--
-- Name: check_item_id_unique; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_item_id_unique BEFORE INSERT ON products FOR EACH ROW EXECUTE PROCEDURE check_item_id_unique();


--
-- Name: check_order_dates_match; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_order_dates_match BEFORE INSERT OR UPDATE ON ordered_items FOR EACH ROW EXECUTE PROCEDURE check_order_dates_match();


--
-- Name: check_order_delivery_method; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_order_delivery_method BEFORE INSERT OR UPDATE ON orders FOR EACH ROW EXECUTE PROCEDURE check_order_delivery_method();


--
-- Name: check_scheduled_bundle; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_scheduled_bundle BEFORE INSERT ON scheduled_bundles FOR EACH ROW EXECUTE PROCEDURE check_scheduled_bundle();


--
-- Name: check_users_data; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_users_data BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE check_users_data();


--
-- Name: copy_consumption_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER copy_consumption_id BEFORE INSERT ON ingredients_log_from_meals FOR EACH ROW EXECUTE PROCEDURE copy_consumption_id();


--
-- Name: copy_consumption_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER copy_consumption_id BEFORE INSERT ON ingredients_log_from_menus FOR EACH ROW EXECUTE PROCEDURE copy_consumption_id();


--
-- Name: copy_consumption_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER copy_consumption_id BEFORE INSERT ON ingredients_log_from_restaurant FOR EACH ROW EXECUTE PROCEDURE copy_consumption_id();


--
-- Name: copy_ingredient_price; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER copy_ingredient_price BEFORE INSERT ON ingredients_log FOR EACH ROW EXECUTE PROCEDURE copy_ingredient_price();


--
-- Name: copy_item_cost; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER copy_item_cost BEFORE INSERT ON lost_items FOR EACH ROW EXECUTE PROCEDURE copy_item_cost();


--
-- Name: copy_item_price; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER copy_item_price BEFORE INSERT ON sold_items FOR EACH ROW EXECUTE PROCEDURE copy_item_price();


--
-- Name: copy_item_price; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER copy_item_price BEFORE INSERT ON restaurant_sales FOR EACH ROW EXECUTE PROCEDURE copy_item_price();


--
-- Name: copy_item_price; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER copy_item_price BEFORE INSERT ON ordered_items FOR EACH ROW EXECUTE PROCEDURE copy_item_price();


--
-- Name: copy_product_cost; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER copy_product_cost BEFORE INSERT ON products_log FOR EACH ROW EXECUTE PROCEDURE copy_product_cost();


--
-- Name: create_ingredients_log_from_meals_entry; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_ingredients_log_from_meals_entry AFTER INSERT ON scheduled_meals FOR EACH ROW EXECUTE PROCEDURE create_ingredients_log_from_meals_entry();


--
-- Name: create_ingredients_log_from_menus_entry; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_ingredients_log_from_menus_entry AFTER INSERT ON scheduled_menus FOR EACH ROW EXECUTE PROCEDURE create_ingredients_log_from_menus_entry();


--
-- Name: delete_item_discounts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_item_discounts AFTER DELETE ON items FOR EACH ROW EXECUTE PROCEDURE delete_item_discounts();


--
-- Name: delete_item_profiles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_item_profiles AFTER DELETE ON items FOR EACH ROW EXECUTE PROCEDURE delete_item_profiles();


--
-- Name: delete_item_profiles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_item_profiles AFTER DELETE ON meals FOR EACH ROW EXECUTE PROCEDURE delete_item_profiles();


--
-- Name: delete_item_profiles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_item_profiles AFTER DELETE ON menus FOR EACH ROW EXECUTE PROCEDURE delete_item_profiles();


--
-- Name: delete_item_profiles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_item_profiles AFTER DELETE ON bundles FOR EACH ROW EXECUTE PROCEDURE delete_item_profiles();


--
-- Name: delete_item_profiles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_item_profiles AFTER DELETE ON products FOR EACH ROW EXECUTE PROCEDURE delete_item_profiles();


--
-- Name: delete_items_from_order; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_items_from_order BEFORE UPDATE ON orders FOR EACH ROW EXECUTE PROCEDURE delete_items_from_order();


--
-- Name: delete_old_guests; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_old_guests BEFORE INSERT ON users FOR EACH ROW EXECUTE PROCEDURE delete_old_guests();


--
-- Name: delete_old_user_tokens; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_old_user_tokens BEFORE INSERT OR UPDATE ON user_tokens FOR EACH ROW EXECUTE PROCEDURE delete_old_user_tokens();


--
-- Name: delete_ordered_items; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_ordered_items AFTER DELETE ON items FOR EACH ROW EXECUTE PROCEDURE delete_ordered_items();


--
-- Name: delete_ordered_items; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_ordered_items AFTER DELETE ON menus FOR EACH ROW EXECUTE PROCEDURE delete_ordered_items();


--
-- Name: delete_ordered_items; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_ordered_items AFTER DELETE ON meals FOR EACH ROW EXECUTE PROCEDURE delete_ordered_items();


--
-- Name: delete_ordered_items; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_ordered_items AFTER DELETE ON bundles FOR EACH ROW EXECUTE PROCEDURE delete_ordered_items();


--
-- Name: delete_ordered_items; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_ordered_items AFTER DELETE ON products FOR EACH ROW EXECUTE PROCEDURE delete_ordered_items();


--
-- Name: delete_scheduled_bundles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delete_scheduled_bundles AFTER DELETE ON scheduled_meals FOR EACH ROW EXECUTE PROCEDURE delete_scheduled_bundles();


--
-- Name: no_guest_orders; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER no_guest_orders BEFORE INSERT OR UPDATE ON orders FOR EACH ROW EXECUTE PROCEDURE no_guest_orders();


--
-- Name: update_ingredients_log_from_meals_entry; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_ingredients_log_from_meals_entry AFTER UPDATE ON scheduled_meals FOR EACH ROW EXECUTE PROCEDURE update_ingredients_log_from_meals_entry();


--
-- Name: update_ingredients_log_from_menus_entry; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_ingredients_log_from_menus_entry AFTER UPDATE ON scheduled_menus FOR EACH ROW EXECUTE PROCEDURE update_ingredients_log_from_menus_entry();


--
-- Name: validate_delete_item_discount; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER validate_delete_item_discount BEFORE DELETE ON item_discounts FOR EACH ROW EXECUTE PROCEDURE validate_delete_item_discount();


--
-- Name: validate_delete_user_discount; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER validate_delete_user_discount BEFORE DELETE ON user_discounts FOR EACH ROW EXECUTE PROCEDURE validate_delete_user_discount();


--
-- Name: validate_insert_user_discount; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER validate_insert_user_discount BEFORE INSERT ON user_discounts FOR EACH ROW EXECUTE PROCEDURE validate_insert_user_discount();


--
-- Name: addresses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: addresses_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES zones(id);


--
-- Name: bundles_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bundles
    ADD CONSTRAINT bundles_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals(id);


--
-- Name: cars_logbooks_car_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cars_logbooks
    ADD CONSTRAINT cars_logbooks_car_id_fkey FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE RESTRICT;


--
-- Name: cars_logbooks_logbook_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cars_logbooks
    ADD CONSTRAINT cars_logbooks_logbook_category_id_fkey FOREIGN KEY (logbook_category_id) REFERENCES logbook_categories(id);


--
-- Name: cars_logbooks_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cars_logbooks
    ADD CONSTRAINT cars_logbooks_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES users(id);


--
-- Name: cars_logbooks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cars_logbooks
    ADD CONSTRAINT cars_logbooks_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- Name: categorized_products_product_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY categorized_products
    ADD CONSTRAINT categorized_products_product_category_id_fkey FOREIGN KEY (product_category_id) REFERENCES product_categories(id) ON DELETE CASCADE;


--
-- Name: categorized_products_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY categorized_products
    ADD CONSTRAINT categorized_products_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;


--
-- Name: courses_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT courses_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE;


--
-- Name: courses_menu_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT courses_menu_id_fkey FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE CASCADE;


--
-- Name: delivery_methods_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delivery_methods
    ADD CONSTRAINT delivery_methods_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES zones(id);


--
-- Name: dialy_menu_entries_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dialy_menu_entries
    ADD CONSTRAINT dialy_menu_entries_category_id_fkey FOREIGN KEY (category_id) REFERENCES meal_categories(id);


--
-- Name: dialy_menu_entries_dialy_menu_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dialy_menu_entries
    ADD CONSTRAINT dialy_menu_entries_dialy_menu_id_fkey FOREIGN KEY (dialy_menu_id) REFERENCES dialy_menus(id);


--
-- Name: expenses_expense_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY expenses
    ADD CONSTRAINT expenses_expense_category_id_fkey FOREIGN KEY (expense_category_id) REFERENCES expense_categories(id) ON DELETE RESTRICT;


--
-- Name: expenses_premise_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY expenses
    ADD CONSTRAINT expenses_premise_id_fkey FOREIGN KEY (premise_id) REFERENCES premises(id) ON DELETE RESTRICT;


--
-- Name: expenses_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY expenses
    ADD CONSTRAINT expenses_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES users(id);


--
-- Name: expenses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY expenses
    ADD CONSTRAINT expenses_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- Name: flagged_meals_meal_flag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flagged_meals
    ADD CONSTRAINT flagged_meals_meal_flag_id_fkey FOREIGN KEY (meal_flag_id) REFERENCES meal_flags(id) ON DELETE CASCADE;


--
-- Name: flagged_meals_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flagged_meals
    ADD CONSTRAINT flagged_meals_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals(id);


--
-- Name: fuel_car_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fuel
    ADD CONSTRAINT fuel_car_id_fkey FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE RESTRICT;


--
-- Name: fuel_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fuel
    ADD CONSTRAINT fuel_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES users(id);


--
-- Name: fuel_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fuel
    ADD CONSTRAINT fuel_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- Name: ingredient_consumptions_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredient_consumptions
    ADD CONSTRAINT ingredient_consumptions_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE;


--
-- Name: ingredient_consumptions_stocktaking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredient_consumptions
    ADD CONSTRAINT ingredient_consumptions_stocktaking_id_fkey FOREIGN KEY (stocktaking_id) REFERENCES stocktakings(id) ON DELETE RESTRICT;


--
-- Name: ingredients_log_from_meals_consumption_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_meals
    ADD CONSTRAINT ingredients_log_from_meals_consumption_id_fkey FOREIGN KEY (consumption_id) REFERENCES ingredient_consumptions(id) ON DELETE SET NULL;


--
-- Name: ingredients_log_from_meals_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_meals
    ADD CONSTRAINT ingredients_log_from_meals_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE RESTRICT;


--
-- Name: ingredients_log_from_meals_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_meals
    ADD CONSTRAINT ingredients_log_from_meals_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE RESTRICT;


--
-- Name: ingredients_log_from_meals_scheduled_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_meals
    ADD CONSTRAINT ingredients_log_from_meals_scheduled_meal_id_fkey FOREIGN KEY (scheduled_meal_id) REFERENCES scheduled_meals(oid) ON DELETE CASCADE;


--
-- Name: ingredients_log_from_menus_consumption_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_menus
    ADD CONSTRAINT ingredients_log_from_menus_consumption_id_fkey FOREIGN KEY (consumption_id) REFERENCES ingredient_consumptions(id) ON DELETE SET NULL;


--
-- Name: ingredients_log_from_menus_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_menus
    ADD CONSTRAINT ingredients_log_from_menus_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE RESTRICT;


--
-- Name: ingredients_log_from_menus_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_menus
    ADD CONSTRAINT ingredients_log_from_menus_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE RESTRICT;


--
-- Name: ingredients_log_from_menus_scheduled_menu_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_menus
    ADD CONSTRAINT ingredients_log_from_menus_scheduled_menu_id_fkey FOREIGN KEY (scheduled_menu_id) REFERENCES scheduled_menus(oid) ON DELETE CASCADE;


--
-- Name: ingredients_log_from_restaurant_consumption_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_restaurant
    ADD CONSTRAINT ingredients_log_from_restaurant_consumption_id_fkey FOREIGN KEY (consumption_id) REFERENCES ingredient_consumptions(id) ON DELETE SET NULL;


--
-- Name: ingredients_log_from_restaurant_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_restaurant
    ADD CONSTRAINT ingredients_log_from_restaurant_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE RESTRICT;


--
-- Name: ingredients_log_from_restaurant_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_restaurant
    ADD CONSTRAINT ingredients_log_from_restaurant_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE RESTRICT;


--
-- Name: ingredients_log_from_restaurant_restaurant_sale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_restaurant
    ADD CONSTRAINT ingredients_log_from_restaurant_restaurant_sale_id_fkey FOREIGN KEY (restaurant_sale_id) REFERENCES restaurant_sales(id) ON DELETE CASCADE;


--
-- Name: ingredients_log_from_stocktakings_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_stocktakings
    ADD CONSTRAINT ingredients_log_from_stocktakings_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE;


--
-- Name: ingredients_log_from_stocktakings_stocktaking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_from_stocktakings
    ADD CONSTRAINT ingredients_log_from_stocktakings_stocktaking_id_fkey FOREIGN KEY (stocktaking_id) REFERENCES stocktakings(id) ON DELETE CASCADE;


--
-- Name: ingredients_log_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log
    ADD CONSTRAINT ingredients_log_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE RESTRICT;


--
-- Name: ingredients_log_watchdogs_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients_log_watchdogs
    ADD CONSTRAINT ingredients_log_watchdogs_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE;


--
-- Name: ingredients_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients
    ADD CONSTRAINT ingredients_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL;


--
-- Name: item_profiles_field_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY item_profiles
    ADD CONSTRAINT item_profiles_field_type_fkey FOREIGN KEY (field_type) REFERENCES item_profile_types(id) ON DELETE CASCADE;


--
-- Name: items_in_trunk_delivery_man_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY items_in_trunk
    ADD CONSTRAINT items_in_trunk_delivery_man_id_fkey FOREIGN KEY (delivery_man_id) REFERENCES users(id);


--
-- Name: items_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;


--
-- Name: lost_items_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lost_items
    ADD CONSTRAINT lost_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: mail_acl_rules_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_acl_rules
    ADD CONSTRAINT mail_acl_rules_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;


--
-- Name: mail_acl_rules_mailbox_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_acl_rules
    ADD CONSTRAINT mail_acl_rules_mailbox_id_fkey FOREIGN KEY (mailbox_id) REFERENCES mail_mailboxes(mailbox_id) ON DELETE CASCADE;


--
-- Name: mail_conversations_handled_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_conversations
    ADD CONSTRAINT mail_conversations_handled_by_fkey FOREIGN KEY (handled_by) REFERENCES users(id) ON DELETE SET NULL;


--
-- Name: mail_conversations_mailbox_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_conversations
    ADD CONSTRAINT mail_conversations_mailbox_id_fkey FOREIGN KEY (mailbox_id) REFERENCES mail_mailboxes(mailbox_id) ON DELETE CASCADE;


--
-- Name: mail_messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_messages
    ADD CONSTRAINT mail_messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES mail_conversations(conversation_id);


--
-- Name: meal_category_order_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meal_category_order
    ADD CONSTRAINT meal_category_order_category_id_fkey FOREIGN KEY (category_id) REFERENCES meal_categories(id);


--
-- Name: meals_meal_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meals
    ADD CONSTRAINT meals_meal_category_id_fkey FOREIGN KEY (meal_category_id) REFERENCES meal_categories(id) ON DELETE CASCADE;


--
-- Name: memberships_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT memberships_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;


--
-- Name: memberships_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: ordered_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ordered_items
    ADD CONSTRAINT ordered_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;


--
-- Name: orders_delivery_man_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_delivery_man_id_fkey FOREIGN KEY (delivery_man_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- Name: orders_delivery_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_delivery_method_id_fkey FOREIGN KEY (delivery_method_id) REFERENCES delivery_methods(id) ON DELETE SET NULL;


--
-- Name: orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: page_histories_page_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_histories
    ADD CONSTRAINT page_histories_page_id_fkey FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE;


--
-- Name: poll_answers_poll_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY poll_answers
    ADD CONSTRAINT poll_answers_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES polls(id) ON DELETE CASCADE;


--
-- Name: poll_votes_poll_answer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY poll_votes
    ADD CONSTRAINT poll_votes_poll_answer_id_fkey FOREIGN KEY (poll_answer_id) REFERENCES poll_answers(id) ON DELETE CASCADE;


--
-- Name: poll_votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY poll_votes
    ADD CONSTRAINT poll_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: product_categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_categories
    ADD CONSTRAINT product_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES product_categories(id) ON DELETE CASCADE;


--
-- Name: products_log_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products_log
    ADD CONSTRAINT products_log_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;


--
-- Name: products_log_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products_log
    ADD CONSTRAINT products_log_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE RESTRICT;


--
-- Name: products_log_warnings_ordered_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products_log_warnings
    ADD CONSTRAINT products_log_warnings_ordered_item_id_fkey FOREIGN KEY (ordered_item_id) REFERENCES ordered_items(oid) ON DELETE CASCADE;


--
-- Name: recipes_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recipes
    ADD CONSTRAINT recipes_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES ingredients(id);


--
-- Name: recipes_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY recipes
    ADD CONSTRAINT recipes_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE;


--
-- Name: restaurant_sales_buyer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY restaurant_sales
    ADD CONSTRAINT restaurant_sales_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- Name: restaurant_sales_premise_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY restaurant_sales
    ADD CONSTRAINT restaurant_sales_premise_id_fkey FOREIGN KEY (premise_id) REFERENCES premises(id) ON DELETE RESTRICT;


--
-- Name: scheduled_bundles_bundle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scheduled_bundles
    ADD CONSTRAINT scheduled_bundles_bundle_id_fkey FOREIGN KEY (bundle_id) REFERENCES bundles(id) ON DELETE CASCADE;


--
-- Name: scheduled_meals_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scheduled_meals
    ADD CONSTRAINT scheduled_meals_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE;


--
-- Name: scheduled_menus_menu_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scheduled_menus
    ADD CONSTRAINT scheduled_menus_menu_id_fkey FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE CASCADE;


--
-- Name: sold_items_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sold_items
    ADD CONSTRAINT sold_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: spices_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY spices
    ADD CONSTRAINT spices_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL;


--
-- Name: used_spices_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY used_spices
    ADD CONSTRAINT used_spices_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE;


--
-- Name: used_spices_spice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY used_spices
    ADD CONSTRAINT used_spices_spice_id_fkey FOREIGN KEY (spice_id) REFERENCES spices(id);


--
-- Name: user_discounts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_discounts
    ADD CONSTRAINT user_discounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: user_import_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_import
    ADD CONSTRAINT user_import_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: user_profiles_field_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_profiles
    ADD CONSTRAINT user_profiles_field_type_fkey FOREIGN KEY (field_type) REFERENCES user_profile_types(id) ON DELETE CASCADE;


--
-- Name: user_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_profiles
    ADD CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: user_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_tokens
    ADD CONSTRAINT user_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: wholesale_discounts_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wholesale_discounts
    ADD CONSTRAINT wholesale_discounts_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE RESTRICT;


--
-- Name: wholesale_discounts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wholesale_discounts
    ADD CONSTRAINT wholesale_discounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20081016012625');

INSERT INTO schema_migrations (version) VALUES ('20081016012726');

INSERT INTO schema_migrations (version) VALUES ('20081016012827');

INSERT INTO schema_migrations (version) VALUES ('20081016012928');

INSERT INTO schema_migrations (version) VALUES ('20081016013029');

INSERT INTO schema_migrations (version) VALUES ('20081016013130');

INSERT INTO schema_migrations (version) VALUES ('20081016013231');

INSERT INTO schema_migrations (version) VALUES ('20081016013332');

INSERT INTO schema_migrations (version) VALUES ('20081016013433');

INSERT INTO schema_migrations (version) VALUES ('20081016013534');

INSERT INTO schema_migrations (version) VALUES ('20081016013736');

INSERT INTO schema_migrations (version) VALUES ('20081016013837');

INSERT INTO schema_migrations (version) VALUES ('20081016013938');

INSERT INTO schema_migrations (version) VALUES ('20081016014039');

INSERT INTO schema_migrations (version) VALUES ('20081016014140');

INSERT INTO schema_migrations (version) VALUES ('20081016014241');

INSERT INTO schema_migrations (version) VALUES ('20081016014342');

INSERT INTO schema_migrations (version) VALUES ('20081016014443');

INSERT INTO schema_migrations (version) VALUES ('20081016014544');

INSERT INTO schema_migrations (version) VALUES ('20081016014645');

INSERT INTO schema_migrations (version) VALUES ('20081016014746');

INSERT INTO schema_migrations (version) VALUES ('20081016014847');

INSERT INTO schema_migrations (version) VALUES ('20081016014948');

INSERT INTO schema_migrations (version) VALUES ('20081016015049');

INSERT INTO schema_migrations (version) VALUES ('20081016015150');

INSERT INTO schema_migrations (version) VALUES ('20081016015251');

INSERT INTO schema_migrations (version) VALUES ('20081016015352');

INSERT INTO schema_migrations (version) VALUES ('20081016015453');

INSERT INTO schema_migrations (version) VALUES ('20081016015554');

INSERT INTO schema_migrations (version) VALUES ('20081016015655');

INSERT INTO schema_migrations (version) VALUES ('20081016015756');

INSERT INTO schema_migrations (version) VALUES ('20081016015857');

INSERT INTO schema_migrations (version) VALUES ('20081016015958');

INSERT INTO schema_migrations (version) VALUES ('20081016020059');

INSERT INTO schema_migrations (version) VALUES ('20081016020200');

INSERT INTO schema_migrations (version) VALUES ('20081016020301');

INSERT INTO schema_migrations (version) VALUES ('20081016020402');

INSERT INTO schema_migrations (version) VALUES ('20081016020503');

INSERT INTO schema_migrations (version) VALUES ('20081016020604');

INSERT INTO schema_migrations (version) VALUES ('20081016020705');

INSERT INTO schema_migrations (version) VALUES ('20081016020806');

INSERT INTO schema_migrations (version) VALUES ('20081016020907');

INSERT INTO schema_migrations (version) VALUES ('20081016021008');

INSERT INTO schema_migrations (version) VALUES ('20081016021109');

INSERT INTO schema_migrations (version) VALUES ('20081016021118');

INSERT INTO schema_migrations (version) VALUES ('20081016021150');

INSERT INTO schema_migrations (version) VALUES ('20081016021170');

INSERT INTO schema_migrations (version) VALUES ('20081016021180');

INSERT INTO schema_migrations (version) VALUES ('20081016021190');

INSERT INTO schema_migrations (version) VALUES ('20081016021210');

INSERT INTO schema_migrations (version) VALUES ('20081016021311');

INSERT INTO schema_migrations (version) VALUES ('20081016021513');

INSERT INTO schema_migrations (version) VALUES ('20081016021614');

INSERT INTO schema_migrations (version) VALUES ('20081016021816');

INSERT INTO schema_migrations (version) VALUES ('20081016021917');

INSERT INTO schema_migrations (version) VALUES ('20081016022018');

INSERT INTO schema_migrations (version) VALUES ('20081016022119');

INSERT INTO schema_migrations (version) VALUES ('20081016022160');

INSERT INTO schema_migrations (version) VALUES ('20081016022220');

INSERT INTO schema_migrations (version) VALUES ('20081016022321');

INSERT INTO schema_migrations (version) VALUES ('20081016022422');

INSERT INTO schema_migrations (version) VALUES ('20081016022523');

INSERT INTO schema_migrations (version) VALUES ('20081016022624');

INSERT INTO schema_migrations (version) VALUES ('20081016022725');

INSERT INTO schema_migrations (version) VALUES ('20081016022826');

INSERT INTO schema_migrations (version) VALUES ('20081016022927');

INSERT INTO schema_migrations (version) VALUES ('20081016023028');

INSERT INTO schema_migrations (version) VALUES ('20081016023030');

INSERT INTO schema_migrations (version) VALUES ('20081016023129');

INSERT INTO schema_migrations (version) VALUES ('20081016023200');

INSERT INTO schema_migrations (version) VALUES ('20081016023210');

INSERT INTO schema_migrations (version) VALUES ('20081016023230');

INSERT INTO schema_migrations (version) VALUES ('20081016023331');

INSERT INTO schema_migrations (version) VALUES ('20081016023432');

INSERT INTO schema_migrations (version) VALUES ('20081105143010');

INSERT INTO schema_migrations (version) VALUES ('20081125140001');

INSERT INTO schema_migrations (version) VALUES ('20081125140601');

INSERT INTO schema_migrations (version) VALUES ('20081125185200');

INSERT INTO schema_migrations (version) VALUES ('20081125185201');

INSERT INTO schema_migrations (version) VALUES ('20081203145701');

INSERT INTO schema_migrations (version) VALUES ('20081214102900');

INSERT INTO schema_migrations (version) VALUES ('20081214113901');

INSERT INTO schema_migrations (version) VALUES ('20090202160000');

INSERT INTO schema_migrations (version) VALUES ('20090202161000');

INSERT INTO schema_migrations (version) VALUES ('20090204114900');

INSERT INTO schema_migrations (version) VALUES ('20090205154200');

INSERT INTO schema_migrations (version) VALUES ('20090402121320');

INSERT INTO schema_migrations (version) VALUES ('20090402121443');

INSERT INTO schema_migrations (version) VALUES ('20090402122343');

INSERT INTO schema_migrations (version) VALUES ('20090402190530');

INSERT INTO schema_migrations (version) VALUES ('20090422132122');

INSERT INTO schema_migrations (version) VALUES ('20090422132123');

INSERT INTO schema_migrations (version) VALUES ('20090422132124');

INSERT INTO schema_migrations (version) VALUES ('20090422132314');

INSERT INTO schema_migrations (version) VALUES ('20090424095131');

INSERT INTO schema_migrations (version) VALUES ('20090427113042');

INSERT INTO schema_migrations (version) VALUES ('20090709125509');

INSERT INTO schema_migrations (version) VALUES ('20100215141506');

INSERT INTO schema_migrations (version) VALUES ('20100626174011');

INSERT INTO schema_migrations (version) VALUES ('20100626174419');

INSERT INTO schema_migrations (version) VALUES ('20100626212118');