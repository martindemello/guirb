#! /usr/bin/env ruby

require 'fox16'

require 'guirb'
require 'singleton'
require 'fxkeys'

include Fox

class FXEvent
  def ctrl?
    (self.state & CONTROLMASK) != 0
  end

  def shift?
    (self.state & SHIFTMASK) != 0
  end
end

class FXIrb < FXText
  include Responder

  attr_accessor :multiline
  attr_accessor :irb

  def initialize(p, tgt, sel, opts)
    FXMAPFUNC(SEL_KEYRELEASE,        0, "onKeyRelease")
    FXMAPFUNC(SEL_KEYPRESS,          0, "onKeyPress")
    FXMAPFUNC(SEL_LEFTBUTTONPRESS,   0, "onLeftBtnPress")
    FXMAPFUNC(SEL_MIDDLEBUTTONPRESS, 0, "onMiddleBtnPress")
    FXMAPFUNC(SEL_LEFTBUTTONRELEASE, 0, "onLeftBtnRelease")

    super
    setFont(FXFont.new(FXApp.instance, "courier", 9))
    @anchor = 0
    @exit_proc = lambda {}
  end

  def create
    super
    setFocus
  end

  def on_irb_exit(&block)
    @exit_proc = block
  end

  def handle_irb_exit
    instance_eval(&@exit_proc)
  end

  private

  def onLeftBtnPress(sender,sel,event)
    @store_anchor = @anchor
    setFocus
    super
  end

  def onLeftBtnRelease(sender,sel,event)
    super
    @anchor = @store_anchor
    setCursorPos(getLength)
  end

  def onMiddleBtnPress(sender,sel,event)
    pos = getPosAt(event.win_x,event.win_y)
    if pos >= @anchor
      super
    end
  end

  def auto_dedent
    str = get_frame
    @anchor -= 2
    clear_frame
    appendText(str)
    setCursorPos(getLength)
  end

  def history(dir)
    if (s = @irb.history(dir))
      clear_frame
      write(s)
    end
  end

  def quit_irb
    clear_frame
    appendText("exit")
    new_line_entered
    handle_irb_exit
  end

  def get_frame
    extractText(@anchor, getLength-@anchor)
  end

  def invalid_pos?
    getCursorPos < @anchor
  end

  def can_move_left?
    getCursorPos > @anchor
  end

  def move_to_start_of_frame
    setCursorPos(@anchor)
  end

  def move_to_end_of_frame
    setCursorPos(getLength)
  end

  def move_to_start_of_line
    if multiline
      cur = getCursorPos
      pos = lineStart(cur)
      pos = @anchor if pos < @anchor
    else
      pos = @anchor
    end
    setCursorPos(pos)
  end

  def move_to_end_of_line
    if multiline
      cur = getCursorPos
      pos = lineEnd(cur)
    else
      pos = getLength
    end
    setCursorPos(pos)
  end

  def get_from_start_of_line
    extractText(@anchor, getCursorPos-@anchor)
  end

  def get_to_end_of_line
    extractText(getCursorPos, getLength - getCursorPos)
  end

  def clear_frame
    removeText(@anchor, getLength-@anchor)
  end

  def delete_from_start_of_line
    str = get_to_end_of_line
    clear_frame
    appendText(str)
    setCursorPos(@anchor)
  end

  def delete_to_end_of_line
    str = get_from_start_of_line
    clear_frame
    appendText(str)
    setCursorPos(getLength)
  end

  def empty_frame?
    get_frame == ""
  end

  def indented?
    extractText(@anchor-2, 2) == "  "
  end

  def new_line_entered
    process_commandline(get_frame)
  end

  def process_commandline(cmd)
    @irb.process_commandline(cmd)
  end

  public

  def send_command(cmd)
    setCursorPos(getLength)
    makePositionVisible(getLength) unless isPosVisible(getLength)
    cmd += "\n"
    appendText(cmd)
    process_commandline(cmd)
  end

  def write(obj)
    str = obj.to_s
    appendText(str)
    setCursorPos(getLength)
    makePositionVisible(getLength) unless isPosVisible(getLength)
    return str.length
  end

  def print(obj)
    write(obj)
    @anchor = getCursorPos
  end
end

# Stand alone run
if __FILE__ == $0
  application = FXApp.new("FXIrb", "ruby")
  application.threadsEnabled = true
  Thread.abort_on_exception = true
  window = FXMainWindow.new(application, "FXIrb",
                            nil, nil, DECOR_ALL, 0, 0, 580, 500)
  editor = FXIrb.new(window, nil, 0,
                     LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP|TEXT_SHOWACTIVE)
  application.create
  window.show(PLACEMENT_SCREEN)
  editor.on_irb_exit {exit}
  irb = IrbRunner.new(editor)
  editor.irb = irb
  application.run
end
