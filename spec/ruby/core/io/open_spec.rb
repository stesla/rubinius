require File.expand_path('../../../spec_helper', __FILE__)
require File.expand_path('../shared/new', __FILE__)
require File.expand_path('../fixtures/classes', __FILE__)

describe "IO.open" do
  it_behaves_like :io_new, :open
end

describe "IO.open" do
  before :all do
    @file_name = fixture __FILE__, "lines.txt"
  end

  it "raises an IOError on closed stream" do
    lambda { IO.open(IOSpecs.closed_file.fileno, 'w') }.should raise_error(IOError)
  end

  it "with a block invokes close on opened IO object when exiting the block" do
    File.open(@file_name, 'r') do |f|
      io = IO.open(f.fileno, 'r') do |io|
        class << io
          @res = "close was not invoked"
          alias_method(:close_orig, :close)
          def close; close_orig; @res = "close was invoked"; end
          def to_s;  @res; end
        end
        io
      end
      io.to_s.should == "close was invoked"
    end
  end

  it "with a block propagates non-StandardErrors produced by close" do
    lambda {
      File.open @file_name do |f|
        IO.open f.fileno do |io|
          def io.close
            raise Exception, "exception out of close"
          end
        end
      end # IO object is closed here
    }.should raise_error(Exception)
  end

  it "with a block swallows StandardErrors produced by close" do
    # This closes the file descriptor twice, the second raises Errno::EBADF
    lambda {
      File.open @file_name do |f|
        IO.open f.fileno do end
      end
    }.should_not raise_error
  end
end
