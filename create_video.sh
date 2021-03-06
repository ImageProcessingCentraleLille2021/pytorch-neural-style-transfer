#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [OPTION]

Create a video using style transfer.

Available options:

-h, --help         Print this help and exit
-v, --verbose      Print script debug info
-c, --config       Use the file config for args. Ignore other args when used
-u, --url          The url of the video
-q, --quality      The quality of the video (144, 240, 360, 480, 720, ...)
-b, --begin-from   The beginning timecode (format mm:ss)
-e, --end-at       The ending timecode (format mm:ss)
-H, --height       The height of the outputed video
-W, --width        The width of the outputed video
-f, --framerate    The framerate of the video (24 for example)
-s, --style        The name of the style file (located in data/style-images)
--gif              Produce a gif instead of mp4
--use-temporal     Use the temporal loss to produce each picture

EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  rm "$SCRIPT_DIR"/data/content-images/source/*
  rm "$SCRIPT_DIR"/data/output-images/*
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m'
    BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    # shellcheck disable=SC2034
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

_msg() {
  echo >&2 -e "${1-}"
}

ok() {
  _msg "${GREEN} [ DONE ] ${NOFORMAT} $*"
}

warn() {
  _msg "${YELLOW} [ WARN ] ${NOFORMAT} $*"
}

error() {
  _msg "${RED} [ERROR] ${NOFORMAT} $*"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  error "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  config=''
  quality=360
  start='00:00'
  end=''
  height=128
  width=128
  framerate=24
  style='candy.jpg'
  format='mp4'
  loss=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    --gif) format="gif" ;;
    --use-temporal) loss="temporal" ;;
    -c | --config)
      config="${2-}"
      shift
      ;;
    -u | --url)
      url="${2-}"
      shift
      ;;
    -q | --quality)
      quality="${2-}"
      shift
      ;;
    -b | --begin-from)
      start="${2-}"
      shift
      ;;
    -e | --end-at)
      end="${2-}"
      shift
      ;;
    -H | --height)
      height="${2-}"
      shift
      ;;
    -W | --width)
      width="${2-}"
      shift
      ;;
    -f | --framerate)
      framerate="${2-}"
      shift
      ;;
    -s | --style)
      style="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done
  # shellcheck source=./config.cfg
  [[ -n "${config-}" ]] && source "$SCRIPT_DIR/$config"
  # check required params and arguments
  [[ -z "${url-}" ]] && die "Missing required parameter: url"

  return 0
}
setup_colors

time_script_start=$(date +%s)

# test if ffmpeg installed
if ! command -v ffmpeg &>/dev/null; then
  die "ffmpeg could not be found"
fi

# test if youtube-dl installed
if ! command -v youtube-dl &>/dev/null; then
  die "youtube-dl could not be found"
fi

parse_params "$@"

mkdir -p "$SCRIPT_DIR/videos"
mkdir -p "$SCRIPT_DIR/data/content-images/source"

youtube-dl --format "best[height<=$quality]" -o "$SCRIPT_DIR/videos/video.mp4" "$url"

ok "Video saved"

if [ -n "$end" ]; then
  ffmpeg -i "$SCRIPT_DIR/videos/video.mp4" \
    -ss "$start" \
    -to "$end" \
    -s "${height}x${width}" \
    -r "$framerate" \
    -f image2 \
    "$SCRIPT_DIR/data/content-images/source/image-%3d.png" &>/dev/null
else
  ffmpeg -i "$SCRIPT_DIR/videos/video.mp4" \
    -ss "$start" \
    -s "${height}x${width}" \
    -r "$framerate" \
    -f image2 \
    "$SCRIPT_DIR/data/content-images/source/image-%3d.png" &>/dev/null
fi

ok "Images extracted from video in $SCRIPT_DIR/data/content-images/source"

images=$(find "$SCRIPT_DIR"/data/content-images/source -name "*.png" | sort)
nb_images=$(echo "$images" | wc -w)
num_image=0

for img in $images; do
  time_start=$(date +%s)
  if [ -n "$loss" ] && [ "$num_image" != 0 ]; then
    previous_num=$(printf "%03d" "$((num_image))")
    previous_img_name="$(dirname "$img")/image-$previous_num.png"

    python "$SCRIPT_DIR/neural_style_transfer.py" \
      --content_img_name "$img" \
      --style_img_name "$SCRIPT_DIR/data/style-images/$style" \
      --output_img_name "$(basename "$img")" \
      --output_directory "$SCRIPT_DIR/data/output-images" \
      --previous_img_name "$previous_img_name" &> /dev/null
  else
    python "$SCRIPT_DIR/neural_style_transfer.py" \
      --content_img_name "$img" \
      --style_img_name "$SCRIPT_DIR/data/style-images/$style" \
      --output_img_name "$(basename "$img")" \
      --output_directory "$SCRIPT_DIR/data/output-images" &>/dev/null
  fi
  time_taken=$(($(date +%s) - time_start))
  num_image=$((num_image + 1))
  ok "$num_image/$nb_images generated in ${time_taken}s"
done

if [ "$format" = "mp4" ]; then
  ffmpeg -r "$framerate" \
    -pattern_type glob \
    -i "$SCRIPT_DIR/data/output-images/*.png" \
    -c:v libx264 \
    -y \
    "$SCRIPT_DIR/videos/video-${style%.*}.$format" &>/dev/null
else
  ffmpeg -r "$framerate" \
    -pattern_type glob \
    -i "$SCRIPT_DIR/data/output-images/*.png" \
    -y \
    "$SCRIPT_DIR/videos/video-${style%.*}.$format" &>/dev/null
fi

ok "Final video generated"

time_script_taken=$(($(date +%s) - time_script_start))
_msg "Script executed in ${time_script_taken}s"

cleanup
