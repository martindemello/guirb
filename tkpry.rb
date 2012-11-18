require 'tk'
require_relative 'guipry'
require_relative 'tkapp'

if __FILE__ == $0
  Thread.abort_on_exception = true
  app = Application.new
  repl = PryRunner.new(app.editor)
  app.editor.connect(repl)
  Tk.mainloop()
end
