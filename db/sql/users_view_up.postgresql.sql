/*
What's that
coming over the hill?

Is it a monster?
Is it a monster?
*/
CREATE VIEW users_view AS SELECT
    users.id,
    users.login,
    users.email,
    users.guest,
    list(groups.title) AS roles,
    addr.street,
    addr.city,
    addr.district,
    addr.house_no,
    addr.zip,
    addr.first_name AS addr_first_name,
    addr.family_name AS addr_family_name,
    addr.company_name AS addr_company_name,
    first_names.field_body AS first_name,
    family_names.field_body AS family_name,
    company_names.field_body AS company_name,
    COALESCE(orders_view.price,0) + imported_orders_price AS spent_money,
    user_discounts.amount AS user_discount
      FROM users
      LEFT JOIN memberships ON users.id = memberships.user_id
      JOIN groups ON memberships.group_id = groups.id
      LEFT JOIN ( SELECT address_type AS type, user_id FROM addresses WHERE address_type = 'delivery')
        AS deliv_addr
        ON deliv_addr.user_id = users.id
      LEFT JOIN addresses AS addr ON addr.user_id = users.id AND addr.address_type = COALESCE (deliv_addr.type, 'home')
      LEFT JOIN (SELECT field_body, field_type, user_id
          FROM user_profiles
          JOIN user_profile_types ON user_profiles.field_type = user_profile_types.id
          WHERE user_profile_types.name = 'first_name')
        AS first_names
        ON users.id = first_names.user_id
      LEFT JOIN (SELECT field_body, field_type, user_id
          FROM user_profiles
          JOIN user_profile_types ON user_profiles.field_type = user_profile_types.id
          WHERE user_profile_types.name = 'family_name')
        AS family_names
        ON users.id = family_names.user_id
      LEFT JOIN (SELECT field_body, field_type, user_id
          FROM user_profiles
          JOIN user_profile_types ON user_profiles.field_type = user_profile_types.id
          WHERE user_profile_types.name = 'company_name')
        AS company_names
        ON users.id = company_names.user_id
      LEFT JOIN (SELECT user_id, SUM(price) AS price
          FROM orders_view
          WHERE state != 'basket' AND cancelled = false
          GROUP BY orders_view.user_id )
        AS orders_view
        ON orders_view.user_id = users.id
      LEFT JOIN ( SELECT user_id, amount
          FROM user_discounts
          WHERE current_date BETWEEN start_at::date AND COALESCE(expire_at::date, current_date ) )
        AS user_discounts
        ON user_discounts.user_id = users.id  
    GROUP BY users.id, users.login, users.email, users.guest, street, city, district, house_no, zip, addr.first_name, addr.family_name, addr.company_name, first_names.field_body, family_names.field_body, company_names.field_body, imported_orders_price, orders_view.user_id, orders_view.price, user_discounts.amount;