require "spec_helper"

module RailsConnector

  describe MenuHelper, "the build_menu method" do

    before do
      nineties  = mock_model(Obj, :display_title => "1990 - 1999", :path => "path/to/history/nineties")
      recent    = mock_model(Obj, :display_title => "2000 - Present", :path => "path/to/history/recent")
      finance   = mock_model(Obj, :display_title => "Finance", :path => "path/to/products/finance")
      @insurance = mock_model(Obj, :display_title => "Insurance", :path => "path/to/products/insurance")
      @history   = mock_model(Obj, :sorted_toclist => [recent, nineties], :display_title => "History", :path => "path/to/history")
      @products  = mock_model(Obj, :sorted_toclist => [@insurance, finance], :display_title => "Products", :path => "path/to/products")
      @home_page = mock_model(Obj, :sorted_toclist => [@history, @products], :path => 'home')
      [@history, @products, @insurance, finance].each do |o|
        helper.stub(:cms_path).with(o).and_return("cms/#{o.path}")
      end
    end

    it "should generate an unordered list with link tags inside list elements" do
      helper.should_receive(:table_of_contents).with(@home_page).and_return([@history, @products])
      html = helper.build_menu(@home_page, nil, :id => "main", :class => "menu")
      html.should have_tag("ul#main.menu") do |menu|
        menu.should have_tag("li:nth-child(1) a", "History")
        menu.should have_tag("li:nth-child(1) a[href='cms/path/to/history']")
        menu.should have_tag("li:nth-child(2) a", "Products")
        menu.should have_tag("li:nth-child(2) a[href='cms/path/to/products']")
      end
    end

    it "should display a menu item plus it's children if one of the children is the current page" \
        "and the relevant block is given" do
      helper.should_receive(:table_of_contents).twice do |obj|
        obj.sorted_toclist
      end

      @history.should_not_receive(:toclist)
      @insurance.should_receive(:ancestors).exactly(2).and_return([@products, @home_page])

      html = helper.build_menu(@home_page, @insurance, :id => "main", :class => "menu") do |entry|
        helper.build_menu(entry, @insurance, :id => "sub", :class => "menu")
      end

      html.should have_tag("ul#main.menu") do |menu|
        menu.should have_tag("li:nth-child(1) a", "History")
        menu.should have_tag("li:nth-child(1) a[href='cms/path/to/history']")
        menu.should have_tag("li:nth-child(2) a", "Products")
        menu.should have_tag("li:nth-child(2) a[href='cms/path/to/products']")
      end

      html.should_not have_tag("ul#main.menu li:nth-child(1) ul")

      html.should have_tag("ul#main.menu li:nth-child(2) ul") do |ul|
        ul.should have_tag("li:nth-child(1) a", "Insurance")
        ul.should have_tag("li:nth-child(1) a[href='cms/path/to/products/insurance']")
        ul.should have_tag("li:nth-child(2) a", "Finance")
        ul.should have_tag("li:nth-child(2) a[href='cms/path/to/products/finance']")
      end
    end

    it "should display a menu item plus it's children if the menu item is the current page and the relevant block is given" do
      helper.should_receive(:table_of_contents).twice do |obj|
        obj.sorted_toclist
      end

      @history.should_not_receive(:toclist)
      @products.should_receive(:ancestors).exactly(1).and_return([@home_page])

      html = helper.build_menu(@home_page, @products, :id => "main", :class => "menu") do |entry|
        helper.build_menu(entry, @products, :id => "sub", :class => "menu")
      end

      html.should have_tag("ul#main.menu") do |menu|
        menu.should have_tag("li:nth-child(1) a", "History")
        menu.should have_tag("li:nth-child(1) a[href='cms/path/to/history']")
        menu.should have_tag("li:nth-child(2) a", "Products")
        menu.should have_tag("li:nth-child(2) a[href='cms/path/to/products']")
      end

      html.should_not have_tag("ul#main.menu li:nth-child(1) ul")

      html.should have_tag("ul#main.menu li:nth-child(2) ul") do |ul|
        ul.should have_tag("li:nth-child(1) a", "Insurance")
        ul.should have_tag("li:nth-child(1) a[href='cms/path/to/products/insurance']")
        ul.should have_tag("li:nth-child(2) a", "Finance")
        ul.should have_tag("li:nth-child(2) a[href='cms/path/to/products/finance']")
      end
    end

  end

end
