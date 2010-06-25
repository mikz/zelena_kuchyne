class CreateSummaries < ActiveRecord::Migration
  def self.up
    sql_script 'summaries_functions_up'
    sql_script 'summary_view_up'
    
  end

  def self.down
    sql_script 'summary_view_down'
    sql_script 'summaries_functions_down'
  end
end
