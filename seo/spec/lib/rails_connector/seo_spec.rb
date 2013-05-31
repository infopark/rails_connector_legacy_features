require "spec_helper"

module RailsConnector
  describe SEO do

    before :all do
      class Model
        include SEO
        def body
          'abcdef <span class="foo">ghi</span>' * 32
        end
      end
      @model = Model.new
    end

    describe "(sitemap)" do
      describe "the default implementation" do
        it "should include the homepage and it's toclist (excluding binaries)" do
          Obj.stub(:homepage).and_return(objs(:toclist_pub))
          Obj.find_all_for_sitemap.to_set.should == [
            objs(:toclist_pub),
            objs(:toclist_entry_pub),
            objs(:toclist_entry_doc)
          ].to_set
        end

        it "should include two levels of toclist hierarchy under the homepage" do
          Obj.stub(:homepage).and_return(objs(:child1))
          Obj.find_all_for_sitemap.map(&:path).to_set.should == [
            "/child1",
            "/child1/subfolder",
            "/child1/config",
            "/child1/subfolder/sub_2_folder",
          ].to_set
        end
      end

      describe "(included_in_sitemap?)" do
        it "should return if the obj is permitted and active" do
          o1 = Obj.root; o1.stub_attrs!(:permitted_groups => [], :readable_for_googlebots? => false, :active? => true)
          o2 = Obj.root; o2.stub_attrs!(:permitted_groups => ['admin'], :readable_for_googlebots? => false, :active? => true)
          o3 = Obj.root; o3.stub_attrs!(:permitted_groups => [], :readable_for_googlebots? => false, :active? => false)
          o1.should be_included_in_seo_sitemap
          o2.should_not be_included_in_seo_sitemap
          o3.should_not be_included_in_seo_sitemap
        end

        it "should return if the obj is google-readable and active" do
          o1 = Obj.root; o1.stub_attrs!(:permitted_groups => ['registered'], :readable_for_googlebots? => true, :active? => true)
          o2 = Obj.root; o2.stub_attrs!(:permitted_groups => ['registered'], :readable_for_googlebots? => false, :active? => true)
          o3 = Obj.root; o3.stub_attrs!(:permitted_groups => ['registered'], :readable_for_googlebots? => false, :active? => false)
          o1.should be_included_in_seo_sitemap
          o2.should_not be_included_in_seo_sitemap
          o3.should_not be_included_in_seo_sitemap
        end
      end
    end

    it "should be readable for googlebots by default" do
      @model.should be_readable_for_googlebots
    end

    describe "(seo_description)" do
      it "should return the first 300 chars of the html-stripped body by default" do
        @model.seo_description.should == "abcdef ghi" * 30
      end

      it "should strip newlines" do
        @model.stub(:body).and_return("abcdef ghi\n\r abcdef ghi\n\r abcdef ghi\n\r")
        @model.seo_description.should_not include("\n")
        @model.seo_description.should_not include("\r")
      end

      it "should strip leading and trailing white spaces" do
        @model.stub(:body).and_return(" abcdef ")
        @model.seo_description.should == "abcdef"
      end

      it "should return nil if the body is empty" do
        @model.stub(:body).and_return(nil)
        @model.seo_description.should be_nil
      end
    end

  end
end
