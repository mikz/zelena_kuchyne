CREATE VIEW poll_answers_view AS SELECT
  poll_answers.*,
  COUNT(poll_answer_id) AS votes,
  total_votes.count AS total_votes,
  (count(poll_answer_id)::float / total_votes.count::float)*100 AS percent
  FROM poll_answers
  LEFT JOIN poll_votes on poll_answers.id = poll_votes.poll_answer_id
  LEFT JOIN (
    SELECT poll_id, COUNT(poll_id) FROM poll_votes
      LEFT JOIN poll_answers ON poll_answers.id = poll_votes.poll_answer_id
    GROUP BY poll_answers.poll_id
  ) AS total_votes ON poll_answers.poll_id = total_votes.poll_id
  GROUP BY poll_answers.id, poll_answers.poll_id, text, total_votes.count;
