import test from 'ava';

import Redis from 'ioredis';

import { ttadd, ttpos } from '../';


const redis = new Redis();

redis.defineCommand('ttpos', ttpos);

const agent_id = '/test/A';

test.before(async t => {
    redis.defineCommand('ttadd', ttadd);

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

    // destruct
    const {
        time: timestamp,
        data: {
            steps: [
                [lng1, lat1],
                [lng2, lat2],
                [lng3, lat3]
            ],
            durations: [t1, t2],
            distances: [s1, s2]
        }
    } = routes[0];

    // exec
    return await redis.ttadd(
        agent_id,
        timestamp,
        lng1, lat1,
        t1, s1,
        lng2, lat2,
        t2, s2,
        lng3,lat3
    );
});

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



test('init', t => {
    t.is(typeof redis.ttpos, 'function');
});


test('get edge', async t => {
    let pos;

    pos = await redis.ttpos(agent_id, 18*60*60 - 600);
    t.falsy(pos);

    pos = await redis.ttpos(agent_id, 18*60*60);
    t.deepEqual(round5(pos), [0, 0]);

    pos = await redis.ttpos(agent_id, 18*60*60 + 600);
    t.deepEqual(round5(pos), [0.33, 0]);

    pos = await redis.ttpos(agent_id, 18*60*60 + 2999);
    t.deepEqual(round5(pos), [1, -1]);

    pos = await redis.ttpos(agent_id, 18*60*60 + 3600);
    t.falsy(pos);


    function round5 (tuple) {
        function round (x) {
            return Math.round(x * 1e2) / 1e2;
        }
        return tuple
            && tuple.map(round);
    }

});
