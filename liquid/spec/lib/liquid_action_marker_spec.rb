require "spec_helper"

require "rails_connector/liquid_support/action_marker"

module RailsConnector::LiquidSupport
  describe ActionMarker do
    before do
      initialize_action_view_and_obj
      @obj.stub_attrs!(:title => "Page Title")
      @obj.stub_attrs!(:id => 15)
      Obj.stub(:find).with([98, 99]).and_return([
        @img1 = Obj.new.stub_attrs!(:id => 98, :title => "img1", :active? => true),
        @img2 = Obj.new.stub_attrs!(:id => 99, :title => "img2", :active? => true)
      ])
      @obj.stub_attrs!(
        :images => RailsConnector::LinkList.new([
          {:destination => 98, :title => "image 1"},
          {:destination => 99, :title => "image 2"},
        ])
      )
      RailsConnector::Configuration.stub(:editor_interface_enabled?).and_return(true)

      @action_view.stub(:random_marker_id).and_return(0)
    end

    it "should forward parameters" do
      am = render_liquid('{% actionmarker obj release foo:bar spam:eggs %}abc{% endactionmarker %}')
      am.should have_tag('a', 'abc')
      am.should have_tag("a[href^='javascript:parent.openActionDialog(']")

      raw_parameters = am.scan(/\{.+\}/).first.to_s
      am.should include((
        "javascript:parent.openActionDialog('release',[15],15,'#{raw_parameters}',null,'_blank')"
      ).gsub(/'/, '&#x27;'))

      parsed_parameters = JSON.parse(CGI.unescape(raw_parameters))
      parsed_parameters["foo"].should == "bar"
      parsed_parameters["spam"].should == "eggs"

      am.should have_tag("a[class='nps_action_marker nps_marker_id_0']")
    end

    it "should interpret parameters" do
      RailsConnector::Configuration.stub(:auto_liquid_editmarkers).and_return(true)
      @action_view.should_receive(:action_marker).with(
        'some_method', [@obj],
        hash_including(:params => {"foo" => '<span class="" id="nps_marker_id_0">Page Title</span>'})
      )
      render_liquid('{% actionmarker obj some_method foo:obj.title %}abc{% endactionmarker %}')
    end

    it "should use the current obj as context" do
      @action_view.should_receive(:action_marker).with(
        'some_method', [@img1],
        hash_including(:context => @obj)
      )
      render_liquid('{% actionmarker obj.images[0].destination some_method foo:obj.title %}abc{% endactionmarker %}')
    end

    it "should raise a SyntaxError if necessary" do
      lambda { render_liquid('{% actionmarker only_one_param %}abc{% endactionmarker %}') }.
        should raise_error(Liquid::SyntaxError, /actionmarker/)
    end

    describe "identifying target objects" do
      it "should use the link drop destination as target obj" do
        @action_view.should_receive(:action_marker).with(
          'some_method', [@img1],
          hash_including(:context => @obj)
        )
        render_liquid('{% actionmarker obj.images[0] some_method foo:obj.title %}abc{% endactionmarker %}')
      end

      it "should replace links by their destination objects" do
        @action_view.should_receive(:action_marker).with(
          'some_method', [@img1, @img2],
          hash_including(:context => @obj)
        )
        render_liquid('{% actionmarker obj.images some_method foo:obj.title %}abc{% endactionmarker %}')
      end
    end

  end
end
