INSERT INTO groups(title, system_name) VALUES
  ('admins', 'admins'),
  ('customers', 'customers'),
  ('delivery men', 'deliverymen'),
  ('warehousers', 'warehousers'),
  ('heads of car pool','heads_of_car_pool'),
  ('operating officers','operating_officers'),
  ('chefs','chefs');

UPDATE groups SET default_group = true WHERE system_name = 'customers';

INSERT INTO user_profile_types(name, data_type, visible, editable, required) VALUES
  ('pagination_setting', 'hidden', false, false, false),
  ('interface_language', 'hidden', false, false, false),
  ('first_name', 'text_field', true, true, true),
  ('family_name', 'text_field', true, true, true),
  ('phone_number', 'text_field', true, true, true),
  ('company_name', 'text_field', true, true, false),
  ('company_registration_no', 'text_field', true, true, false),
  ('company_tax_no', 'text_field', true, true, false),
  ('phone_number_country_code', 'text_field', true, true, true),
  ('tomorrow_menu_by_mail', 'checkbox', true, true, false),
  ('delivery_man_color', 'text_field', false, true, false),
  ('admin_note', 'text_field', false, true, false);

INSERT INTO item_profile_types (name, data_type) VALUES
  ('description', 'text_area'),
  ('recipe',  'text_area');

INSERT INTO snippets (name, content, cachable_flag) VALUES
  ('user_agreement','Podmínky použití jsou následující:',true),
  ('footer','<p>Copyright © 2005 - 2007 <a href="/">Zelenakuchyne.cz</a> | <a href="/kontakt">Kontakt</a> | XHTML 1.0 Strict</p>',true),
  ('unavailable_menu','<p>Nabídka pro tento den, již není dostupná.</p>',true),
  ('no_scheduled_meals', '<p>Na tento den nemáme napánovaná žádná jídla.</p>', true),
  ('e_error', '<p>Při zpracování požadavku zjevně nastala chyba a s tím se očividně nepočítalo, což z ní asi dělá neočekávanou chybu. A proto jste teď tady a ne tam, kde jste chtěli být.</p>', true),
  ('e_unknown_action', '<p>Zdá se, že jste na špatné adrese, zkuste to jinudy.</p>', true),
  ('e_record_not_found', '<p>Každý dneska něco hledá... a někdo má holt smůlu.</p>', true),
  ('e_access_denied', '<p>Jen si dělám srandu, přístup je samozřejmě odepřen. A teď přišla chvíle hezky <em>pomalu</em> a bez prudkých pohybů kliknout na tlačítko Zpět... Nebo se zkusit přihlásit.</p>', true),
  ('e_login_required', '<p>Pro přístup sem se musíte přihlásit.</p>', true),
  ('welcome', '<p>Jsme vegetari&aacute;nsk&aacute; restaurace připravuj&iacute;c&iacute; pro v&aacute;s každ&yacute; den dobroty z čerstv&eacute; zeleniny, ovoce, obilovin, lu&scaron;těnin, ml&eacute;ka, oř&iacute;&scaron;ků, kořen&iacute;, bylinek, medu a dal&scaron;&iacute;ch lahodn&yacute;ch př&iacute;sad. Vaj&iacute;čka či drožd&iacute; v&scaron;ak v na&scaron;ich pokrmech budete hledat marně. Suroviny pro v&aacute;s nakupujeme na farm&aacute;ch či ve specializovan&yacute;ch obchodech, co možn&aacute; nejv&iacute;ce se snaž&iacute;me podporovat dom&aacute;c&iacute; produkci. Vyberte si, na co m&aacute;te chuť, v na&scaron;em <a href="/menu">dne&scaron;n&iacute;m menu</a>.</p><p>Je-li pro v&aacute;s Žižkov poněkud z ruky, nezoufejte. Již od roku 2005 rozv&aacute;ž&iacute;me j&iacute;dla až k v&aacute;m domů nebo do pr&aacute;ce ve v&aacute;mi zvolen&eacute;m čase. Pro v&iacute;ce informac&iacute; se pod&iacute;vejte do sekce <a href="/rozvoz-jidel">Rozvoz</a>.</p>', true),
  ('forgotten_password_dialog', '<p>Zadejte va&scaron;e uživatelsk&eacute; jm&eacute;no nebo email, uveden&yacute; při registraci, a dal&scaron;&iacute; instrukce V&aacute;m za&scaron;leme emailem.</p>', true),
  ('opening_hours', 'Po&nbsp;&ndash;&nbsp;P&aacute;:&nbsp;11:00&nbsp;&ndash;&nbsp;22:00', true),
  ('tomorrow_menu_mail_header', '<p>Dobr&yacute; den,<br />r&aacute;di bychom V&aacute;s informovali o tom, co budeme z&iacute;tra vařit:</p>', true),
  ('restaurant_vcard', '<p class="vcard"><span class="fn org">Restaurace <strong>Zelen&aacute; kuchyně</strong></span><br /><span class="adr"><strong class="street-address">Mil&iacute;čova 5</strong>,           <span class="locality">Praha 3&ndash;Žižkov</span>, <span class="postal-code">130 00</span></span></p>', true),
  ('delivery_vcard', '<p class="vcard"><span class="fn org"><strong>Zelen&aacute; kuchyně</strong>, spol. s.r.o.</span><br /><span class="adr"><strong class="street-address">Pod vilami 857/9</strong>, <span class="locality">Praha 4</span>, <span class="postal-code">140 00</span></span><br />IČ: 27369404</p><p><small>(objedn&aacute;vky, rezervace)</small><br />E: <a href="mailto:objednavky@zelenakuchyne.cz">objednavky@zelenakuchyne.cz</a><br />&nbsp;</p><p>T: <strong>+420&nbsp;222&nbsp;220&nbsp;114</strong><br />E: <a href="mailto:info@zelenakuchyne.cz">info@zelenakuchyne.cz</a></p>', true),
  ('report_error', '<p>Pokud jste přesvědčeni, že někdo něco zeslonil na naší straně, bez váhání a rozpaků si postěžujte <a href="mailto:admin@zelenakuchyne.cz">administrátorovi</a>.</p>', true);

INSERT INTO delivery_methods(name, price, minimal_order_price, flag_has_delivery_man) VALUES
  ('naším rozvozcem', 50, 0, true),
  ('naším rozvozcem zdarma', 0, 200, true);
 
INSERT INTO meal_flags(name,description,icon_path) VALUES
  ('nejprodávanější','jedno z nejoblíbenějších jídel','/images/icon_star.png'),
  ('bez lepku','jídlo neobsahuje lepek','/images/icon_no_cereals.png'),
  ('bez mléka','jídlo neobsahuje mléčné výrobky','/images/icon_no_milk.png'),
  ('ostré','jídlo je ostré','/images/icon_hot.png'),
  ('novinka','toto jídlo je novinka','/images/icon_new.png');

INSERT INTO pages(url, title, body) VALUES
  ('zapomenute_heslo_odeslano','Zapomenuté heslo','<p>Zaslali jsme instrukce na Váš mail, uvedený při registraci.');

 INSERT INTO expense_categories(name) VALUES
  ('vybavení kuchyně'),
  ('vybavení restaurace'),
  ('spotřební materiál'),
  ('potraviny'),
  ('hygiena'),
  ('další');