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

    bind("Control-u") {
      delete(@anchor, index('insert'))
    }

    bind("Control-d") {
      exit
    }
  end
end
