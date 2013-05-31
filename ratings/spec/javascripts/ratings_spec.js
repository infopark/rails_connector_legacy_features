require("javascripts/ratings.js");

Screw.Unit(function() {
  describe("Ratings", function() {
    use_fixture("ratings");

    before(function() {
      rails_connector.ratings.initialize();
    });

    describe("when hovering stars", function() {
      it("should update the description text", function() {
        expect($("#starRating_label").text()).to(be, "The default description");

        $("#starRating ul.star-rating li a").eq(0).trigger("mouseover");
        expect($("#starRating_label").text()).to(be, "Some description");
        $("#starRating ul.star-rating li a").eq(0).mouseout();
        expect($("#starRating_label").text()).to(be, "The default description");

        $("#starRating ul.star-rating li a").eq(1).mouseover();
        expect($("#starRating_label").text()).to(be, "Another description");
        $("#starRating ul.star-rating li a").eq(1).mouseout();
        expect($("#starRating_label").text()).to(be, "The default description");
      });
    });

    describe("when clicking on a star", function() {
      it("should post to the server", function() {
        mock(jQuery).must_receive("post").and_execute(function(uri, callback, type) {
          expect(uri).to(match, "/some/uri");
          expect(type).to(be, "html");
        });
        $("#starRating ul.star-rating li a").eq(0).click();

        mock(jQuery).must_receive("post").and_execute(function(uri, callback) {
          expect(uri).to(match, "/another/uri");
        });
        $("#starRating ul.star-rating li a").eq(1).click();
      });
    });

    describe("when the server responds", function() {
      before(function() {
        mock(jQuery).must_receive("post").and_execute(function(uri, callback) {
          callback("<div id='starRating'><span>Thank you for rating!</span></div>");
        });
      });

      it("should update the markup", function() {
        $("#starRating ul.star-rating li a").eq(0).click();
        expect($("#starRating").find("span").text()).to(be, "Thank you for rating!");
      });
    });
  });
});
