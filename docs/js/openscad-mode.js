/**
 * OpenSCAD language mode for CodeMirror 6 (StreamLanguage tokenizer).
 */
import { StreamLanguage, tags } from '../vendor/codemirror.js';

const KEYWORDS = new Set([
    'module', 'function', 'if', 'else', 'for', 'intersection_for',
    'let', 'each', 'include', 'use', 'assert', 'echo',
]);

const ATOMS = new Set(['true', 'false', 'undef', 'PI']);

const BUILTINS = new Set([
    // 3D primitives
    'cube', 'sphere', 'cylinder', 'polyhedron', 'import', 'surface',
    // 2D primitives
    'square', 'circle', 'polygon', 'text', 'projection',
    // Transformations
    'translate', 'rotate', 'scale', 'resize', 'mirror', 'multmatrix',
    'color', 'offset', 'hull', 'minkowski',
    // Boolean operations
    'union', 'difference', 'intersection', 'render',
    // Extrusion
    'linear_extrude', 'rotate_extrude',
    // Other modules
    'children',
    // Math functions
    'abs', 'sign', 'sin', 'cos', 'tan', 'acos', 'asin', 'atan', 'atan2',
    'floor', 'round', 'ceil', 'ln', 'len', 'log', 'pow', 'sqrt', 'exp',
    'rands', 'min', 'max', 'norm', 'cross',
    // Type/string functions
    'concat', 'lookup', 'str', 'chr', 'ord', 'search', 'version',
    'version_num', 'parent_module', 'is_undef', 'is_bool', 'is_num',
    'is_string', 'is_list', 'is_function',
]);

export const openscad = StreamLanguage.define({
    name: 'openscad',

    startState: () => ({ inComment: false }),

    token(stream, state) {
        if (state.inComment) {
            if (stream.match(/^.*?\*\//)) {
                state.inComment = false;
            } else {
                stream.skipToEnd();
            }
            return 'comment';
        }
        if (stream.eatSpace()) return null;
        if (stream.match('//')) {
            stream.skipToEnd();
            return 'comment';
        }
        if (stream.match('/*')) {
            state.inComment = true;
            return 'comment';
        }
        if (stream.match(/^"(?:[^"\\]|\\.)*"?/)) return 'string';
        if (stream.match(/^\$[A-Za-z_]\w*/)) return 'special';
        if (stream.match(/^[A-Za-z_]\w*/)) {
            const word = stream.current();
            if (KEYWORDS.has(word)) return 'keyword';
            if (ATOMS.has(word)) return 'atom';
            if (BUILTINS.has(word)) return 'builtin';
            return 'variableName';
        }
        if (stream.match(/^(?:\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+)/)) return 'number';
        if (stream.match(/^[+\-*\/%<>=!&|?:^~#]+/)) return 'operator';
        stream.next();
        return null;
    },

    tokenTable: {
        special: tags.special(tags.variableName),
        builtin: tags.function(tags.variableName),
    },

    languageData: {
        commentTokens: { line: '//', block: { open: '/*', close: '*/' } },
    },
});
