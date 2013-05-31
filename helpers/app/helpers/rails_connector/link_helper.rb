require "uri"

module RailsConnector

  # This module contains a helper that can be used to build markup for a link, e.g. a download link.
  # @api public
  module LinkHelper
    # Generates a link by producing the corresponding HTML markup.
    # <em>link</em> is the Link to be rendered, you may specify the following <em>options</em>:
    #
    # [:file_extension] specifies the file extension if the link object is an internal link.
    # An external link has no file extension since there is no destination object from which
    # the file extension could be taken. File extensions are, for example, 'pdf', 'zip', or 'doc'.
    #
    # The HTML text generated depends on the kind of Link passed to the helper:
    #
    #   <%= link(@myLinkObject) %>
    #
    # [With an internal Link] The helper will produce the following HTML where path is
    # the path created by the PageHelper, file extension is the file_extension of the
    # destination object. For a Content, the display title is the Link's display_title and
    # size is the size of its body (in KB or MB):
    #   <a href='path' class='link'>
    #     <span class='file extension'>
    #     display title
    #     <span class='link_size'> (size)</span>
    #     </span>
    #   </a></tt>
    #
    # [With an external Link] The helper will produce the following HTML where url
    # is the external url of the link and display title is the display_title of the Link:
    #
    #   <a class='link' href='url'>
    #     <span>display title</span>
    #   </a>
    #
    # Normally, you do not know the file extension of the external source, so by default
    # there will be no CSS class generated for the nested <tt><span></tt> tag. In the case
    # that you do know it or want some external links to have a special style, you can
    # specify the file extension with the :file_extension option:
    #
    #   <%= link(@myLinkObject, :file_extension => 'file_extension' %>
    #
    # The helper would then produce the following:
    #
    #   <a class='link' href='destination'>
    #     <span class='file_extension'>title</span>
    #   </a>
    # @api public
    def link(link, options = {})
      link_attributes = {
        :href => cms_path(link),
        :class => 'link'
      }
      link_attributes[:target] = link.target unless link.target.blank?
      content_tag(:a,
        content_tag(:span,
          display_value(link.display_title) + size_content(link),
          :class => options[:file_extension] || link.file_extension
        ),
        link_attributes
      )
    end

    # Displays a link list as an HTML list.
    # <em>link_list</em> is the link list to be rendered. For each link #link is called.
    # For a list of valid <em>options</em> see #link.
    #
    # The generated list element has the CSS class 'linklist'.
    # @api public
    def link_list(link_list, options = {})
      return if link_list.blank?
      markup = "<ul class='linklist'>"
      link_list.each do |l|
        markup << "<li>#{link l, options}</li>"
      end
      markup << "</ul>"

      markup.html_safe
    end

    private

    def size_content(link)
      return "" unless link.internal? && link.destination_object && link.destination_object.binary?
      size = ' (' + number_to_human_size(link.destination_object.body_length) + ')'
      content_tag(:span, size, :class => 'link_size')
    end

    include DisplayHelper
  end

end
