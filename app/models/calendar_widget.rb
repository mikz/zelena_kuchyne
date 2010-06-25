class CalendarWidget
  def self.parse param
    dates = [Date.today, Date.today]
    if param and param != ""
      if param.include?(';')
        dates = param.split(';')
        dates.reverse! if dates[0] > dates[1]
      else
        if param.is_a? Array
          dates = param
        else
          dates = [param, param]
        end
      end
    end
    dates
  end
end