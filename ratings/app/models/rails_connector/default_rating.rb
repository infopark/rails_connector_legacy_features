require "active_record"

module RailsConnector
  #
  # This model is responsible for rating CMS objects.
  class DefaultRating < ActiveRecord::Base
    self.abstract_class = true

    MINIMUM = 1
    MAXIMUM = 5

    belongs_to :obj

    validates_uniqueness_of :score, :scope => :obj_id
    validates_numericality_of :score, :count
    validates_presence_of :obj_id, :score, :count
    validates_inclusion_of :score, :in => MINIMUM..MAXIMUM

    attr_accessible :obj_id, :score, :count
  end

end
