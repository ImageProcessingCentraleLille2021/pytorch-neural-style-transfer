#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Create a video using style transfer.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-f, --flag      Some flag description
-p, --param     Some param description
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    # shellcheck disable=SC2034
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  flag=0
  param=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -f | --flag) flag=1 ;; # example flag
    -p | --param)          # example named parameter
      param="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  #[[ -z "${param-}" ]] && die "Missing required parameter: param"
  #[[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}

parse_params "$@"

mkdir -p "$SCRIPT_DIR/videos"
mkdir -p "$SCRIPT_DIR/data/content-images/source"

youtube-dl --format "best[height<=360]" -o "$SCRIPT_DIR/videos/video.mp4" 'https://www.youtube.com/watch?v=3V0oqnrml0o'

ffmpeg -i "$SCRIPT_DIR/videos/video.mp4" -ss 04:00 -to 04:01 -s 128x128 -r 6 -f image2 "$SCRIPT_DIR/data/content-images/source/image-%3d.png"

images=$(find "$SCRIPT_DIR"/data/content-images/source -name "*.png")

for img in $images; do
  python "$SCRIPT_DIR/neural_style_transfer.py" \
  --content_img_name "$img" \
  --style_img_name "$SCRIPT_DIR/data/style-images/candy.jpg" \
  --output_img_name "$(basename "$img")" \
  --output_directory "$SCRIPT_DIR/data/output-images"
done

ffmpeg -f image2 -i "$SCRIPT_DIR/data/output-images/image-%03d.png" "$SCRIPT_DIR/videos/video-candy.mpg" -framerate 1
