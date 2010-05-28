class FXIrb < Fox::FXText
  private

  def onKeyRelease(sender, sel, event)
    case event.code
    when KEY_Return, KEY_KP_Enter
      new_line_entered unless empty_frame?
    end
    return 1
  end

  def onKeyPress(sender,sel,event)
    case event.code
    when KEY_Return, KEY_KP_Enter
      move_to_end_of_frame
      super unless empty_frame?

    when KEY_Up, KEY_KP_Up
      multiline = true if get_from_start_of_line =~ /\n/
      multiline ? super : history(:prev)
      move_to_start_of_line if invalid_pos?

    when KEY_Down, KEY_KP_Down
      multiline = true if get_to_end_of_line =~ /\n/
      multiline ? super : history(:next)

    when KEY_Left, KEY_KP_Left
      super if can_move_left?

    when KEY_Delete, KEY_KP_Delete, KEY_BackSpace
      if event.shift? or event.ctrl?
        event.code == KEY_BackSpace ? 
          delete_from_start_of_line :
          delete_to_end_of_line
      elsif can_move_left?
        super
      end

    when KEY_Home, KEY_KP_Home
      move_to_start_of_line

    when KEY_End, KEY_KP_End
      move_to_end_of_line

    when KEY_Page_Up, KEY_KP_Page_Up
      history(:prev)

    when KEY_Page_Down, KEY_KP_Page_Down
      history(:next)

    when KEY_bracketright, KEY_braceright
      #auto-auto_dedent if the } or ] is on a line by itself
      auto_dedent if empty_frame? and indented?
      super

    when KEY_u
      event.ctrl? ? delete_from_start_of_line : super

    when KEY_k
      event.ctrl? ? delete_to_end_of_line :  super

    when KEY_d
      if event.ctrl? and empty_frame?
        quit_irb
      else
        # test for 'end' so we can auto_dedent
        if (get_frame == "en") and indented?
          auto_dedent
        end
        super
      end

    else
      super
    end
  end
end
