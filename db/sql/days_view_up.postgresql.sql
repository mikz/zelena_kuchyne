-- this view lists all dates that have any meals OR menus scheduled for them
CREATE VIEW days_view AS
SELECT DISTINCT COALESCE(scheduled_for, lost_at)::date as scheduled_for
   FROM scheduled_meals
   NATURAL FULL JOIN scheduled_menus
   NATURAL FULL JOIN lost_items
   WHERE COALESCE(invisible,false) = false
ORDER BY scheduled_for;