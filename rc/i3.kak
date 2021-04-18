# Commands #

define-command i3-mode -docstring 'i3wm controls' %{
    require-module i3wm
    evaluate-commands 'enter-user-mode i3'
}

provide-module i3wm %§

declare-option str i3_termcmd ''

define-command -hidden -params 1.. i3-new-impl %{
    evaluate-commands %sh{
        if [ -z "$kak_opt_termcmd" ]; then
          echo "fail 'termcmd option is not set'"
          exit
        fi
        i3_split="$1"
        shift
        # clone (same buffer, same line)
        cursor="$kak_cursor_line.$kak_cursor_column"
        kakoune_args="-e 'execute-keys :buffer <space> $kak_buffile <ret> :select <space> $cursor,$cursor <ret> $@'"
        {
          # https://github.com/i3/i3/issues/1767
          [ -n "$i3_split" ] && i3-msg "split $i3_split"
          exec $kak_opt_termcmd "kak -c ${kak_session} ${kakoune_args}"
        } < /dev/null > /dev/null 2>&1 &
    }
}

define-command i3-new-d -params 0.. -docstring "Create a new window below" %{
    i3-new-impl v %arg{@}
}

define-command i3-new-u -params 0.. -docstring "Create a new window below" %{
    i3-new-impl v :nop <space> '%sh{ i3-msg move up }' <ret> %arg{@}
}

define-command i3-new-r -params 0.. -docstring "Create a new window on the right" %{
    i3-new-impl h %arg{@}
}

define-command i3-new-l -docstring "Create a new window on the left" %{
    i3-new-impl h :nop <space> '%sh{ i3-msg move left }' <ret> %arg{@}
}

define-command i3-new -params 0.. -docstring "Create a new window in the current container" %{
    i3-new-impl "" %arg{@}
}

declare-option -hidden str i3_before_cmd ''
declare-option -hidden str i3_after_cmd ''

define-command -hidden -params 1.. i3-terminal-impl %{
    nop %sh{
        if [ -z "$kak_opt_termcmd" ] && [ -z "$kak_opt_i3_termcmd" ]; then
          echo "fail 'termcmd option is not set'"
          exit
        fi
        {
            sleep 0.3;
            eval $kak_opt_i3_after_cmd
        } > /dev/null 2>&1 < /dev/null &

        {
            i3_termcmd="${kak_opt_i3_termcmd:-$(echo "${kak_opt_termcmd}" | cut -d ' ' -f1)}"
            eval $kak_opt_i3_before_cmd
            setsid $i3_termcmd "$@" < /dev/null > /dev/null 2>&1
        } > /dev/null 2>&1 < /dev/null &
    }
}

define-command i3-terminal-popup -params 1.. -shell-completion -docstring '
i3-terminal <program> [<arguments>]: create a new terminal as a floating window
The program passed as argument will be executed in the new terminal
' \
%{
    fail "not implemented"
}

define-command i3-terminal-b -params 1.. -shell-completion -docstring '
i3-terminal <program> [<arguments>]: create a new terminal underneath current window
The program passed as argument will be executed in the new terminal
' \
%{
    set-option global i3_before_cmd 'i3-msg -q split "v"'
    set-option global i3_after_cmd ''
    i3-terminal-impl %arg{@}
}

define-command i3-terminal-r -params 1.. -shell-completion -docstring '
i3-terminal <program> [<arguments>]: create a new terminal to right of current window
The program passed as argument will be executed in the new terminal
' \
%{
    set-option global i3_before_cmd 'i3-msg -q split h'
    set-option global i3_after_cmd ''
    i3-terminal-impl %arg{@}
}

define-command i3-terminal-l -params 1.. -shell-completion -docstring '
i3-terminal <program> [<arguments>]: create a new terminal to right of current window
The program passed as argument will be executed in the new terminal
' \
%{
    set-option global i3_before_cmd 'i3-msg -q split h'
    set-option global i3_after_cmd 'i3-msg -q move left'
    i3-terminal-impl %arg{@}
}

define-command i3-terminal-t -params 1.. -shell-completion -docstring '
i3-terminal <program> [<arguments>]: create a new terminal to top of current window
The program passed as argument will be executed in the new terminal
' \
%{
    set-option global i3_before_cmd 'i3-msg -q split v'
    set-option global i3_after_cmd 'i3-msg -q move up'
    i3-terminal-impl %arg{@}
}

declare-user-mode i3
map global i3 n :i3-new<ret> -docstring "new window in the current container"
map global i3 h :i3-new-l<ret> -docstring '← new window on the left'
map global i3 l :i3-new-r<ret> -docstring '→ new window on the right'
map global i3 k :i3-new-u<ret> -docstring '↑ new window above'
map global i3 j :i3-new-d<ret> -docstring '↓ new window below'

§
