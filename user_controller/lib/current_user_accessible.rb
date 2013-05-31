module CurrentUserAccessible

  # Filter method to check if access to the loaded object is permitted. If it is
  # not, a 403 Forbidden error message will be generated (by calling render_obj_error)
  #
  # To require the check for all actions, use this in your controllers:
  #   before_filter :load_object
  #   before_filter :ensure_object_is_permitted
  def ensure_object_is_permitted
    unless is_permitted(@obj)
      @obj = nil
      render_obj_error(403, "forbidden")
      return false
    end
    return true
  end

  # Inclusion hook to make is_permitted available as helper method.
  def self.included(base)
    base.__send__ :helper_method, :is_permitted
  end

  # Helper method to check live permissions
  def is_permitted(obj)
    obj.permitted_for_user?(current_user)
  end

  # This method is called when rendering an error caused by either {ensure_object_is_permitted}
  # or {ensure_object_is_active} before filter. It renders an error template located in
  # "errors/*.html.erb" with given HTTP status and content type "text/html" and with no layout.
  # Overwrite this method to change the error page.
  # @api public
  def render_obj_error(status, name)
    force_html_format
    render(
      :template => "errors/#{status}_#{name}",
      :layout => false,
      :status => status,
      :content_type => Mime::HTML
    )
  end

  # Enforce "html" as template format.
  # @api public
  def force_html_format
    request.format = :html
  end
end
