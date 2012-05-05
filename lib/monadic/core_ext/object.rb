class Object
  def _?
    Maybe(self).fetch(nil)
  end
end
