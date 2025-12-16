#!/usr/bin/env bash
# Strip JSONC comments (// and /* */) from input
# Usage: strip-jsonc-comments.sh < input.jsonc > output.json
#    or: strip-jsonc-comments.sh input.jsonc

set -euo pipefail

strip_comments() {
    local content="$1"

    # Use sed to remove comments while preserving strings
    # This is a simplified approach - for complex cases use the Python validator

    # Step 1: Remove single-line comments (// to end of line)
    # But not inside strings - use a heuristic approach
    local result
    result=$(echo "$content" | sed -E '
        # Remove // comments that are clearly outside strings
        # This looks for // not preceded by : and quote patterns
        s|([^:"])//[^"]*$|\1|g
        # Remove // comments at start of line
        s|^[[:space:]]*//.*$||g
    ')

    # Step 2: Remove multi-line comments /* */
    # This is tricky in pure bash/sed, so we use a simple approach
    result=$(echo "$result" | perl -0777 -pe '
        # Remove /* */ comments but preserve newlines for line counting
        s{/\*.*?\*/}{
            my $match = $&;
            my $newlines = ($match =~ tr/\n//);
            "\n" x $newlines
        }gse if defined $_;
    ' 2>/dev/null || echo "$result")

    echo "$result"
}

# Main
if [[ $# -eq 0 ]]; then
    # Read from stdin
    content=$(cat)
    strip_comments "$content"
elif [[ $# -eq 1 && -f "$1" ]]; then
    # Read from file
    content=$(cat "$1")
    strip_comments "$content"
else
    echo "Usage: $0 [file]" >&2
    echo "  Strips JSONC comments from input" >&2
    echo "  Read from stdin or specified file" >&2
    exit 1
fi
