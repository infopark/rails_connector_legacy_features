module RailsConnector
  #
  # This helper provides methods for use with ratings.
  module DefaultRatingsHelper
    # Determines whether the current user has rated a CMS object.
    def rated_by_current_user?(obj)
      session[:rated_objs] && session[:rated_objs][obj.id]
    end

    # Builds the HTML markup for the ratings section.
    def stars_for_rating(obj)
      stars = "".html_safe
      (Rating::MINIMUM..Rating::MAXIMUM).collect do |score|
        stars << content_tag(:li, link_a_star(score, obj))
      end
      stars
    end

    private

    def link_a_star(score, obj)
      css_classes = ["", "one-star", "two-stars", "three-stars", "four-stars", "five-stars"]
      descriptions = ["",
        t(:"rails_connector.helpers.ratings.bad"),
        t(:"rails_connector.helpers.ratings.mediocre"),
        t(:"rails_connector.helpers.ratings.average"),
        t(:"rails_connector.helpers.ratings.good"),
        t(:"rails_connector.helpers.ratings.very_good")
      ]
      html_options = {
        :title => "#{score} von #{Rating::MAXIMUM} Sternen",
        :class => css_classes[score],
        "data-description" => descriptions[score]
      }
      link_to(score.to_s, ratings_url(:action => :rate, :id => obj.id, :score => score), html_options)
    end
  end
end
