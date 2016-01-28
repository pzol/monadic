class Object
  def _?
    Maybe(self).fetch(Nothing)
  end
end
