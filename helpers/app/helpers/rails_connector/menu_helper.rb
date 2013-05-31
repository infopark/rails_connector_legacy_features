module RailsConnector

  # This module contains helpers that can be used to build all kinds of menus.
  # @api public
  module MenuHelper
    include DisplayHelper

    # The <tt>build_menu</tt> method should serve as an example of how to build navigational
    # menus using Infopark Rails Connector. If you need to extend this method, copy it into
    # the relevant helper for your application.
    #
    # Example 1 - Single-tier menu:
    #
    #   build_menu(Obj.find(123), nil, :id => "menu")
    #
    # produces:
    #
    #   <ul id="menu">
    #     <li>
    #       <a href="path/to/history">History</a>
    #     </li>
    #     <li>
    #       <a href="path/to/services">Services</a>
    #     </li>
    #   </ul>
    #
    # <tt>build_menu</tt> also takes a block so you can use it recursively for multiple levels
    # (<tt>current_page</tt> returns the Obj for "Insurance" in this example):
    #
    # Example 2 - Two-tier Menu:
    #
    #   build_menu(Obj.find(123), current_page, :id => "main_menu") do |entry|
    #     build_menu(entry, current_page, :id => "sub_menu")
    #   end
    #
    # produces:
    #
    #   <ul id="main_menu">
    #     <li>
    #       <a href="path/to/history">History</a>
    #     </li>
    #     <li>
    #       <a href="path/to/products">Services</a>
    #       <ul id="sub_menu">
    #         <li>
    #           <a href="path/to/products/insurance">Insurance</a>
    #         </li>
    #         <li>
    #           <a href="path/to/products/finance">Finance</a>
    #         </li>
    #       </ul>
    #     </li>
    #   </ul>
    #
    # @api public
    def build_menu(start_obj, current_obj, html_options, &block)
      children = table_of_contents(start_obj)
      content_tag(:ul, html_options) do
        content = "".html_safe
        children.each do |child|
          content << content_tag(:li) do
            list_entry = link_to(child.display_title, cms_path(child))
            list_entry += block.call(child) if block_given? && current_obj &&
              (current_obj == child || current_obj.ancestors.include?(child))
            list_entry
          end
        end
        content
      end
    end
  end

end
