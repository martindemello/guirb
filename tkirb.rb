require 'tk'
require 'guirb'

class TkIrb < TkText
  attr_accessor :irb

  def initialize(container, status)
    super(container)
    setup_bindings
    @anchor = index('insert')
    @status = status
  end

  def brk
    Tk.callback_break
  end

  def setup_bindings
    bind("Key-Return") {
      brk unless process_commandline
    }

    for k in %w(BackSpace Left) do
      bind("Key-#{k}") {
        brk unless after_anchor?
      }
    end

    bind("Key-Delete") {
      brk if before_anchor?
    }

    bind("Key-Home") {
      set_insert @anchor
      brk
    }

    bind("Key-Up") {
      if (s = @irb.history(:prev))
        clear
        insert 'end', s
      end
      brk
    }

    bind("Key-Down") {
      if (s = @irb.history(:next))
        clear
        insert 'end', s
      end
      brk
    }

  end

  def clear
    delete(@anchor, 'end')
  end

  def print(obj)
    insert('end', obj.to_s)
    @anchor = index('insert')
  end

  def cmp_anchor
    ix = index('insert')
    (@anchor.split(".") <=> ix.split("."))
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

  def process_commandline
    unless @irb
      @status.text = "irb not ready"
      return false
    end

    ix = index('insert')
    return false if not after_anchor?

    txt = get(@anchor, ix)
    @irb.process_commandline(txt)
    return true
  end
end

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
