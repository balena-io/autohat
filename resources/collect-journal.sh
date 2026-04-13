#!/usr/bin/env bash
set -euo pipefail

sock="${1:?usage: $0 /path/to/console.sock username [outfile]}"
user="${2:?usage: $0 /path/to/console.sock username [outfile]}"
outfile="${3:-journalctl-$(date +%Y%m%d-%H%M%S).log}"

raw_log=$(mktemp "${outfile}.raw.XXXXXX")
trap 'rm -f "$raw_log"' EXIT

marker="$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
begin_marker="__JOURNAL_BEGIN_${marker}__"
end_marker="__JOURNAL_END_${marker}__"

expect -f - "$sock" "$user" "$raw_log" "$begin_marker" "$end_marker" <<'EXPECT_SCRIPT'
set timeout 120
set sock         [lindex $argv 0]
set user         [lindex $argv 1]
set rawlog       [lindex $argv 2]
set begin_marker [lindex $argv 3]
set end_marker   [lindex $argv 4]

set prompt_re {(?m)^[^\r\n]*[#$] ?$}
set rc 0
log_user 0

spawn socat -,rawer,echo=0,escape=0x1d "unix-connect:$sock"

# --- login ---
send -- "\r"

set need_login 1
expect {
  -re {(?i)login:\s*$} {}
  -re $prompt_re {
    set need_login 0
  }
  timeout { send_user "timed out waiting for login prompt\n"; exit 1 }
  eof     { send_user "console closed before login\n"; exit 1 }
}

if {$need_login} {
  send -- "$user\r"

  expect {
    -re $prompt_re {}
    timeout { send_user "timed out waiting for shell prompt after login\n"; exit 1 }
    eof     { send_user "console closed after login\n"; exit 1 }
  }
}

# --- sanity check ---
send -- "hostname; printf '__HOST_DONE__\\n'\r"
expect {
  -re {([^\r\n]+)\r?\n__HOST_DONE__} {
    send_user "logged in to: $expect_out(1,string)\n"
  }
  timeout { send_user "timed out waiting for hostname output\n"; exit 1 }
  eof     { send_user "console closed during sanity check\n"; exit 1 }
}

# --- collect journal ---
log_file -noappend $rawlog

send -- "printf '%s\\n' '$begin_marker'; journalctl -b --no-pager --output=short-iso; rc=\$?; printf '\\n%s rc=%s\\n' '$end_marker' \"\$rc\"\r"

expect {
  -re "${end_marker} rc=([0-9]+)" {
    set rc $expect_out(1,string)
  }
  timeout { send_user "timed out waiting for journalctl output\n"; exit 1 }
  eof     { send_user "console closed while collecting logs\n"; exit 1 }
}

log_file

# --- close transport cleanly ---
send -- "exit\r"
expect {
  -re {(?i)login:\s*$} {}
  timeout {}
}
close
wait

if {$rc ne "0"} {
  send_user "journalctl exited with rc=$rc\n"
  exit $rc
}

exit 0
EXPECT_SCRIPT

tr -d '\r' <"$raw_log" |
  awk -v b="$begin_marker" -v e="$end_marker" '
      index($0, b) { in_block=1; next }
      index($0, e) { in_block=0; exit }
      in_block { print }
    ' \
    >"$outfile"

echo "wrote $outfile"
