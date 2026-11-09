#!/bin/sh
# Claude Code sets up its cross-session messaging socket under /tmp and refuses
# a world-writable /tmp without the sticky bit, which is what a pod emptyDir with
# fsGroup produces (mode 2777, root-owned, so the workspace user cannot chmod it).
# Point the socket at the private TMPDIR instead. The flag has to come before any
# subcommand, so it is prepended here for every invocation.
real="${HOME}/.local/bin/claude"
[ -x "$real" ] || { echo "claude is not installed (agent.preset is not claude-code?)" >&2; exit 127; }
# `remote-control` refuses the flag (it cannot carry it over to the sessions it
# starts) and its headless sessions have no TUI to show the /tmp warning in.
[ "$1" = "remote-control" ] && exec "$real" "$@"
exec "$real" --messaging-socket-path "${TMPDIR:-${HOME}/.tmp}/messaging-$$.sock" "$@"
