/**
 * Gallery page - discovers and displays available designs.
 */
import { STLViewer } from './viewer.js';

// Design manifest - lists available designs and their STL files.
// This is updated by the generation script.
const DESIGNS_MANIFEST_URL = 'models/manifest.json';

// Fallback manifest built from known designs
const FALLBACK_MANIFEST = [
    {
        name: 'Cardboard Box Latch',
        slug: 'cardboard_box_latch',
        description: 'A two-piece handle/latch mechanism for cardboard boxes. Features a D-shaped shaft for aligned rotation.',
        scadFile: 'designs/cardboard_box_latch.scad',
        stlFiles: {
            both: 'models/cardboard_box_latch_both.stl',
            handle: 'models/cardboard_box_latch_handle.stl',
            hook: 'models/cardboard_box_latch_hook.stl',
            assembled: 'models/cardboard_box_latch_assembled.stl',
        },
        parameters: [
            'cardboard_thickness', 'shaft_diameter', 'handle_length',
            'hook_arm_length', 'tolerance'
        ]
    }
];

const gallery = document.getElementById('gallery');

async function loadManifest() {
    try {
        const resp = await fetch(DESIGNS_MANIFEST_URL);
        if (resp.ok) return await resp.json();
    } catch (_) {
        // manifest not generated yet
    }
    return FALLBACK_MANIFEST;
}

function formatName(slug) {
    return slug.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

function createCard(design) {
    const card = document.createElement('div');
    card.className = 'design-card';

    // 3D preview container
    const preview = document.createElement('div');
    preview.className = 'preview';
    card.appendChild(preview);

    // Info section
    const info = document.createElement('div');
    info.className = 'info';
    info.innerHTML = `
        <h3>${design.name}</h3>
        <p class="meta">${design.description || ''}</p>
    `;
    card.appendChild(info);

    // View mode selector + actions
    const actions = document.createElement('div');
    actions.className = 'actions';

    const select = document.createElement('select');
    select.className = 'btn';
    for (const mode of Object.keys(design.stlFiles)) {
        const opt = document.createElement('option');
        opt.value = mode;
        opt.textContent = formatName(mode);
        select.appendChild(opt);
    }
    actions.appendChild(select);

    const editLink = document.createElement('a');
    editLink.className = 'btn btn-primary';
    editLink.href = `editor.html?design=${design.slug}`;
    editLink.textContent = 'Open in Editor';
    actions.appendChild(editLink);

    card.appendChild(actions);

    // Initialize 3D viewer
    requestAnimationFrame(() => {
        const viewer = new STLViewer(preview, {
            modelColor: 0x4a9eff,
        });
        viewer.startAnimation();

        // Try loading the default STL
        const defaultMode = Object.keys(design.stlFiles)[0];
        loadModel(viewer, design.stlFiles[defaultMode], preview);

        select.addEventListener('change', () => {
            loadModel(viewer, design.stlFiles[select.value], preview);
        });
    });

    return card;
}

async function loadModel(viewer, stlUrl, container) {
    try {
        await viewer.loadSTL(stlUrl);
    } catch (_) {
        // STL not generated yet - show placeholder message
        if (!container.querySelector('.placeholder')) {
            const placeholder = document.createElement('div');
            placeholder.className = 'placeholder';
            placeholder.style.cssText = `
                position: absolute; top: 50%; left: 50%;
                transform: translate(-50%, -50%);
                text-align: center; color: #666; font-size: 0.85rem;
                pointer-events: none;
            `;
            placeholder.innerHTML = 'STL not generated yet.<br>Use the Editor to render, or run the generation script.';
            container.style.position = 'relative';
            container.appendChild(placeholder);
        }
    }
}

async function init() {
    const manifest = await loadManifest();
    gallery.innerHTML = '';

    if (manifest.length === 0) {
        gallery.innerHTML = '<div class="loading">No designs found. Add .scad files to the designs/ directory.</div>';
        return;
    }

    for (const design of manifest) {
        gallery.appendChild(createCard(design));
    }
}

init();
