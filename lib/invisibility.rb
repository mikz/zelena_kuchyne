module Invisibility

  def visible
    not invisible
  end

  def visible= val
    self.invisible = !val
  end

end
