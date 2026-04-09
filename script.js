/* ═══════════════════════════════════════════════════════════════════════
   KITLY — Website JavaScript
   Handles: navigation, copy-to-clipboard, terminal animation,
   scroll animations, and tab switching.
   ═══════════════════════════════════════════════════════════════════════ */

document.addEventListener('DOMContentLoaded', () => {
    initNavbar();
    initMobileNav();
    initInstallTabs();
    initTerminalAnimation();
    initScrollAnimations();
    initSmoothScrollLinks();
});

/* ═══════════════════════════════════════════════════════════════════════
   NAVBAR — Scroll-triggered background
   ═══════════════════════════════════════════════════════════════════════ */
function initNavbar() {
    const navbar = document.getElementById('navbar');
    if (!navbar) return;

    const onScroll = () => {
        if (window.scrollY > 60) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
    };

    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
}

/* ═══════════════════════════════════════════════════════════════════════
   MOBILE NAVIGATION — Toggle menu
   ═══════════════════════════════════════════════════════════════════════ */
function initMobileNav() {
    const toggle = document.getElementById('navToggle');
    const links = document.getElementById('navLinks');
    if (!toggle || !links) return;

    toggle.addEventListener('click', () => {
        toggle.classList.toggle('active');
        links.classList.toggle('open');
        document.body.style.overflow = links.classList.contains('open') ? 'hidden' : '';
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
    
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const target = tab.dataset.tab;
            
            // Deactivate all tabs and panels
            document.querySelectorAll('.install-tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.install-panel').forEach(p => p.classList.remove('active'));
            
            // Activate selected
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
        // Find the parent install-command and its copy button
        const command = el.closest('.install-command');
        const btn = command ? command.querySelector('.copy-btn') : null;
        
        if (btn) {
            const copyIcon = btn.querySelector('.copy-icon');
            const checkIcon = btn.querySelector('.check-icon');
            
            btn.classList.add('copied');
            if (copyIcon) copyIcon.style.display = 'none';
            if (checkIcon) checkIcon.style.display = 'block';

            setTimeout(() => {
                btn.classList.remove('copied');
                if (copyIcon) copyIcon.style.display = 'block';
                if (checkIcon) checkIcon.style.display = 'none';
            }, 2000);
        }
    }).catch(() => {
        // Fallback for older browsers
        const textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.position = 'fixed';
        textarea.style.opacity = '0';
        document.body.appendChild(textarea);
        textarea.select();
        try { document.execCommand('copy'); } catch(e) { /* silent fail */ }
        document.body.removeChild(textarea);
    });
}

// Expose globally for onclick handlers
window.copyCommand = copyCommand;

/* ═══════════════════════════════════════════════════════════════════════
   TERMINAL ANIMATION — Typing effect with simulated output
   ═══════════════════════════════════════════════════════════════════════ */
function initTerminalAnimation() {
    const cmdEl = document.getElementById('typingCmd');
    const outputEl = document.getElementById('terminalOutput');
    const cursorEl = document.querySelector('.t-cursor');
    if (!cmdEl || !outputEl) return;

    const command = 'kitly install dev-frontend';
    const outputLines = [
        { text: '', cls: '' },
        { text: ' [*] KITLY | Installing: dev-frontend', cls: 't-info' },
        { text: ' [i] Found bundle \'dev-frontend\' with 7 packages.', cls: 't-muted' },
        { text: '', cls: '' },
        { text: ' [i] Attempting to install: Microsoft.VisualStudioCode', cls: 't-muted' },
        { text: ' [v] Installed \'Microsoft.VisualStudioCode\' successfully!', cls: 't-success' },
        { text: ' [i] Attempting to install: OpenJS.NodeJS', cls: 't-muted' },
        { text: ' [v] Installed \'OpenJS.NodeJS\' successfully!', cls: 't-success' },
        { text: ' [i] Attempting to install: Git.Git', cls: 't-muted' },
        { text: ' [v] \'Git.Git\' is already installed or up-to-date!', cls: 't-success' },
        { text: ' [i] Attempting to install: Google.Chrome', cls: 't-muted' },
        { text: ' [v] \'Google.Chrome\' is already installed or up-to-date!', cls: 't-success' },
        { text: '', cls: '' },
        { text: ' [*] KITLY | Installation Completed!', cls: 't-info' },
    ];

    let charIndex = 0;
    let hasStarted = false;

    // Use IntersectionObserver to start when visible
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting && !hasStarted) {
                hasStarted = true;
                startTyping();
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.3 });

    observer.observe(document.querySelector('.hero-terminal'));

    function startTyping() {
        typeChar();
    }

    function typeChar() {
        if (charIndex < command.length) {
            cmdEl.textContent += command[charIndex];
            charIndex++;
            setTimeout(typeChar, 40 + Math.random() * 40);
        } else {
            // Hide cursor briefly, then show output
            if (cursorEl) cursorEl.style.display = 'none';
            setTimeout(showOutput, 400);
        }
    }

    function showOutput() {
        let lineIndex = 0;

        function addLine() {
            if (lineIndex >= outputLines.length) {
                if (cursorEl) {
                    cursorEl.style.display = 'inline-block';
                }
                // Restart animation after a pause
                setTimeout(() => {
                    cmdEl.textContent = '';
                    outputEl.innerHTML = '';
                    charIndex = 0;
                    hasStarted = true;
                    if (cursorEl) cursorEl.style.display = 'inline-block';
                    startTyping();
                }, 5000);
                return;
            }

            const line = outputLines[lineIndex];
            const div = document.createElement('div');
            div.className = `t-line ${line.cls}`;
            div.textContent = line.text || '\u00A0';
            div.style.animationDelay = '0s';
            outputEl.appendChild(div);
            lineIndex++;

            setTimeout(addLine, 120);
        }

        addLine();
    }
}

/* ═══════════════════════════════════════════════════════════════════════
   SCROLL ANIMATIONS — Reveal on scroll with IntersectionObserver
   ═══════════════════════════════════════════════════════════════════════ */
function initScrollAnimations() {
    const animatedElements = document.querySelectorAll(
        '.feature-card, .bundle-card, .step-card'
    );

    if (!animatedElements.length) return;

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                // Stagger delay based on element index within its container
                const parent = entry.target.parentElement;
                const siblings = Array.from(parent.children).filter(
                    c => c.classList.contains(entry.target.classList[0])
                );
                const index = siblings.indexOf(entry.target);
                const delay = index * 100;

                setTimeout(() => {
                    entry.target.classList.add('visible');
                }, delay);

                observer.unobserve(entry.target);
            }
        });
    }, {
        threshold: 0.15,
        rootMargin: '0px 0px -50px 0px'
    });

    animatedElements.forEach(el => observer.observe(el));
}

/* ═══════════════════════════════════════════════════════════════════════
   SMOOTH SCROLL — For anchor links
   ═══════════════════════════════════════════════════════════════════════ */
function initSmoothScrollLinks() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const target = document.querySelector(this.getAttribute('href'));
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
