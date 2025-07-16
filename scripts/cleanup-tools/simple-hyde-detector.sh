#!/bin/bash

# Simple Hyde Reference Detection
echo "Scanning for Hyde references..."

# Find all script files and search for Hyde references
echo "{"
echo "  \"scan_date\": \"$(date -Iseconds)\","
echo "  \"files\": ["

first=true
/usr/bin/find scripts -type f \( -name "*.sh" -o -name "*.py" \) | while read -r file; do
    # Check if file contains Hyde references
    if grep -q -i "hyde" "$file" 2>/dev/null; then
        if [ "$first" = false ]; then
            echo ","
        fi
        first=false

        ref_count=$(grep -c -i "hyde" "$file" 2>/dev/null || echo "0")
        echo "    {"
        echo "      \"file\": \"$file\","
        echo "      \"reference_count\": $ref_count,"
        echo "      \"references\": ["

        # Get specific references
        grep -n -i "hyde" "$file" 2>/dev/null | head -5 | while IFS=: read -r line_num line_content; do
            echo "        {"
            echo "          \"line_number\": $line_num,"
            echo "          \"line_content\": $(echo "$line_content" | jq -R .)"
            echo "        }"
        done | sed '$!s/$/,/'

        echo "      ]"
        echo "    }"
    fi
done

echo "  ]"
echo "}"