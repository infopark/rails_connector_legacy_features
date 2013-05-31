var rails_connector = (function(rails_connector, $) {
  rails_connector.comments = {
    initialize: function() {
      var form = $("#comment_form");
      if (form.length > 0) {
        form.find(".submit").click(function() {
          $.post(form.attr("action"), form.serialize(), function(json) {
            form.find("label").removeClass("error");
            if (json.comment) {
              $("#no_comments").hide();
              $("#comment_list_container").show();
              var comment = $(json.comment).hide();
              $("#comment_list_container").append(comment);
              comment.slideDown(750, "swing");
              $("html, body").animate({scrollTop: comment.offset().top}, 1000);
              form[0].reset();
            } else {
              $.each(json.errors, function() {
                $("#comment_form_" + this + "_label").addClass("error");
              });
            }
          }, "json");
          return false;
        });
      }
    }
  };
  return rails_connector;
}(rails_connector || {}, jQuery));
