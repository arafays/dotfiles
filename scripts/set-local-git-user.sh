#!/bin/bash

# List of users
declare -A users
users=(
  ["arafays"]="me@arafays.com"
  ["Abdul Rafay Shaikh"]="abdul.rafay@mayabytes.com"
  ["developer"]="dev.test785@gmail.com"
)

# Check if the current directory is a git repository
if [ ! -d ".git" ]; then
  echo "This is not a git repository."
  exit 1
fi

# Display the list of users
echo "Current directory: $(pwd)"
echo "Available users:"
for user in "${!users[@]}"; do
  echo "$user (${users[$user]})"
done
echo "Select a user to set as the local git user:"
select user in "${!users[@]}"; do
  echo "You selected: $user"
  if [[ -n "$user" ]]; then
    echo "You selected: $user (${users[$user]})"
    git config user.name "$user"
    git config user.email "${users[$user]}"
    echo "Git user set to $user (${users[$user]})"
    break
  else
    echo "Invalid selection. Please try again."
  fi
done