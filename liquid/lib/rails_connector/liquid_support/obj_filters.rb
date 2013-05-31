module RailsConnector::LiquidSupport

  # Filters in general are methods used in Liquid templates.
  # ObjFilters are filters specifically for dealing with CMS objects.
  module ObjFilters

    # Generates a link for the +target+.
    # +target+ can be an Obj, a Link or a Linklist.
    # If +target+ is a Linklist, the first element of the list will be used.
    #
    # Example:
    #   {{ "Click me" | link_to: obj }}
    #
    def link_to(a, b = nil)
      if b
        title = a || ""
        target =  b
      else
        target = a
      end
      target = first_link_if_linklist(target)
      if target
        action_view.link_to(title || target.display_title, drop_cms_path(target))
      end
    end

    # Generates an IMG tag for +target+.
    # +target+ can be an Obj, a Link or a Linklist.
    # If +target+ is a Linklist, the first element of the list will be used.
    #
    # Example:
    #   {{ @obj | image_tag }}
    def image_tag(target, title = nil)
      action_view.cms_image_tag(unwrap_drop(target), :alt => title)
    end

    # Generates the URL where +target+ can be reached.
    # +target+ can be an Obj, a Link or a Linklist.
    # If +target+ is a Linklist, the first element of the list will be used.
    #
    # Example:
    #   This document can be found at {{ obj | url }}
    def url(target)
      target = first_link_if_linklist(target)
      drop_cms_path(target) if target
    end

    # Generates an editmarker for +field_value_drop+
    def editmarker(field_value_drop, visible=true)
      drop = field_value_drop.dup
      drop.__marker = visible
      drop
    end

  private

    def drop_cms_path(possible_drop)
      action_view.cms_path(unwrap_drop(possible_drop))
    end

    def unwrap_drop(possible_drop)
      possible_drop.respond_to?(:__drop_content) ? possible_drop.__drop_content : possible_drop
    end

    def action_view
      @context.registers[:action_view]
    end

    def first_link_if_linklist(target)
      return target if target.is_a?(LinkDrop) || target.is_a?(ObjDrop)
      if target.respond_to?(:first)
        first_element = target.first.to_liquid
        return first_element if first_element.is_a?(LinkDrop)
      end
    end
  end
end