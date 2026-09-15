import re

with open('REPORT_SDRAM_VGA.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Fix 1: Mermaid rendering in display:none
old_mermaid_start = "        // 2. Render Mermaid"
new_mermaid_start = "        document.getElementById('view-report').style.display = 'block'; // Tạm hiện để Mermaid lấy kích thước\n        // 2. Render Mermaid"
html = html.replace(old_mermaid_start, new_mermaid_start)

old_mermaid_end = "mermaid.init(undefined, document.querySelectorAll('.mermaid'));"
new_mermaid_end = "mermaid.init(undefined, document.querySelectorAll('.mermaid'));\n        document.getElementById('view-report').style.display = 'none'; // Ẩn lại sau khi render"
html = html.replace(old_mermaid_end, new_mermaid_end)

# Fix 2: Simulator height (Scaling down and reducing margins)
old_css_sim = ".pc-simulator-container {\n            flex-direction: column; align-items: center; margin: 50px 0;\n            background: rgba(15, 23, 42, 0.6); padding: 40px; border-radius: 20px;"
new_css_sim = ".pc-simulator-container {\n            flex-direction: column; align-items: center; margin: 0;\n            background: rgba(15, 23, 42, 0.6); padding: 20px; border-radius: 20px;\n            transform: scale(0.75); transform-origin: center top;"

html = html.replace(old_css_sim, new_css_sim)

# Also reduce spacing above the simulator title
html = html.replace('<h2 style="margin-top:0;', '<h2 style="margin-top:0; margin-bottom:10px;')

# Ensure view-simulator doesn't have min-height 80vh pushing things
html = html.replace('min-height: 80vh;', 'min-height: 0;')

with open('REPORT_SDRAM_VGA.html', 'w', encoding='utf-8') as f:
    f.write(html)
