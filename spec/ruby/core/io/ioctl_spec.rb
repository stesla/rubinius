require File.expand_path('../../../spec_helper', __FILE__)
require File.expand_path('../fixtures/classes', __FILE__)

describe "IO#ioctl" do
  it "raises IOError on closed stream" do
    lambda { IOSpecs.closed_file.ioctl(5, 5) }.should raise_error(IOError)
  end
end
