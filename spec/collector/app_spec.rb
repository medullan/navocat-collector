require File.expand_path '../spec_helper.rb', __FILE__

describe "Collector Application" do
  it "should get hello world" do
    get '/'
    last_response.should be_ok
  end
end

