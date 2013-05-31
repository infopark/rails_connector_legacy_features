require("javascripts/comments.js");

Screw.Unit(function(){
  describe("Comments", function(){
    use_fixture("comments");

    before(function() {
      rails_connector.comments.initialize();
      $("#comment_name").val("Peter Griffin");
      $("#comment_email").val("peter.griffin@family-guy.com");
      $("#comment_body").val("oh no... oh NO... OH NO... OOOHHHH YEEEAHHH!");
    });

    describe("when the form is submitted", function() {
      it("should post serialized data", function() {
        mock(jQuery).must_receive("post").and_execute(function(uri, data, callback, data_type) {
          expect(uri).to(be, "/some/uri");
          expect(data).to(be, "name=Peter+Griffin&email=peter.griffin%40family-guy.com&" +
              "body=oh+no...+oh+NO...+OH+NO...+OOOHHHH+YEEEAHHH!");
          expect(data_type).to(be, "json");
        });
        $(".submit").click();
      });
    });

    describe("when server responds with markup", function() {
      before(function() {
        mock(jQuery).must_receive("post").and_execute(function(uri, dara, callback, data_type) {
          callback({comment: "<div class='comment'>Comment's content</div>"});
        });
      });

      it("should show comment list container", function() {
        $("#comment_list_container").hide();
        $(".submit").click();
        expect($("#comment_list_container").is(":visible")).to(be, true);
      });

      it("should append markup to the comment list container", function() {
        expect($(".comment").length).to(be, 0);

        $(".submit").click();
        expect($(".comment").length).to(be, 1);
        expect($(".comment").eq(0).is(":visible")).to(be, true);
        expect($(".comment").eq(0).text()).to(be, "Comment's content");

        $(".submit").click();
        expect($(".comment").length).to(be, 2);
        expect($(".comment").eq(1).is(":visible")).to(be, true);
        expect($(".comment").eq(1).text()).to(be, "Comment's content");
      });

      it("should hide the 'no comments' message", function() {
        expect($("#no_comments").is(":visible")).to(be, true);
        $(".submit").click();
        expect($("#no_comments").is(":hidden")).to(be, true);
      });

      it("should reset the form", function() {
        $(".submit").click();
        expect($("form input[type=text]").eq(0).val()).to(be, "");
        expect($("form input[type=text]").eq(1).val()).to(be, "");
        expect($("form textarea").val()).to(be, "");
      });

      describe("and there were previous errors", function() {
        before(function() {
          $("label").eq(0).addClass("error");
          $("label").eq(2).addClass("error");
        });

        it("should clear all errors", function() {
          $(".submit").click();
          expect($("label").eq(0).hasClass("error")).to(be, false);
          expect($("label").eq(1).hasClass("error")).to(be, false);
          expect($("label").eq(2).hasClass("error")).to(be, false);
        });
      });
    });

    describe("when server responds with errors", function() {
      before(function() {
        mock(jQuery).must_receive("post").and_execute(function(uri, dara, callback, data_type) {
          callback({errors: ["email","body"]});
        });
      });

      it("should mark errors", function() {
        $(".submit").click();
        expect($("label").eq(0).hasClass("error")).to(be, false);
        expect($("label").eq(1).hasClass("error")).to(be, true);
        expect($("label").eq(2).hasClass("error")).to(be, true);
      });

      describe("and there were previous errors", function() {
        before(function() {
          $("label").eq(0).addClass("name");
          $("label").eq(2).addClass("email");
        });

        it("should update errors", function() {
          $(".submit").click();
          expect($("label").eq(0).hasClass("error")).to(be, false);
          expect($("label").eq(1).hasClass("error")).to(be, true);
          expect($("label").eq(2).hasClass("error")).to(be, true);
        });
      });
    });
  });
});
