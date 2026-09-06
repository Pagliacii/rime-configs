#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target=
skip_upstream=false
skip_deploy=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) target=$2; shift 2 ;;
    --skip-upstream) skip_upstream=true; shift ;;
    --skip-deploy) skip_deploy=true; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

platform=$(uname -s)
if [ -z "$target" ]; then
  case "$platform" in
    Darwin) target="$HOME/Library/Rime" ;;
    Linux)
      if [ -d "$HOME/.config/ibus/rime" ]; then
        target="$HOME/.config/ibus/rime"
      else
        target="$HOME/.local/share/fcitx5/rime"
      fi
      ;;
    *) echo 'Cannot detect the Rime user directory; pass --target.' >&2; exit 2 ;;
  esac
fi
mkdir -p "$target"

if [ "$skip_upstream" = false ]; then
  version=$(tr -d '\r\n' < "$repo/rime-ice.version")
  cache_root=${XDG_CACHE_HOME:-"$HOME/.cache"}
  plum="$cache_root/rime-plum"
  if [ -d "$plum/.git" ]; then
    git -C "$plum" pull --ff-only
  else
    git clone --depth 1 https://github.com/rime/plum.git "$plum"
  fi
  phrase="$target/custom_phrase.txt"
  phrase_backup=
  restore_phrase() {
    if [ -n "$phrase_backup" ]; then
      cp "$phrase_backup" "$phrase"
      rm -f "$phrase_backup"
    fi
  }
  if [ -f "$phrase" ]; then
    phrase_backup=$(mktemp)
    cp "$phrase" "$phrase_backup"
    trap restore_phrase 0
  fi
  rime_dir="$target" bash "$plum/rime-install" "iDvel/rime-ice@$version"
  restore_phrase
  phrase_backup=
  trap - 0
fi

cp "$repo"/common/*.yaml "$target"/
cp "$repo"/legacy/*.yaml "$target"/
if [ "$platform" = Darwin ] && [ -d "$repo/squirrel" ]; then
  cp "$repo"/squirrel/*.yaml "$target"/
fi

if [ "$skip_deploy" = false ]; then
  echo 'Configuration installed. Redeploy your Rime frontend to activate it.'
fi
echo "Rime configuration installed in $target"
