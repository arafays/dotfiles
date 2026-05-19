#!/bin/bash
# Compress all videos in this folder and subfolders using AMD GPU (VAAPI H.265)
# Output: *_compressed.mp4 next to each original

INPUT_DIR="${1:-.}"
QUALITY="${QUALITY:-18}" # lower = better quality (0-51), 18 is visually lossless
PRESET="${PRESET:-fast}" # veryfast, fast, medium, slow, veryslow (vaapi presets)
EXTENSIONS=("*.mp4" "*.mkv" "*.avi" "*.mov" "*.webm" "*.flv" "*.wmv" "*.mts" "*.m2ts")

# Check for GPU render node
if [ ! -e /dev/dri/renderD128 ]; then
  echo "ERROR: No GPU render node found at /dev/dri/renderD128"
  exit 1
fi

count=0
skipped=0
failed=0

# Build find args for extensions
find_args=()
for ext in "${EXTENSIONS[@]}"; do
  find_args+=(-name "$ext" -o)
done
unset 'find_args[${#find_args[@]}-1]' # remove trailing -o

while IFS= read -r -d '' file; do
  dir=$(dirname "$file")
  base=$(basename "$file")
  name="${base%.*}"
  output="${dir}/${name}_compressed.mp4"

  if [ -f "$output" ]; then
    echo "SKIP: $output already exists"
    ((skipped++))
    continue
  fi

  echo "--- Processing: $file"
  ffmpeg -hwaccel vaapi -hwaccel_output_format vaapi -vaapi_device /dev/dri/renderD128 \
    -i "$file" \
    -c:v hevc_vaapi -qp "$QUALITY" -preset "$PRESET" \
    -c:a aac -b:a 128k \
    -movflags +faststart \
    "$output"

  if [ $? -eq 0 ]; then
    echo "DONE: $output"
    ((count++))
  else
    echo "FAILED: $file"
    ((failed++))
  fi
done < <(find "$INPUT_DIR" -type f \( "${find_args[@]}" \) -print0)

echo ""
echo "========================"
echo "Summary: $count converted, $skipped skipped, $failed failed"
echo "========================"
