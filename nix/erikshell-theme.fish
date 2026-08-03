# 337 themes is more than anyone remembers the spelling of, so the slugs are
# the completion. Read from the shell's catalogue every time rather than baked
# in here: the list is generated, and a stale copy of it would be a lie.
complete -c erikshell-theme -f -a "(erikshell-theme --slugs)"
complete -c erikshell-theme -f -s h -l help -d "usage"
