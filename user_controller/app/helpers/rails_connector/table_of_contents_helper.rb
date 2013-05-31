module RailsConnector

  #
  # This module contains a helper that can be used to build a table of contents of an object.
  #
  # @api public
  module TableOfContentsHelper

    #
    # The <tt>table_of_contents</tt> helper method gets an object as argument and returns an array,
    # which can be used as the table of contents of the given object.
    #
    # The returned array consists of the child objects of the given object.
    # The array is sorted according to the configured sort order and the sort keys.
    # It also contains only objects which the current user is permitted to view.
    #
    # @api public
    def table_of_contents(obj)
      obj.sorted_toclist.reject { |o| not o.permitted_for_user?(current_user) }
    end
  end
end
