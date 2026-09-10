#!/usr/bin/env bash

# QML Linter Script
# Usage: ./scripts/dev/lint.sh [-v] [files...]
#   -v  Verbose mode (show all files checked)
# If no files specified, checks all .qml files in the project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERBOSE=0
FAILURES=0

for arg in "$@"; do
    case $arg in
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
    esac
done

check_file() {
    local file="$1"
    local file_display="${file#$PROJECT_ROOT/}"

    if [ "$VERBOSE" -eq 1 ]; then
        echo "Checking: $file_display"
    fi

    if qmllint "$file" 2>&1 | grep -q "."; then
        echo "✗ Linting errors in: $file_display"
        qmllint "$file"
        FAILURES=$((FAILURES + 1))
        return 1
    else
        [ "$VERBOSE" -eq 1 ] && echo "✓ $file_display"
        return 0
    fi
}

main() {
    local files=()

    if [ $# -gt 0 ]; then
        # Use files provided as arguments
        files=("$@")
    else
        # Find all .qml files in the project
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "$PROJECT_ROOT" -name "*.qml" -print0 2>/dev/null)
    fi

    if [ ${#files[@]} -eq 0 ]; then
        echo "No QML files to lint"
        exit 0
    fi

    echo "=== QML Lint Check ==="
    echo "Checking ${#files[@]} file(s)..."
    echo

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            check_file "$file"
        fi
    done

    echo
    echo "=== Result ==="
    if [ "$FAILURES" -gt 0 ]; then
        echo "✗ Failed: $FAILURES file(s) with linting errors"
        exit 1
    else
        echo "✓ All QML files passed linting"
        exit 0
    fi
}

main "$@"
