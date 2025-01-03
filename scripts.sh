
# Git commit with custom date and random time
function git-commit-with-date() {
  if [ "$#" -lt 1 ]; then
    echo "Usage: git-commit-with-date <commit message>"
    return 1
  fi

  local input_date=$(date -j -f "%Y-%m-%d" "$1" "+%Y-%m-%dT%H:%M:%S" 2> /dev/null)
  local last_commit_date=$(git log -1 --format=%cd --date=iso-strict)

  if [ "$input_date" != "" ] && [ $(date -j -f "%Y-%m-%dT%H:%M:%S" "$input_date" "+%s") -gt $(date -j -f "%Y-%m-%dT%H:%M:%S" "$last_commit_date" "+%s") ]; then
    last_commit_date="$input_date"
  fi

  if [ -z "$last_commit_date" ]; then
    # If there is no commit, use a random time at or after 7am
    local random_time=$(printf "%02d:%02d:%02d" $((RANDOM % 5 + 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    last_commit_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$last_commit_date" "+%Y-%m-%dT%H:%M:%S")
  else
    # If there is a commit, use a random time after that of the last commit
    local random_minutes=$((RANDOM % 60 + 10))  # Random number of minutes between 10 and 60
    last_commit_date=$(date -j -v+${random_minutes}M -f "%Y-%m-%dT%H:%M:%S" "$last_commit_date" "+%Y-%m-%dT%H:%M:%S")
  fi

  GIT_AUTHOR_DATE="$last_commit_date" GIT_COMMITTER_DATE="$last_commit_date" git commit ${@:2}
}
