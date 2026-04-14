/* ═══════════════════════════════════════════════════════════════════════
   KITLY — Website JavaScript
   Handles: navigation, copy-to-clipboard, terminal animation,
   scroll animations, tab switching, and app command builder.
   Optimized for performance: requestAnimationFrame, passive listeners,
   IntersectionObserver, no layout thrashing.
   ═══════════════════════════════════════════════════════════════════════ */

document.addEventListener('DOMContentLoaded', () => {
    initNavbar();
    initMobileNav();
    initInstallTabs();
    initTerminalAnimation();
    initScrollAnimations();
    initSmoothScrollLinks();
    initAppBuilder();
});

/* ═══════════════════════════════════════════════════════════════════════
   NAVBAR — Scroll-triggered background (optimized with rAF)
   ═══════════════════════════════════════════════════════════════════════ */
function initNavbar() {
    const navbar = document.getElementById('navbar');
    if (!navbar) return;

    let ticking = false;
    let lastScrolled = false;

    const update = () => {
        const scrolled = window.scrollY > 60;
        if (scrolled !== lastScrolled) {
            navbar.classList.toggle('scrolled', scrolled);
            lastScrolled = scrolled;
        }
        ticking = false;
    };

    window.addEventListener('scroll', () => {
        if (!ticking) {
            requestAnimationFrame(update);
            ticking = true;
        }
    }, { passive: true });

    update();
}

/* ═══════════════════════════════════════════════════════════════════════
   MOBILE NAVIGATION — Toggle menu
   ═══════════════════════════════════════════════════════════════════════ */
function initMobileNav() {
    const toggle = document.getElementById('navToggle');
    const links = document.getElementById('navLinks');
    if (!toggle || !links) return;

    toggle.addEventListener('click', () => {
        const isOpen = links.classList.toggle('open');
        toggle.classList.toggle('active', isOpen);
        document.body.style.overflow = isOpen ? 'hidden' : '';
    });

    // Close menu when a link is clicked
    links.querySelectorAll('.nav-link, .nav-cta').forEach(link => {
        link.addEventListener('click', () => {
            toggle.classList.remove('active');
            links.classList.remove('open');
            document.body.style.overflow = '';
        });
    });
}

/* ═══════════════════════════════════════════════════════════════════════
   INSTALL TABS — PowerShell / CMD switcher
   ═══════════════════════════════════════════════════════════════════════ */
function initInstallTabs() {
    const tabs = document.querySelectorAll('.install-tab');
    const panels = document.querySelectorAll('.install-panel');
    
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const target = tab.dataset.tab;
            
            // Single pass: deactivate all, then activate selected
            tabs.forEach(t => t.classList.remove('active'));
            panels.forEach(p => p.classList.remove('active'));
            
            tab.classList.add('active');
            const panel = document.getElementById(`panel${capitalize(target)}`);
            if (panel) panel.classList.add('active');
        });
    });
}

function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}

/* ═══════════════════════════════════════════════════════════════════════
   COPY TO CLIPBOARD
   ═══════════════════════════════════════════════════════════════════════ */
function copyCommand(elementId) {
    const el = document.getElementById(elementId);
    if (!el) return;

    const text = el.textContent.trim();

    navigator.clipboard.writeText(text).then(() => {
        showCopyFeedback(el);
    }).catch(() => {
        // Fallback for older browsers / insecure contexts
        const textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.cssText = 'position:fixed;opacity:0;pointer-events:none';
        document.body.appendChild(textarea);
        textarea.select();
        try { 
            document.execCommand('copy');
            showCopyFeedback(el);
        } catch(e) { /* silent */ }
        document.body.removeChild(textarea);
    });
}

function showCopyFeedback(el) {
    const command = el.closest('.install-command');
    const btn = command ? command.querySelector('.copy-btn') : null;
    if (!btn) return;

    const copyIcon = btn.querySelector('.copy-icon');
    const checkIcon = btn.querySelector('.check-icon');
    
    btn.classList.add('copied');
    if (copyIcon) copyIcon.style.display = 'none';
    if (checkIcon) checkIcon.style.display = 'block';

    setTimeout(() => {
        btn.classList.remove('copied');
        if (copyIcon) copyIcon.style.display = '';
        if (checkIcon) checkIcon.style.display = 'none';
    }, 2000);
}

// Expose globally for onclick handlers
window.copyCommand = copyCommand;

/* ═══════════════════════════════════════════════════════════════════════
   TERMINAL ANIMATION — Typing effect (optimized, no layout thrashing)
   Uses requestAnimationFrame-friendly timing
   ═══════════════════════════════════════════════════════════════════════ */
function initTerminalAnimation() {
    const cmdEl = document.getElementById('typingCmd');
    const outputEl = document.getElementById('terminalOutput');
    const cursorEl = document.querySelector('.t-cursor');
    if (!cmdEl || !outputEl) return;

    const command = 'kitly install dev-frontend';
    const outputLines = [
        { text: '', cls: '' },
        { text: ' ┌─────────────────────────────────────────┐', cls: 't-muted' },
        { text: ' │  KITLY │ Installing: dev-frontend        │', cls: 't-info' },
        { text: ' └─────────────────────────────────────────┘', cls: 't-muted' },
        { text: '', cls: '' },
        { text: ' → Installing: Microsoft.VisualStudioCode', cls: 't-muted' },
        { text: ' ✓ Installed \'VS Code\' successfully!', cls: 't-success' },
        { text: ' → Installing: OpenJS.NodeJS', cls: 't-muted' },
        { text: ' ✓ Installed \'Node.js\' successfully!', cls: 't-success' },
        { text: ' → Installing: Git.Git', cls: 't-muted' },
        { text: ' ✓ \'Git\' is already up-to-date!', cls: 't-success' },
        { text: '', cls: '' },
        { text: ' ┌─────────────────────────────────────────┐', cls: 't-muted' },
        { text: ' │  KITLY │ Installation Completed!         │', cls: 't-info' },
        { text: ' └─────────────────────────────────────────┘', cls: 't-muted' },
    ];

    let charIndex = 0;
    let animationTimer = null;

    // Use IntersectionObserver to start when visible
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                startTyping();
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.3 });

    observer.observe(document.querySelector('.hero-terminal'));

    function startTyping() {
        charIndex = 0;
        cmdEl.textContent = '';
        outputEl.innerHTML = '';
        if (cursorEl) cursorEl.style.display = 'inline-block';
        typeNextChar();
    }

    function typeNextChar() {
        if (charIndex < command.length) {
            cmdEl.textContent += command[charIndex];
            charIndex++;
            animationTimer = setTimeout(typeNextChar, 35 + Math.random() * 35);
        } else {
            if (cursorEl) cursorEl.style.display = 'none';
            animationTimer = setTimeout(showOutputLines, 350);
        }
    }

    function showOutputLines() {
        let lineIndex = 0;

        function addNextLine() {
            if (lineIndex >= outputLines.length) {
                if (cursorEl) cursorEl.style.display = 'inline-block';
                // Restart after a pause
                animationTimer = setTimeout(startTyping, 5000);
                return;
            }

            const line = outputLines[lineIndex];
            const div = document.createElement('div');
            div.className = `t-line ${line.cls}`;
            div.textContent = line.text || '\u00A0';
            outputEl.appendChild(div);
            lineIndex++;

            animationTimer = setTimeout(addNextLine, 100);
        }

        addNextLine();
    }
}

/* ═══════════════════════════════════════════════════════════════════════
   SCROLL ANIMATIONS — Reveal on scroll (optimized, batched reads)
   Uses CSS classes for transforms instead of inline styles
   ═══════════════════════════════════════════════════════════════════════ */
function initScrollAnimations() {
    const animatedElements = document.querySelectorAll(
        '.feature-card, .bundle-card, .step-card'
    );

    if (!animatedElements.length) return;

    // Pre-compute sibling indices to avoid layout reads during animation
    const elementData = new Map();
    animatedElements.forEach(el => {
        const parent = el.parentElement;
        const className = el.classList[0];
        const siblings = Array.from(parent.children).filter(c => c.classList.contains(className));
        elementData.set(el, siblings.indexOf(el));
    });

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const index = elementData.get(entry.target) || 0;
                const delay = index * 80;

                // Use requestAnimationFrame for smooth class addition
                if (delay > 0) {
                    setTimeout(() => {
                        requestAnimationFrame(() => {
                            entry.target.classList.add('visible');
                        });
                    }, delay);
                } else {
                    requestAnimationFrame(() => {
                        entry.target.classList.add('visible');
                    });
                }

                observer.unobserve(entry.target);
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '0px 0px -40px 0px'
    });

    animatedElements.forEach(el => observer.observe(el));
}

/* ═══════════════════════════════════════════════════════════════════════
   SMOOTH SCROLL — For anchor links
   ═══════════════════════════════════════════════════════════════════════ */
function initSmoothScrollLinks() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const href = this.getAttribute('href');
            if (href === '#') return;
            
            const target = document.querySelector(href);
            if (!target) return;

            e.preventDefault();
            const navHeight = document.getElementById('navbar')?.offsetHeight || 0;
            const top = target.getBoundingClientRect().top + window.scrollY - navHeight - 16;

            window.scrollTo({
                top: top,
                behavior: 'smooth'
            });
        });
    });
}

/* ═══════════════════════════════════════════════════════════════════════
   APP BUILDER — Select apps, generate commands
   ═══════════════════════════════════════════════════════════════════════ */

const APP_CATALOG = [
    { id: 'Microsoft.VisualStudioCode', name: 'VS Code', cat: 'dev' },
    { id: 'OpenJS.NodeJS',              name: 'Node.js', cat: 'dev' },
    { id: 'Git.Git',                    name: 'Git', cat: 'dev' },
    { id: 'Python.Python.3.11',         name: 'Python 3.11', cat: 'dev' },
    { id: 'Docker.DockerDesktop',       name: 'Docker Desktop', cat: 'dev' },
    { id: 'Postman.Postman',            name: 'Postman', cat: 'dev' },
    { id: 'Figma.Figma',               name: 'Figma', cat: 'dev' },
    { id: 'Microsoft.VisualStudio.2022.Community', name: 'Visual Studio 2022', cat: 'dev' },
    { id: 'Microsoft.DotNet.SDK.8',     name: '.NET SDK 8', cat: 'dev' },
    { id: 'Amazon.AWSCLI',              name: 'AWS CLI', cat: 'dev' },
    { id: 'dbeaver.dbeaver',            name: 'DBeaver', cat: 'dev' },
    { id: 'Microsoft.SQLServerManagementStudio', name: 'SSMS', cat: 'dev' },
    { id: 'RProject.R',                 name: 'R Language', cat: 'dev' },

    { id: 'Google.Chrome',              name: 'Chrome', cat: 'browser' },
    { id: 'Mozilla.Firefox',            name: 'Firefox', cat: 'browser' },
    { id: 'Brave.Brave',                name: 'Brave', cat: 'browser' },

    { id: '7zip.7zip',                  name: '7-Zip', cat: 'util' },
    { id: 'Notepad++.Notepad++',        name: 'Notepad++', cat: 'util' },
    { id: 'voidtools.Everything',        name: 'Everything', cat: 'util' },
    { id: 'Microsoft.PowerToys',        name: 'PowerToys', cat: 'util' },
    { id: 'TimKosse.FileZillaClient',   name: 'FileZilla', cat: 'util' },
    { id: 'AnyDeskSoftwareGmbH.AnyDesk',name: 'AnyDesk', cat: 'util' },
    { id: 'LocalSend.LocalSend',        name: 'LocalSend', cat: 'util' },

    { id: 'VideoLAN.VLC',               name: 'VLC', cat: 'media' },
    { id: 'OBSProject.OBSStudio',       name: 'OBS Studio', cat: 'media' },
    { id: 'Audacity.Audacity',          name: 'Audacity', cat: 'media' },
    { id: 'BlenderFoundation.Blender',  name: 'Blender', cat: 'media' },
    { id: 'GIMP.GIMP',                  name: 'GIMP', cat: 'media' },
    { id: 'KDE.Krita',                  name: 'Krita', cat: 'media' },
    { id: 'KDE.Kdenlive',               name: 'Kdenlive', cat: 'media' },
    { id: 'BlackmagicDesign.DaVinciResolve', name: 'DaVinci Resolve', cat: 'media' },

    { id: 'Discord.Discord',            name: 'Discord', cat: 'comm' },
    { id: 'SlackTechnologies.Slack',     name: 'Slack', cat: 'comm' },
    { id: 'Zoom.Zoom',                  name: 'Zoom', cat: 'comm' },

    { id: 'Valve.Steam',                name: 'Steam', cat: 'gaming' },
    { id: 'EpicGames.EpicGamesLauncher',name: 'Epic Games', cat: 'gaming' },
    { id: 'Nvidia.GeForceExperience',   name: 'GeForce Exp.', cat: 'gaming' },
    { id: 'GOG.Galaxy',                 name: 'GOG Galaxy', cat: 'gaming' },

    { id: 'TheDocumentFoundation.LibreOffice', name: 'LibreOffice', cat: 'office' },
    { id: 'SumatraPDF.SumatraPDF',      name: 'SumatraPDF', cat: 'office' },
    { id: 'ONLYOFFICE.DesktopEditors',   name: 'ONLYOFFICE', cat: 'office' },
    { id: 'AppFlowy.AppFlowy',           name: 'AppFlowy', cat: 'office' },

    { id: 'PuTTY.PuTTY',               name: 'PuTTY', cat: 'admin' },
    { id: 'MartinPrikryl.WinSCP',       name: 'WinSCP', cat: 'admin' },
    { id: 'WireGuard.WireGuard',        name: 'WireGuard', cat: 'admin' },
    { id: 'WiresharkFoundation.Wireshark', name: 'Wireshark', cat: 'admin' },
    { id: 'Microsoft.Sysinternals',     name: 'Sysinternals', cat: 'admin' },

    { id: 'qBittorrent.qBittorrent',    name: 'qBittorrent', cat: 'util' },
];

const BUNDLES = {
    'essential':     ['7zip.7zip','Google.Chrome','VideoLAN.VLC','Notepad++.Notepad++','voidtools.Everything','Microsoft.PowerToys'],
    'dev-frontend':  ['Microsoft.VisualStudioCode','OpenJS.NodeJS','Git.Git','Google.Chrome','Mozilla.Firefox','Figma.Figma','Postman.Postman'],
    'dev-backend':   ['Docker.DockerDesktop','Python.Python.3.11','Git.Git','Postman.Postman','dbeaver.dbeaver','Amazon.AWSCLI'],
    'gaming':        ['Valve.Steam','Discord.Discord','EpicGames.EpicGamesLauncher','Nvidia.GeForceExperience','GOG.Galaxy'],
    'media-creator': ['OBSProject.OBSStudio','BlackmagicDesign.DaVinciResolve','BlenderFoundation.Blender','Audacity.Audacity','GIMP.GIMP','KDE.Krita'],
    'sysadmin':      ['PuTTY.PuTTY','MartinPrikryl.WinSCP','Notepad++.Notepad++','WireGuard.WireGuard','Microsoft.Sysinternals','WiresharkFoundation.Wireshark'],
    'office':        ['TheDocumentFoundation.LibreOffice','SumatraPDF.SumatraPDF','Zoom.Zoom','SlackTechnologies.Slack','7zip.7zip'],
};

function initAppBuilder() {
    const grid = document.getElementById('builderGrid');
    const commandText = document.getElementById('builderCommandText');
    const copyBtn = document.getElementById('builderCopyBtn');
    const countEl = document.getElementById('builderCount');
    const clearBtn = document.getElementById('builderClearBtn');
    if (!grid || !commandText) return;

    const selected = new Set();
    let mode = 'kitly'; // 'kitly' or 'winget'

    // ── Render app grid ──
    const checkSvg = '<svg viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>';

    APP_CATALOG.forEach(app => {
        const el = document.createElement('div');
        el.className = 'builder-app';
        el.dataset.appId = app.id;
        el.innerHTML = `<div class="builder-app-check">${checkSvg}</div><div class="builder-app-info"><div class="builder-app-name">${app.name}</div><div class="builder-app-id">${app.id}</div></div>`;
        el.addEventListener('click', () => {
            if (selected.has(app.id)) {
                selected.delete(app.id);
                el.classList.remove('selected');
            } else {
                selected.add(app.id);
                el.classList.add('selected');
            }
            updateCommand();
        });
        grid.appendChild(el);
    });

    // ── Update command display ──
    function updateCommand() {
        const apps = Array.from(selected);

        if (apps.length === 0) {
            commandText.innerHTML = '<span class="builder-placeholder">Select apps above to generate a command...</span>';
            copyBtn.disabled = true;
            countEl.textContent = '';
            // Clear active bundle buttons
            document.querySelectorAll('.builder-bundle-btn[data-bundle]').forEach(b => b.classList.remove('active'));
            return;
        }

        copyBtn.disabled = false;
        countEl.textContent = `${apps.length} app${apps.length > 1 ? 's' : ''} selected`;

        if (mode === 'kitly') {
            const ids = apps.map(id => {
                const app = APP_CATALOG.find(a => a.id === id);
                return app ? app.id : id;
            });
            commandText.textContent = 'kitly install ' + ids.join(' ');
        } else {
            const lines = apps.map(id =>
                `winget install --id ${id} --silent --accept-package-agreements --accept-source-agreements`
            );
            commandText.textContent = lines.join('\n');
        }
    }

    // ── Mode tabs ──
    document.querySelectorAll('.builder-mode-tab').forEach(tab => {
        tab.addEventListener('click', () => {
            document.querySelectorAll('.builder-mode-tab').forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            mode = tab.dataset.mode;
            updateCommand();
        });
    });

    // ── Copy button ──
    copyBtn.addEventListener('click', () => {
        if (copyBtn.disabled) return;
        const text = commandText.textContent.trim();
        navigator.clipboard.writeText(text).then(() => {
            showBuilderCopyFeedback();
        }).catch(() => {
            const ta = document.createElement('textarea');
            ta.value = text;
            ta.style.cssText = 'position:fixed;opacity:0;pointer-events:none';
            document.body.appendChild(ta);
            ta.select();
            try { document.execCommand('copy'); showBuilderCopyFeedback(); } catch(e) {}
            document.body.removeChild(ta);
        });
    });

    function showBuilderCopyFeedback() {
        const ci = copyBtn.querySelector('.copy-icon');
        const ch = copyBtn.querySelector('.check-icon');
        copyBtn.classList.add('copied');
        if (ci) ci.style.display = 'none';
        if (ch) ch.style.display = 'block';
        setTimeout(() => {
            copyBtn.classList.remove('copied');
            if (ci) ci.style.display = '';
            if (ch) ch.style.display = 'none';
        }, 2000);
    }

    // ── Bundle quick-select ──
    document.querySelectorAll('.builder-bundle-btn[data-bundle]').forEach(btn => {
        btn.addEventListener('click', () => {
            const bundleName = btn.dataset.bundle;
            const bundleIds = BUNDLES[bundleName];
            if (!bundleIds) return;

            const isActive = btn.classList.contains('active');

            // Clear all bundle active states
            document.querySelectorAll('.builder-bundle-btn[data-bundle]').forEach(b => b.classList.remove('active'));

            if (isActive) {
                // Deselect this bundle's apps
                bundleIds.forEach(id => selected.delete(id));
            } else {
                // Select this bundle's apps
                btn.classList.add('active');
                bundleIds.forEach(id => selected.add(id));
            }

            // Sync grid checkboxes
            grid.querySelectorAll('.builder-app').forEach(el => {
                const id = el.dataset.appId;
                el.classList.toggle('selected', selected.has(id));
            });

            updateCommand();
        });
    });

    // ── Clear all ──
    if (clearBtn) {
        clearBtn.addEventListener('click', () => {
            selected.clear();
            grid.querySelectorAll('.builder-app').forEach(el => el.classList.remove('selected'));
            document.querySelectorAll('.builder-bundle-btn[data-bundle]').forEach(b => b.classList.remove('active'));
            updateCommand();
        });
    }
}
