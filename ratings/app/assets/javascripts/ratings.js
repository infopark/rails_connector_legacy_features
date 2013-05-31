var rails_connector = (function(rails_connector, $) {
  rails_connector.ratings = {
    initialize: function() {
      var rating = $("#starRating");
      if (rating.length > 0) {
        var label = $("#starRating_label");
        $.each(rating.find("ul.star-rating li a"), function(i, link_elem) {
          var link = $(link_elem);
          link.click(function() {
            $.post(link.attr("href"), function(data) {
              rating.replaceWith(data);
            }, "html");
            return false;
          });
          link.mouseover(function() {
            label.text(link.attr("data-description"));
          });
          link.mouseout(function() {
            label.text(rating.attr("data-default_description"));
          });
        });
      }
    }
  };
  return rails_connector;
}(rails_connector || {}, jQuery));
