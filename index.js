const load = require('./load');

const dirname = __dirname + '/src/';

module.exports.ttadd = {
    lua: load(dirname + 'ttadd'),
    numberOfKeys: 1
};