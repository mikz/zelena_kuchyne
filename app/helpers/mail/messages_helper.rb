module Mail::MessagesHelper

  def format_reply(message)
    reply = "\n\n\n#{format_date(message.created_at)} #{format_time(message.created_at)} <#{message.from_address}>\n"
    reply += message.body.split(/\n/).collect {|l| "> #{l}"}.join("\n")
  
  end
end
