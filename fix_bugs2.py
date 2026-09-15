import re

with open('REPORT_SDRAM_VGA.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Fix 1: Mermaid rendering in display:none
html = re.sub(
    r'(\s*// 2\. Render Mermaid\s*const mermaidCodes)',
    r'\n        document.getElementById("view-report").style.display = "block";\n\1',
    html
)

html = re.sub(
    r'(mermaid\.init\(undefined, document\.querySelectorAll\(\'\.mermaid\'\)\);)',
    r'\1\n        document.getElementById("view-report").style.display = "none";\n        document.getElementById("view-simulator").style.display = "flex";',
    html
)

# Fix 2: Simulator height (Scaling down and reducing margins)
html = re.sub(
    r'\.pc-simulator-container\s*\{[^}]*\}',
    r'.pc-simulator-container {\n            flex-direction: column; align-items: center; margin: 0;\n            background: rgba(15, 23, 42, 0.6); padding: 20px; border-radius: 20px;\n            border: 1px solid var(--border); box-shadow: inset 0 0 20px rgba(0,0,0,0.5);\n            transform: scale(0.75); transform-origin: center top;\n        }',
    html
)

# Also reduce spacing above the simulator title
html = html.replace('<h2 style="margin-top:0; color:var(--text-heading); text-align:center; border:none;">', '<h2 style="margin-top:0; margin-bottom:10px; color:var(--text-heading); text-align:center; border:none;">')

# Ensure view-simulator doesn't have min-height 80vh pushing things
html = html.replace('min-height: 80vh;', 'min-height: 0;')

with open('REPORT_SDRAM_VGA.html', 'w', encoding='utf-8') as f:
    f.write(html)
