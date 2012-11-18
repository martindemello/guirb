#! /usr/bin/env ruby
require 'pry'
require "English"
require 'thread'

class PryRunner
  attr_accessor :repl

  def initialize(output)
    @inputAdded = 0
    @input_reader, @input_writer = IO.pipe
    @output = output

    @repl = Thread.new do 
      Pry.config.color = false
      Pry.config.correct_indent = false
      Pry.start(0, :input => self, :output => output)
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

  def history(dir)
    str = (dir == :prev) ? @im.prev_cmd.chomp : @im.next_cmd.chomp
    str if str != ""
  end

  def readline(prompt)
    if @inputAdded == 0
      @output.puts prompt
      Thread.stop
    end
    @inputAdded -= 1
    retval = @input_reader.gets
    return retval
  end
end
