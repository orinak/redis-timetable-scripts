import test from 'ava';

import Redis from 'ioredis';

import { ttadd, ttrange } from '../';


const redis = new Redis();

redis.defineCommand('ttrange', ttrange);


const agent_id = '/test/A';

const routes = [{
    time: 12,
    data: {
        steps: [[0, -1], [-1, 0], [0, 1]],
        durations: [3, 6],
        distances: [6, 6]
    }
}, {
    time: 24,
    data: {
        steps: [[0, 1], [1, 1], [1, 0], [0, 0]],
        durations: [6, 4, 2],
        distances: [4, 4, 4]
    }
}];


test.before(async t => {
    redis.defineCommand('ttadd', ttadd);

    const key = agent_id;

    const pipeline = redis.pipeline();

    const transform = durations => (route, step, i) => {
        route.unshift(...step);
        if (i)
            route.unshift(
                durations.pop()
            );
        return route;
    };

    routes.forEach(route => {
        const {
            time,
            data: {
                steps,
                durations
            }
        } = route;

        const argv = steps.reduceRight(transform(durations), []);

        pipeline.ttadd(key, time, ...argv);
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
    const key = agent_id;

    let range;

    const expect = data => res => {
        t.deepEqual(res.map(Number), data)
        return Promise.resolve();
    }

    await redis
        .ttrange(key)
        .then(expect([1, 2]));

    await redis
        .ttrange(key, 24)
        .then(expect([2]))

    await redis
        .ttrange(key, 12, 36)
        .then(expect([1, 2]));

    await redis
        .ttrange(key, 18, 30)
        .then(expect([1, 2]));

    await redis
        .ttrange(key, 12, 24)
        .then(expect([1]));

    await redis
        .ttrange(key, 21, 27)
        .then(expect([2]))


});
