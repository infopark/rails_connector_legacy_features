require "spec_helper"

describe SearchConfiguration do

  describe 'search options' do
    it 'should be stored' do
      SearchController.options[:foo].should be_nil
      SearchConfiguration.search_options = {:foo => 'bar'}
      SearchConfiguration.search_options[:foo].should == 'bar'
    end

    it 'should fallback to what rails_connector.yml says' do
      SearchConfiguration.search_options = nil

      SearchConfiguration.local_config_file.should_receive(:[]).with('search') \
          .and_return({'url' => 'asdf'})
      SearchConfiguration.search_options[:url].should == 'asdf'
    end
  end

end
