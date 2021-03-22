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

exports.updateData = functions.runWith(runtimeOpts).pubsub.schedule('0 0 * * *')
    .timeZone('America/New_York')
    .onRun(async (context) => {
        return updateData();
    });

exports.updateDataOnCheese = functions.runWith(runtimeOpts).firestore
    .document('cheese/cheese')
    .onUpdate((snap, context) => {
        return updateData();
    });

async function updateData() {
    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    var formatted_scores = [];

    return api_request().then(async (data) => {
        var event_codes = [];

        for (var i = 0; i < data['Events'].length; i++) {
            const code = data['Events'][i]['code'];

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
                            'galactic_search': (row['Galactic Search'] == 0) ? 0 : row['19'],
                            'auto_nav': (row['Auto-Nav'] == 0) ? 0 : row['20'],
                            'hyperdrive': (row['Hyperdrive'] == 0) ? 0 : row['21'],
                            'interstellar': (row['Interstellar Accuracy'] == 0) ? 0 : row['22'],
                            'powerport': (row['Power Port'] == 0) ? 0 : row['23']
                        };
                        if (score.galactic_search != 0 || score.auto_nav != 0 || score.hyperdrive != 0 || score.interstellar != 0 || score.powerport != 0) {
                            formatted_scores.push(score);
                        }
                    }
                }
            }
        }
        browser.close();

        var scores = db.collection('scores');
        var batch = db.batch();

        for (var i = 0; i < formatted_scores.length; i++) {
            const score = formatted_scores[i];
            var doc = scores.doc(score.team);
            batch.set(doc, {
                'galactic_search': parseFloat(score.galactic_search),
                'auto_nav': parseFloat(score.auto_nav),
                'hyperdrive': parseFloat(score.hyperdrive),
                'interstellar': parseFloat(score.interstellar),
                'powerport': parseFloat(score.powerport)
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
