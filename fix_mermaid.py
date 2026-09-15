import re

with open('REPORT_SDRAM_VGA.html', 'r', encoding='utf-8') as f:
    html = f.read()

# 1. Clean up old messy mermaid render logic
old_logic = r'''        document\.getElementById\('view-report'\)\.style\.display = 'block'; // Tạm hiện.*
        document\.getElementById\("view-report"\)\.style\.display = "block";

        // 2\. Render Mermaid
        const mermaidCodes = document\.querySelectorAll\('code\.language-mermaid'\);
        mermaidCodes\.forEach\(code => \{
            const div = document\.createElement\('div'\);
            div\.className = 'mermaid';
            div\.textContent = code\.textContent;
            code\.parentElement\.replaceWith\(div\);
        \}\);

        mermaid\.initialize\(\{ startOnLoad: false, theme: 'default' \}\);
        mermaid\.init\(undefined, document\.querySelectorAll\('\.mermaid'\)\);
        document\.getElementById\("view-report"\)\.style\.display = "none";
        document\.getElementById\("view-simulator"\)\.style\.display = "flex";
        document\.getElementById\('view-report'\)\.style\.display = 'none'; // Ẩn lại sau khi render'''

new_logic = '''        // 2. Chuẩn bị thẻ Mermaid (Chưa render SVG vội)
        const mermaidCodes = document.querySelectorAll('code.language-mermaid');
        mermaidCodes.forEach(code => {
            const div = document.createElement('div');
            div.className = 'mermaid';
            div.textContent = code.textContent;
            code.parentElement.replaceWith(div);
        });
        mermaid.initialize({ startOnLoad: false, theme: 'default' });'''

html = re.sub(old_logic, new_logic, html, flags=re.DOTALL)

# 2. Modify switchView to render mermaid on first click
old_switch = r'''        // 5\. Chuyển đổi giữa 2 thế giới \(Tabs\)
        function switchView\(view\) \{
            document\.getElementById\('btn-sim'\)\.classList\.remove\('active'\);
            document\.getElementById\('btn-report'\)\.classList\.remove\('active'\);
            
            if \(view === 'sim'\) \{
                document\.getElementById\('btn-sim'\)\.classList\.add\('active'\);
                document\.getElementById\('view-simulator'\)\.style\.display = 'flex';
                document\.getElementById\('view-report'\)\.style\.display = 'none';
            \} else \{
                document\.getElementById\('btn-report'\)\.classList\.add\('active'\);
                document\.getElementById\('view-simulator'\)\.style\.display = 'none';
                document\.getElementById\('view-report'\)\.style\.display = 'block';
            \}
        \}'''

new_switch = '''        // 5. Chuyển đổi giữa 2 thế giới (Tabs)
        let isMermaidRendered = false;
        function switchView(view) {
            document.getElementById('btn-sim').classList.remove('active');
            document.getElementById('btn-report').classList.remove('active');
            
            if (view === 'sim') {
                document.getElementById('btn-sim').classList.add('active');
                document.getElementById('view-simulator').style.display = 'flex';
                document.getElementById('view-report').style.display = 'none';
            } else {
                document.getElementById('btn-report').classList.add('active');
                document.getElementById('view-simulator').style.display = 'none';
                document.getElementById('view-report').style.display = 'block';
                
                // Trì hoãn render Mermaid cho đến khi Tab Báo cáo thực sự hiện lên
                if (!isMermaidRendered) {
                    mermaid.init(undefined, document.querySelectorAll('.mermaid'));
                    isMermaidRendered = true;
                }
            }
        }'''

html = re.sub(old_switch, new_switch, html, flags=re.DOTALL)

with open('REPORT_SDRAM_VGA.html', 'w', encoding='utf-8') as f:
    f.write(html)
