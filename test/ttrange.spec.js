import test from 'ava';

import Redis from 'ioredis';

import { ttadd, ttrange } from '../';


const redis = new Redis();

redis.defineCommand('ttrange', ttrange);


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
}, {
    time: String(20*60*60),
    data: {
        steps: [[0, 0], [-1, 0], [0, 1]],
        durations: [600, 1800],
        distances: [6e3, 9e3]
    }
}];


test.before(async t => {
    redis.defineCommand('ttadd', ttadd);

    const pipeline = redis.pipeline();

    routes.forEach(route => {
        const {
            time,
            data: {
                steps,
                durations,
                distances
            }
        } = route;

        const track = [];

        steps.reduceRight((v, step, i) => {
            v.unshift(...step);
            if (i)
                v.unshift(
                    durations.pop(),
                    distances.pop()
                )
            return v
        }, track)

        pipeline.ttadd(agent_id, time, ...track);

    });

    // exec
    return pipeline.exec();
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
    t.is(typeof redis.ttrange, 'function');
});


test('get range', async t => {
    let range;

    const t1800 = 18*60*60
    const t1830 = 18*60*60 + 30*60
    const t1900 = 19*60*60
    const t1930 = 19*60*60 + 30*60
    const t2000 = 12*60*60


    range = await redis.ttrange(agent_id, t1800);
    t.falsy(pos);

    pos = await redis.ttpos(agent_id, 18*60*60);
    t.deepEqual(round5(pos), [0, 0]);

    pos = await redis.ttpos(agent_id, 18*60*60 + 600);
    t.deepEqual(round5(pos), [0.33333, 0]);

    pos = await redis.ttpos(agent_id, 18*60*60 + 3000);
    t.deepEqual(round5(pos), [1, -1]);

    pos = await redis.ttpos(agent_id, 18*60*60 + 3600);
    t.deepEqual(round5(pos), [1, -1]);


    function round5 (tuple) {
        function round (x) {
            return Math.round(x * 1e5) / 1e5;
        }
        return tuple.map(round);
    }

});
