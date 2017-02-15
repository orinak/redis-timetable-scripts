import test from 'ava';

import Redis from 'ioredis';

import { ttadd } from '../';


const redis = new Redis();

redis.defineCommand('ttadd', ttadd);


const KEY = '/test/A';

const routes = [{
    time: 12,
    data: {
        steps: [[0, -1], [-1, 0], [0, 1]],
        durations: [3, 6]
    }
}, {
    time: 24,
    data: {
        steps: [[0, 1], [1, 1], [1, 0], [0, 0]],
        durations: [6, 4, 2]
    }
}];



test.after.always(async t => {
    function cleanup (keys) {
        const pipeline = redis.pipeline();
        keys.forEach(key => pipeline.del(key));
        return pipeline.exec();
    }

    return redis
        .keys('/test/*')
        .then(cleanup);
});


test('add one', async t => {
    // destruct
    const {
        time,
        data: {
            steps,
            durations
        }
    } = routes[0];

    const [t12, t23] = durations;
    const [
        [lng1, lat1],
        [lng2, lat2],
        [lng3, lat3]
    ] = steps;

    // exec
    const id = await redis
        .ttadd(
            KEY,        // key
            time,       // start
            lng1, lat1, // initial
            t12,        // interval
            lng2, lat2, // ...
            t23,        //
            lng3,lat3   // final
        );

    t.is(id, 1, 'first');

    // check redis
    const key = KEY + ':' + id;

    const index_accum = (arr, delta, i) => {
        const last = arr[arr.length-1];
        arr.push(i+1, last+delta)
        return arr;
    }

    redis
        .zrange(key + ':timeline', 0, -1, 'withscores')
        .then(timeline => t.deepEqual(
            timeline,
            durations
                .reduce(index_accum, [0, 0])
                .map(String)
        ));


    const round = tuple => tuple.map(x => {
        const k = Math.pow(10, 5);
        return Math.round(x * k) / k;
    });

    redis
        .geopos(key + ':geoindex', 0, 1, 2)
        .then(geoindex => t.deepEqual(
            geoindex.map(round5),
            steps
        ));


    function round5 (tuple) {
        function round (x) {
            return Math.round(x * 1e5) / 1e5;
        }
        return tuple.map(round);
    }

});


test('add next', async t => {
    // destruct
    const {
        time,
        data: {
            steps,
            durations
        }
    } = routes[1];

    const [t12] = durations;
    const [
        [lng1, lat1],
        [lng2, lat2]
    ] = steps;


    // exec
    const id = await redis
        .ttadd(
            KEY,
            time,
            lng1, lat1,
            t12,
            lng2, lat2,
        );

    t.is(id, 2, 'second');

    // check indexing

    redis
        .zrange(KEY + ':timeline', 0, -1, 'withscores')
        .then(list => t.deepEqual(
            list,
            routes
                .reduce((m, r, i) => m.concat(i+1, r.time), [])
                .map(String)
        ));
});
