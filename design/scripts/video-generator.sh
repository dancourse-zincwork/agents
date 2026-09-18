#!/bin/bash
#
# Learning Video Generator
# Creates narrated videos from slides using OpenAI TTS + ffmpeg
# Completely local/free video assembly (only cost is TTS API)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env file if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Defaults
DEFAULT_VOICE="nova"
DEFAULT_MODEL="gpt-4o-mini-tts"
DEFAULT_INSTRUCTIONS="Speak in a warm, engaging tone suitable for a learning video. Be clear and conversational, like a friendly instructor."

# ElevenLabs defaults
ELEVENLABS_MODEL="${ELEVENLABS_MODEL:-eleven_multilingual_v2}"  # eleven_multilingual_v2 (better quality) or eleven_turbo_v2 (faster/cheaper)
TTS_PROVIDER="${TTS_PROVIDER:-elevenlabs}"  # elevenlabs or openai

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_error() { echo -e "${RED}Error: $1${NC}" >&2; }
print_success() { echo -e "${GREEN}$1${NC}"; }
print_info() { echo -e "${YELLOW}$1${NC}"; }
print_step() { echo -e "${CYAN}→ $1${NC}"; }

check_api_key() {
    if [ -z "$OPENAI_API_KEY" ]; then
        print_error "OPENAI_API_KEY not set"
        echo "Either:"
        echo "  1. Add it to $SCRIPT_DIR/.env"
        echo "  2. Or: export OPENAI_API_KEY='your-key'"
        exit 1
    fi
}

check_dependencies() {
    local missing=()
    command -v jq &>/dev/null || missing+=("jq")
    command -v curl &>/dev/null || missing+=("curl")
    command -v ffmpeg &>/dev/null || missing+=("ffmpeg")

    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing[*]}"
        echo "Install with: brew install ${missing[*]}"
        exit 1
    fi
}

usage() {
    cat << EOF
Learning Video Generator - OpenAI TTS + ffmpeg

Usage: $0 <action> [options]

Actions:
  generate      Generate video from script JSON + slide images
  audio-only    Generate audio files only (no video)
  list-voices   Show available TTS voices

Generate Options:
  --json        Path to video-script.json (required)
  --slides      Path to folder containing slide images (required)
  --output      Output video filename (default: output.mp4)
  --voice       TTS voice: alloy, echo, fable, onyx, nova, shimmer (default: nova)
  --instructions Custom speaking instructions for TTS

Examples:
  $0 generate --json ./video-script.json --slides ./slide-images --output lesson.mp4
  $0 audio-only --json ./video-script.json --output ./audio
  $0 list-voices

Slide Image Naming:
  Images should be named: slide-01.png, slide-02.png, etc.
  Or: slide-01-title.png, slide-02-problem.png (prefix matching)
EOF
    exit 1
}

# Generate audio using ElevenLabs TTS
generate_audio_elevenlabs() {
    local text="$1"
    local output_file="$2"
    local voice_id="${ELEVENLABS_VOICE_ID}"

    if [ -z "$ELEVENLABS_API_KEY" ] || [ -z "$voice_id" ]; then
        return 1
    fi

    local response
    response=$(curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/${voice_id}" \
        -H "xi-api-key: $ELEVENLABS_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg text "$text" \
            --arg model "$ELEVENLABS_MODEL" \
            '{
                text: $text,
                model_id: $model,
                voice_settings: {
                    stability: 0.37,
                    similarity_boost: 0.75,
                    style: 0.09,
                    use_speaker_boost: true
                },
                speed: 0.85
            }')" \
        --output "$output_file" \
        -w "%{http_code}")

    if [ "$response" != "200" ]; then
        return 1
    fi

    return 0
}

# Generate audio using OpenAI TTS
generate_audio_openai() {
    local text="$1"
    local output_file="$2"
    local voice="${3:-$DEFAULT_VOICE}"
    local instructions="${4:-$DEFAULT_INSTRUCTIONS}"

    local response
    response=$(curl -s -X POST "https://api.openai.com/v1/audio/speech" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg model "$DEFAULT_MODEL" \
            --arg input "$text" \
            --arg voice "$voice" \
            --arg instructions "$instructions" \
            '{
                model: $model,
                input: $input,
                voice: $voice,
                instructions: $instructions,
                response_format: "mp3"
            }')" \
        --output "$output_file" \
        -w "%{http_code}")

    if [ "$response" != "200" ]; then
        print_error "OpenAI TTS failed (HTTP $response)"
        cat "$output_file"
        return 1
    fi

    return 0
}

# Generate audio - tries ElevenLabs first, falls back to OpenAI
generate_audio() {
    local text="$1"
    local output_file="$2"
    local voice="${3:-$DEFAULT_VOICE}"
    local instructions="${4:-$DEFAULT_INSTRUCTIONS}"

    # Try ElevenLabs first (if configured)
    if [ "$TTS_PROVIDER" = "elevenlabs" ] && [ -n "$ELEVENLABS_API_KEY" ]; then
        if generate_audio_elevenlabs "$text" "$output_file"; then
            return 0
        fi
        print_info "  ElevenLabs failed, falling back to OpenAI..."
    fi

    # Fallback to OpenAI
    if [ -n "$OPENAI_API_KEY" ]; then
        if generate_audio_openai "$text" "$output_file" "$voice" "$instructions"; then
            return 0
        fi
    fi

    print_error "All TTS providers failed"
    return 1
}

# Get duration of audio file in seconds
get_audio_duration() {
    local file="$1"
    ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null | cut -d'.' -f1
}

# Find slide image matching index
find_slide_image() {
    local slides_dir="$1"
    local index="$2"
    local padded=$(printf "%02d" "$index")

    # Try different naming patterns
    for pattern in "slide-${padded}"*.png "slide-${padded}"*.jpg "slide${padded}"*.png "${padded}"*.png; do
        local match=$(ls "$slides_dir"/$pattern 2>/dev/null | head -1)
        if [ -n "$match" ]; then
            echo "$match"
            return 0
        fi
    done

    return 1
}

# Create video clip from image + audio
create_video_clip() {
    local image="$1"
    local audio="$2"
    local output="$3"
    local pause_after="${4:-0}"

    # Get audio duration
    local duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$audio")

    # Add pause after clip (minimum 2 seconds between slides for natural pacing)
    local min_pause=2
    if [ "$pause_after" != "0" ] && [ "$pause_after" != "null" ]; then
        # Use the larger of specified pause or minimum pause
        if [ $(echo "$pause_after > $min_pause" | bc) -eq 1 ]; then
            duration=$(echo "$duration + $pause_after" | bc)
        else
            duration=$(echo "$duration + $min_pause" | bc)
        fi
    else
        duration=$(echo "$duration + $min_pause" | bc)
    fi

    # Create video: static image + audio
    ffmpeg -y -loop 1 -i "$image" -i "$audio" \
        -c:v libx264 -tune stillimage -c:a aac -b:a 192k \
        -pix_fmt yuv420p -shortest -t "$duration" \
        "$output" 2>/dev/null
}

# Concatenate video clips
concatenate_videos() {
    local output="$1"
    shift
    local clips=("$@")

    # Create concat file
    local concat_file=$(mktemp)
    for clip in "${clips[@]}"; do
        echo "file '$clip'" >> "$concat_file"
    done

    # Concatenate
    ffmpeg -y -f concat -safe 0 -i "$concat_file" -c copy "$output" 2>/dev/null

    rm "$concat_file"
}

# Main generate function
do_generate() {
    local json_file=""
    local slides_dir=""
    local output_file="output.mp4"
    local voice="$DEFAULT_VOICE"
    local instructions="$DEFAULT_INSTRUCTIONS"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --json) json_file="$2"; shift 2 ;;
            --slides) slides_dir="$2"; shift 2 ;;
            --output) output_file="$2"; shift 2 ;;
            --voice) voice="$2"; shift 2 ;;
            --instructions) instructions="$2"; shift 2 ;;
            *) print_error "Unknown option: $1"; usage ;;
        esac
    done

    # Validate inputs
    if [ -z "$json_file" ]; then
        print_error "JSON file required (--json)"
        exit 1
    fi
    if [ ! -f "$json_file" ]; then
        print_error "JSON file not found: $json_file"
        exit 1
    fi
    if [ -z "$slides_dir" ]; then
        print_error "Slides directory required (--slides)"
        exit 1
    fi
    if [ ! -d "$slides_dir" ]; then
        print_error "Slides directory not found: $slides_dir"
        exit 1
    fi

    # Create temp directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    print_info "Generating video: $output_file"
    echo "Voice: $voice"
    echo ""

    # Read clips from JSON
    local clip_count=$(jq '.clips | length' "$json_file")
    local video_clips=()
    local index=1

    for ((i=0; i<clip_count; i++)); do
        local script_text=$(jq -r ".clips[$i].scriptText // empty" "$json_file")
        local pause_after=$(jq -r ".clips[$i].pauseAfter // 0" "$json_file")
        local is_demo=$(jq -r ".clips[$i].isDemo // false" "$json_file")

        if [ -z "$script_text" ] || [ "$script_text" == "null" ]; then
            ((index++))
            continue
        fi

        print_step "Processing clip $index of $clip_count..."

        # Find slide image
        local slide_image=$(find_slide_image "$slides_dir" "$index")
        if [ -z "$slide_image" ]; then
            print_error "No slide image found for clip $index"
            echo "Expected: slide-$(printf '%02d' $index).png in $slides_dir"
            exit 1
        fi

        # Generate audio
        local audio_file="$temp_dir/audio-$(printf '%02d' $index).mp3"
        print_step "  Generating audio..."

        if ! generate_audio "$script_text" "$audio_file" "$voice" "$instructions"; then
            exit 1
        fi

        # Create video clip
        local clip_file="$temp_dir/clip-$(printf '%02d' $index).mp4"
        print_step "  Creating video clip..."
        create_video_clip "$slide_image" "$audio_file" "$clip_file" "$pause_after"

        video_clips+=("$clip_file")
        ((index++))

    done

    # Concatenate all clips
    print_step "Assembling final video..."
    concatenate_videos "$output_file" "${video_clips[@]}"

    # Get final duration
    local duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$output_file" | cut -d'.' -f1)

    echo ""
    print_success "Video created successfully!"
    echo "Output: $output_file"
    echo "Duration: ${duration}s"
    echo "Clips: ${#video_clips[@]}"
}

# Audio only generation
do_audio_only() {
    local json_file=""
    local output_dir="./audio"
    local voice="$DEFAULT_VOICE"
    local instructions="$DEFAULT_INSTRUCTIONS"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --json) json_file="$2"; shift 2 ;;
            --output) output_dir="$2"; shift 2 ;;
            --voice) voice="$2"; shift 2 ;;
            --instructions) instructions="$2"; shift 2 ;;
            *) print_error "Unknown option: $1"; usage ;;
        esac
    done

    if [ -z "$json_file" ]; then
        print_error "JSON file required (--json)"
        exit 1
    fi

    mkdir -p "$output_dir"

    print_info "Generating audio files to: $output_dir"
    echo "Voice: $voice"
    echo ""

    local clips=$(jq -c '.clips[]' "$json_file")
    local index=1

    while IFS= read -r clip; do
        local script_text=$(echo "$clip" | jq -r '.scriptText // ""')

        if [ -z "$script_text" ] || [ "$script_text" == "null" ]; then
            ((index++))
            continue
        fi

        local audio_file="$output_dir/clip-$(printf '%02d' $index).mp3"
        print_step "Generating clip $index..."

        if ! generate_audio "$script_text" "$audio_file" "$voice" "$instructions"; then
            exit 1
        fi

        ((index++))
    done <<< "$clips"

    print_success "Audio files generated in: $output_dir"
}

# List available voices
list_voices() {
    cat << EOF
Available OpenAI TTS Voices:

  alloy    - Neutral, balanced
  ash      - Clear, professional
  ballad   - Warm, melodic
  coral    - Friendly, approachable
  echo     - Calm, measured
  fable    - Expressive, storytelling
  nova     - Energetic, engaging (recommended for learning)
  onyx     - Deep, authoritative
  sage     - Wise, thoughtful
  shimmer  - Light, optimistic

Recommended for learning videos: nova, coral, sage

Example:
  $0 generate --json script.json --slides ./slides --voice nova
EOF
}

# Main
check_dependencies

if [ $# -lt 1 ]; then
    usage
fi

action="$1"
shift

case "$action" in
    generate)
        check_api_key
        do_generate "$@"
        ;;
    audio-only)
        check_api_key
        do_audio_only "$@"
        ;;
    list-voices)
        list_voices
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        print_error "Unknown action: $action"
        usage
        ;;
esac
