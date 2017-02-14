import test from 'ava';

import Redis from 'ioredis';

import { ttadd, ttrange } from '../';


const redis = new Redis();

redis.defineCommand('ttrange', ttrange);


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
    t.is(typeof redis.ttrange, 'function');
});


test('get range', async t => {
    const expect = data => res => {
        t.deepEqual(res.map(Number), data)
        return Promise.resolve();
    };

    const run = (input, output) => redis
        .ttrange(KEY, ...input)
        .then(expect(output));

    await Promise.all([
        run([],       [1, 2]),
        run([12],     [1, 2]),
        run([24],     [   2]),
        run([36],     [    ]),

        run([12, 36], [1, 2]),
        run([18, 30], [1, 2]),
        run([21, 27], [   2]),

        run([21, 24], [    ]),

        run([20, 20], [1   ]),
        run([21, 21], [    ]),
        run([22, 22], [    ]),
        run([23, 23], [    ]),
        run([24, 24], [   2])
    ]);
});
