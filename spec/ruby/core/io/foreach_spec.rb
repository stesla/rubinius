# -*- encoding: utf-8 -*-
require File.expand_path('../../../spec_helper', __FILE__)
require File.expand_path('../fixtures/classes', __FILE__)

describe "IO.foreach" do
  before :each do
    @name = fixture __FILE__, "lines.txt"
    @count = 0
    ScratchPad.record []
  end

  it "raises TypeError if the first parameter is nil" do
    lambda { IO.foreach(nil) {} }.should raise_error(TypeError)
  end

  it "raises Errno::ENOENT if the file does not exist" do
    lambda { IO.foreach(tmp("nonexistent.txt")) {} }.should raise_error(Errno::ENOENT)
  end

  it "converts first parameter to string and uses as file name" do
    obj = mock('lines.txt fixture')
    obj.should_receive(:to_str).and_return(@name)
    IO.foreach(obj) { |l| ScratchPad << l }
    ScratchPad.recorded.should == IOSpecs.lines
  end

  ruby_version_is "1.8.7" do
    it "returns an Enumerator when called without a block" do
      IO.foreach(@name).should be_an_instance_of(enumerator_class)
      IO.foreach(@name).to_a.should == IOSpecs.lines
    end
  end

  describe "with no separator argument" do
    it "yields a sequence of Strings that were separated by $/" do
      IO.foreach(@name) { |l| ScratchPad << l }
      ScratchPad.recorded.should == IOSpecs.lines
    end

    it "updates $. with each yield" do
      IO.foreach(@name) { $..should == @count += 1 }
    end
  end

  describe "with nil as the separator argument" do
    it "yields a single string with entire content" do
      IO.foreach(@name, nil) { |l| ScratchPad << l }
      ScratchPad.recorded.should == [IOSpecs.lines.join]
    end

    it "updates $. with each yield" do
      IO.foreach(@name, nil) { $..should == @count += 1 }
    end
  end

  describe "with an empty String as the separator argument" do
    it "yields a sequence of paragraphs when the separator is an empty string" do
      IO.foreach(@name, "") { |l| ScratchPad << l }
      ScratchPad.recorded.should == IOSpecs.lines_empty_separator
    end

    it "updates $. with each yield" do
      IO.foreach(@name, "") { $..should == @count += 1 }
    end
  end

  describe "with an arbitrary String as the separator argument" do
    it "yields a sequence of Strings that were separated by r" do
      IO.foreach(@name, "r") { |l| ScratchPad << l }
      ScratchPad.recorded.should == IOSpecs.lines_r_separator
    end

    it "updates $. with each yield" do
      IO.foreach(@name, "la") { $..should == @count += 1 }
    end

    it "accepts non-ASCII data as separator" do
      IO.foreach(@name, "\303\250") { |l| ScratchPad << l }
      ScratchPad.recorded.should == IOSpecs.lines_arbitrary_separator
    end

  end

  describe "with an object as the separator argument" do
    ruby_version_is "" ... "1.9" do
      it "calls #to_str once to convert it to a String" do
        obj = mock("IO.foreach separator 'r'")
        obj.should_receive(:to_str).once.and_return("r")
        IO.foreach(@name, obj) { |l| ScratchPad << l }
        ScratchPad.recorded.should == IOSpecs.lines_r_separator
      end
    end

    ruby_version_is "1.9" do
      it "calls #to_str once for each line read to convert it to a String" do
        obj = mock("IO.foreach separator 'r'")
        obj.should_receive(:to_str).exactly(6).times.and_return("r")
        IO.foreach(@name, obj) { |l| ScratchPad << l }
        ScratchPad.recorded.should == IOSpecs.lines_r_separator
      end

      it "calls #to_path on non-String arguments" do
        path = mock("IO.foreach path")
        path.should_receive(:to_path).and_return(@name)
        IO.foreach(path).to_a.should == IOSpecs.lines
      end
    end
  end
end
