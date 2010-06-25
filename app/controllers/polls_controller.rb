class PollsController < ApplicationController
  before_filter(:except => [:vote]) { |c| c.must_belong_to_one_of(:admins)}
  include_javascripts 'fullscreen'
  exposure({
    :title => {:name => "question"},
    :columns => [
      { :name => :answer_count},
      { :name => :active},
      { :name => :created_at, :options => {:formatter => "date_and_time"}}
    ],
    :include => [{:poll_answers => :poll_votes}]
  })
  
  
  
  def activate
    @record = Poll.find_by_id params[:id]
    @record.active = true
    @record.save
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html "record_#{@record.id}", :partial => "show", :locals => {:record => @record}
        end
      }
    end
  end
  
  def deactivate
    @record = Poll.find_by_id params[:id]
    @record.active = false
    @record.save
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html "record_#{@record.id}", :partial => "show", :locals => {:record => @record}
        end
      }
    end
  end
  
  def vote
    @poll = Poll.find_by_id params[:id]
    if !params[:poll] || !params[:poll]['vote']
      respond_to do |format|
        format.js {
          render :update do |page|
            page.visual_effect :fade, "poll_#{params[:id]}", :duration => 0.3
            page.delay 0.3 do
              page.replace_html "poll_#{params[:id]}", :partial => "polls/poll", :locals => {:message => locales[:cant_vote_blank], :poll => @poll, :error => true}
              page.visual_effect :appear, "poll_#{params[:id]}", :duration => 0.3
            end
          end
        }
        format.html {
          flash[:notice] = locales[:cant_vote_blank]
          redirect_to :back
        }
      end
      return
    end
    @poll_votes = params[:poll]['vote'].map do |vote|
      PollVote.new(:poll_answer_id => vote, :user_id => current_user.id)
    end
    
    #check if user can vote
    unless @poll.can_vote?(current_user)
      respond_to do |format|
        format.js {
          render :update do |page|
            page.visual_effect :fade, "poll_#{params[:id]}", :duration => 0.3
            page.delay 0.3 do
              page.replace_html "poll_#{params[:id]}", :partial => "polls/message", :locals => {:message => locales[:cant_vote_twice], :error => true}
              page.visual_effect :appear, "poll_#{params[:id]}", :duration => 0.3
            end
          end
        }
        format.html {
          flash[:notice] = locales[:cant_vote_twice]
          redirect_to :back
        }
      end
      return
    end
    #check if votes are valid
    @poll_votes.each do |vote|
      if (!vote.valid? || !vote.save)
        respond_to do |format|
          format.js {
            render :update do |page|
              page.visual_effect :fade, "poll_#{params[:id]}", :duration => 0.3
              page.delay 0.3 do
                page.replace_html "poll_#{params[:id]}", :partial => "polls/message", :locals => {:message => vote.errors.on_base, :error => true}
                page.visual_effect :appear, "poll_#{params[:id]}", :duration => 0.3
              end
            end
          }
          format.html {
            flash[:notice] = vote.errors.on_base
            redirect_to :back
          }
        end
        return
      end
    end
    #or finally render result
    respond_to do |format|
      format.js {
        render :update do |page|
          page.visual_effect :fade, "poll_#{params[:id]}", :duration => 0.3
          page.delay 0.3 do
            page.replace_html "poll_#{@poll.id}", :partial => "polls/result", :locals => {:message => locales[:thanks_for_voting], :poll => @poll }
            page.visual_effect :appear, "poll_#{params[:id]}", :duration => 0.3
          end
        end
      }
      format.html {
        flash[:notice] = locales[:thanks_for_voting]
        redirect_to :back
      }
    end
  end
end
