/**
 * OpenSCAD Web Editor
 * - Code editor with parameter extraction
 * - OpenSCAD WASM rendering
 * - Three.js 3D preview
 */
import { STLViewer } from './viewer.js';

// OpenSCAD WASM is loaded from local files in docs/wasm/
// Built from https://github.com/openscad/openscad-wasm (release 2022.03.20)

// Design list loaded from generated manifest
let DESIGNS = {};

// DOM elements
const codeEditor = document.getElementById('code-editor');
const designSelect = document.getElementById('design-select');
const renderBtn = document.getElementById('render-btn');
const downloadBtn = document.getElementById('download-stl-btn');
const resetBtn = document.getElementById('reset-btn');
const viewResetBtn = document.getElementById('view-reset-btn');
const viewFrontBtn = document.getElementById('view-front-btn');
const viewTopBtn = document.getElementById('view-top-btn');
const viewIsoBtn = document.getElementById('view-iso-btn');
const renderStatus = document.getElementById('render-status');
const previewCanvas = document.getElementById('preview-canvas');
const paramsContainer = document.getElementById('params-container');
const autoRenderCb = document.getElementById('auto-render-cb');

// Loading screen elements
const loadingScreen = document.getElementById('loading-screen');
const loadingStatusEl = document.getElementById('loading-status');
const loadingProgressBar = document.getElementById('loading-progress-bar');

// State
let viewer = null;
let originalCode = '';
let lastSTLBlob = null;
let isRendering = false;
let renderQueued = false;
let autoRenderTimeout = null;
const AUTO_RENDER_DELAY = 1500; // ms

// Initialize viewer
function initViewer() {
    viewer = new STLViewer(previewCanvas, {
        modelColor: 0x4a9eff,
    });
    viewer.startAnimation();
}

// Load design manifest and populate selector
async function initDesignSelector() {
    // Load designs from generated manifest
    try {
        const resp = await fetch('designs.json');
        if (resp.ok) {
            const manifest = await resp.json();
            for (const entry of manifest) {
                DESIGNS[entry.slug] = {
                    name: entry.name,
                    file: entry.scadFile,
                };
            }
        }
    } catch (_) {
        // manifest not generated yet
    }

    for (const [slug, design] of Object.entries(DESIGNS)) {
        const opt = document.createElement('option');
        opt.value = slug;
        opt.textContent = design.name;
        designSelect.appendChild(opt);
    }

    // Check URL params for pre-selected design
    const params = new URLSearchParams(window.location.search);
    const selected = params.get('design');
    if (selected && DESIGNS[selected]) {
        designSelect.value = selected;
    }

    designSelect.addEventListener('change', () => loadDesign(designSelect.value));
}

// Load a design's SCAD source
async function loadDesign(slug) {
    const design = DESIGNS[slug];
    if (!design) return;

    cancelAutoRender();
    lastSTLBlob = null;
    setStatus('Loading...', 'rendering');

    try {
        const resp = await fetch(design.file);
        if (!resp.ok) throw new Error(`Failed to load ${design.file}`);
        const code = await resp.text();
        originalCode = code;
        codeEditor.value = code;
        extractParameters(code);
        setStatus('Loaded - click Render to preview', 'success');
    } catch (err) {
        setStatus(`Load error: ${err.message}`, 'error');
    }
}

// Extract parameters from SCAD source
function extractParameters(code) {
    paramsContainer.innerHTML = '';
    const params = [];
    let currentGroup = 'General';

    const lines = code.split('\n');
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];

        // Check for group headers: /* [Group Name] */
        const groupMatch = line.match(/\/\*\s*\[(.+?)\]\s*\*\//);
        if (groupMatch) {
            currentGroup = groupMatch[1];
            continue;
        }

        // Check for parameter assignments
        const paramMatch = line.match(/^(\w+)\s*=\s*([^;]+);/);
        if (paramMatch) {
            const name = paramMatch[1];
            const rawValue = paramMatch[2].trim();

            // Skip $-prefixed (OpenSCAD special) and _-prefixed (internal) variables
            if (name.startsWith('$')) continue;
            if (name.startsWith('_')) continue;

            // The inline comment holds the customizer spec ([min:step:max]
            // or option list); the comment on the line above holds the
            // human description
            let inline = '';
            const inlineComment = line.match(/\/\/\s*(.+)/);
            if (inlineComment) inline = inlineComment[1].trim();
            let above = '';
            if (i > 0) {
                const prevComment = lines[i - 1].match(/^\s*\/\/\s*(.+)/);
                if (prevComment) above = prevComment[1].trim();
            }
            const comment = inline || above;
            // Display label: comment text with any [spec] stripped out
            const label = inline.replace(/\[[^\]]*\]/g, '').trim() ||
                above.replace(/\[[^\]]*\]/g, '').trim();

            // Determine type
            let type = 'number';
            let value = parseFloat(rawValue);
            let options = null;
            let min = null, max = null, step = null;

            if (rawValue.startsWith('"')) {
                type = 'string';
                value = rawValue.replace(/"/g, '');
                // Check for dropdown options
                const optMatch = comment.match(/\[([^\]]+)\]/);
                if (optMatch) {
                    options = optMatch[1].split(',').map(s => s.trim().replace(/"/g, ''));
                    type = 'select';
                }
            } else if (isNaN(value)) {
                continue; // skip non-numeric, non-string params
            }

            // Check for range in comment: [min:step:max]
            const rangeMatch = comment.match(/\[(\d+):(\d+):(\d+)\]/);
            if (rangeMatch) {
                min = parseInt(rangeMatch[1]);
                step = parseInt(rangeMatch[2]);
                max = parseInt(rangeMatch[3]);
            }

            params.push({
                name, value, type, label, group: currentGroup,
                options, min, max, step, line: i
            });
        }
    }

    // Render parameter UI grouped
    const groups = {};
    for (const p of params) {
        if (!groups[p.group]) groups[p.group] = [];
        groups[p.group].push(p);
    }

    for (const [groupName, groupParams] of Object.entries(groups)) {
        const groupDiv = document.createElement('div');
        groupDiv.className = 'param-group';
        const groupTitle = document.createElement('div');
        groupTitle.className = 'group-title';
        groupTitle.textContent = groupName;
        groupDiv.appendChild(groupTitle);

        for (const p of groupParams) {
            const row = document.createElement('div');
            row.className = 'param-row';

            const label = document.createElement('label');
            label.textContent = p.label || formatName(p.name);
            label.title = p.name;
            row.appendChild(label);

            if (p.type === 'select') {
                const select = document.createElement('select');
                select.dataset.param = p.name;
                for (const opt of p.options) {
                    const optEl = document.createElement('option');
                    optEl.value = opt;
                    optEl.textContent = formatName(opt);
                    if (opt === p.value) optEl.selected = true;
                    select.appendChild(optEl);
                }
                select.addEventListener('change', () => updateParam(p.name, `"${select.value}"`));
                row.appendChild(select);
            } else if (p.min !== null) {
                const range = document.createElement('input');
                range.type = 'range';
                range.min = p.min;
                range.max = p.max;
                range.step = p.step;
                range.value = p.value;
                range.dataset.param = p.name;

                const valSpan = document.createElement('span');
                valSpan.className = 'value';
                valSpan.textContent = p.value;

                range.addEventListener('input', () => {
                    valSpan.textContent = range.value;
                    updateParam(p.name, range.value);
                });
                row.appendChild(range);
                row.appendChild(valSpan);
            } else {
                const input = document.createElement('input');
                input.type = 'number';
                input.value = p.value;
                input.step = p.value < 1 ? 0.1 : 0.5;
                input.dataset.param = p.name;
                input.addEventListener('change', () => updateParam(p.name, input.value));
                row.appendChild(input);
            }

            groupDiv.appendChild(row);
        }

        paramsContainer.appendChild(groupDiv);
    }
}

function formatName(slug) {
    return slug.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

// Update a parameter value in the code
function updateParam(name, value) {
    const code = codeEditor.value;
    const regex = new RegExp(`^(${name}\\s*=\\s*)([^;]+)(;.*)$`, 'm');
    codeEditor.value = code.replace(regex, `$1${value}$3`);
    scheduleAutoRender();
}

// Schedule an auto-render after a debounce delay
function scheduleAutoRender() {
    if (!autoRenderCb.checked) return;
    clearTimeout(autoRenderTimeout);
    autoRenderTimeout = setTimeout(() => {
        renderSCAD();
    }, AUTO_RENDER_DELAY);
}

function cancelAutoRender() {
    clearTimeout(autoRenderTimeout);
    autoRenderTimeout = null;
}

// Set render status
function setStatus(text, state = '') {
    renderStatus.textContent = text;
    renderStatus.className = `status ${state}`;
}

// Update loading screen progress
function setLoadingProgress(status, percent) {
    if (loadingStatusEl) loadingStatusEl.textContent = status;
    if (loadingProgressBar) loadingProgressBar.style.width = `${percent}%`;
}

// Dismiss loading screen
function dismissLoadingScreen() {
    if (!loadingScreen) return;
    loadingScreen.classList.add('fade-out');
    loadingScreen.addEventListener('transitionend', () => {
        loadingScreen.remove();
    }, { once: true });
    // Fallback in case transitionend never fires (e.g. reduced motion)
    setTimeout(() => loadingScreen.remove(), 1000);
}

// OpenSCAD instance management. The WASM runtime exits after callMain()
// returns, so an instance can only render once - each render consumes the
// prepared instance and a fresh one is warmed up in the background.
let instancePromise = null;
let macroCache = null;

const MACRO_FILES = ['shapes.scad'];

// Fetch shared macro libraries once and cache their contents
async function fetchMacroLibraries() {
    if (macroCache) return macroCache;
    const cache = {};
    for (const file of MACRO_FILES) {
        try {
            const resp = await fetch(`macros/${file}`);
            if (resp.ok) cache[file] = await resp.text();
        } catch (_) {
            // Macro file not available - designs still work without shared libs
        }
    }
    macroCache = cache;
    return cache;
}

// Prepare a fresh OpenSCAD instance with macro libraries mounted
function prepareOpenSCAD() {
    if (!instancePromise) {
        const promise = (async () => {
            const [{ default: OpenSCAD }, macros] = await Promise.all([
                import('../wasm/openscad.js'),
                fetchMacroLibraries(),
            ]);
            const instance = await OpenSCAD({ noInitialRun: true });
            // Design files are written to /designs/ so that
            // "use <../macros/...>" resolves to /macros/
            try {
                instance.FS.mkdir('/designs');
                instance.FS.mkdir('/macros');
                for (const [file, content] of Object.entries(macros)) {
                    instance.FS.writeFile(`/macros/${file}`, content);
                }
            } catch (_) {
                // FS setup failed - non-fatal, self-contained designs still render
            }
            return instance;
        })();
        instancePromise = promise;
        promise.catch(() => {
            if (instancePromise === promise) instancePromise = null;
        });
    }
    return instancePromise;
}

// Render SCAD code to STL using WASM
async function renderSCAD() {
    // The WASM render runs synchronously on the main thread; if a render
    // is already in flight, queue a single follow-up instead of overlapping.
    if (isRendering) {
        renderQueued = true;
        return;
    }

    const code = codeEditor.value;
    if (!code.trim()) {
        setStatus('No code to render', 'error');
        return;
    }

    isRendering = true;
    renderBtn.disabled = true;
    setStatus('Rendering...', 'rendering');

    try {
        let instance;
        try {
            instance = await prepareOpenSCAD();
        } catch (err) {
            console.warn('OpenSCAD WASM failed to load:', err);
            setStatus('WASM not available - download OpenSCAD to render locally', 'error');
            return;
        }
        // The instance is consumed by this render; a fresh one is prepared
        // in the finally block below
        instancePromise = null;

        // Write the SCAD file into /designs/ so relative paths to ../macros/ resolve
        instance.FS.writeFile('/designs/input.scad', code);

        // Let the browser paint the "Rendering..." status before the
        // synchronous WASM call blocks the main thread
        await new Promise(r => requestAnimationFrame(() => setTimeout(r, 0)));

        // Run OpenSCAD (input file first, then options)
        try {
            instance.callMain(['/designs/input.scad', '-o', '/output.stl']);
        } catch (exitErr) {
            // callMain may throw on exit, check if file was created
        }

        // Read the output
        let stlData;
        try {
            stlData = instance.FS.readFile('/output.stl');
        } catch (_) {
            setStatus('Render failed - check SCAD syntax', 'error');
            return;
        }

        // Load into viewer
        const buffer = stlData.buffer;
        viewer.loadSTLBuffer(buffer);

        // Store for download
        lastSTLBlob = new Blob([buffer], { type: 'application/octet-stream' });

        setStatus('Render complete', 'success');
    } catch (err) {
        setStatus(`Render error: ${err.message}`, 'error');
        console.error('Render error:', err);
    } finally {
        isRendering = false;
        renderBtn.disabled = false;
        // Warm up a fresh instance so the next render starts immediately
        prepareOpenSCAD().catch(() => {});
        if (renderQueued) {
            renderQueued = false;
            renderSCAD();
        }
    }
}

// Download the rendered STL
function downloadSTL() {
    if (!lastSTLBlob) {
        setStatus('Render first to download STL', 'error');
        return;
    }

    const slug = designSelect.value || 'model';
    const url = URL.createObjectURL(lastSTLBlob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${slug}.stl`;
    a.click();
    URL.revokeObjectURL(url);
}

// Handle tab key in editor
function handleTab(e) {
    if (e.key === 'Tab') {
        e.preventDefault();
        const start = codeEditor.selectionStart;
        const end = codeEditor.selectionEnd;
        codeEditor.value = codeEditor.value.substring(0, start) +
            '    ' + codeEditor.value.substring(end);
        codeEditor.selectionStart = codeEditor.selectionEnd = start + 4;
    }
}

// Ctrl+Enter to render
function handleKeyboard(e) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
        e.preventDefault();
        renderSCAD();
    }
}

// Initialize
async function init() {
    setLoadingProgress('Setting up editor...', 5);

    initViewer();
    await initDesignSelector();

    // Event listeners
    renderBtn.addEventListener('click', renderSCAD);
    downloadBtn.addEventListener('click', downloadSTL);
    resetBtn.addEventListener('click', () => {
        cancelAutoRender();
        codeEditor.value = originalCode;
        extractParameters(originalCode);
    });
    autoRenderCb.addEventListener('change', () => {
        if (!autoRenderCb.checked) cancelAutoRender();
    });
    viewResetBtn.addEventListener('click', () => viewer.setView('iso'));
    viewFrontBtn.addEventListener('click', () => viewer.setView('front'));
    viewTopBtn.addEventListener('click', () => viewer.setView('top'));
    viewIsoBtn.addEventListener('click', () => viewer.setView('iso'));

    codeEditor.addEventListener('keydown', handleTab);
    codeEditor.addEventListener('input', scheduleAutoRender);
    document.addEventListener('keydown', handleKeyboard);

    // Load initial design
    setLoadingProgress('Loading design...', 10);
    const slug = designSelect.value || Object.keys(DESIGNS)[0];
    if (slug) await loadDesign(slug);

    // Eagerly load OpenSCAD WASM
    setLoadingProgress('Loading OpenSCAD WASM...', 30);
    try {
        await prepareOpenSCAD();
        setLoadingProgress('OpenSCAD ready', 100);
        setStatus('OpenSCAD ready', 'success');
    } catch (err) {
        console.warn('OpenSCAD WASM failed to load:', err);
        setLoadingProgress('WASM unavailable - continuing without it', 100);
        setStatus('WASM unavailable - use local OpenSCAD to render', 'error');
    }

    // Dismiss loading screen
    dismissLoadingScreen();
}

init();
