#! /usr/bin/env rspec

require_relative "./spec_helper"

describe InstSys do
  describe ".check!" do
    context "when running in an inst-sys" do
    end

    context "when running in a normal system" do
      before do
        expect(described_class).to receive(:`).with("mount").and_return(<<~MOUNT
          proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
          /dev/sda1 on / type btrfs (rw,relatime,ssd,space_cache,subvolid=267,subvol=/@/.snapshots/1/snapshot)
          /dev/sda2 on /home type ext4 (rw,relatime,stripe=32596,data=ordered)
          MOUNT
        )
        allow(described_class).to receive(:exit).with(1)
      end

      it "does not continue and exits with status 1" do
        expect(described_class).to receive(:exit).with(1)
        # capture the std streams to not print the errors on the console
        capture_stdio { described_class.check! }
      end

      it "prints an error on STDERR" do
        _stdout, stderr = capture_stdio { described_class.check! }
        expect(stderr).to match(/ERROR: .*inst-sys/)
      end
    end
  end
end
