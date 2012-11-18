require 'tk'
require_relative 'tkkeys'

class TkRepl < TkText
  attr_accessor :repl

  def initialize(container, status)
    super(container)
    setup_bindings
    @anchor = cursor
    @status = status
    @exit_proc = lambda {}
  end

  def on_repl_exit(&block)
    @exit_proc = block
  end

  def handle_repl_exit
    instance_eval(&@exit_proc)
  end

  def cursor
    index('insert')
  end

  def line
    get @anchor, cursor
  end

  def brk
    Tk.callback_break
  end

  def clear
    delete(@anchor, 'end')
  end

  def print(obj)
    insert('end', obj.to_s)
    @anchor = cursor
  end

  def puts(obj)
    if !obj.end_with? "\n"
      obj += "\n"
    end
    print obj
  end

  def tty?
    true
  end

  def flush
  end

  def cmp_anchor
    (@anchor.split(".") <=> cursor.split("."))
  end

  def after_anchor?
    cmp_anchor == -1
  end

  def before_anchor?
    cmp_anchor == 1
  end

  def at_anchor?
    cmp_anchor == 0
  end

  def indented?
    get(@anchor - 2, @anchor) == "  "
  end

  def history(dir)
    if (s = repl.history(dir))
      clear
      insert 'end', s
    end
  end

  def auto_dedent
    x = line
    return unless indented?
    return unless ['end', ']', '}'].include? x
    @anchor = @anchor - 2
    clear
    insert('end', x)
  end

  def can_process_commandline
    unless repl
      @status.text = "repl not ready"
      return false
    end

    return false if not after_anchor?
    return true
  end

  def process_commandline
    repl.process_commandline(line)
  end
  
  def connect(repl)
    @repl = repl
  end
end
