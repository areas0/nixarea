# NERV-style status line for Claude Code. Reads the session JSON on stdin.
# Wrapped by writeShellApplication (see default.nix): jq and git come from runtimeInputs.
input=$(cat)

# A single jq call for every field, since this runs after each assistant message.
# Absent values become "-": read would collapse empty tab-separated fields.
IFS=$'\t' read -r model cwd ctx cost five seven effort pr_num pr_state worktree agent < <(
  jq -r '[
    (.model.display_name // "MAGI"),
    (.workspace.current_dir // .cwd // "."),
    ((.context_window.used_percentage // 0) | floor),
    (.cost.total_cost_usd // 0),
    ((.rate_limits.five_hour.used_percentage // null) | if . == null then "-" else floor end),
    ((.rate_limits.seven_day.used_percentage // null) | if . == null then "-" else floor end),
    (.effort.level // "-"),
    (.pr.number // "-"),
    (.pr.review_state // "-"),
    (.worktree.name // "-"),
    (.agent.name // "-")
  ] | map(tostring) | @tsv' <<<"$input"
)

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

# Green while healthy, orange above 60%, red above 85% (pattern orange).
level() {
  if [ "$1" -gt 85 ]; then
    printf '%s' "$red"
  elif [ "$1" -gt 60 ]; then
    printf '%s' "$orange"
  else
    printf '%s' "$green"
  fi
}

# Ten-cell gauge, filled in proportion to the percentage.
bar() {
  local filled=$(($1 * 10 / 100)) i out=""
  if [ "$filled" -gt 10 ]; then
    filled=10
  fi
  for ((i = 0; i < 10; i++)); do
    if [ "$i" -lt "$filled" ]; then
      out+="█"
    else
      out+="░"
    fi
  done
  printf '%s' "$out"
}

# LC_NUMERIC=C: printf rejects "1.23" under a decimal-comma locale (fr_FR)
price=$(LC_NUMERIC=C printf '$%.2f' "$cost")

sep=" ${dim}▸${rst} "

# Line 1: where the pilot is.
line1="${orange}NERV${rst}${sep}${purple}${model}${rst}${sep}${blue}${cwd}${rst}"
if [ -n "$branch" ]; then
  line1+=" ${green}⎇ ${branch}${dirty}${rst}"
fi
if [ "$worktree" != "-" ]; then
  line1+=" ${dim}[${worktree}]${rst}"
fi
if [ "$pr_num" != "-" ]; then
  case "$pr_state" in
  approved) pr_color="$green" ;;
  changes_requested) pr_color="$red" ;;
  *) pr_color="$dim" ;;
  esac
  line1+="${sep}${pr_color}PR #${pr_num}"
  if [ "$pr_state" != "-" ]; then
    line1+=" ${pr_state}"
  fi
  line1+="${rst}"
fi
if [ "$agent" != "-" ]; then
  line1+="${sep}${purple}${agent}${rst}"
fi

# Line 2: the pilot's state. The A.T. Field gauges only exist on Pro and Max plans.
ctx_color=$(level "$ctx")
line2="${dim}SYNC${rst} ${ctx_color}$(bar "$ctx") ${ctx}%${rst}"
if [ "$five" != "-" ]; then
  line2+="${sep}${dim}A.T. FIELD 5h${rst} $(level "$five")${five}%${rst}"
  if [ "$seven" != "-" ]; then
    line2+=" ${dim}7d${rst} $(level "$seven")${seven}%${rst}"
  fi
fi
if [ "$effort" != "-" ]; then
  line2+="${sep}${dim}EFFORT${rst} ${purple}${effort}${rst}"
fi
line2+="${sep}${orange}${price}${rst}"

printf '%s\n%s\n' "$line1" "$line2"
