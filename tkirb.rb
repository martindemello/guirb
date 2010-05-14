require 'tk'
require 'guirb'
require 'tkkeys'

class TkIrb < TkText
  attr_accessor :irb

  def initialize(container, status)
    super(container)
    setup_bindings
    @anchor = cursor
    @status = status
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

  def auto_dedent
    x = line
    return unless indented?
    return unless ['end', ']', '}'].include? x
    @anchor = @anchor - 2
    clear
    insert('end', x)
  end

  def can_process_commandline
    unless @irb
      @status.text = "irb not ready"
      return false
    end

    return false if not after_anchor?
    return true
  end

  def process_commandline
    @irb.process_commandline(line)
  end
end

if __FILE__ == $0
  Thread.abort_on_exception = true
  root = TkRoot.new() { title "TkIRB" }
  frame = TkFrame.new(root).pack("side"=>"right")
  buttons = TkFrame.new(frame).pack("side"=>"bottom")
  quit = TkButton.new(buttons) {
    text "Exit"
    command lambda { exit }
  }
  TkGrid.configure(quit)
  display = TkFrame.new(root).pack("side"=>"left")
  status = TkLabel.new(display)
  editor = TkIrb.new(display, status).pack()  # top
  irb = IrbRunner.new(editor)
  editor.irb = irb
  status.pack("side"=>"bottom", "anchor"=>"w")
  frame.pack("fill"=>"y")
  display.pack("fill"=>"both", "expand"=>true)
  status.pack("before"=>editor)
  editor.pack("fill"=>"both", "expand"=>true)
  editor.focus
  Tk.mainloop()
end
