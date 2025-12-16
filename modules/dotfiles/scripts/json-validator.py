#!/usr/bin/env python3
"""
JSON/JSONC validator with duplicate key detection.

Usage:
    python json-validator.py [--fix] [--quiet] <file1> [file2...]

Exit codes:
    0 - All files valid
    1 - Validation errors found
    2 - Warnings only (duplicate keys fixed with --fix)
"""

import json
import re
import sys
import argparse
from pathlib import Path
from typing import Optional


class ValidationError:
    """Represents a validation error with location info."""

    def __init__(self, error_type: str, message: str, line: Optional[int] = None,
                 key: Optional[str] = None, value: Optional[str] = None):
        self.error_type = error_type
        self.message = message
        self.line = line
        self.key = key
        self.value = value

    def __str__(self):
        location = f"line {self.line}" if self.line else "unknown location"
        if self.key:
            return f"{self.error_type} at {location}: \"{self.key}\" - {self.message}"
        return f"{self.error_type} at {location}: {self.message}"


def strip_jsonc_comments(content: str) -> str:
    """
    Strip JSONC comments from content while preserving line numbers.
    Handles both // single-line and /* multi-line */ comments.
    """
    result = []
    i = 0
    in_string = False

    while i < len(content):
        char = content[i]

        # Track string boundaries
        if char == '"' and (i == 0 or content[i-1] != '\\'):
            in_string = not in_string
            result.append(char)
            i += 1
            continue

        # Don't process comments inside strings
        if in_string:
            result.append(char)
            i += 1
            continue

        # Check for single-line comment
        if i + 1 < len(content) and content[i:i+2] == '//':
            # Skip until end of line, preserve newline for line counting
            while i < len(content) and content[i] != '\n':
                i += 1
            continue

        # Check for multi-line comment
        if i + 1 < len(content) and content[i:i+2] == '/*':
            # Skip until */, preserve newlines for line counting
            i += 2
            while i + 1 < len(content) and content[i:i+2] != '*/':
                if content[i] == '\n':
                    result.append('\n')
                i += 1
            i += 2  # Skip */
            continue

        result.append(char)
        i += 1

    return ''.join(result)


def find_line_number(content: str, key: str, occurrence: int = 1) -> Optional[int]:
    """Find the line number of a key in the content."""
    lines = content.split('\n')
    count = 0
    for i, line in enumerate(lines, 1):
        # Look for the key as a JSON key (with quotes and colon)
        pattern = rf'"\s*{re.escape(key)}\s*"\s*:'
        if re.search(pattern, line):
            count += 1
            if count == occurrence:
                return i
    return None


def check_duplicate_keys(content: str, stripped_content: str) -> list[ValidationError]:
    """
    Check for duplicate keys by parsing with object_pairs_hook.
    Returns list of ValidationError for any duplicates found.
    """
    errors = []
    key_occurrences = {}  # Track {key_path: [line_numbers]}

    def track_duplicates(pairs, path=""):
        """Track keys and detect duplicates at current level."""
        seen = {}
        result = {}

        for key, value in pairs:
            full_key = f"{path}.{key}" if path else key

            if key in seen:
                # Found duplicate
                line1 = find_line_number(content, key, 1)
                line2 = find_line_number(content, key, 2)
                errors.append(ValidationError(
                    "DUPLICATE_KEY",
                    f"First occurrence at line {line1}, second at line {line2}",
                    line=line2,
                    key=key,
                    value=str(value)[:50]
                ))
            else:
                seen[key] = True

            # Recursively process nested objects
            if isinstance(value, dict):
                result[key] = value
            else:
                result[key] = value

        return result

    # Custom decoder that uses object_pairs_hook
    class DuplicateKeyDecoder(json.JSONDecoder):
        def __init__(self, *args, **kwargs):
            super().__init__(object_pairs_hook=track_duplicates, *args, **kwargs)

    try:
        json.loads(stripped_content, cls=DuplicateKeyDecoder)
    except json.JSONDecodeError:
        pass  # Syntax errors handled separately

    return errors


def validate_json_syntax(stripped_content: str, original_content: str) -> list[ValidationError]:
    """
    Validate JSON syntax and return list of errors.
    """
    errors = []
    try:
        json.loads(stripped_content)
    except json.JSONDecodeError as e:
        # Try to find the actual line in original content
        line = e.lineno
        errors.append(ValidationError(
            "SYNTAX_ERROR",
            e.msg,
            line=line
        ))
    return errors


def fix_duplicate_keys(content: str) -> tuple[str, int]:
    """
    Remove duplicate keys from JSON content, keeping the last value.
    Returns (fixed_content, number_of_duplicates_removed).
    """
    # Handle both single-line and multi-line JSON
    # Strategy: find all "key": patterns and track duplicates

    # Pattern to match "key": value pairs (handles various formats)
    # We'll process the content character by character to handle nested structures
    key_value_pattern = re.compile(r'"([^"]+)"\s*:\s*')

    # Find all key positions
    key_positions = []  # [(start, end, key, full_match)]
    for match in key_value_pattern.finditer(content):
        key = match.group(1)
        key_positions.append((match.start(), match.end(), key))

    # Track seen keys and find duplicates (keep last)
    seen_keys = {}  # {key: (position_index, start, end)}
    duplicates_to_remove = []  # [(start, end)] - ranges to remove

    for idx, (start, end, key) in enumerate(key_positions):
        if key in seen_keys:
            # Mark the earlier occurrence for removal
            old_idx, old_start, old_end = seen_keys[key]
            # Find the extent of the key-value pair (until the next , or })
            # This is tricky - we need to find where the value ends
            value_end = find_value_end(content, old_end)
            duplicates_to_remove.append((old_start, value_end))
        seen_keys[key] = (idx, start, end)

    if not duplicates_to_remove:
        return content, 0

    # Sort duplicates by position (reverse to remove from end first)
    duplicates_to_remove.sort(key=lambda x: x[0], reverse=True)

    fixed_content = content
    for start, end in duplicates_to_remove:
        # Remove the duplicate key-value pair
        fixed_content = fixed_content[:start] + fixed_content[end:]

    # Clean up: remove double commas and trailing commas
    fixed_content = re.sub(r',\s*,', ',', fixed_content)
    fixed_content = re.sub(r',(\s*[}\]])', r'\1', fixed_content)
    fixed_content = re.sub(r'{\s*,', '{', fixed_content)

    return fixed_content, len(duplicates_to_remove)


def find_value_end(content: str, start: int) -> int:
    """Find where a JSON value ends (at the comma or closing brace)."""
    depth = 0
    in_string = False
    i = start

    while i < len(content):
        char = content[i]

        if char == '"' and (i == 0 or content[i-1] != '\\'):
            in_string = not in_string
        elif not in_string:
            if char in '{[':
                depth += 1
            elif char in '}]':
                if depth == 0:
                    return i
                depth -= 1
            elif char == ',' and depth == 0:
                return i + 1  # Include the comma

        i += 1

    return len(content)


def validate_file(filepath: str, fix: bool = False, quiet: bool = False) -> tuple[bool, list[ValidationError], bool]:
    """
    Validate a single JSON/JSONC file.

    Returns: (is_valid, errors, was_fixed)
    """
    path = Path(filepath)

    if not path.exists():
        return False, [ValidationError("FILE_ERROR", f"File not found: {filepath}")], False

    try:
        content = path.read_text(encoding='utf-8')
    except Exception as e:
        return False, [ValidationError("FILE_ERROR", f"Cannot read file: {e}")], False

    # Strip JSONC comments
    stripped_content = strip_jsonc_comments(content)

    # Check for syntax errors first
    syntax_errors = validate_json_syntax(stripped_content, content)
    if syntax_errors:
        return False, syntax_errors, False

    # Check for duplicate keys
    duplicate_errors = check_duplicate_keys(content, stripped_content)

    if duplicate_errors and fix:
        fixed_content, num_fixed = fix_duplicate_keys(content)
        if num_fixed > 0:
            path.write_text(fixed_content, encoding='utf-8')
            if not quiet:
                print(f"  Fixed {num_fixed} duplicate key(s)")
            return True, [], True

    if duplicate_errors:
        return False, duplicate_errors, False

    return True, [], False


def main():
    parser = argparse.ArgumentParser(
        description='Validate JSON/JSONC files for syntax errors and duplicate keys'
    )
    parser.add_argument('files', nargs='+', help='Files to validate')
    parser.add_argument('--fix', action='store_true',
                       help='Automatically fix duplicate keys (keeps last value)')
    parser.add_argument('-q', '--quiet', action='store_true',
                       help='Only output errors')
    parser.add_argument('--json', action='store_true',
                       help='Output in JSON format')

    args = parser.parse_args()

    results = {
        'files_checked': 0,
        'valid': 0,
        'errors': 0,
        'fixed': 0,
        'details': []
    }

    for filepath in args.files:
        results['files_checked'] += 1

        if not args.quiet and not args.json:
            print(f"\nChecking: {filepath}")

        is_valid, errors, was_fixed = validate_file(filepath, args.fix, args.quiet)

        if was_fixed:
            results['fixed'] += 1
            results['valid'] += 1
        elif is_valid:
            results['valid'] += 1
            if not args.quiet and not args.json:
                print(f"  ✅ Valid JSON")
        else:
            results['errors'] += 1
            if not args.json:
                for error in errors:
                    print(f"  ❌ {error}")
                    # Add helpful suggestions
                    if error.error_type == "DUPLICATE_KEY":
                        print(f"     ⚠️  Suggestion: Remove duplicate key \"{error.key}\" (keeping last value)")
                        print(f"     💡 Run with --fix to automatically fix this issue")
                    elif error.error_type == "SYNTAX_ERROR":
                        print(f"     ⚠️  Check the syntax around line {error.line}")
                        print(f"     💡 Common issues: missing comma, unquoted key, trailing comma")

        results['details'].append({
            'file': filepath,
            'valid': is_valid or was_fixed,
            'fixed': was_fixed,
            'errors': [str(e) for e in errors]
        })

    # Summary
    if args.json:
        import json as json_out
        print(json_out.dumps(results, indent=2))
    elif not args.quiet:
        print(f"\n{'='*40}")
        print(f"Files checked: {results['files_checked']}")
        print(f"  Valid: {results['valid']}")
        print(f"  Errors: {results['errors']}")
        if results['fixed']:
            print(f"  Fixed: {results['fixed']}")

    # Exit code
    if results['errors'] > 0:
        sys.exit(1)
    elif results['fixed'] > 0:
        sys.exit(2)  # Warning - files were fixed
    else:
        sys.exit(0)


if __name__ == '__main__':
    main()
