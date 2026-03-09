/**
 * Three.js STL Viewer Module
 * Provides reusable 3D viewer for STL files and geometry.
 */
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { STLLoader } from 'three/addons/loaders/STLLoader.js';

export class STLViewer {
    constructor(container, options = {}) {
        this.container = container;
        this.options = {
            background: 0x0d1117,
            modelColor: 0x4a9eff,
            gridColor: 0x333355,
            ambientIntensity: 0.4,
            directionalIntensity: 0.8,
            ...options
        };

        this.scene = new THREE.Scene();
        this.scene.background = new THREE.Color(this.options.background);

        this.camera = new THREE.PerspectiveCamera(45, 1, 0.1, 1000);
        this.camera.position.set(60, 40, 60);

        this.renderer = new THREE.WebGLRenderer({ antialias: true });
        this.renderer.setPixelRatio(window.devicePixelRatio);
        container.appendChild(this.renderer.domElement);

        // Controls
        this.controls = new OrbitControls(this.camera, this.renderer.domElement);
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.1;

        // Lighting
        const ambient = new THREE.AmbientLight(0xffffff, this.options.ambientIntensity);
        this.scene.add(ambient);

        const dir1 = new THREE.DirectionalLight(0xffffff, this.options.directionalIntensity);
        dir1.position.set(50, 80, 50);
        this.scene.add(dir1);

        const dir2 = new THREE.DirectionalLight(0xffffff, 0.3);
        dir2.position.set(-30, -20, -40);
        this.scene.add(dir2);

        // Grid
        const grid = new THREE.GridHelper(100, 20, this.options.gridColor, this.options.gridColor);
        grid.material.opacity = 0.3;
        grid.material.transparent = true;
        this.scene.add(grid);

        this.currentMesh = null;
        this.loader = new STLLoader();
        this.animating = false;

        this._resize();
        this._onResize = () => this._resize();
        window.addEventListener('resize', this._onResize);
    }

    _resize() {
        const rect = this.container.getBoundingClientRect();
        this.camera.aspect = rect.width / rect.height;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(rect.width, rect.height);
    }

    startAnimation() {
        if (this.animating) return;
        this.animating = true;
        const animate = () => {
            if (!this.animating) return;
            requestAnimationFrame(animate);
            this.controls.update();
            this.renderer.render(this.scene, this.camera);
        };
        animate();
    }

    stopAnimation() {
        this.animating = false;
    }

    /** Load STL from a URL */
    async loadSTL(url) {
        return new Promise((resolve, reject) => {
            this.loader.load(
                url,
                (geometry) => {
                    this._setGeometry(geometry);
                    resolve(geometry);
                },
                undefined,
                reject
            );
        });
    }

    /** Load STL from an ArrayBuffer */
    loadSTLBuffer(buffer) {
        const geometry = this.loader.parse(buffer);
        this._setGeometry(geometry);
        return geometry;
    }

    _setGeometry(geometry) {
        if (this.currentMesh) {
            this.scene.remove(this.currentMesh);
            this.currentMesh.geometry.dispose();
            this.currentMesh.material.dispose();
        }

        geometry.computeBoundingBox();
        geometry.computeVertexNormals();

        const material = new THREE.MeshPhongMaterial({
            color: this.options.modelColor,
            specular: 0x222222,
            shininess: 40,
            flatShading: false,
        });

        const mesh = new THREE.Mesh(geometry, material);

        // Center the model
        const box = geometry.boundingBox;
        const center = new THREE.Vector3();
        box.getCenter(center);
        mesh.position.sub(center);
        mesh.position.y += (box.max.y - box.min.y) / 2;

        this.currentMesh = mesh;
        this.scene.add(mesh);
        this._fitCamera(geometry);
    }

    _fitCamera(geometry) {
        const box = geometry.boundingBox;
        const size = new THREE.Vector3();
        box.getSize(size);
        const maxDim = Math.max(size.x, size.y, size.z);
        const dist = maxDim * 2;

        this.camera.position.set(dist * 0.8, dist * 0.6, dist * 0.8);
        this.controls.target.set(0, size.y * 0.3, 0);
        this.controls.update();
    }

    setView(name) {
        if (!this.currentMesh) return;
        const box = this.currentMesh.geometry.boundingBox;
        const size = new THREE.Vector3();
        box.getSize(size);
        const d = Math.max(size.x, size.y, size.z) * 2;

        const views = {
            front: [0, d * 0.3, d],
            top: [0, d, 0.01],
            iso: [d * 0.8, d * 0.6, d * 0.8],
        };

        const pos = views[name] || views.iso;
        this.camera.position.set(...pos);
        this.controls.target.set(0, size.y * 0.3, 0);
        this.controls.update();
    }

    dispose() {
        this.stopAnimation();
        window.removeEventListener('resize', this._onResize);
        if (this.currentMesh) {
            this.currentMesh.geometry.dispose();
            this.currentMesh.material.dispose();
        }
        this.renderer.dispose();
        this.container.removeChild(this.renderer.domElement);
    }
}

// Export for global access
window.STLViewer = STLViewer;
