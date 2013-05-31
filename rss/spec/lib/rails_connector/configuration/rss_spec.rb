require "spec_helper"

require "active_support/log_subscriber/test_helper"

module RailsConnector
  class Configuration

    describe Rss do
      before do
        @original_provider =
            Rss.module_eval do
              @root_provider
            end

        Rss.module_eval do
          @root_provider = nil
        end
      end

      after do
        Rss.root = @original_provider
      end

      describe ".root=(provider)" do
        describe "when called with an Obj (deprecated)" do
          let(:logger) { ActiveSupport::LogSubscriber::TestHelper::MockLogger.new }

          before do
            Rails.stub(:logger).and_return(logger)
          end

          let(:obj) {Obj.root.tap {|o| o.stub(:id).and_return("a")}}

          it "should raise a warning" do
            Rss.root = obj
            logger.logged(:warn).last.should =~ /called with an Obj/
          end

          it "should remember the object's id" do
            Rss.root = obj
          end

          it "should use the remembered it on later calls for #root" do
            obj.should_receive(:id).and_return("a")
            Rss.root = obj
            obj.stub(:id).and_return("obj has been accessed after been assigned to root")
            Obj.should_receive(:find).with("a").and_return("an obj")
            Rss.root.should == "an obj"
          end
        end

        describe "when called with a lambda" do
          before do
            lambda {Rss.root}.should raise_error(Rss::RootUndefined)
            Rss.root = lambda { "bla" }
          end

          it "should store a lambda" do
            Rss.root.should_not raise_error(Rss::RootUndefined)
          end

          it "should use the lambda" do
            Rss.root.should == "bla"
          end
        end
      end

      describe ".root" do
        describe "when root= has not been provided yet" do
          it "should raise an error" do
            lambda {Rss.root}.should raise_error(Rss::RootUndefined)
          end
        end

        describe "called multiple times" do
          it "should always (re)load the root" do
            counter = 0
            Rss.root = lambda { counter += 1 }
            Rss.root.should == 1
            Rss.root.should == 2
          end
        end

        describe "when missing the obj" do
          it "should raise an error" do
            counter = 0
            Rss.root = lambda {
              case counter += 1
              when 1
                counter
              else
                raise RailsConnector::ResourceNotFound
              end
            }
            lambda {Rss.root}.should_not raise_error
            lambda {Rss.root}.should raise_error(Rss::RootNotFound)
            # old API
            lambda {Rss.root}.should raise_error(Rss::RootUndefined)
          end
        end
      end
    end
  end
end
