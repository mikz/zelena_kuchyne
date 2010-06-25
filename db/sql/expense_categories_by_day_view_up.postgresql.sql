CREATE VIEW expense_categories_by_day_view AS SELECT
  expense_categories.*,
  expenses.expense_owner,
  SUM(expenses.price) AS cost,
  expenses.bought_at::date AS date
  FROM expense_categories
  LEFT JOIN expenses ON expenses.expense_category_id = expense_categories.id
  GROUP BY expense_categories.id, expense_categories.name, expense_categories.description, expenses.expense_owner, date;