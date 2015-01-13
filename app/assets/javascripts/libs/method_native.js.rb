class Method

  def to_n
    return lambda { |*args| self.call(*args)}.to_n
  end

end