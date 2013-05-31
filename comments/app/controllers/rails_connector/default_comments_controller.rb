module RailsConnector
  #
  # This class provides a default controller implementation for comment creation.
  # It should only be used indirectly via a subclass named {CommentsController}.
  #
  # The controller actions only respond to XMLHttpRequests (Ajax).
  class DefaultCommentsController < ApplicationController
    layout nil

    before_filter :ensure_object_is_commentable, :only => :create
    before_filter :ensure_admin, :only => :delete

    #
    # Creates a comment and calls the +after_create+ callback.
    #
    def create
      respond_to do |format|
        format.js do
          @comment = @obj.comments.create(
            if logged_in?
              params[:comment].merge({
                :name => "#{current_user.first_name} #{current_user.last_name}",
                :email => current_user.email
              })
            else
              params[:comment]
            end
          )
          if @comment.errors.empty?
            after_create
            html = render_to_string(:partial => "comments/comment", :locals => {:comment => @comment})
            render :json => {:comment => html}.to_json
          else
            render :json => {:errors => @comment.errors.keys}.to_json
          end
        end
      end
    end

    #
    # Deletes a comment.
    # Allowed only to an admin.
    #
    def delete
      respond_to do |format|
        format.html do
          @comment = Comment.find(params[:id])
          @comment.destroy
          redirect_to :back
        end
      end
    end

    private

    def ensure_object_is_commentable
      @obj = Obj.find(params[:obj_id])
      render :nothing => true unless @obj.allow_comments?
      unless @obj.allow_anonymous_comments? or logged_in?
        render '/errors/403_forbidden', :status => 403
      end
    end

    def ensure_admin
      render("errors/403_forbidden", :status => 403) unless admin?
    end

    def after_create; end
  end
end
