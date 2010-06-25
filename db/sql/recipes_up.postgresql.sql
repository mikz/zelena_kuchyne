-- binds meals to ingredients, and adds information on the amount of each ingredient
CREATE TABLE recipes (
  id              serial NOT NULL UNIQUE, --activerecord needs this
  amount          float NOT NULL CHECK(amount > 0),
  ingredient_id   integer NOT NULL REFERENCES ingredients (id),
  meal_id         integer NOT NULL REFERENCES meals (id) ON DELETE CASCADE,
  PRIMARY KEY (ingredient_id, meal_id)
);