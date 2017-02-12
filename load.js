const fs = require('fs');
const path = require('path');

const re = /require [\"\']{1}(.+)[\"\']{1}/g;

const read = src => fs.readFileSync(src, 'utf8');

function load (src, cwd, skip=[]) {
    if (cwd)
        src = path.join(cwd, src);

    if (!path.extname(src))
        src += '.lua';

    if (skip.indexOf(src) !== -1)
        return '';
    else
        skip.push(src);

    cwd = path.dirname(src);

    return read(src)
        .replace(re, (m, f) => load(f, cwd, skip));
}


module.exports = load;
