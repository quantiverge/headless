require 'spec_helper'

describe Headless do
  let(:display_before) { ':31337' }
  let(:display_after) { ':99' }

  before do
    ENV['DISPLAY'] = display_before
    stub_environment
  end

  context "instaniation" do
    context "when Xvfb is not installed" do
      before do
        Headless::CliUtil.stub!(:application_exists?).and_return(false)
      end

      it "raises an error" do
        lambda { Headless.new }.should raise_error(Headless::Exception)
      end
    end

    context "when Xvfb not started yet" do
      it "starts Xvfb" do
        Headless.any_instance.should_receive(:system).with("/usr/bin/Xvfb #{display_after} -screen 0 1280x1024x24 -ac >/dev/null 2>&1 &").and_return(true)

        headless = Headless.new
      end

      it "allows setting screen dimensions" do
        Headless.any_instance.should_receive(:system).with("/usr/bin/Xvfb #{display_after} -screen 0 1024x768x16 -ac >/dev/null 2>&1 &").and_return(true)

        headless = Headless.new(:dimensions => "1024x768x16")
      end
    end

    context "when Xvfb is already running" do
      before do
        Headless::CliUtil.stub!(:read_pid).and_return(31337)
      end

      it "raises an error if reuse display is not allowed" do
        lambda { Headless.new(:reuse => false) }.should raise_error(Headless::Exception)
      end

      it "doesn't raise an error if reuse display is allowed" do
        lambda { Headless.new(:reuse => true) }.should_not raise_error(Headless::Exception)
        lambda { Headless.new }.should_not raise_error(Headless::Exception)
      end
    end
  end

  context "lifecycle" do
    let(:headless) { Headless.new }

    describe "#start" do
      it "switches to the headless server" do
        ENV['DISPLAY'].should == display_before
        headless.start
        ENV['DISPLAY'].should == display_after
      end
    end

    describe "#stop" do
      it "switches back from the headless server" do
        ENV['DISPLAY'].should == display_before
        headless.start
        ENV['DISPLAY'].should == display_after
        headless.stop
        ENV['DISPLAY'].should == display_before
      end
    end

    describe "#destroy" do
      let(:pid) { 4444 }

      before do
        Headless::CliUtil.stub!(:read_pid).and_return(pid)
      end

      it "switches back from the headless server and terminates the headless session" do
        Process.should_receive(:kill).with('TERM', pid)

        ENV['DISPLAY'].should == display_before
        headless.start
        ENV['DISPLAY'].should == display_after
        headless.destroy
        ENV['DISPLAY'].should == display_before
      end
    end
  end

  context "#video" do
    let(:headless) { Headless.new }

    it "returns video recorder" do
      headless.video.should be_a_kind_of(Headless::VideoRecorder)
    end

    it "returns the same instance" do
      recorder = headless.video
      headless.video.should be_eql(recorder)
    end
  end

  context "#take_screenshot" do
    let(:headless) { Headless.new }

    it "raises an error if imagemagick is not installed" do
      Headless::CliUtil.stub!(:application_exists?).and_return(false)

      lambda { headless.take_screenshot }.should raise_error(Headless::Exception)
    end

    it "issues command to take screenshot" do
      headless = Headless.new

      Headless.any_instance.should_receive(:system)

      headless.take_screenshot("/tmp/image.png")
    end
  end

private
  def stub_environment
    Headless::CliUtil.stub!(:application_exists?).and_return(true)
    Headless::CliUtil.stub!(:read_pid).and_return(nil)
    Headless::CliUtil.stub!(:path_to).and_return("/usr/bin/Xvfb")
  end
end
