class Mailer < ActionMailer::Base
  helper :application
  helper {def locales; I18n.locales; end}
  helper {def snippet(name); unless(s = Snippet.find_by_name(name)).blank?; s.content; else; Snippet.create(:content => ""){|s| s.name = name}.content; end; end}
  
  def tomorrow_menu(user, menus, categories, options ={} )
      @recipients   = user.email
      @from         = "noreply@zelenakuchyne.cz"
      @subject      = "Zítřejší menu"
      @sent_on      = Time.now
      @content_type = "text/html"

      body[:name]  = user.name
      body[:menus] = menus
      body[:categories]  = categories
      body[:date]  = Date.tomorrow
      body[:user]  = user 
      body[:currency_template] = options[:currency_template]
    end
    
  def forgotten_password(user)
    @recipients   = user.email
    @from         = "Zelená kuchyně <noreply@zelenakuchyne.cz>"
    @subject      = "Zapomenuté heslo"
    @sent_on      = Time.now
    @content_type = "text/html"

    body[:user]   = user
  end
  
  def changed_login(email, new, original)
    @recipients   = email
    @from         = "objednavky@zelenakuchyne.cz"
    @subject      = "Váš účet na Zelenakuchyne.cz"
    @sent_on      = Time.now
    @content_type = "text/plain"
    
    body[:email]  = email
    body[:new]    = new
    body[:original] = original
  end
  
  def order_submitted(user, order)
    @recipients   = user.email
    @from         = "Zelená kuchyně <objednavky@zelenakuchyne.cz>"
    @bcc          = "objednavky@zelenakuchyne.cz"
    @subject      = "Objednávka ze ZelenaKuchyne.cz"
    @sent_on      = Time.now
    @content_type = "text/html"
    
    body[:order]  = order
    body[:address]= user.delivery_address
    body[:user]   = user
  end
  
  def echosdb(email)
    @recipients   = email
    @from         = "objednavky@zelenakuchyne.cz"
    @subject      = "Pátky v restauraci Zelená kuchyně"
    @sent_on      = Time.now
    @content_type = "text/html"
  end  
end
