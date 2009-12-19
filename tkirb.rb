require 'tk'
require 'guirb'

class TkIrb < TkText
  attr_accessor :irb

  def initialize(container, status)
    super(container)
    bind("Key-Return") {
      Tk.callback_break unless process_commandline
    }
    @anchor = index('insert')
    @status = status
  end

  def print(obj)
    insert('end', obj.to_s)
    @anchor = index('insert')
  end

  def process_commandline
    unless @irb
      @status.text = "irb not ready"
      return false
    end

    ix = index('insert')
    return false if (@anchor.split(".") <=> ix.split(".")) > -1

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
