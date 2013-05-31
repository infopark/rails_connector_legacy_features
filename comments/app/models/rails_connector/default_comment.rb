require "active_record"

module RailsConnector

  # Abstract base class for Comment.
  #
  # Objects do only have comments if the addon <tt>:comments</tt> is enabled
  # and the module {Commentable} is thereby included.
  #
  # A comment must have a name, email, subject, and body.
  class DefaultComment < ActiveRecord::Base
    self.abstract_class = true

    belongs_to :obj

    validates_presence_of :name, :message => I18n.t(:"rails_connector.models.comment.name_missing")
    validates_presence_of :body, :message => I18n.t(:"rails_connector.models.comment.body_missing")
    validates_presence_of :subject, :message => I18n.t(:"rails_connector.models.comment.subject_missing")

    EMAIL_FORMAT = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

    validates_format_of(
      :email,
      :with => EMAIL_FORMAT,
      :message => I18n.t(:"rails_connector.models.comment.email_format_invalid")
    )

    attr_accessible :name, :body, :subject, :email
  end
end
