#!/bin/zsh

#colors

ALLOWED_GIT=(
  'https://github.com/'
  'https://gitlab.com/'
)


function _deer_wget() {
  local plug_file=$(echo "$1" | rev | cut -d "/" -f1 | rev)
  wget "$1" -O "$plug_file"
  mv "$plug_file" "$DEER_DIR/$plug_file"
  _deer_try_source "$DEER_DIR/$plug_file"
}

ERRORS=(
  FILE_NOT_EXIST
  GIT_REPO_NOT_ALLOWED
)
_info_MSGS=(
  CLONING
  UPDATING
  INSTALLING
  UPDATE_NOTICE
  TOGGLE
)
typeset -Ag color; color=(
reset '\e[0m'
green '\e[32m'
bold '\e[1m'
red '\e[31m'
blue '\e[34m'
)
# exports
export DEER_DIR="$HOME/.local/share/deer"
export DEER_PLUG_DIR="$HOME/.local/share/deer/plugins"

# preset check

if [ ! -d "$DEER_PLUG_DIR" ]; then
  mkdir -p "$DEER_PLUG_DIR"
fi


function _die() {
  case "$1" in 
    (FILE_NOT_EXIST)
      echo -e "$color[red]$color[bold]ERROR: File: \"$color[reset]$color[bold]$2$color[red]\" does not exist.$color[reset]" 
      return ;;
    (GIT_REPO_NOT_ALLOWED)
      echo -e "$color[red]$color[bold]ERROR: Repository: \"$color[reset]$color[bold]$2$color[red]\" is not currently permitted.$color[reset]" 
      return ;;
  esac
}
function _info() {
  case "$1" in 
    (CLONING)
      echo -e "$color[bold]$color[blue]Notice: Cloning repository: \"$color[reset]$2$color[bold]$color[blue]\"$color[reset]" ;;
    (INSTALLING)
      echo -e "$color[bold]$color[red]Notice: Installing plugin: \"$color[reset]$2$color[bold]$color[red]\"$color[reset]" ;;
    (UPDATING)
      echo -e "$color[bold]$color[green]Notice: Updating plugin: \"$color[blue]$2$color[bold]$color[green]\"$color[reset]" ;;
    (UPDATE_NOTICE)
      echo -e "$color[bold]$color[red]Notice: Plugins that are toggled off will not be updated.$color[reset]" ;;
    (TOGGLE)
      echo -e "$color[bold]$color[green]Notice: Toggling plugin: \"$color[blue]$2$color[bold]$color[green]\"$color[reset]" ;;
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
function _deer_check_clone() {
  for i in "${ALLOWED_GIT[@]}"
  do
    if $(git ls-remote "$i/$1" CHECK_GIT_REMOTE_URL_REACHABILITY >/dev/null 2>&1)
    then
      true
      break
    fi
  done
}


function _deer_source_file() {
  if [ -e "$1" ]; then
    source "$1" > /dev/null 2>&1
  fi
}
function toggle () {
  if [ -d "$DEER_DIR/$1" ]; then
    mv "$DEER_DIR/$1" "$DEER_PLUG_DIR" 
    _info TOGGLE "$1"
  elif [ -d "$DEER_PLUG_DIR/$1" ]; then 
    mv "$DEER_PLUG_DIR/$1" "$DEER_DIR/$1" && mkdir "$DEER_PLUG_DIR/$1"
  fi
}
function deerplug() {
  if [[ "$1" =~ "/" ]] 
  then
    if [[ "$1" =~ "https://raw." ]]; then
      zapwget "$1"
    else
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
        _info CLONING "$repo"
        if $vclone
        then
          $(git clone "$1" "$DEER_PLUG_DIR/$repo" > /dev/null 2>&1) || _die FAILED_TO_INSTALL "$repo"
          _info INSTALLING "$repo"
        else
          if $(_deer_check_clone "$1"); then
            $(git clone "$(deer_try_clone $1)$1" "$DEER_PLUG_DIR/$repo" > /dev/null 2>&1) || _die FAILED_TO_INSTALL "$repo"
            _info INSTALLING "$repo"
          else
            _die FAILED_TO_INSTALL "$repo"
          fi
        fi
      fi
      _deer_source_file "$DEER_PLUG_DIR/$repo/$repo.plugin.zsh" || \
        _deer_source_file "$DEER_PLUG_DIR/$repo/$repo.zsh"
    fi
  fi
}

function deerupdate() {
  local tmpdir=$(pwd)
  cd "$DEER_PLUG_DIR"
  for dir in *
  do
    _info UPDATING "$dir"
    cd "$dir" && git pull > /dev/null 2>&1
    cd ..
  done
  cd "$tmpdir"
}
