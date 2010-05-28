class TkText
  def setup_bindings
    bind("Key-Return") {
      brk unless can_process_commandline
      auto_dedent
      set_insert 'end'
      process_commandline
      yview_pickplace 'end'
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
      history(:prev)
      brk
    }

    bind("Key-Down") {
      history(:next)
      brk
    }

    bind("Control-u") {
      delete(@anchor, index('insert'))
    }

    bind("Control-d") {
      on_irb_exit
    }
  end
end
