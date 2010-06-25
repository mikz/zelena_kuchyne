CREATE VIEW summary_view AS SELECT
  * 
  FROM get_summary_between(current_date,current_date);