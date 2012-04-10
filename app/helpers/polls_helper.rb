# -*- encoding : utf-8 -*-
module PollsHelper
  def render_single_poll answer
    %{<input type="radio" name="poll[vote][]" id="poll_answer_#{answer.id}" value="#{answer.id}"/><label for="poll_answer_#{answer.id}">#{answer.text}</label>}
  end
  def render_multi_poll answer
    %{<input type="checkbox" name="poll[vote][]" id="poll_answer_#{answer.id}" value="#{answer.id}"/><label for="poll_answer_#{answer.id}">#{answer.text}</label>}
  end
end

