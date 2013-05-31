module RailsConnector
  # This module is included if the <tt>:comments</tt> addon is
  # enabled:
  #     RailsConnector::Configuration.enable(:comments)
  module Commentable
    # returns all Comments for this Obj.
    def comments
      Comment.where(:obj_id => id).order("created_at")
    end

    # Returns +true+ by default.
    # Implement your own conditions by overwriting this method in your {Obj}.
    def allow_comments?
      true
    end

    # Returns +true+ by default.
    # Implement your own conditions by overwriting this method in your {Obj}.
    def allow_anonymous_comments?
      true
    end
  end
end
