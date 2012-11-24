require_relative 'tkrepl'

class Application
  attr_accessor :editor

  def initialize
    root = TkRoot.new() { title "TkRepl" }
    frame = TkFrame.new(root).pack("side"=>"right")
    buttons = TkFrame.new(frame).pack("side"=>"bottom")
    quit = TkButton.new(buttons) {
      text "Exit"
      command lambda { exit }
    }
    TkGrid.configure(quit)
    display = TkFrame.new(root).pack("side"=>"left")
    status = TkLabel.new(display)
    editor = TkRepl.new(display, status).pack()  # top
    editor.on_repl_exit {exit}
    status.pack("side"=>"bottom", "anchor"=>"w")
    frame.pack("fill"=>"y")
    display.pack("fill"=>"both", "expand"=>true)
    status.pack("before"=>editor)
    editor.pack("fill"=>"both", "expand"=>true)
    editor.focus
    @editor = editor
  end
end

