#!/usr/bin/env bash
# PermissionRequest hook: Hyprland dialog that's hard to miss.
#  - sound + noctalia toast on open, repeated every REMIND seconds until answered
#  - dialog window is pinned (visible on every workspace) and re-focused on each reminder
# No answer within TIMEOUT => prints nothing => falls back to the terminal prompt.
TIMEOUT=${CLAUDE_PERM_TIMEOUT:-120}
REMIND=${CLAUDE_PERM_REMIND:-15}
SOUND=@sound@

in=$(cat)
# keep the raw payload so we can see exactly what Claude Code sends
mkdir -p ~/.cache/claude-perm; printf '%s\n' "$in" >> ~/.cache/claude-perm/payloads.jsonl
tool=$(jq -r '.tool_name' <<<"$in")
cwd=$(jq -r '.cwd // "?"' <<<"$in")
mode=$(jq -r '.permission_mode // "?"' <<<"$in")
sid=$(jq -r '.session_id // "?"' <<<"$in")
desc=$(jq -r '.tool_input.description // empty' <<<"$in")
# main input: command / path / pretty JSON, plus any remaining fields
detail=$(jq -r '.tool_input.command // .tool_input.file_path // (.tool_input|tojson)' <<<"$in" | head -c 450)
extra=$(jq -r '.tool_input | del(.command,.description,.file_path) | select(length>0) | to_entries[] | "  \(.key): \(.value|tostring|.[0:300])"' <<<"$in" 2>/dev/null | head -20)
sugg=$(jq -r '(.permission_suggestions // [])[] | "  - " + (.type // "?") + ": " + ((.rules // [])|map((.toolName // "") + (if .ruleContent then "(" + .ruleContent + ")" else "" end))|join(", ")) + " [" + (.behavior // "") + " -> " + (.destination // "") + "]"' <<<"$in" 2>/dev/null | head -5)
# what Claude said right before this call (last assistant text in the transcript)
tp=$(jq -r '.transcript_path // empty' <<<"$in")
said=""
[ -r "$tp" ] && said=$(tac "$tp" | jq -r 'select(.type=="assistant") | [.message.content[]? | select(.type=="text") | .text] | join(" ") | select(length>0)' 2>/dev/null | head -1 | head -c 600)

# dialog is fixed-size (~550x385): most important first, compact, hard-capped
text="$tool in ${cwd/#$HOME/~}  ·  $mode  ·  ${sid:0:8}"
text+=$'\n\n'"$detail"
[ -n "$desc" ] && text+=$'\n\nWhy: '"$desc"
[ -n "$said" ] && text+=$'\n\nClaude: '"${said:0:250}"
[ -n "$extra" ] && text+=$'\n\n'"$(tr '\n' ' ' <<<"$extra" | tr -s ' ' | head -c 160)"
if [ -n "$sugg" ]; then
  first=${sugg%%$'\n'*}
  text+=$'\n\nAlways-allow: '"$(head -c 160 <<<"${first#"  - "}")"
fi
text=$(head -c 900 <<<"$text")
detail="$text"

# address of the Hyprland window hosting this Claude session (ancestor pid that owns a client)
term_addr() {
  local clients p=$PPID; clients=$(hyprctl clients -j 2>/dev/null)
  while [ -n "$p" ] && [ "$p" -gt 1 ]; do
    local a; a=$(jq -r --argjson p "$p" '.[]|select(.pid==$p)|.address' <<<"$clients" | head -1)
    [ -n "$a" ] && { echo "$a"; return; }
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  done
}
termwin=$(term_addr)

out=$(mktemp); trap 'kill $dpid 2>/dev/null; rm -f "$out"' EXIT
title="Claude: $tool"

hyprland-dialog --title "Claude Code" --apptitle "$title" --text "$text" \
  --buttons "Allow;Deny;Deny & discuss" >"$out" 2>/dev/null &
dpid=$!

alert() {
  pw-play "$SOUND" 2>/dev/null &
  noctalia msg notification-show "Claude needs permission" "$tool: ${desc:-${detail:0:100}}" >/dev/null 2>&1
  # pin the dialog to all workspaces and pull focus to it
  addr=$(hyprctl clients -j | jq -r --arg t "$title" '.[]|select(.class=="hyprland-dialog" and .title==$t)|.address' | head -1)
  if [ -n "$addr" ]; then
    hyprctl dispatch "hl.dsp.window.pin({window=\"address:$addr\", action=\"enable\"})" >/dev/null 2>&1
    hyprctl dispatch "hl.dsp.focus({window=\"address:$addr\"})" >/dev/null 2>&1
  fi
}

sleep 0.3; alert
elapsed=0
while kill -0 "$dpid" 2>/dev/null && [ "$elapsed" -lt "$TIMEOUT" ]; do
  sleep 1; elapsed=$((elapsed+1))
  [ $((elapsed % REMIND)) -eq 0 ] && alert
done

case "$(cat "$out")" in
  Allow) echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}' ;;
  Deny)  echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"deny","message":"Denied via Hyprland dialog"}}}' ;;
  "Deny & discuss")
    # deny + interrupt so Claude stops and waits; then jump to this session's terminal
    echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"deny","interrupt":true,"message":"The user denied this and wants to discuss it first. Do not retry or work around it; stop and wait for their message."}}}'
    [ -n "$termwin" ] && hyprctl dispatch "hl.dsp.focus({window=\"address:$termwin\"})" >/dev/null 2>&1
    ;;
esac
exit 0
