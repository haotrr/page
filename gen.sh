#!/bin/bash

#==============================================================================
# Markdown to HTML Conversion Script
#==============================================================================
# Purpose: Convert page.md / page-en.md to index.html / en.html
# Dependencies: pandoc (brew install pandoc)
#==============================================================================

set -e  # Exit immediately on error

readonly STYLES_FILE="styles.css"

print_info() { echo "📝 $1"; }
print_success() { echo "✅ $1"; }

get_current_date() {
    date '+%Y/%m/%d'
}

generate_toc() {
    local html_content="$1"
    local home_href="$2"
    local home_label="$3"
    local index_label="$4"
    local switcher="$5"

    local toc_items
    toc_items=$(echo "$html_content" | grep -E '^<h2 id="[^"]*">' | sed -E 's|<h2 id="([^"]*)">([^<]*)</h2>|  <li><a href="#\1">\2</a></li>|')

    if [ -n "$toc_items" ]; then
        echo "<nav class=\"toc\">
  <h3>${index_label}</h3>
  <ul><li><a href=\"${home_href}\">${home_label}</a></li></ul>
  <ul>
$toc_items
  </ul>
  ${switcher}
</nav>"
    fi
}

lang_switcher() {
    local lang="$1"

    if [ "$lang" = "zh" ]; then
        echo "<p class=\"lang-switch\"><a href=\"en.html\" hreflang=\"en\">EN</a></p>"
    else
        echo "<p class=\"lang-switch\"><a href=\"index.html\" hreflang=\"zh-CN\">中文</a></p>"
    fi
}

convert_to_html() {
    local source_file="$1"
    local subtitle="$2"
    local update_label="$3"
    local update_time="$4"

    local html_content
    html_content=$(pandoc "$source_file" --from markdown --to html --syntax-highlighting=none --wrap=none)

    html_content=$(echo "$html_content" | awk -v subtitle="$subtitle" -v label="$update_label" -v update="$update_time" '
        /<\/h1>/ && !inserted {
            print $0
            print "<p>" subtitle "</p>"
            print "<p class=\"update-time\">" label ": " update "</p>"
            inserted = 1
            next
        }
        { print }
    ')

    html_content=$(echo "$html_content" | sed 's|<center>|<p class="footer-quote">|g')
    html_content=$(echo "$html_content" | sed 's|</center>|</p>|g')
    html_content=$(echo "$html_content" | perl -pe 's/<h3([^>]*)>/<h3\1> ♦ /g')

    echo "$html_content"
}

generate_html_page() {
    local title="$1"
    local lang="$2"
    local content="$3"
    local toc="$4"

    cat << EOF
<!DOCTYPE html>
<html lang="${lang}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
    <link rel="stylesheet" href="${STYLES_FILE}">
    <link rel="alternate" hreflang="zh-CN" href="index.html">
    <link rel="alternate" hreflang="en" href="en.html">
</head>
<body>
<div class="container">
    <div class="main-content">
${content}
    </div>
    <div class="sidebar">
${toc}
    </div>
</div>
</body>
</html>
EOF
}

build_page() {
    local source_file="$1"
    local output_file="$2"
    local html_lang="$3"
    local page_lang="$4"
    local subtitle="$5"
    local update_label="$6"
    local home_href="$7"
    local home_label="$8"
    local index_label="$9"
    local title="Aha, I'm Just Kidding."
    local update_time
    update_time=$(get_current_date)

    if [ ! -f "$source_file" ]; then
        echo "❌ Error: $source_file not found"
        exit 1
    fi

    print_info "Converting $source_file to $output_file..."

    local html_content
    html_content=$(convert_to_html "$source_file" "$subtitle" "$update_label" "$update_time")

    local switcher
    switcher=$(lang_switcher "$page_lang")

    local toc
    toc=$(generate_toc "$html_content" "$home_href" "$home_label" "$index_label" "$switcher")

    generate_html_page "$title" "$html_lang" "$html_content" "$toc" > "$output_file"
    print_success "Generated $output_file successfully!"
}

main() {
    if ! command -v pandoc >/dev/null 2>&1; then
        echo "❌ Error: pandoc is required (brew install pandoc)"
        exit 1
    fi

    if [ ! -f "$STYLES_FILE" ]; then
        echo "❌ Error: $STYLES_FILE not found"
        exit 1
    fi

    build_page "page.md" "index.html" "zh-CN" "zh" "当然，我在扯淡。" "更新" "#" "首页" "目录"
    build_page "page-en.md" "en.html" "en" "en" "Of course, I'm just kidding." "Updated" "en.html" "Home" "Index"
}

main "$@"
