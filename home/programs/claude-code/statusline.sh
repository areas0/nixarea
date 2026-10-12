# NERV-style status line for Claude Code. Reads the session JSON on stdin.
# Wrapped by writeShellApplication (see default.nix): jq and git come from runtimeInputs.
input=$(cat)

model=$(jq -r '.model.display_name // "MAGI"' <<<"$input")
cwd=$(jq -r '.workspace.current_dir // .cwd // "."' <<<"$input")
ctx=$(jq -r '.context_window.used_percentage // 0 | floor' <<<"$input")
cost=$(jq -r '.cost.total_cost_usd // 0' <<<"$input")

branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || true)
dirty=""
if [ -n "$branch" ] && [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null || true)" ]; then
  dirty="*"
fi

# Show the home directory as ~
case "$cwd" in
"$HOME"*) cwd="~${cwd#"$HOME"}" ;;
*) ;;
esac

esc=$'\033'
orange="${esc}[38;2;255;106;0m"
purple="${esc}[38;2;139;79;196m"
green="${esc}[38;2;124;252;0m"
blue="${esc}[38;2;111;183;255m"
red="${esc}[38;2;255;42;42m"
dim="${esc}[38;2;122;110;143m"
rst="${esc}[0m"

# Sync rate colour: green while healthy, orange above 60%, red above 85% (pattern orange).
sync="$green"
if [ "$ctx" -gt 85 ]; then
  sync="$red"
elif [ "$ctx" -gt 60 ]; then
  sync="$orange"
fi

# LC_NUMERIC=C: printf rejects "1.23" under a decimal-comma locale (fr_FR)
price=$(LC_NUMERIC=C printf '$%.2f' "$cost")

out="${orange}NERV${rst} ${dim}▸${rst} ${purple}${model}${rst} ${dim}▸${rst} ${blue}${cwd}${rst}"
if [ -n "$branch" ]; then
  out+=" ${green}⎇ ${branch}${dirty}${rst}"
fi
out+=" ${dim}▸${rst} ${sync}SYNC ${ctx}%${rst} ${dim}▸${rst} ${orange}${price}${rst}"

printf '%s\n' "$out"
