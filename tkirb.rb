require 'tk'
require_relative 'guirb'
require_relative 'tkapp'

if __FILE__ == $0
  Thread.abort_on_exception = true
  app = Application.new
  repl = IrbRunner.new(app.editor)
  app.editor.connect(repl)
  Tk.mainloop()
end
