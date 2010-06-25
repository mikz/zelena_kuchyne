-- this is kind of a tricky part: the items table stores meals, menus, and products through the mechanism of table inheritance
-- this means, among other things, that menus, meals and products all have a unique item_id that they can be referenced by
-- without neccesarilly having knowledge on _what_ you're referencing, other than the fact that it's in one of those three tables
-- There were two reasons for this design decision:
-- 1) I wanted to try a cool new feature in Postgres (well, it's new to me, anyway)
-- 2) It allows us to easily attach items to things like orders and such, and since they all share columns like name and price, we're not really missing any important data
CREATE TYPE item_type AS ENUM ('meal', 'product', 'bundle', 'menu');
CREATE TABLE items (
  item_id     serial PRIMARY KEY,
  price       float NOT NULL,
  name        varchar(100) NOT NULL CHECK(length(name) > 1),
  item_type   item_type NOT NULL,
  created_at  timestamp DEFAULT current_timestamp,
  updated_at  timestamp DEFAULT current_timestamp,
  updated_by  integer REFERENCES users(id) ON DELETE SET NULL,
  image_flag  boolean NOT NULL DEFAULT false
);
