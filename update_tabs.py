import re

with open('REPORT_SDRAM_VGA.html', 'r', encoding='utf-8') as f:
    html = f.read()

# 1. Add CSS
css_to_add = '''
        /* Navigation Tabs */
        .app-nav {
            position: sticky;
            top: 0;
            z-index: 1000;
            background: rgba(15, 23, 42, 0.85);
            backdrop-filter: blur(12px);
            padding: 15px;
            display: flex;
            justify-content: center;
            gap: 20px;
            border-bottom: 1px solid var(--border);
            box-shadow: 0 4px 30px rgba(0, 0, 0, 0.5);
            margin: -40px -20px 40px -20px; /* Offset body padding */
        }
        .nav-btn {
            background: #1e293b;
            color: var(--text-main);
            border: 1px solid var(--border);
            padding: 12px 24px;
            border-radius: 30px;
            font-size: 1.1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            font-family: 'Inter', sans-serif;
        }
        .nav-btn:hover {
            background: #334155;
            color: #fff;
            transform: translateY(-2px);
        }
        .nav-btn.active {
            background: var(--accent);
            color: #0f172a;
            border-color: var(--accent);
            box-shadow: 0 0 20px rgba(56, 189, 248, 0.5);
        }
        
        #view-simulator {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 80vh;
        }
'''
html = html.replace('</style>', css_to_add + '\n    </style>')

# 2. Modify Body Structure
old_body = '''</head>
<body>
    <div id="content"></div>

    <!-- Simulator Container du?c kéo ra ngoài kh?i textarea d? JS không b? block -->
    <div class="pc-simulator-container" id="sim-container">'''

new_body = '''</head>
<body>
    <!-- Thanh di?u hu?ng Tab -->
    <div class="app-nav">
        <button id="btn-sim" class="nav-btn active" onclick="switchView('sim')">?? Trình Gi? L?p VGA</button>
        <button id="btn-report" class="nav-btn" onclick="switchView('report')">?? Báo Cáo K? Thu?t</button>
    </div>

    <!-- TH? GI?I 1: TRÌNH GI? L?P -->
    <div id="view-simulator">
        <div class="pc-simulator-container" id="sim-container" style="display: flex;">'''
html = html.replace(old_body, new_body)

# 3. Close the views and wrap content
# The textarea and scripts are at the bottom.
# Wait, the DOM right now is:
# <div class="pc-simulator-container">...</div>
# <textarea id="md-source">...</textarea>
# <script>...</script>
# We need to wrap <div id="content"></div> inside <div id="view-report">
# Let's just do it directly.
html = html.replace('<div id="content"></div>', '<div id="view-report" style="display: none;">\\n        <div id="content"></div>\\n    </div>')

# 4. Modify JS
old_js = '''        // Ðua simulator vào dúng v? trí tru?c ph?n Ki?n trúc H? th?ng
        // Ho?c dua xu?ng cu?i bài
        document.getElementById('content').appendChild(document.getElementById('sim-container'));
        document.getElementById('sim-container').style.display = 'flex';'''

new_js = '''        // Chuy?n d?i gi?a 2 th? gi?i
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
            }
        }
        
        // Kh?i t?o hi?n th? Gi? l?p d?u tiên
        document.getElementById('sim-container').style.display = 'flex';'''
html = html.replace(old_js, new_js)

with open('REPORT_SDRAM_VGA.html', 'w', encoding='utf-8') as f:
    f.write(html)
