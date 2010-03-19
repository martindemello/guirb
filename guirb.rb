#! /usr/bin/env ruby
require "irb"
require "singleton"
require "English"
require 'thread'


# make irb honour IRB::Context#output_value
module IRB
  class Context
    attr_reader :output_method
  end

  class Irb
    def output_value
      c = @context
      val = c.inspect? ? c.last_value.inspect : c.last_value
      c.output_method.printf c.return_format, val
    end
  end
end

class GUIRBInputMethod < IRB::StdioInputMethod
	attr_accessor :print_prompt, :gets_mode

  def initialize(input, output)
    super()
    @input = input
    @output = output
    @history = 1
    @begin = nil
    @end = nil
    @print_prompt = true
    @continued_from = nil
    @gets_mode = false
  end

  def gets
    if @gets_mode
      return @input.get_line
    end

    if (a = @prompt.match(/(\d+)[>*]/))
      level = a[1].to_i
      continued = @prompt =~ /\*\s*$/
    else
      level = 0
    end

    if level > 0 or continued
      @continued_from ||= @line_no
    elsif @continued_from
      merge_last(@line_no-@continued_from+1)
      @continued_from = nil
    end

    l = @line.length
    @line = @line.reverse.uniq.reverse
    delta = l - @line.length
    @line_no -= delta
    @history -= delta

    if print_prompt
      @output.print @prompt

      #indentation
      @output.print "  "*level
    end

    str = @input.get_line

    @line_no += 1
    @history = @line_no + 1
    @line[@line_no] = str

    str
  end

  # merge a block spanning several lines into one \n-separated line
  def merge_last(i)
    return unless i > 1
    range = -i..-1
    @line[range] = @line[range].join
    @line_no -= (i-1)
    @history -= (i-1)
  end

  def prev_cmd
    return "" if @gets_mode

    if @line_no > 0
      @history -= 1 unless @history <= 1
      return line(@history)
    end
    return ""
  end

  def next_cmd
    return "" if @gets_mode

    if (@line_no > 0) && (@history < @line_no)
      @history += 1
      return line(@history)
    end
    return ""
  end
end

class GUIRBOutputMethod < IRB::OutputMethod
  def initialize(output)
    @output = output
  end

  def print(*opts)
    @output.print(*opts)
  end
end

class GUIRBStderr
  def initialize(output)
    @output = output
  end

  def write(*opts)
    @output.print(*opts)
  end
end

module IRB
	def IRB.start_in_gui(im, om)
	  IRB.setup(nil)

		irb = Irb.new(nil, im, om)

		@CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
		@CONF[:MAIN_CONTEXT] = irb.context
		trap("SIGINT") do
			irb.signal_handle
		end

		class << irb.context.workspace.main
			def gets
				inp = IRB.conf[:MAIN_CONTEXT].io
				inp.gets_mode = true
				retval = IRB.conf[:MAIN_CONTEXT].io.gets
				inp.gets_mode = false
				retval
			end
		end

		catch(:IRB_EXIT) do
			irb.eval_input
		end
		print "\n"
	end
end

class IrbRunner
  def initialize(output)
    IRB.conf[:LC_MESSAGES] = IRB::Locale.new
		@inputAdded = 0
		@input = IO.pipe

    @om = GUIRBOutputMethod.new(output)
		@im = GUIRBInputMethod.new(self, @om)

    # for some reason setting $stderr doesn't work, but this does
    # (we can still distinguish between $stderr and $stdout since
    # normal output is already redirected to @om by overriding
    # Irb#output_value above
    $DEFAULT_OUTPUT = GUIRBStderr.new(output)

		@irb = Thread.new {
			IRB.start_in_gui(@im, @om)
		}

		@multiline = false

		@exit_proc = lambda {exit}
  end

	def process_commandline(cmd)
		multiline = false
		lines = cmd.split(/\n/)
		lines.each {|i|
			@input[1].puts i
			@inputAdded += 1
		}

		while (@inputAdded > 0) do
			@irb.run
		end
	end

	def history(dir)
		str = (dir == :prev) ? @im.prev_cmd.chomp : @im.next_cmd.chomp
		str if str != ""
	end

  def get_line
		if @inputAdded == 0
			Thread.stop
		end
		@inputAdded -= 1
		retval = @input[0].gets
		# don't print every prompt for multiline input
		@im.print_prompt = (@inputAdded == 0)
		return retval
	end
end
