import test from 'ava';

import Redis from 'ioredis';

import { ttadd, ttpos } from '../';


const redis = new Redis();

redis.defineCommand('ttpos', ttpos);


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


test.before(async t => {
    redis.defineCommand('ttadd', ttadd);

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
            data: { steps, durations }
        } = route;

        const argv = steps.reduceRight(transform(durations), []);

        pipeline.ttadd(KEY, time, ...argv);
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
    t.is(typeof redis.ttpos, 'function');
});


test('get range', async t => {
    const decimal = x => Math.round(x * 1e2) / 1e2;

    const expect = input => res => {
        if (res)
            t.deepEqual(res.map(decimal), input)
        else
            t.falsy(input);
        return Promise.resolve();
    };

    const run = (input, output) => redis
        .ttpos(KEY, input)
        .then(expect(output));


    await Promise.all([
        run(0, null),
        run(11.999, null),

        run(12, [0, -1]),
        run(15, [-1, 0]),
        run(18, [-.5, .5]),
        run(20.999, [0, 1]),
        run(21, null),

        run(24, [0, 1]),
        run(28, [0.67, 1]),
        run(30, [1, 1]),
        run(34, [1, 0]),
        run(35.999, [0, 0]),
        run(36, null),
    ]);
});
