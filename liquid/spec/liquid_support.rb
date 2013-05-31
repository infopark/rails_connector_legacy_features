# Folgende Helper-Methoden sind für Liquid-Specs gedacht
class ActionViewTest < ActionView::Base
  include CmsHelper
  include CmsRoutingHelper

  def initialize(obj)
    @obj = obj
  end

  # Stub an empty session
  def session
    {}
  end

  def logger
    Logger.new(STDOUT)
  end

  def compile_and_render(template)
    eval(RailsConnector::LiquidSupport::LiquidTemplateHandler.call(template))
  end

  def config
    ActionController::Base.config
  end
end

def initialize_action_view_and_obj
  @obj = Obj.new
  @obj.stub(:obj_class).and_return('Publication')
  @action_view = ActionViewTest.new(@obj)
  @action_view.controller = mock
  RailsConnector::LiquidSupport::LiquidTemplateRepository.drop_all
end

def mock_template(source, path = "foo_path")
  mock(ActionView::Template, {
    :path => path,
    :source => source,
  })
end

def render_liquid(source)
  @action_view.compile_and_render(mock_template(source))
end
