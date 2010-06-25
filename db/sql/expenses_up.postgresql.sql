CREATE TYPE expense_type AS ENUM ('investment', 'other');
CREATE TYPE expense_owner AS ENUM ('delivery', 'restaurant', 'office');

CREATE TABLE expenses(
  id            serial PRIMARY KEY,
  name          varchar(100) NOT NULL,
  price         float NOT NULL,
  user_id       integer REFERENCES users(id) ON DELETE RESTRICT NOT NULL ,
  bought_at     timestamp NOT NULL,
  expense_category_id integer REFERENCES expense_categories(id) ON DELETE RESTRICT NOT NULL,
  expense_owner expense_owner NOT NULL CHECK(expense_owner != 'restaurant' AND premise_id IS NULL OR expense_owner = 'restaurant'),
  premise_id    integer REFERENCES premises(id) ON DELETE RESTRICT CHECK(expense_owner = 'restaurant' AND  premise_id IS NOT NULL OR expense_owner != 'restaurant'),
  note          varchar(100),
  created_at    timestamp NOT NULL DEFAULT NOW(),
  updated_at    timestamp NOT NULL DEFAULT NOW(),
  updated_by    integer REFERENCES users(id)
);