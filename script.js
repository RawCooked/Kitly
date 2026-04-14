/* ═══════════════════════════════════════════════════════════════════════
   KITLY — Website JavaScript
   Handles: navigation, copy-to-clipboard, terminal animation,
   scroll animations, and tab switching.
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
