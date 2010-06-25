-- Sample content for Zelena Kuchyne (testing purposes, mostly)

DELETE FROM suppliers;
DELETE FROM ingredients;
DELETE FROM meal_categories;
DELETE FROM meals;
DELETE FROM item_profiles;
DELETE FROM recipes;
DELETE FROM menus;
DELETE FROM courses;
DELETE FROM scheduled_meals;
DELETE FROM scheduled_menus;
DELETE FROM mail_mailboxes;
DELETE FROM mail_conversations;
DELETE FROM mail_messages;

INSERT INTO users(login, email) VALUES
  ('pepa', 'pepa@pepa.cz'),
  ('honza', 'honza@pepa.cz'),
  ('anicka', 'anicka@pepa.cz'),
  ('wanker_holding', 'wanker@holding.com'),
  ('ivanek', 'ivan@vsiti.com'),
  ('petanek', 'peta@vsiti.com');

INSERT INTO user_profiles (field_type, user_id, field_body) VALUES
  ( (SELECT id FROM user_profile_types WHERE name = 'first_name'), (SELECT id FROM users WHERE login = 'pepa'), 'Josef'),
  ( (SELECT id FROM user_profile_types WHERE name = 'family_name'), (SELECT id FROM users WHERE login = 'pepa'), 'Le Hanka'),
  ( (SELECT id FROM user_profile_types WHERE name = 'phone_number'), (SELECT id FROM users WHERE login = 'pepa'), '555 962 777'),
  ( (SELECT id FROM user_profile_types WHERE name = 'first_name'), (SELECT id FROM users WHERE login = 'anicka'), 'Anča'),
  ( (SELECT id FROM user_profile_types WHERE name = 'family_name'), (SELECT id FROM users WHERE login = 'anicka'), 'Satanistka'),
  ( (SELECT id FROM user_profile_types WHERE name = 'phone_number'), (SELECT id FROM users WHERE login = 'anicka'), '666 962 777'),
  ( (SELECT id FROM user_profile_types WHERE name = 'first_name'), (SELECT id FROM users WHERE login = 'admin'), 'Admin'),
  ( (SELECT id FROM user_profile_types WHERE name = 'family_name'), (SELECT id FROM users WHERE login = 'admin'), 'Adminovič'),
  ( (SELECT id FROM user_profile_types WHERE name = 'phone_number'), (SELECT id FROM users WHERE login = 'admin'), '627669677'),
  ( (SELECT id FROM user_profile_types WHERE name = 'first_name'), (SELECT id FROM users WHERE login = 'honza'), 'Jan'),
  ( (SELECT id FROM user_profile_types WHERE name = 'family_name'), (SELECT id FROM users WHERE login = 'honza'), 'Březina'),
  ( (SELECT id FROM user_profile_types WHERE name = 'phone_number'), (SELECT id FROM users WHERE login = 'honza'), '555 777 777'),
  ( (SELECT id FROM user_profile_types WHERE name = 'delivery_man_color'), (SELECT id FROM users WHERE login = 'ivanek'), '#FFAABB'),
  ( (SELECT id FROM user_profile_types WHERE name = 'company_name'), (SELECT id FROM users WHERE login = 'wanker_holding'), 'Wanker Holding corp.'),
  ( (SELECT id FROM user_profile_types WHERE name = 'company_registration_no'), (SELECT id FROM users WHERE login = 'wanker_holding'), '87146843'),
  ( (SELECT id FROM user_profile_types WHERE name = 'phone_number'), (SELECT id FROM users WHERE login = 'wanker_holding'), '777 777 777');

INSERT INTO addresses(user_id, address_type, city, district, street, house_no, zip, first_name, family_name, company_name) VALUES
  ( (SELECT id FROM users WHERE login = 'pepa'), 'home', 'Praha', 'Vinohrady', 'Banánova', '17/257', '120 00', NULL, NULL, NULL),
  ( (SELECT id FROM users WHERE login = 'admin'), 'home', 'Praha', 'Vinohrady', 'Jana Masaryka', '1', '12000', 'Generál', 'Adminovič', NULL),
  ( (SELECT id FROM users WHERE login = 'honza'), 'home', 'Brno', 'na návsi', 'hlavní', '4', '80568', NULL, NULL, NULL),
  ( (SELECT id FROM users WHERE login = 'honza'), 'delivery', 'Praha', 'Nusle', 'Náměstí bří. Synků', '14/9268', '101 00', 'Jana', 'Vonásková', NULL),
  ( (SELECT id FROM users WHERE login = 'anicka'), 'home', 'Praha', 'Olšanské hřbitovy', 'třetí hrob zleva', '666', '666 00', NULL, NULL, NULL),
  ( (SELECT id FROM users WHERE login = 'wanker_holding'), 'home', 'Praha', 'Vankerov', 'boing boing', '7/86', '180 00', NULL, NULL, NULL),
  ( (SELECT id FROM users WHERE login = 'wanker_holding'), 'delivery', 'Praha', 'Vinohrady', 'Francouzská', '6/58', '120 00', 'Eleanora', 'Rigbyová', 'Wanker Holding corp.');

INSERT INTO memberships (user_id, group_id) VALUES
  ( (SELECT id FROM users WHERE login = 'pepa'), (SELECT id FROM groups WHERE system_name = 'customers') ),
  ( (SELECT id FROM users WHERE login = 'honza'), (SELECT id FROM groups WHERE system_name = 'customers') ),
  ( (SELECT id FROM users WHERE login = 'anicka'), (SELECT id FROM groups WHERE system_name = 'customers') ),
  ( (SELECT id FROM users WHERE login = 'wanker_holding'), (SELECT id FROM groups WHERE system_name = 'customers') ),
  ( (SELECT id FROM users WHERE login = 'ivanek'), (SELECT id FROM groups WHERE system_name = 'deliverymen') ),
  ( (SELECT id FROM users WHERE login = 'petanek'), (SELECT id FROM groups WHERE system_name = 'deliverymen') );

INSERT INTO suppliers(name, name_abbr, address) VALUES
  ('Macro', 'macro', 'Falešná 123, Černý most'),
  ('Fanda Fonásek-Frštel', 'fanda', 'Feniklová fulice feftnáct');

INSERT INTO ingredients(unit, name, cost, supplier_id) VALUES
  ('g', 'zelí', 0.1, (SELECT id FROM suppliers WHERE name_abbr = 'macro')),
  ('g', 'strouhaná mrkev', 0.2, (SELECT id FROM suppliers WHERE name_abbr = 'macro')),
  ('ml', 'mléko', 0.1, (SELECT id FROM suppliers WHERE name_abbr = 'fanda')),
  ('ml', 'smetana', 0.25, (SELECT id FROM suppliers WHERE name_abbr = 'fanda')),
  ('ks', 'chilli paprička', 13, (SELECT id FROM suppliers WHERE name_abbr = 'macro')),
  ('g', 'brambory', 0.075, (SELECT id FROM suppliers WHERE name_abbr = 'macro')),
  ('g', 'fazole', 0.15, (SELECT id FROM suppliers WHERE name_abbr = 'macro')),
  ('ml', 'pomerančová šťáva', 0.15, (SELECT id FROM suppliers WHERE name_abbr = 'macro')),
  ('g', 'okurky', 0.1, (SELECT id FROM suppliers WHERE name_abbr = 'fanda')),
  ('ks', 'lidská lebka', 19.5, (SELECT id FROM suppliers WHERE name_abbr = 'fanda'));

INSERT INTO ingredients_log(ingredient_id, amount, day) VALUES
  ((SELECT id FROM ingredients WHERE name = 'mléko'),
    800,
    current_date - 5),
  ((SELECT id FROM ingredients WHERE name = 'okurky'),
    1950,
    current_date - 4),
  ((SELECT id FROM ingredients WHERE name = 'strouhaná mrkev'),
    4950,
    current_date - 4),
  ((SELECT id FROM ingredients WHERE name = 'zelí'),
    4000,
    current_date - 4),
  ((SELECT id FROM ingredients WHERE name = 'brambory'),
    10650,
    current_date - 14),
  ((SELECT id FROM ingredients WHERE name = 'fazole'),
    6000,
    current_date - 14),
  ((SELECT id FROM ingredients WHERE name = 'lidská lebka'),
    40,
    current_date - 20),
  ((SELECT id FROM ingredients WHERE name = 'okurky'),
    1500,
    current_date - 20),
  ((SELECT id FROM ingredients WHERE name = 'smetana'),
    1825,
    current_date - 22),
  ((SELECT id FROM ingredients WHERE name = 'fazole'),
    7875,
    current_date - 22),
  ((SELECT id FROM ingredients WHERE name = 'brambory'),
    11650,
    current_date - 22),
  ((SELECT id FROM ingredients WHERE name = 'chilli paprička'),
    380,
    current_date - 25),
  ((SELECT id FROM ingredients WHERE name = 'strouhaná mrkev'),
    8150,
    current_date - 25),
  ((SELECT id FROM ingredients WHERE name = 'zelí'),
    5000,
    current_date - 25),
  ((SELECT id FROM ingredients WHERE name = 'smetana'),
    4425,
    current_date - 25);


INSERT INTO meal_categories(name) VALUES
  ('polévky'),
  ('hlavní jídla'),
  ('saláty');

INSERT INTO meals(name, meal_category_id, price) VALUES
  ('smetanová polévka', (SELECT id FROM meal_categories WHERE name = 'polévky'), 25),
  ('zeleninová polévka', (SELECT id FROM meal_categories WHERE name = 'polévky'), 20),
  ('fazolový salát', (SELECT id FROM meal_categories WHERE name = 'saláty'), 29.5),
  ('mrkvový salát', (SELECT id FROM meal_categories WHERE name = 'saláty'), 20),
  ('pečené brambory', (SELECT id FROM meal_categories WHERE name = 'hlavní jídla'), 35),
  ('guláš', (SELECT id FROM meal_categories WHERE name = 'hlavní jídla'), 45),
  ('voodoo překvapení', (SELECT id FROM meal_categories WHERE name = 'hlavní jídla'), 30);

INSERT INTO bundles(name, amount, price, meal_id) VALUES
  ('fazolový salát trio', 3, 70, (SELECT id FROM meals WHERE name = 'fazolový salát')),
  ('mrkvový salát double', 2, 34.9, (SELECT id FROM meals WHERE name = 'mrkvový salát'));

INSERT INTO products(name, price) VALUES
  ('zelený čaj', 20),
  ('černý čaj', 15),
  ('amulet nepředstavitelné hrůzy', 45),
  ('sušené lidské maso', 8);

INSERT INTO item_profiles(field_type, item_id, field_body) VALUES
  ( (SELECT id FROM item_profile_types WHERE name = 'description'), (SELECT item_id FROM meals WHERE name = 'smetanová polévka'), '<p>jemná polévka se smetanou</p>'),
  ( (SELECT id FROM item_profile_types WHERE name = 'description'), (SELECT item_id FROM meals WHERE name = 'zeleninová polévka'), '<p>polévka se zeleninou</p>'),
  ( (SELECT id FROM item_profile_types WHERE name = 'description'), (SELECT item_id FROM meals WHERE name = 'fazolový salát'), '<p>fazole v salátu</p>'),
  ( (SELECT id FROM item_profile_types WHERE name = 'description'), (SELECT item_id FROM meals WHERE name = 'mrkvový salát'), '<p>v podstatě mrkev</p>'),
  ( (SELECT id FROM item_profile_types WHERE name = 'description'), (SELECT item_id FROM meals WHERE name = 'pečené brambory'), '<p>hádej, co tohle je</p>'),
  ( (SELECT id FROM item_profile_types WHERE name = 'description'), (SELECT item_id FROM meals WHERE name = 'guláš'), '<p>všechno dohromady, je to červené</p>'),
  ( (SELECT id FROM item_profile_types WHERE name = 'description'), (SELECT item_id FROM meals WHERE name = 'voodoo překvapení'), '<p>nikdy nevíš, na co narazíš</p>');

INSERT INTO recipes(ingredient_id, meal_id, amount) VALUES
  ( (SELECT id FROM ingredients WHERE name = 'smetana'), (SELECT id FROM meals WHERE name = 'smetanová polévka'), 50),
  ( (SELECT id FROM ingredients WHERE name = 'zelí'), (SELECT id FROM meals WHERE name = 'smetanová polévka'), 40),
  ( (SELECT id FROM ingredients WHERE name = 'brambory'), (SELECT id FROM meals WHERE name = 'zeleninová polévka'), 40),
  ( (SELECT id FROM ingredients WHERE name = 'strouhaná mrkev'), (SELECT id FROM meals WHERE name = 'zeleninová polévka'), 20),
  ( (SELECT id FROM ingredients WHERE name = 'okurky'), (SELECT id FROM meals WHERE name = 'zeleninová polévka'), 10),
  ( (SELECT id FROM ingredients WHERE name = 'fazole'), (SELECT id FROM meals WHERE name = 'fazolový salát'), 100),
  ( (SELECT id FROM ingredients WHERE name = 'zelí'), (SELECT id FROM meals WHERE name = 'fazolový salát'), 50),
  ( (SELECT id FROM ingredients WHERE name = 'strouhaná mrkev'), (SELECT id FROM meals WHERE name = 'mrkvový salát'), 135),
  ( (SELECT id FROM ingredients WHERE name = 'brambory'), (SELECT id FROM meals WHERE name = 'pečené brambory'), 150),
  ( (SELECT id FROM ingredients WHERE name = 'smetana'), (SELECT id FROM meals WHERE name = 'pečené brambory'), 40),
  ( (SELECT id FROM ingredients WHERE name = 'brambory'), (SELECT id FROM meals WHERE name = 'guláš'), 60),
  ( (SELECT id FROM ingredients WHERE name = 'fazole'), (SELECT id FROM meals WHERE name = 'guláš'), 50),
  ( (SELECT id FROM ingredients WHERE name = 'chilli paprička'), (SELECT id FROM meals WHERE name = 'guláš'), 2),
  ( (SELECT id FROM ingredients WHERE name = 'okurky'), (SELECT id FROM meals WHERE name = 'guláš'), 30),
  ( (SELECT id FROM ingredients WHERE name = 'lidská lebka'), (SELECT id FROM meals WHERE name = 'voodoo překvapení'), 1),
  ( (SELECT id FROM ingredients WHERE name = 'zelí'), (SELECT id FROM meals WHERE name = 'voodoo překvapení'), 20);

INSERT INTO menus(name, price) VALUES
  ('zeleninové menu', 75),
  ('polední menu', 95),
  ('voodoo menu', 80),
  ('malé menu', 60),
  ('smetanové menu', 75);

INSERT INTO item_profiles(field_type, item_id, field_body) VALUES
  ( (SELECT id FROM item_profile_types WHERE name = 'description'), (SELECT item_id FROM menus WHERE name = 'zeleninové menu'), '<p>menu se zeleninou</p>'),
  ( (SELECT id FROM item_profile_types WHERE name = 'description'), (SELECT item_id FROM menus WHERE name = 'polední menu'), '<p>menu vhodné v poledne</p>'),
  ( (SELECT id FROM item_profile_types WHERE name = 'description'), (SELECT item_id FROM menus WHERE name = 'voodoo menu'), '<p>voodoo menu za příznivou cenu</p>'),
  ( (SELECT id FROM item_profile_types WHERE name = 'description'), (SELECT item_id FROM menus WHERE name = 'malé menu'), '<p>malé menu na zakousnutí</p>'),
  ( (SELECT id FROM item_profile_types WHERE name = 'description'), (SELECT item_id FROM menus WHERE name = 'smetanové menu'), '<p>smetana rulez, woot, woot!</p>');

INSERT INTO courses(meal_id, menu_id) VALUES
  ( (SELECT id FROM meals WHERE name = 'zeleninová polévka'), (SELECT id FROM menus WHERE name = 'zeleninové menu') ),
  ( (SELECT id FROM meals WHERE name = 'mrkvový salát'), (SELECT id FROM menus WHERE name = 'zeleninové menu') ),
  ( (SELECT id FROM meals WHERE name = 'pečené brambory'), (SELECT id FROM menus WHERE name = 'zeleninové menu') ),
  ( (SELECT id FROM meals WHERE name = 'smetanová polévka'), (SELECT id FROM menus WHERE name = 'polední menu') ),
  ( (SELECT id FROM meals WHERE name = 'fazolový salát'), (SELECT id FROM menus WHERE name = 'polední menu') ),
  ( (SELECT id FROM meals WHERE name = 'guláš'), (SELECT id FROM menus WHERE name = 'polední menu') ),
  ( (SELECT id FROM meals WHERE name = 'voodoo překvapení'), (SELECT id FROM menus WHERE name = 'voodoo menu') ),
  ( (SELECT id FROM meals WHERE name = 'mrkvový salát'), (SELECT id FROM menus WHERE name = 'voodoo menu') ),
  ( (SELECT id FROM meals WHERE name = 'fazolový salát'), (SELECT id FROM menus WHERE name = 'malé menu') ),
  ( (SELECT id FROM meals WHERE name = 'zeleninová polévka'), (SELECT id FROM menus WHERE name = 'malé menu') ),
  ( (SELECT id FROM meals WHERE name = 'smetanová polévka'), (SELECT id FROM menus WHERE name = 'smetanové menu') ),
  ( (SELECT id FROM meals WHERE name = 'pečené brambory'), (SELECT id FROM menus WHERE name = 'smetanové menu') );

INSERT INTO pages(title, url, body) VALUES
  ('Úvod', 'uvod', '<p>Vítejte!</p>');

INSERT INTO scheduled_meals(meal_id, scheduled_for, amount) VALUES
  ( (SELECT id FROM meals WHERE name = 'pečené brambory'), (current_date + 1), 20 ),
  ( (SELECT id FROM meals WHERE name = 'voodoo překvapení'), (current_date + 2), 35 ),
  ( (SELECT id FROM meals WHERE name = 'pečené brambory'), (current_date + 3), 25 ),
  ( (SELECT id FROM meals WHERE name = 'mrkvový salát'), (current_date + 3), 20 ),
  ( (SELECT id FROM meals WHERE name = 'guláš'), (current_date + 5), 25 ),
  ( (SELECT id FROM meals WHERE name = 'pečené brambory'), (current_date + 8), 30 ),
  ( (SELECT id FROM meals WHERE name = 'fazolový salát'), (current_date + 8), 15 ),
  ( (SELECT id FROM meals WHERE name = 'guláš'), (current_date + 30), 20 ),
  ( (SELECT id FROM meals WHERE name = 'voodoo překvapení'), (current_date), 20 ),
  ( (SELECT id FROM meals WHERE name = 'mrkvový salát'), (current_date - 2), 20 );

INSERT INTO scheduled_menus(menu_id, scheduled_for, amount) VALUES
  ( (SELECT id FROM menus WHERE name = 'polední menu'), (current_date + 1), 15 ),
  ( (SELECT id FROM menus WHERE name = 'zeleninové menu'), (current_date + 2), 20 ),
  ( (SELECT id FROM menus WHERE name = 'malé menu'), (current_date + 3), 15 ),
  ( (SELECT id FROM menus WHERE name = 'voodoo menu'), (current_date + 5), 25 ),
  ( (SELECT id FROM menus WHERE name = 'polední menu'), (current_date + 6), 30 );

INSERT INTO scheduled_bundles(bundle_id, scheduled_for) VALUES
  ( (SELECT id FROM bundles WHERE name = 'mrkvový salát double'), (current_date - 2)),
  ( (SELECT id FROM bundles WHERE name = 'mrkvový salát double'), (current_date + 3)),
  ( (SELECT id FROM bundles WHERE name = 'fazolový salát trio'), (current_date + 8));

INSERT INTO orders(user_id, deliver_at, state, cancelled) VALUES
  ( (SELECT id FROM users WHERE login = 'pepa'), (current_date + 1), 'order', false),
  ( (SELECT id FROM users WHERE login = 'pepa'), (current_date + 3), 'expedited', false),
  ( (SELECT id FROM users WHERE login = 'honza'), (current_date + 1), 'basket', false),
  ( (SELECT id FROM users WHERE login = 'honza'), (current_date + 2), 'order', false),
  ( (SELECT id FROM users WHERE login = 'anicka'), (current_date + 3), 'closed', true);

INSERT INTO ordered_items(item_id, order_id, amount) VALUES
  (
      (SELECT item_id FROM items WHERE name = 'polední menu'),
      (SELECT id FROM orders WHERE deliver_at = current_date + 1 AND user_id = (SELECT id FROM users WHERE login = 'pepa')),
      2
  ),
  (
      (SELECT item_id FROM items WHERE name = 'malé menu'),
      (SELECT id FROM orders WHERE deliver_at = current_date + 3 AND user_id = (SELECT id FROM users WHERE login = 'pepa')),
      1
  ),
  (
      (SELECT item_id FROM items WHERE name = 'pečené brambory'),
      (SELECT id FROM orders WHERE deliver_at = current_date + 3 AND user_id = (SELECT id FROM users WHERE login = 'pepa')),
      1
  ),
  (
      (SELECT item_id FROM items WHERE name = 'pečené brambory'),
      (SELECT id FROM orders WHERE deliver_at = current_date + 1 AND user_id = (SELECT id FROM users WHERE login = 'honza')),
      3
  ),
  (
      (SELECT item_id FROM items WHERE name = 'zeleninové menu'),
      (SELECT id FROM orders WHERE deliver_at = current_date + 2 AND user_id = (SELECT id FROM users WHERE login = 'honza')),
      2
  ),
  (
      (SELECT item_id FROM items WHERE name = 'malé menu'),
      (SELECT id FROM orders WHERE deliver_at = current_date + 3 AND user_id = (SELECT id FROM users WHERE login = 'anicka')),
      1
  ),
  (
      (SELECT item_id FROM items WHERE name = 'mrkvový salát'),
      (SELECT id FROM orders WHERE deliver_at = current_date + 3 AND user_id = (SELECT id FROM users WHERE login = 'anicka')),
      1
  );
  
INSERT INTO user_discounts(user_id, amount, start_at, expire_at, discount_class, name) VALUES
   ( (SELECT id FROM users WHERE login = 'admin'), 0.1, current_date, NULL, 'meal', 'sleva za prodeje' ),
   ( (SELECT id FROM users WHERE login = 'pepa'), 0.05, (current_date + 2 ), NULL, 'product', 'sleva ze znamosti' ),
   ( (SELECT id FROM users WHERE login = 'pepa'), 0.15, (current_date + 1 ), NULL, 'meal', 'sleva za obrat' );

INSERT INTO item_discounts(item_id, amount, start_at, expire_at, name) VALUES
  ( (SELECT item_id FROM items WHERE name = 'polední menu'), 0.15, current_date, (current_date + 5) , 'doprodej poledniho menu');
  
-- MAIL

INSERT INTO mail_mailboxes(address, human_name, imap_server, imap_login, imap_password) VALUES 
  ('info@example.com', 'Info', 'mail.example.com', 'info@example.com', 'password'),
  ('objednavky@example.com', 'Objednávky', 'mail.example.com', 'objednavky@example.com', 'password');
  
INSERT INTO mail_conversations(mailbox_id, tracker, note) VALUES
  ((SELECT mailbox_id FROM mail_mailboxes WHERE address = 'info@example.com'), 'a1d5e87a43', 'Retard...'),
  ((SELECT mailbox_id FROM mail_mailboxes WHERE address = 'objednavky@example.com'), 'ds5s54ee54', ''),
  ((SELECT mailbox_id FROM mail_mailboxes WHERE address = 'objednavky@example.com'), 'qwea74qew8', 'Neni trochu drzej??');
  
INSERT INTO mail_messages(imap_id, conversation_id, from_address, from_name, to_address, subject, body, flag_new, direction, created_at) VALUES
   (1000, (SELECT conversation_id FROM mail_conversations WHERE tracker = 'a1d5e87a43'), 'pepa@pepa.cz', 'Pepa Lehanka', 'info@example.com', 'Otevírací doba', 'Jak máte otevřeno?', false, 'recieved', (current_timestamp - INTERVAL '5 hours')),
   (1005, (SELECT conversation_id FROM mail_conversations WHERE tracker = 'a1d5e87a43'), 'info@example.com', 'Info', 'pepa@pepa.cz', 'Otevírací doba', 'Ve všední dny...', false, 'sent', current_timestamp - INTERVAL '4 hours'),
   (1015, (SELECT conversation_id FROM mail_conversations WHERE tracker = 'a1d5e87a43'), 'pepa@pepa.cz', 'Pepa Lehanka', 'info@example.com', 'Otevírací doba', 'A od kdy do kdy?', true, 'recieved', current_timestamp - INTERVAL '3 hours'),
   
   (1010, (SELECT conversation_id FROM mail_conversations WHERE tracker = 'ds5s54ee54'), 'anyone@example.com', 'Anyone', 'objednavky@example.com', 'Jídloooo', 'Mám hlad, přivezte cokoliv!', true, 'recieved', current_timestamp - INTERVAL '210 minutes'),
   
   (1020, (SELECT conversation_id FROM mail_conversations WHERE tracker = 'qwea74qew8'), 'johndoe@example.com', NULL, 'objednavky@example.com', 'Maso?', 'Děláte i něco s masem?', false, 'recieved', current_timestamp - INTERVAL '3 hours'),
   (1025, (SELECT conversation_id FROM mail_conversations WHERE tracker = 'qwea74qew8'), 'objednavky@example.com', 'Objednávky', 'johndoe@example.com', 'Maso?', 'NIKDY!!!', false, 'sent', current_timestamp - INTERVAL '2 hours');