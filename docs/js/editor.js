/**
 * OpenSCAD Web Editor
 * - Code editor with parameter extraction
 * - OpenSCAD WASM rendering
 * - Three.js 3D preview
 */
import { STLViewer } from './viewer.js';

const OPENSCAD_WASM_URL = 'https://cdn.jsdelivr.net/npm/openscad-wasm@1.0.0/dist/openscad.js';

// Known designs - matches gallery manifest
const DESIGNS = {
    cardboard_box_latch: {
        name: 'Cardboard Box Latch',
        file: 'designs/cardboard_box_latch.scad',
    },
};

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

// State
let viewer = null;
let openscadInstance = null;
let originalCode = '';
let lastSTLBlob = null;
let wasmSupported = true;

// Initialize viewer
function initViewer() {
    viewer = new STLViewer(previewCanvas, {
        modelColor: 0x4a9eff,
    });
    viewer.startAnimation();
}

// Populate design selector
function initDesignSelector() {
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

    // Match lines like: param_name = value; // comment
    const paramRegex = /^(\w+)\s*=\s*([^;]+);.*?\/\/\s*(.+)?$/gm;
    let match;
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

            // Skip $fn and display_mode
            if (name === '$fn') continue;

            // Get comment from the line above or inline
            let comment = '';
            const inlineComment = line.match(/\/\/\s*(.+)/);
            if (inlineComment) {
                comment = inlineComment[1].trim();
            } else if (i > 0) {
                const prevComment = lines[i - 1].match(/^\/\/\s*(.+)/);
                if (prevComment) comment = prevComment[1].trim();
            }

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
                name, value, type, comment, group: currentGroup,
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
        groupDiv.innerHTML = `<div class="group-title">${groupName}</div>`;

        for (const p of groupParams) {
            const row = document.createElement('div');
            row.className = 'param-row';

            const label = document.createElement('label');
            label.textContent = p.comment || formatName(p.name);
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
}

// Set render status
function setStatus(text, state = '') {
    renderStatus.textContent = text;
    renderStatus.className = `status ${state}`;
}

// Load OpenSCAD WASM
async function loadOpenSCAD() {
    if (openscadInstance) return openscadInstance;

    setStatus('Loading OpenSCAD WASM...', 'rendering');

    try {
        // Dynamically import the WASM module
        const module = await import(/* webpackIgnore: true */ OPENSCAD_WASM_URL);
        const OpenSCAD = module.default || module;
        openscadInstance = await OpenSCAD({
            noInitialRun: true,
        });
        setStatus('OpenSCAD ready', 'success');
        return openscadInstance;
    } catch (err) {
        console.warn('OpenSCAD WASM failed to load:', err);
        wasmSupported = false;
        setStatus('WASM unavailable - use local OpenSCAD to render', 'error');
        return null;
    }
}

// Render SCAD code to STL using WASM
async function renderSCAD() {
    const code = codeEditor.value;
    if (!code.trim()) {
        setStatus('No code to render', 'error');
        return;
    }

    renderBtn.disabled = true;
    setStatus('Rendering...', 'rendering');

    try {
        const instance = await loadOpenSCAD();
        if (!instance) {
            setStatus('WASM not available - download OpenSCAD to render locally', 'error');
            renderBtn.disabled = false;
            return;
        }

        // Write the SCAD file to the virtual filesystem
        instance.FS.writeFile('/input.scad', code);

        // Run OpenSCAD
        try {
            instance.callMain(['-o', '/output.stl', '/input.scad']);
        } catch (exitErr) {
            // callMain may throw on exit, check if file was created
        }

        // Read the output
        let stlData;
        try {
            stlData = instance.FS.readFile('/output.stl');
        } catch (_) {
            setStatus('Render failed - check SCAD syntax', 'error');
            renderBtn.disabled = false;
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
        renderBtn.disabled = false;
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
function init() {
    initViewer();
    initDesignSelector();

    // Event listeners
    renderBtn.addEventListener('click', renderSCAD);
    downloadBtn.addEventListener('click', downloadSTL);
    resetBtn.addEventListener('click', () => {
        codeEditor.value = originalCode;
        extractParameters(originalCode);
    });
    viewResetBtn.addEventListener('click', () => viewer.setView('iso'));
    viewFrontBtn.addEventListener('click', () => viewer.setView('front'));
    viewTopBtn.addEventListener('click', () => viewer.setView('top'));
    viewIsoBtn.addEventListener('click', () => viewer.setView('iso'));

    codeEditor.addEventListener('keydown', handleTab);
    document.addEventListener('keydown', handleKeyboard);

    // Load initial design
    const slug = designSelect.value || Object.keys(DESIGNS)[0];
    if (slug) loadDesign(slug);
}

init();
