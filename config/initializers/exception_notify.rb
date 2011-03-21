if defined? ExceptionNotification
  ExceptionNotification::Notifier.sender_address =%("Zelená kuchyně" <error@zelenakuchyne.cz>)
  ExceptionNotification::Notifier.email_prefix = "[ZelenáKuchyně] [ERROR] "
  ExceptionNotification::Notifier.exception_recipients = %w(michal.cichra@gmail.com)
end