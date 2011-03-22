if defined? ExceptionNotification
  ExceptionNotification::Notifier.sender_address =%("Zelená kuchyně" <error@zelenakuchyne.cz>)
  ExceptionNotification::Notifier.email_prefix = "[ZelenáKuchyně] [ERROR] "
  ExceptionNotification::Notifier.exception_recipients = %w(service@o2h.cz)
end