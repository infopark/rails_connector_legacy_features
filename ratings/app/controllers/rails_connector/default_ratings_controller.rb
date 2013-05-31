module RailsConnector
  #
  # This controller provides an interface for rating CMS objects.
  #
  # =Before Filters
  # <tt>load_object</tt>: finds the Obj instance using <tt>params[:obj_id]</tt>
  # <tt>ensure_object_is_rateable</tt>: renders nothing unless <tt>@obj.allow_rating?</tt> AND <tt>user_has_already_rated?(@obj.id)</tt> return <tt>true</tt>.
  #
  # =Hooks
  #
  # <tt>after_create</tt>: redefine this method in your application in order to specify additional functionality that should occur after a rating has been created.
  #
  # Example:
  #
  #   class RatingsController < RailsConnector::DefaultRatingsController
  #     private
  #     def after_create
  #       # * send an email
  #       # * create an inquiry in the OMC
  #     end
  #   end
  class DefaultRatingsController < ApplicationController

    before_filter :load_object
    before_filter :ensure_object_is_rateable, :only => [:rate]
    before_filter :ensure_admin, :only => :reset

    layout nil

    # Rate a CMS object.
    def rate
      respond_to do |format|
        format.html do
          score = params[:score].to_i
          if @obj.rate(score)
            store_rating_in_session(@obj.id, score)
            after_create
          end
          render :partial => "cms/rating"
        end
      end
    end

    # Reset rating for a CMS object.
    def reset
      respond_to do |format|
        format.html do
          @obj.reset_rating
          store_rating_in_session(@obj.id, nil)
          redirect_to :back
        end
      end
    end

    private

    def after_create;end

    def load_object
      @obj = Obj.find(params[:id])
    end

    def ensure_object_is_rateable
      render(:nothing => true) if (!@obj.allow_rating? || user_has_already_rated?(@obj.id))
      unless @obj.allow_anonymous_rating? or logged_in?
        render '/errors/403_forbidden', :status => 403
      end
    end

    def user_has_already_rated?(obj_id)
      session[:rated_objs] && session[:rated_objs][obj_id]
    end

    def store_rating_in_session(obj_id, score)
      session[:rated_objs] ||= {}
      session[:rated_objs][obj_id] = score
    end

    def ensure_admin
      render("errors/403_forbidden", :status => 403) unless admin?
    end
  end

end
