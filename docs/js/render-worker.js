/**
 * OpenSCAD render worker
 * Runs OpenSCAD WASM renders off the main thread so the UI stays
 * responsive; the main thread can terminate the worker to cancel a render.
 *
 * Protocol:
 *   in:  { id, type: 'init' }                    warm up a WASM instance
 *   in:  { id, type: 'render', code }            render SCAD source to STL
 *   out: { type: 'progress', status, percent }   loading progress (no id)
 *   out: { id, ok: true }                        init done
 *   out: { id, ok: true, stl: ArrayBuffer }      render result (transferred)
 *   out: { id, ok: false, error, log }           failure + captured output
 */

const MACRO_FILES = ['shapes.scad'];

// The WASM runtime exits after callMain() returns, so an instance can only
// render once - each render consumes the prepared instance and the next one
// is warmed up immediately afterwards.
let instancePromise = null;
let macroCache = null;
let logLines = [];

const captureLog = (text) => { logLines.push(String(text)); };

function progress(status, percent) {
    self.postMessage({ type: 'progress', status, percent });
}

// Fetch shared macro libraries once and cache their contents
async function fetchMacroLibraries() {
    if (macroCache) return macroCache;
    const cache = {};
    for (const file of MACRO_FILES) {
        try {
            const resp = await fetch(new URL(`../macros/${file}`, self.location.href));
            if (resp.ok) cache[file] = await resp.text();
        } catch (_) {
            // Macro file not available - designs still work without shared libs
        }
    }
    macroCache = cache;
    return cache;
}

// Prepare a fresh OpenSCAD instance with macro libraries mounted
function prepareInstance(reportProgress) {
    if (!instancePromise) {
        const promise = (async () => {
            if (reportProgress) progress('Fetching OpenSCAD WASM module...', 30);
            const [{ default: OpenSCAD }, macros] = await Promise.all([
                import('../wasm/openscad.js'),
                fetchMacroLibraries(),
            ]);
            if (reportProgress) progress('Compiling WebAssembly...', 60);
            const instance = await OpenSCAD({
                noInitialRun: true,
                print: captureLog,
                printErr: captureLog,
            });
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

self.onmessage = async (e) => {
    const { id, type, code } = e.data;

    if (type === 'init') {
        try {
            await prepareInstance(true);
            progress('OpenSCAD ready', 100);
            self.postMessage({ id, ok: true });
        } catch (err) {
            self.postMessage({ id, ok: false, error: String((err && err.message) || err) });
        }
        return;
    }

    if (type === 'render') {
        let instance;
        try {
            instance = await prepareInstance(false);
        } catch (err) {
            self.postMessage({ id, ok: false, error: String((err && err.message) || err), log: [] });
            return;
        }
        // The instance is consumed by this render
        instancePromise = null;
        logLines = [];

        try {
            instance.FS.writeFile('/designs/input.scad', code);
            try {
                // Binary STL is ~5x smaller than the default ASCII output
                instance.callMain(['/designs/input.scad', '--export-format=binstl', '-o', '/output.stl']);
            } catch (_) {
                // callMain may throw on exit - check whether output exists
            }

            let stlData;
            try {
                stlData = instance.FS.readFile('/output.stl');
            } catch (_) {
                self.postMessage({ id, ok: false, error: 'Render failed - check SCAD syntax', log: logLines });
                return;
            }

            self.postMessage({ id, ok: true, stl: stlData.buffer }, [stlData.buffer]);
        } catch (err) {
            self.postMessage({ id, ok: false, error: String((err && err.message) || err), log: logLines });
        } finally {
            // Warm up the next instance so the following render starts fast
            prepareInstance(false).catch(() => {});
        }
    }
};
