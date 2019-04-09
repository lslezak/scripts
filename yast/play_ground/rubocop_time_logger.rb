

require "rubocop/formatter/base_formatter"
require "pp"

class RubocopTimeLogger < RuboCop::Formatter::BaseFormatter
  def initialize(output, options = {})
    super
    @files = {}
  end

  def file_started(file, _options)
    # use the monotonic time to
    files[file] = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def file_finished(file, _offenses)
    files[file] = Process.clock_gettime(Process::CLOCK_MONOTONIC) - files[file]
  end

  def finished(_inspected_files)
    pp files
  end

private

  attr_accessor :files

  def unique_log
    with_locked_log do |logfile|
      separator = "\n"
      groups = logfile.read.split(separator).map { |line| line.split(":") }.group_by(&:first)
      lines = groups.map do |file, times|
        time = "%.2f" % times.map(&:last).map(&:to_f).inject(:+)
        "#{file}:#{time}"
      end
      logfile.rewind
      logfile.write(lines.join(separator) + separator)
      logfile.truncate(logfile.pos)
    end
  end

  def with_locked_log
    File.open(logfile, File::RDWR | File::CREAT) do |logfile|
      logfile.flock(File::LOCK_EX)
      yield logfile
    end
  end
end
