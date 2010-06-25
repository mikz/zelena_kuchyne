class IngredientsLogWatchdog < ActiveRecord::Base
  belongs_to :ingredient
  
  def self.operators
    [['e','='],['lt','<'],['gt','>'],['ltoe','<='],['gtoe','>='],['ne','!=']]
  end
  
  def operator
    case super
      when '100'
        '<'
      when '110'
        '<='
      when '010'
        '='
      when '011'
        '>='
      when '001'
        '>'
      when '000'
        '!='
    end
  end
  
  def operator=(op)
    self[:operator] = case op
      when '<'
        '100'
      when '<='
        '110'
      when '='
        '010'
      when '>='
        '011'
      when '>'
        '001'
      when '!='
        '101'
    end
  end
  
  def operator_readable
    self.class.operators.each {|o|
      return o.first if o.last == self.operator
    }
    return nil
  end
end