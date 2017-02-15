const fs = require('fs');
const path = require('path');

const read = src => fs.readFileSync(src, 'utf8');

const re = /require [\"\']{1}(.+)[\"\']{1}/g;

function load (src, cwd) {
    if (cwd)
        src = path.join(cwd, src);

    if (!path.extname(src))
        src += '.lua';

    cwd = path.dirname(src);

    return read(src)
        .replace(re, (m, f) => [
                '(function ()',
                    load(f, cwd),
                'end)()'
            ].join('\n')
        )
        .replace(/^/gm, '  ');
}


module.exports = load;
