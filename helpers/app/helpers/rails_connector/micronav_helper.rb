module RailsConnector

  # This module contains a helper that can be used to build a micronavigation.
  # @api public
  module MicronavHelper

    # Generates a micronavigation by producing HTML markup.
    # <em>obj</em> becomes the rightmost Obj in the micronavigation since it is the one
    # for which the micronavigation is built. Assume that all the ancestors of this obj are
    # available as an array starting with the root object at index 1.
    # The following <em>options</em> exist:
    #
    # [:start] index of the ancestor object to start with. Default is 1, i.e. the object Obj::root.
    # [:micronav_id] ID of the micronavigation. Default is 'micronav'.
    #
    # All ancestors of <em>obj</em> are linked to the respective objects. <em>obj</em>
    # has no linkage. The first and the last <tt><li></tt> tags have apropriate CSS classes.
    #
    # For example, assume that you have the following object hierarchy:
    #
    # * Root
    #   * Ancestor_1
    #     * Ancestor_2
    #       * Current_Object
    #
    # Normal usage with the context Obj set to <tt>@obj</tt>:
    #
    #   <%= micronav(@obj) %>
    #
    # The helper will start with the Root and will generate the follwing HTML if <tt>@obj</tt> is set to Current_Object:
    #
    #   <ul id='micronav'>
    #     <li class='first'>
    #       <a href='/2001/Root'>
    #         Root
    #       </a>
    #     </li>
    #     <li>
    #       <a href='/2011/Ancestor_1'>
    #         Ancestor_1
    #       </a>
    #     </li>
    #     <li>
    #       <a href='/2012/Ancestor_2'>
    #         Ancestor_2
    #       </a>
    #     </li>
    #     <li class='last'>
    #       <span>
    #         Current_Object
    #       </span>
    #     </li>
    #   </ul>
    #
    # If the <tt>:start</tt> option is set to 2
    #
    #   <%= micronav(@obj, :start => 2) %>
    #
    # then the helper will start with Ancestor_1 and will generate:
    #
    #   <ul id='micronav'>
    #     <li class='first'>
    #       <a href='/2011/Ancestor_1'>
    #         Ancestor_1
    #       </a>
    #     </li>
    #     <li>
    #       <a href='/2012/Ancestor_2'>
    #         Ancestor_2
    #       </a>
    #     </li>
    #     <li class='last'>
    #       <span>
    #         Current_Object
    #       </span>
    #     </li>
    #   </ul>
    #
    # If you specify the <tt>:micronav_id</tt> option as in
    #
    #   <%= micronav(@obj, :micronav_id => '<em><b>micronav_below_banner</b></em>') %>
    #
    # then the <tt><ul></tt> tag of the micronavigation will get your custom ID:
    #
    #   <ul id='<em><b>micronav_below_banner</b></em>'></tt>
    #     ...
    #   </ul>
    # @api public
    def micronav(obj, options = {})
      options.reverse_merge!({:start => 1, :micronav_id => 'micronav'})
      ancestors = obj.ancestors
      start = options[:start] - 1
      start = 0 if start < 0
      ancestors = ancestors[start..-1]
      ancestors ||= []
      li_tags = "".html_safe
      ancestors.each do |ancestor|
        tag_options = {}
        tag_options[:class] = "first" if li_tags.empty?
        li_tags << content_tag(:li, link_to(display_value(ancestor.display_title), cms_path(ancestor)), tag_options)
      end
      li_tags << content_tag(:li, content_tag(:span, display_value(obj.display_title)), :class => 'last')
      content_tag(:ul, li_tags, :id => options[:micronav_id])
    end

    include DisplayHelper
  end

end
