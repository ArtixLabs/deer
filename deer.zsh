#!/bin/zsh

#colors

ALLOWED_GIT=(
  'https://github.com/'
  'https://gitlab.com/'
)



ERRORS=(
  FILE_NOT_EXIST
  GIT_REPO_NOT_ALLOWED
)
INFO_MSGS=(
  CLONING
  INSTALLING
)
typeset -Ag color; color=(
  reset '\e[0m'
  bold '\e[1m'
  red '\e[31m'
  blue '\e[34m'
)
# exports

export DEER_PLUG_DIR="$HOME/.local/share/deer"

# preset check

if [ ! -d "$DEER_PLUG_DIR" ]; then
  mkdir -p "$DEER_PLUG_DIR"
fi


function die() {
  case "$1" in 
    (FILE_NOT_EXIST)
      echo -e "$color[red]$color[bold]ERROR: File: \"$color[reset]$color[bold]$2$color[red]\" does not exist.$color[reset]" 
      return ;;
    (GIT_REPO_NOT_ALLOWED)
      echo -e "$color[red]$color[bold]ERROR: Repository: \"$color[reset]$color[bold]$2$color[red]\" is not currently permitted.$color[reset]" 
      return ;;
  esac
}
function info() {
  case "$1" in 
    (CLONING)
      echo -e "$color[bold]$color[blue]Notice: Cloning repository: \"$color[reset]$2$color[bold]$color[blue]\"$color[reset]" ;;
    (INSTALLING)
      echo -e "$color[bold]$color[red]Notice: Installing plugin: \"$color[reset]$2$color[bold]$color[red]\"$color[reset]" ;;
  esac
}

function deer_try_clone() {
  for i in "${ALLOWED_GIT[@]}"
  do
    if $(git ls-remote "$i/$1" CHECK_GIT_REMOTE_URL_REACHABILITY >/dev/null 2>&1)
    then
      echo -e "$i"
      break
    fi
  done
}


function deer_source_file() {
  if [ -e "$1" ]; then
    source "$1" > /dev/null 2>&1
  fi
}

function deerplug() {
  local repo=$(echo "$1" | rev | cut -d "/" -f1 | rev)
  local vclone=false
  if [ ! -d "$DEER_PLUG_DIR/$repo" ]
  then
    for git_repo in "${ALLOWED_GIT[@]}"
    do
      if [[ "$1" =~ "\"$git_repo\"" ]]
      then
        vclone=true
        break
      fi
    done
    info CLONING "$repo"
    if $vclone
    then
      $(git clone "$1" "$DEER_PLUG_DIR/$repo" > /dev/null 2>&1) || die FAILED_TO_INSTALL "$repo"
      info INSTALLING "$repo"
    else
      $(git clone "$(deer_try_clone $1)$1" "$DEER_PLUG_DIR/$repo" > /dev/null 2>&1) || die FAILED_TO_INSTALL "$repo"
      info INSTALLING "$repo"
    fi
  fi
  deer_source_file "$DEER_PLUG_DIR/$repo/$repo.plugin.zsh" || \
    deer_source_file "$DEER_PLUG_DIR/$repo/$repo.zsh"
}
