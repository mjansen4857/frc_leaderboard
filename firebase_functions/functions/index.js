const functions = require('firebase-functions');
const puppeteer = require('puppeteer');
const tabletojson = require('tabletojson').Tabletojson;
const https = require('https');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

const runtimeOpts = {
    timeoutSeconds: 300,
    memory: '4GB'
}

exports.updateData = functions.runWith(runtimeOpts).pubsub.schedule('0 12 * * *')
    .timeZone('America/New_York')
    .onRun(async (context) => {
        return updateData(true);
    });

exports.updateDataOnCheese = functions.runWith(runtimeOpts).firestore
    .document('cheese/cheese')
    .onUpdate((snap, context) => {
        return updateData(false);
    });

async function updateData(replaceChange) {
    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    var formatted_scores = [];

    return api_request().then(async (data) => {
        var event_codes = [];

        for (var e = 0; e < data['Events'].length; e++) {
            const code = data['Events'][e]['code'];

            if (code.startsWith('IRH')) {
                event_codes.push(code);
            }
        }

        for (var i = 0; i < event_codes.length; i++) {
            await page.goto('https://frc-events.firstinspires.org/2021/' + event_codes[i] + '/rankings');

            const page_data = await page.evaluate(() => {
                return document.querySelector('*').outerHTML;
            });

            const converted = tabletojson.convert(page_data);

            if (converted[0]) {
                for (var j = 0; j < converted[0].length; j++) {
                    var row = converted[0][j];
                    if (row['Team']) {
                        const score = {
                            'team': row['Team'],
                            'galactic_search': (row['Galactic Search'] == 0) ? 0 : parseFloat(row['19']),
                            'auto_nav': (row['Auto-Nav'] == 0) ? 0 : parseFloat(row['20']),
                            'hyperdrive': (row['Hyperdrive'] == 0) ? 0 : parseFloat(row['21']),
                            'interstellar': (row['Interstellar Accuracy'] == 0) ? 0 : parseFloat(row['22']),
                            'powerport': (row['Power Port'] == 0) ? 0 : parseFloat(row['23']),
                            'computed_galactic': 0,
                            'computed_auto': 0,
                            'computed_hyperdrive': 0,
                            'computed_interstellar': 0,
                            'computed_powerport': 0,
                            'computed_overall': 0,
                            'computed_overall_5': 0,
                            'team_rank': 0,
                            'galactic_rank': 0,
                            'auto_rank': 0,
                            'hyper_rank': 0,
                            'inter_rank': 0,
                            'power_rank': 0,
                            'rank_5': 0,
                            'group': event_codes[i],
                        };
                        if (score.galactic_search != 0 || score.auto_nav != 0 || score.hyperdrive != 0 || score.interstellar != 0 || score.powerport != 0) {
                            formatted_scores.push(score);
                        }
                    }
                }
            }
        }
        browser.close();

        // team
        formatted_scores.sort((a, b) => {
            return parseInt(a.team) - parseInt(b.team);
        });
        for (var i = 0; i < formatted_scores.length; i++) {
            formatted_scores[i].team_rank = i + 1;
        }

        // galactic
        formatted_scores.sort((a, b) => {
            if (a.galactic_search == 0) return 1;
            if (b.galactic_search == 0) return -1;
            return a.galactic_search - b.galactic_search;
        });
        for (var i = 0; i < formatted_scores.length; i++) {
            formatted_scores[i].galactic_rank = i + 1;
        }

        // auto
        formatted_scores.sort((a, b) => {
            if (a.auto_nav == 0) return 1;
            if (b.auto_nav == 0) return -1;
            return a.auto_nav - b.auto_nav;
        });
        for (var i = 0; i < formatted_scores.length; i++) {
            formatted_scores[i].auto_rank = i + 1;
        }

        // hyper
        formatted_scores.sort((a, b) => {
            if (a.hyperdrive == 0) return 1;
            if (b.hyperdrive == 0) return -1;
            return a.hyperdrive - b.hyperdrive;
        });
        for (var i = 0; i < formatted_scores.length; i++) {
            formatted_scores[i].hyper_rank = i + 1;
        }

        // inter
        formatted_scores.sort((a, b) => {
            return b.interstellar - a.interstellar;
        });
        for (var i = 0; i < formatted_scores.length; i++) {
            formatted_scores[i].inter_rank = i + 1;
        }

        // power
        formatted_scores.sort((a, b) => {
            return b.powerport - a.powerport;
        });
        for (var i = 0; i < formatted_scores.length; i++) {
            formatted_scores[i].power_rank = i + 1;
        }

        var galactic_scores = [];
        var auto_scores = [];
        var hyper_scores = [];
        var interstellar_scores = [];
        var powerport_scores = [];

        for (var k = 0; k < formatted_scores.length; k++) {
            const score = formatted_scores[k];
            if (score.galactic_search != 0) {
                galactic_scores.push(score.galactic_search);
            }
            if (score.auto_nav != 0) {
                auto_scores.push(score.auto_nav);
            }
            if (score.hyperdrive != 0) {
                hyper_scores.push(score.hyperdrive);
            }
            if (score.interstellar != 0) {
                interstellar_scores.push(score.interstellar);
            }
            if (score.powerport != 0) {
                powerport_scores.push(score.powerport);
            }
        }

        galactic_scores.sort((a, b) => a - b);
        const galactic_rValues = getRValues([...galactic_scores]);
        const galactic_bFirst = Math.min(...galactic_scores);
        const galactic_bLast = Math.max(...galactic_scores);

        auto_scores.sort((a, b) => a - b);
        const auto_rValues = getRValues([...auto_scores]);
        const auto_bFirst = Math.min(...auto_scores);
        const auto_bLast = Math.max(...auto_scores);

        hyper_scores.sort((a, b) => a - b);
        const hyper_rValues = getRValues([...hyper_scores]);
        const hyper_bFirst = Math.min(...hyper_scores);
        const hyper_bLast = Math.max(...hyper_scores);

        interstellar_scores.sort((a, b) => a - b);
        const interstellar_rValues = getRValues([...interstellar_scores]);
        const interstellar_bFirst = Math.max(...interstellar_scores);
        const interstellar_bLast = Math.min(...interstellar_scores);

        powerport_scores.sort((a, b) => a - b);
        const powerport_rValues = getRValues([...powerport_scores]);
        const powerport_bFirst = Math.max(...powerport_scores);
        const powerport_bLast = Math.min(...powerport_scores);

        for (var i = 0; i < formatted_scores.length; i++) {
            const score = formatted_scores[i];

            if (score.galactic_search != 0) {
                const b = Math.max(Math.min(galactic_rValues.rUpper, score.galactic_search), galactic_rValues.rLower);
                const c = (Math.abs((b - galactic_bLast) / (galactic_bFirst - galactic_bLast)) * 100) + 50;
                formatted_scores[i].computed_galactic = c;
            }

            if (score.auto_nav != 0) {
                const b = Math.max(Math.min(auto_rValues.rUpper, score.auto_nav), auto_rValues.rLower);
                const c = (Math.abs((b - auto_bLast) / (auto_bFirst - auto_bLast)) * 100) + 50;
                formatted_scores[i].computed_auto = c;
            }

            if (score.hyperdrive != 0) {
                const b = Math.max(Math.min(hyper_rValues.rUpper, score.hyperdrive), hyper_rValues.rLower);
                const c = (Math.abs((b - hyper_bLast) / (hyper_bFirst - hyper_bLast)) * 100) + 50;
                formatted_scores[i].computed_hyperdrive = c;
            }

            if (score.interstellar != 0) {
                const b = Math.max(Math.min(interstellar_rValues.rUpper, score.interstellar), interstellar_rValues.rLower);
                const c = (Math.abs((b - interstellar_bLast) / (interstellar_bFirst - interstellar_bLast)) * 100) + 50;
                formatted_scores[i].computed_interstellar = c;
            }

            if (score.powerport != 0) {
                const b = Math.max(Math.min(powerport_rValues.rUpper, score.powerport), powerport_rValues.rLower);
                const c = (Math.abs((b - powerport_bLast) / (powerport_bFirst - powerport_bLast)) * 100) + 50;
                formatted_scores[i].computed_powerport = c;
            }

            const ordered_scores = [score.computed_galactic, score.computed_auto, score.computed_hyperdrive, score.computed_interstellar, score.computed_powerport].sort((a, b) => b - a);
            formatted_scores[i].computed_overall = ordered_scores[0] + ordered_scores[1] + ordered_scores[2];
        }

        formatted_scores.sort((a, b) => {
            var compare = b.computed_overall_5 - a.computed_overall_5;
            return compare;
        });

        for (var i = 0; i < formatted_scores.length; i++) {
            formatted_scores[i].rank_5 = i + 1;
        }

        formatted_scores.sort((a, b) => {
            var compare = b.computed_overall - a.computed_overall;

            if (compare == 0) {
                const ordered_scores_a = [a.computed_galactic, a.computed_auto, a.computed_hyperdrive, a.computed_interstellar, a.computed_powerport].sort((a, b) => b - a);
                const ordered_scores_b = [b.computed_galactic, b.computed_auto, b.computed_hyperdrive, b.computed_interstellar, b.computed_powerport].sort((a, b) => b - a);
                compare = ordered_scores_b[0] - ordered_scores_a[0];
                if (compare == 0) {
                    compare = ordered_scores_b[1] - ordered_scores_a[1];
                    if (compare == 0) {
                        compare = ordered_scores_b[3] - ordered_scores_a[3];
                        if (compare == 0) {
                            compare = ordered_scores_b[5] - ordered_scores_a[5];
                        }
                    }
                }
            }
            return compare;
        });

        var scores = db.collection('scores');
        var cheese = db.collection('cheese');

        var batch = db.batch();

        batch.set(cheese.doc('high_scores'), {
            'galactic_search': galactic_bFirst,
            'auto_nav': auto_bFirst,
            'hyperdrive': hyper_bFirst,
            'interstellar': interstellar_bFirst,
            'powerport': powerport_bFirst
        });

        for (var i = 0; i < formatted_scores.length; i++) {
            const score = formatted_scores[i];
            var doc = scores.doc(score.team);
            let change = 0;
            let change_5 = 0;
            var docData = await doc.get();
            if (docData.exists) {
                change = docData.data()['rank'] - (i + 1);
                change_5 = docData.data()['rank_5'] - (i + 1);
                if (!replaceChange) {
                    const prevChange = docData.data()['change'];
                    const prevChange5 = docData.data()['change_5'];
                    change += prevChange;
                    change_5 += prevChange5;
                }
            }

            batch.set(doc, {
                'galactic_search': score.galactic_search,
                'auto_nav': score.auto_nav,
                'hyperdrive': score.hyperdrive,
                'interstellar': score.interstellar,
                'powerport': score.powerport,
                'rank': i + 1,
                'rank_5': score.rank_5,
                'change': change,
                'change_5': change_5,
                'team_rank': score.team_rank,
                'galactic_rank': score.galactic_rank,
                'auto_rank': score.auto_rank,
                'hyper_rank': score.hyper_rank,
                'inter_rank': score.inter_rank,
                'power_rank': score.power_rank,
                'group': score.group,
                'computed_galactic': score.computed_galactic,
                'computed_auto': score.computed_auto,
                'computed_hyperdrive': score.computed_hyperdrive,
                'computed_interstellar': score.computed_interstellar,
                'computed_powerport': score.computed_powerport,
                'computed_overall': score.computed_overall
            });
        }
        batch.commit();
    });
}

function api_request() {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'frc-api.firstinspires.org',
            port: 443,
            path: '/v2.0/2021/events',
            method: 'GET',
            headers: {
                'Authorization': 'Basic bWphbnNlbjQ4NTc6NDBlNWRmZDMtN2I1ZC00NjlkLWI1N2MtYjY1NTFiNWQ5Y2Qx'
            }
        };
        const req = https.request(options, (res) => {
            if (res.statusCode < 200 || res.statusCode >= 300) {
                return reject(new Error('statusCode=' + res.statusCode));
            }
            var body = [];
            res.on('data', function (chunk) {
                body.push(chunk);
            });
            res.on('end', function () {
                try {
                    body = JSON.parse(Buffer.concat(body).toString());
                } catch (e) {
                    reject(e);
                }
                resolve(body);
            });
        });
        req.on('error', (e) => {
            reject(e.message);
        });
        // send the request
        req.end();
    });
}

function getRValues(scores) {
    const getMedian = (arr) => {
        const _mid = Math.floor(arr.length / 2),
            nums = [...arr].sort((a, b) => a - b);
        return arr.length % 2 !== 0 ? nums[_mid] : (nums[_mid - 1] + nums[_mid]) / 2;
    };

    const median = getMedian(scores);
    const mid = Math.floor(scores.length / 2);
    let firstHalf = scores.splice(0, mid);
    if (firstHalf.length % 2 == 0) firstHalf.push(median);
    let lastHalf = scores.splice(-mid);

    const q1 = getMedian(firstHalf);
    const q3 = getMedian(lastHalf);

    const rLower = q1 - (q3 - q1);
    const rUpper = q3 + (q3 - q1);

    return { rLower, rUpper };
}
