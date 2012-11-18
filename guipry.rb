#! /usr/bin/env ruby
require 'pry'
require "English"
require 'thread'

class GuiPryStdout < IO
  def initialize(output)
    @output = output
  end

  def print(*opts)
    opts = opts.map(&:to_s)
    @output.print(*opts)
  end

  def write(*opts)
    opts = opts.map(&:to_s)
    @output.print(*opts)
  end

  def flush
    # we aren't buffering anything
  end
end

class PryRunner
  attr_accessor :repl

  def initialize(output)
    @inputAdded = 0
    @input_reader, @input_writer = IO.pipe
    @output = output
    @history_cursor = 0
    @history = []

    $DEFAULT_OUTPUT = GuiPryStdout.new(output)

    @repl = Thread.new do
      Pry.config.color = false
      Pry.config.correct_indent = false
      Pry.history.pusher = method(:add_history)
      Pry.history.clearer = method(:clear_history)
      Pry.start(nil, :input => self, :output => output)
    end
  end

  def process_commandline(cmd)
    lines = cmd.split(/\n/)
    lines.each {|i|
      @input_writer.puts i
      @inputAdded += 1
    }

    while (@inputAdded > 0) do
      @repl.run
    end
  end

  def add_history(cmd)
    @history.push(cmd)
  end

  def clear_history(cmd)
    @history = []
  end

  def history(dir)
    @history_cursor += (dir == :prev) ? 1 : -1
    if @history_cursor > 0
      @history[-@history_cursor]
    end
  end

  def readline(prompt)
    if @inputAdded == 0
      @history_cursor = 0
      @output.print prompt
      Thread.stop
    end
    @inputAdded -= 1
    @input_reader.gets
  end
end
