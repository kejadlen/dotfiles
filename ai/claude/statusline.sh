#!/bin/bash
# Usage: statusline.sh [--short-model]
#   --short-model  Show abbreviated model name (e.g., "sonnet-4.5")
#   Default shows the full model ID

# Read JSON input from stdin
input=$(cat)

# Extract model name
model_id=$(echo "$input" | jq -r '.model.id')
if [[ "$1" == "--short-model" ]]; then
    model=$(echo "$model_id" | sed -E 's/^.*claude-//; s/-[0-9]{8,}.*$//; s/^([a-z]+)-([0-9]+)-([0-9]+)$/\1-\2.\3/')
else
    model="$model_id"
fi

# Get the default model from settings and format it the same way
default_model=$(jq -r '.model // "sonnet"' ~/.claude/settings.json)

# Only show model if it's not the default
if [[ "$model" =~ ^${default_model} ]]; then
    model=''
fi

# Get current working directory
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Get output style
style=$(echo "$input" | jq -r '.output_style.name')

# Get git repository name and root (or fall back to current directory)
repo=''
git_root=''
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
    repo=$(basename "$git_root" 2>/dev/null)
fi
if [ -z "$repo" ]; then
    repo=$(basename "$cwd")
fi

# Calculate relative path if cwd differs from git root
rel_path=''
if [ -n "$git_root" ] && [ "$cwd" != "$git_root" ]; then
    rel_path="${cwd#$git_root/}"
fi

# Get git branch
branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo '')

# Calculate context window usage
ctx=''
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != 'null' ]; then
    cur=$(($(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')))
    sz=$(echo "$input" | jq '.context_window.context_window_size')
    pct=$((cur * 100 / sz))

    # Format token counts as "125k" or "1.0M"
    fmt_tokens() {
        if [ "$1" -ge 1000000 ]; then
            printf '%s.%sM' $(($1 / 1000000)) $(($1 % 1000000 / 100000))
        else
            printf '%sk' $(($1 / 1000))
        fi
    }
    cur_fmt=$(fmt_tokens "$cur")
    sz_fmt=$(fmt_tokens "$sz")

    # Color shifts with usage: green < 50%, yellow 50-80%, red > 80%
    if [ "$pct" -gt 80 ]; then
        color='31' # red
    elif [ "$pct" -gt 50 ]; then
        color='33' # yellow
    else
        color='32' # green
    fi

    ctx=$(printf " \033[2m•\033[0m \033[%sm%s/%s %s%%\033[0m" "$color" "$cur_fmt" "$sz_fmt" "$pct")
fi

# Format output style
sty=''
if [ "$style" != 'null' ] && [ "$style" != 'default' ]; then
    sty=$(printf " \033[2m•\033[0m \033[35m%s\033[0m" "$style")
fi

# Calculate session cost
cost=''
total_input=$(echo "$input" | jq '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq '.context_window.total_output_tokens // 0')
if [ "$total_input" != "0" ] || [ "$total_output" != "0" ]; then
    # Pricing per million tokens (as of Jan 2025)
    # Opus 4.5: $15 input, $75 output
    # Sonnet 4.5: $3 input, $15 output
    # Haiku 4.5: $0.80 input, $4 output
    if [[ "$model_id" =~ opus ]]; then
        input_cost=$(echo "scale=4; $total_input * 15 / 1000000" | bc)
        output_cost=$(echo "scale=4; $total_output * 75 / 1000000" | bc)
    elif [[ "$model_id" =~ haiku ]]; then
        input_cost=$(echo "scale=4; $total_input * 0.80 / 1000000" | bc)
        output_cost=$(echo "scale=4; $total_output * 4 / 1000000" | bc)
    else
        # Default to Sonnet pricing
        input_cost=$(echo "scale=4; $total_input * 3 / 1000000" | bc)
        output_cost=$(echo "scale=4; $total_output * 15 / 1000000" | bc)
    fi
    total_cost=$(echo "scale=4; $input_cost + $output_cost" | bc)
    # Only show if non-zero
    if (( $(echo "$total_cost > 0" | bc -l) )); then
        cost=$(printf " \033[2m•\033[0m \033[36m\$%.2f\033[0m" "$total_cost")
    fi
fi

# Build location string (repo:branch/path or just repo)
loc=$(printf "\033[34m%s\033[0m" "$repo")
if [ -n "$branch" ]; then
    loc=$(printf "%s\033[2m:\033[0m\033[36m%s\033[0m" "$loc" "$branch")
fi
if [ -n "$rel_path" ]; then
    loc=$(printf "%s\033[2m/\033[0m\033[33m%s\033[0m" "$loc" "$rel_path")
fi

# Build the status line with left-aligned prefix
# Format: ✴ model • location • context • cost • style
parts=""
if [ -n "$model" ]; then
    parts=$(printf "\033[32m%s\033[0m" "$model")
    if [ -n "$loc" ] || [ -n "$ctx" ] || [ -n "$cost" ] || [ -n "$sty" ]; then
        parts=$(printf '%s \033[2m•\033[0m' "$parts")
    fi
fi

# Add location
if [ -n "$loc" ]; then
    parts="${parts} ${loc}"
fi

# Add remaining parts
parts="${parts}${ctx}${cost}${sty}"

# Current time
parts=$(printf "%s \033[2m•\033[0m \033[2m%s\033[0m" "$parts" "$(date +%H:%M)")

printf "✴️ %s\n" "$parts"
