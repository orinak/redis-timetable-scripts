import test from 'ava';

import Redis from 'ioredis';


const model = require('../');


const redis = new Redis();


const PIVOT = 0;

const clock = (hh=0, mm=0) => (hh + mm * 60) * 60;


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
    const name = 'ttadd';
    const dist = model[name];

    t.not(dist, void 0, 'should exist');
    t.notThrows(() => redis.defineCommand(name, dist), 'should evaluate');
    t.is(typeof redis.ttadd, 'function');
});

test('run', async t => {
    // key
    const agent_id = '/test/A';

    // start
    const timestamp = clock(18, 0);

    const steps = [
        [0, 0],
        [1, 0],
        [0, 0]
    ];

    const durations = [
        clock(30),
        clock(10)
    ];

    const distances = [
        6000,
        6000
    ];

    const [
        [lng1, lat1],
        [lng2, lat2],
        [lng3, lat3]
    ] = steps;

    const [t1, t2] = durations;
    const [s1, s2] = distances;

    const route_id =  await redis.ttadd(
        agent_id,   // key
        timestamp,  // start
        lng1, lat1, // initial
        t1, s1,
        lng2, lat2, // midpoint
        t2, s2,
        lng3,lat3   // final
    );

    t.is(route_id, 1);

    // check redis
    const $route_id = await redis.get(agent_id + ':luid');
    t.is($route_id, '1')

    const routes_key = agent_id + ':timetable'
    const $routes = await redis.zrange(routes_key, 0, -1, 'withscores');
    t.deepEqual($routes, ['1', String(timestamp)], 'should index');

    const $timeline = await redis.zrange(agent_id + ':1:timeline', 0, -1, 'withscores');
    t.deepEqual($timeline, [
        '1', '0',
        '2', '1800',
        '3', '2400'
    ]);

    const $distance = await redis.zrange(agent_id + ':1:distance', 0, -1, 'withscores');
    t.deepEqual($distance, [
        '1', '0',
        '2', '6000',
        '3', '12000'
    ]);

    const $geoindex = await redis
        .geopos(agent_id + ':1:geoindex', 1, 2, 3)
        .then(steps => {
            steps = steps.map(xy => xy.map(round))
            return Promise.resolve(steps);
        });

    t.deepEqual($geoindex, steps);

    function round (number, precision=5) {
        var factor = Math.pow(10, precision);
        var tempNumber = number * factor;
        var roundedTempNumber = Math.round(tempNumber);
        return roundedTempNumber / factor;
    };
});