class Obj < RailsConnector::BasicObj

  def to_liquid
    LiquidSupport::ObjDrop.new(self)
  end

end
