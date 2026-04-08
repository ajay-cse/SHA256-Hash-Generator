#!/usr/bin/env bash
# hash_files.sh
# Drop this file in your folder and run it.
# Usage: bash hash_files.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="$SCRIPT_DIR/file_hashes.csv"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# IST offset = +05:30
IST_OFFSET="+05:30"

# Convert epoch to IST datetime string: 15-Mar-2024 02:30 PM
to_ist() {
    local epoch="$1"
    # Format in IST using TZ
    TZ="Asia/Kolkata" date -d "@$epoch" "+%d-%b-%Y %I:%M %p" 2>/dev/null
}

# Get file size in "2.9561 MB" format
to_mb() {
    local bytes="$1"
    awk "BEGIN { printf \"%.4f MB\", $bytes / 1048576 }"
}

# CSV-safe: escape internal double quotes
q() {
    echo "$1" | sed 's/"/""/g'
}

# Write CSV header
echo "FileName,RelativePath,Extension,FileSize,DateCreated,DateModified,SHA256Hash" > "$OUTPUT"

# Count total files (excluding this script and output CSV)
total=$(find "$SCRIPT_DIR" -type f \
        ! -name "$SCRIPT_NAME" \
        ! -name "file_hashes.csv" | wc -l)

echo "Found $total files. Starting hash..."
count=0

find "$SCRIPT_DIR" -type f \
     ! -name "$SCRIPT_NAME" \
     ! -name "file_hashes.csv" \
     -print0 | sort -z | \
while IFS= read -r -d '' file; do
    count=$((count + 1))
    pct=$(awk "BEGIN { printf \"%.1f\", ($count / $total) * 100 }")
    printf "\r[%d/%d | %s%%] %s                    " \
           "$count" "$total" "$pct" "$(basename "$file")"

    # SHA-256 hash
    hash=$(sha256sum "$file" | awk '{print $1}')

    # File size
    size_bytes=$(stat --printf="%s" "$file")
    size_mb=$(to_mb "$size_bytes")

    # Dates — get epoch then convert to IST
    epoch_modified=$(stat --printf="%Y" "$file")
    epoch_created=$(stat --printf="%W" "$file")

    # Fallback: if birth time not available (ext4 without birthtime), use change time
    if [[ "$epoch_created" == "0" || -z "$epoch_created" ]]; then
        epoch_created=$(stat --printf="%Z" "$file")
    fi

    created=$(to_ist "$epoch_created")
    modified=$(to_ist "$epoch_modified")

    # Paths
    filename=$(basename "$file")
    rel_path="${file#$SCRIPT_DIR/}"
    extension=""
    if [[ "$filename" == *.* ]]; then
        extension=".${filename##*.}"
    fi

    # Write CSV row
    printf '"%s","%s","%s","%s","%s","%s","%s"\n' \
        "$(q "$filename")" \
        "$(q "$rel_path")" \
        "$(q "$extension")" \
        "$(q "$size_mb")" \
        "$(q "$created")" \
        "$(q "$modified")" \
        "$hash" >> "$OUTPUT"
done

echo ""
echo ""
echo "Completed! $total files processed."
echo "Output saved to: $OUTPUT"