/**
 * Three.js STL viewers.
 *  - STLViewer: standalone viewer with its own canvas (editor preview).
 *  - GalleryViewer: renders any number of previews through ONE shared
 *    WebGL context using scissored viewports, so the gallery never hits
 *    the browser's WebGL context limit as the design collection grows.
 */
import {
    AmbientLight, Color, DirectionalLight, GridHelper, Mesh,
    MeshPhongMaterial, PerspectiveCamera, Scene, Vector2, Vector3,
    WebGLRenderer, OrbitControls, STLLoader,
} from '../vendor/three.js';

const DEFAULTS = {
    background: 0x0d1117,
    modelColor: 0x4a9eff,
    gridColor: 0x333355,
    ambientIntensity: 0.4,
    directionalIntensity: 0.8,
};

const stlLoader = new STLLoader();

// --- Shared scene helpers (used by both viewer types) ---

function buildScene(options) {
    const scene = new Scene();
    scene.background = new Color(options.background);

    scene.add(new AmbientLight(0xffffff, options.ambientIntensity));

    const dir1 = new DirectionalLight(0xffffff, options.directionalIntensity);
    dir1.position.set(50, 80, 50);
    scene.add(dir1);

    const dir2 = new DirectionalLight(0xffffff, 0.3);
    dir2.position.set(-30, -20, -40);
    scene.add(dir2);

    const grid = new GridHelper(100, 20, options.gridColor, options.gridColor);
    grid.material.opacity = 0.3;
    grid.material.transparent = true;
    scene.add(grid);

    return scene;
}

// Swap the displayed mesh on a holder ({scene, camera, controls,
// currentMesh, options}) and refit the camera.
function swapGeometry(holder, geometry) {
    if (holder.currentMesh) {
        holder.scene.remove(holder.currentMesh);
        holder.currentMesh.geometry.dispose();
        holder.currentMesh.material.dispose();
    }

    geometry.computeBoundingBox();
    geometry.computeVertexNormals();

    const material = new MeshPhongMaterial({
        color: holder.options.modelColor,
        specular: 0x222222,
        shininess: 40,
        flatShading: false,
    });

    const mesh = new Mesh(geometry, material);

    // Center the model
    const box = geometry.boundingBox;
    const center = new Vector3();
    box.getCenter(center);
    mesh.position.sub(center);
    mesh.position.y += (box.max.y - box.min.y) / 2;

    holder.currentMesh = mesh;
    holder.scene.add(mesh);
    fitCamera(holder, geometry);
    holder._needsRender = true;
}

function fitCamera(holder, geometry) {
    const box = geometry.boundingBox;
    const size = new Vector3();
    box.getSize(size);
    const maxDim = Math.max(size.x, size.y, size.z);
    const dist = maxDim * 2;

    holder.camera.position.set(dist * 0.8, dist * 0.6, dist * 0.8);
    holder.controls.target.set(0, size.y * 0.3, 0);
    holder.controls.update();
}

function applyView(holder, name) {
    if (!holder.currentMesh) return;
    const box = holder.currentMesh.geometry.boundingBox;
    const size = new Vector3();
    box.getSize(size);
    const d = Math.max(size.x, size.y, size.z) * 2;

    const views = {
        front: [0, d * 0.3, d],
        top: [0, d, 0.01],
        iso: [d * 0.8, d * 0.6, d * 0.8],
    };

    const pos = views[name] || views.iso;
    holder.camera.position.set(...pos);
    holder.controls.target.set(0, size.y * 0.3, 0);
    holder.controls.update();
    holder._needsRender = true;
}

function loadSTLInto(holder, url) {
    return new Promise((resolve, reject) => {
        stlLoader.load(
            url,
            (geometry) => {
                swapGeometry(holder, geometry);
                resolve(geometry);
            },
            undefined,
            reject
        );
    });
}

// --- Standalone viewer (editor preview) ---

export class STLViewer {
    constructor(container, options = {}) {
        this.container = container;
        this.options = { ...DEFAULTS, ...options };

        this.scene = buildScene(this.options);

        this.camera = new PerspectiveCamera(45, 1, 0.1, 1000);
        this.camera.position.set(60, 40, 60);

        this.renderer = new WebGLRenderer({ antialias: true });
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
        container.appendChild(this.renderer.domElement);

        this.controls = new OrbitControls(this.camera, this.renderer.domElement);
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.1;

        this.currentMesh = null;
        this._rafId = null;
        this._needsRender = true;

        this._resize();
        this._onResize = () => this._resize();
        // ResizeObserver also catches layout-driven size changes
        // (panel resizes, grid reflow) that window resize misses
        if (typeof ResizeObserver !== 'undefined') {
            this._resizeObserver = new ResizeObserver(this._onResize);
            this._resizeObserver.observe(container);
        } else {
            window.addEventListener('resize', this._onResize);
        }
    }

    _resize() {
        const rect = this.container.getBoundingClientRect();
        if (rect.width === 0 || rect.height === 0) return;
        this.camera.aspect = rect.width / rect.height;
        this.camera.updateProjectionMatrix();
        // updateStyle=false: the canvas is sized by CSS (100% of the
        // container). Letting setSize write inline styles would grow the
        // container and re-trigger the ResizeObserver in a feedback loop.
        this.renderer.setSize(rect.width, rect.height, false);
        this._needsRender = true;
    }

    startAnimation() {
        if (this._rafId !== null) return;
        const animate = () => {
            this._rafId = requestAnimationFrame(animate);
            // Redraw only when the camera actually moved (interaction or
            // damping still settling) or the scene changed; an idle viewer
            // costs no GPU time.
            const moved = this.controls.update();
            if (moved || this._needsRender) {
                this._needsRender = false;
                this.renderer.render(this.scene, this.camera);
            }
        };
        animate();
    }

    stopAnimation() {
        if (this._rafId !== null) {
            cancelAnimationFrame(this._rafId);
            this._rafId = null;
        }
    }

    /** Load STL from a URL */
    loadSTL(url) {
        return loadSTLInto(this, url);
    }

    /** Load STL from an ArrayBuffer */
    loadSTLBuffer(buffer) {
        const geometry = stlLoader.parse(buffer);
        swapGeometry(this, geometry);
        return geometry;
    }

    setView(name) {
        applyView(this, name);
    }

    dispose() {
        this.stopAnimation();
        if (this._resizeObserver) {
            this._resizeObserver.disconnect();
        } else {
            window.removeEventListener('resize', this._onResize);
        }
        if (this.currentMesh) {
            this.currentMesh.geometry.dispose();
            this.currentMesh.material.dispose();
        }
        this.controls.dispose();
        this.renderer.dispose();
        this.container.removeChild(this.renderer.domElement);
    }
}

// --- Shared-context gallery renderer ---

// One item = one card preview. Owns a scene/camera/controls but no
// renderer; the GalleryViewer draws it into its rect on the shared canvas.
class GalleryItem {
    constructor(owner, element, options) {
        this.owner = owner;
        this.element = element;
        this.options = { ...DEFAULTS, ...options };

        this.scene = buildScene(this.options);
        this.camera = new PerspectiveCamera(45, 1, 0.1, 1000);
        this.camera.position.set(60, 40, 60);

        this.controls = new OrbitControls(this.camera, element);
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.1;

        this.currentMesh = null;
        this.visible = true;
        this._needsRender = true;
    }

    setVisible(v) {
        this.visible = v;
        if (v) this._needsRender = true;
    }

    loadSTL(url) {
        return loadSTLInto(this, url);
    }

    setView(name) {
        applyView(this, name);
    }
}

export class GalleryViewer {
    constructor() {
        this.canvas = document.createElement('canvas');
        this.canvas.className = 'gallery-gl';
        document.body.appendChild(this.canvas);

        this.renderer = new WebGLRenderer({
            canvas: this.canvas,
            antialias: true,
            alpha: true,
        });
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
        this.renderer.setScissorTest(true);
        this.renderer.setClearColor(0x000000, 0);

        this.items = [];
        this._allDirty = true;
        this._size = new Vector2();
        this._rafId = null;

        this._markAll = () => { this._allDirty = true; };
        window.addEventListener('scroll', this._markAll, { passive: true });
        window.addEventListener('resize', this._markAll);

        const frame = () => {
            this._rafId = requestAnimationFrame(frame);
            this._draw();
        };
        frame();
    }

    /** Register a card preview element; returns its GalleryItem handle. */
    addItem(element, options = {}) {
        const item = new GalleryItem(this, element, options);
        this.items.push(item);
        this._allDirty = true;
        return item;
    }

    /** Force a full repaint (call after layout changes, e.g. filtering). */
    markDirty() {
        this._allDirty = true;
    }

    _draw() {
        // Advance controls damping and collect dirty state - this part
        // touches no DOM, so idle frames are nearly free.
        let any = this._allDirty;
        for (const item of this.items) {
            if (item.visible && item.controls.update()) item._needsRender = true;
            if (item._needsRender) any = true;
        }
        if (!any) return;

        const w = window.innerWidth;
        const h = window.innerHeight;
        this.renderer.getSize(this._size);
        if (this._size.x !== w || this._size.y !== h) {
            this.renderer.setSize(w, h, false);
        }

        if (this._allDirty) {
            // Positions changed (scroll/resize/filter) - wipe the whole
            // canvas so stale pixels don't linger at old positions.
            this.renderer.setScissorTest(false);
            this.renderer.clear();
            this.renderer.setScissorTest(true);
        }

        for (const item of this.items) {
            if (!this._allDirty && !item._needsRender) continue;
            item._needsRender = false;
            if (!item.currentMesh) continue; // nothing to show yet
            const rect = item.element.getBoundingClientRect();
            if (rect.width === 0 || rect.height === 0) continue; // hidden
            if (rect.bottom < 0 || rect.top > h || rect.right < 0 || rect.left > w) continue; // off-screen

            const y = h - rect.bottom; // WebGL origin is bottom-left
            this.renderer.setViewport(rect.left, y, rect.width, rect.height);
            this.renderer.setScissor(rect.left, y, rect.width, rect.height);
            item.camera.aspect = rect.width / rect.height;
            item.camera.updateProjectionMatrix();
            this.renderer.render(item.scene, item.camera);
        }

        this._allDirty = false;
    }
}
