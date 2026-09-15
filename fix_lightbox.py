import re

with open('REPORT_SDRAM_VGA.html', 'r', encoding='utf-8') as f:
    html = f.read()

# 1. Replace setTimeout with function initLightbox()
old_lightbox = r'''        // 4\. Lightbox Zoom & Pan cho Mermaid \(Trải nghiệm người dùng cao cấp\)
        setTimeout\(\(\) => \{
            const diagrams = document\.querySelectorAll\('\.mermaid svg'\);'''

new_lightbox = '''        // 4. Lightbox Zoom & Pan cho Mermaid (Trải nghiệm người dùng cao cấp)
        function initLightbox() {
            const diagrams = document.querySelectorAll('.mermaid svg');'''

html = re.sub(old_lightbox, new_lightbox, html)

# Replace the closing of setTimeout
old_lightbox_close = r'''                \}\);
            \}\);
        \}, 1500\);'''

new_lightbox_close = '''                });
            });
        }'''
html = re.sub(old_lightbox_close, new_lightbox_close, html)

# 2. Add initLightbox() call inside switchView
old_switch = r'''                // Trì hoãn render Mermaid cho đến khi Tab Báo cáo thực sự hiện lên
                if \(!isMermaidRendered\) \{
                    mermaid\.init\(undefined, document\.querySelectorAll\('\.mermaid'\)\);
                    isMermaidRendered = true;
                \}'''

new_switch = '''                // Trì hoãn render Mermaid cho đến khi Tab Báo cáo thực sự hiện lên
                if (!isMermaidRendered) {
                    mermaid.init(undefined, document.querySelectorAll('.mermaid'));
                    setTimeout(initLightbox, 500); // Gắn sự kiện click sau khi vẽ xong
                    isMermaidRendered = true;
                }'''

html = re.sub(old_switch, new_switch, html)

with open('REPORT_SDRAM_VGA.html', 'w', encoding='utf-8') as f:
    f.write(html)
