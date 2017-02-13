const load = require('./load');

const dirname = __dirname + '/src/';

module.exports.ttadd = {
    lua: load(dirname + 'ttadd'),
    numberOfKeys: 1
};

module.exports.ttrange = {
    lua: load(dirname + 'ttrange'),
    numberOfKeys: 1
};

module.exports.ttpos = {
    lua: load(dirname + 'ttpos'),
    numberOfKeys: 1
};
