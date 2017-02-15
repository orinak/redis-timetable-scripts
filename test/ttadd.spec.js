import test from 'ava';

import Redis from 'ioredis';

import { ttadd } from '../';


const redis = new Redis();

redis.defineCommand('ttadd', ttadd);


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


const agent_id = '/test/A';

const routes = [{
    time: String(18*60*60),
    data: {
        steps: [[0, 0], [1, 0], [1, -1]],
        durations: [1800, 1200],
        distances: [6e3, 6e3]
    }
}, {
    time: String(19*60*60),
    data: {
        steps: [[1, -1], [0, 0]],
        durations: [900],
        distances: [9e3]
    }
}];


test('init', t => {
    t.is(typeof redis.ttadd, 'function');
});

test('add one', async t => {
    // destruct
    const {
        time: timestamp,
        data: {
            steps,
            durations
        }
    } = routes[0];

    const [t1, t2] = durations;
    const [
        [lng1, lat1],
        [lng2, lat2],
        [lng3, lat3]
    ] = steps;


    // exec
    const id = await redis
        .ttadd(
            agent_id,   // key
            timestamp,  // start
            lng1, lat1, // initial
            t1,         // interval
            lng2, lat2, // ...
            t2,         //
            lng3,lat3   // final
        );

    t.is(id, 1, 'first');

    // check redis

    const key = agent_id + ':' + id;

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
        time: timestamp,
        data: {
            steps,
            durations,
            distances
        }
    } = routes[1];

    const [t1] = durations;
    const [s1] = distances;
    const [
        [lng1, lat1],
        [lng2, lat2]
    ] = steps;


    // exec
    const id = await redis
        .ttadd(
            agent_id,
            timestamp,
            lng1, lat1,
            t1,
            lng2, lat2,
        );

    t.is(id, 2, 'second');

    // check indexing

    const routes_key = agent_id + ':timeline'

    redis
        .zrange(routes_key, 0, -1, 'withscores')
        .then(list => t.deepEqual(
            list,
            routes
                .reduce((m, r, i) => m.concat(i+1, r.time), [])
                .map(String)
        ));
});
