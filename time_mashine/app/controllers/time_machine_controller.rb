module RailsConnector

  class TimeMachineController < ApplicationController

    protect_from_forgery :except => :set_preview_time

    before_filter :only_available_in_editor_mode

    def index
      @language = params[:language] || 'de'
      @preview_time = session[:preview_time] || Time.now
    end

    # Set the preview time to the Time as specified by the parameter <tt>:preview_time</tt>.
    def set_preview_time
      if preview_time = params[:preview_time]
        pt = Time.from_iso(preview_time)
        pt = nil if pt <= Time.now
        handle_request pt
      end
    end

    # Resets the preview time, so <tt>Time::now</tt> will be used as preview time afterwards.
    def reset_preview_time
      handle_request nil
    end

  private

    def handle_request(preview_time)
      session[:preview_time] = preview_time
      if request.xhr?
        render :js => "window.location.reload();"
      else
        render :nothing => true
      end
    end

    def only_available_in_editor_mode
      unless Configuration.editor_interface_enabled?
        render :template => 'errors/403_forbidden', :status => 403, :content_type => Mime::HTML
        return false
      end
    end

  end

end