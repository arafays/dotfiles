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

# create a function to set the git user
function set_git_user() {
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
}

# Check if local git user is already set
current_name=$(git config user.name)
current_email=$(git config user.email)

if [[ -n "$current_name" && -n "$current_email" ]]; then
  echo "Current local git user is set to: $current_name ($current_email)"
  echo "Do you want to change the local git user? (y/n)"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    set_git_user
  else
    echo "Local git user is not changed."
  fi
else
  echo "No local git user is set."
  set_git_user
fi