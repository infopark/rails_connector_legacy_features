module RailsConnector
  #
  # This module provides a mixin for the CMS object model. It provides a {ratings} association and well as several helper methods.
  module Rateable

    # returns all Ratings for this Obj.
    def ratings
      Rating.where(:obj_id => id)
    end

    # Creates/updates the rating for a CMS object.
    def rate(score)
      rating = ratings.find_by_score(score) || ratings.build(:score => score)
      rating.count += 1
      rating.save
    end

    # Returns a count for the particular score for a CMS object.
    def count_for_score(score)
      rating = ratings.find_by_score(score)
      rating ? rating.count : 0
    end

    # Determines if a CMS object has already been rated.
    def rated?
      !ratings.empty?
    end

    # Calculates the average rating for a CMS object.
    def average_rating
      raise TypeError unless rated?
      sum, count = ratings.inject([0, 0]) do |(sum, count), rating|
        [sum + rating.score * rating.count, count + rating.count]
      end
      sum.to_f / count.to_f
    end

    # Calculates the average rating for a CMS object in per cent.
    def average_rating_in_percent
      if rated?
        (100 * average_rating / Rating::MAXIMUM).to_i
      else
        0
      end
    end

    # Resets the ratings for a CMS object.
    def reset_rating
      ratings.destroy_all
    end

    # Redefine this method in your application's <tt>obj_extensions.rb</tt> in order to define conditions for allowing a CMS object to be rated.
    def allow_rating?; true; end
    # Redefine this method in your application's <tt>obj_extensions.rb</tt> in order to define conditions for allowing a CMS object to be rated anonymously.
    def allow_anonymous_rating?; true; end
  end
end
