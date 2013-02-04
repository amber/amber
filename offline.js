d.r.OfflineApp = d.Class(d.r.App, {
    latency: 100,
    init: function () {
        var i;
        function rint(min, max) {
            return Math.random() * (max - min + 1) + min | 0;
        }
        function rfloat(min, max) {
            return Math.random() * (max - min + 1) + min;
        }
        function rvowel() {
            return vowels[Math.random() * vowels.length | 0];
        }
        function rconsonant() {
            return consonants[Math.random() * consonants.length | 0];
        }
        function rpunctuation() {
            return punctuation[Math.random() * punctuation.length | 0];
        }
        function rword() {
            return (Array(Math.random() * 3 + 1 | 0).join(',').split(',').map(function () {
                return rconsonants() + rvowel();
            }).join('') + (Math.random() < .5 ? rvowel() : '')).replace(/q([^u\s])/g, 'qu$1');
        }
        function rconsonants() {
            var r = Math.random();
            return Array(r < .03 ? 3 : r < .2 ? 2 : 1).join(',').split(',').map(function () {
                return rconsonant();
            }).join('');
        }
        function rclause(min, max) {
            return Array(Math.random() * (max - min + 1) + min | 0).join(',').split(',').map(function () {
                return rword();
            }).join(' ');
        }
        function rsentencep(min, max) {
            var r = Math.random();
            return r < .1 ? rsentencep(min, max) + ', ' + rsentencep(min, max) :
                r < .2 ? rsentencep(min, max) + ';  ' + rsentencep(min, max) : rclause(min, max);
        }
        function rsentence(min, max) {
            return capitalize(rsentencep(min, max) + rpunctuation());
        }
        function rparagraph(min, max, mins, maxs) {
            return Array(Math.random() * (max - min + 1) + min | 0).join(',').split(',').map(function () {
                return rsentence(mins, maxs);
            }).join(' ');
        }
        function ressay(min, max, minp, maxp, mins, maxs) {
            return Array(Math.random() * (max - min + 1) + min | 0).join(',').split(',').map(function () {
                return rparagraph(minp, maxp, mins, maxs);
            }).join('\n\n');
        }
        function capitalize(string) {
            return string[0].toUpperCase() + string.substr(1);
        }
        var vowels = 'aeiou';
        var consonants = 'abcdefghijklmnopqrstuvwxyz'.replace(new RegExp(vowels.split('').join('|'), 'g'), '');
        var punctuation = '..............?!';
        this.base(arguments);
        this.data = {
            projects: [],
            orderedProjects: [],
        };
        i = 400;
        while (i--) {
            this.data.projects.push({
                id: this.data.projects.length,
                favorites: rfloat(0, 10) * rfloat(0, 10) | 0,
                loves: rfloat(0, 10) * rfloat(0, 30) | 0,
                views: rfloat(0, 10) * rfloat(0, 10) * rfloat(0, 10) | 0,
                versions: rint(1, 5),
                remixes: [],
                project: {
                    created: +new Date,
                    authors: rclause(1, rint(2, 5)).split(' '),
                    name: capitalize(rclause(1, rint(5, 10))),
                    notes: ressay(1, 8, 1, 10, 3, 24)
                }
            });
        }
    },
    request: function (method, url, body, callback, error) {
        var t = this, req = {};
        if (!this.requests.length) {
            this.spinner.show();
        }
        this.requests.push(req);
        setTimeout(function () {
            t.requests.splice(t.requests.indexOf(req), 1);
            if (!t.requests.length) {
                t.spinner.hide();
            }
            callback.call(t, t.api(method, d.API_URL + url, body));
        }, this.latency);
        return this;
    },
    api: function (method, url, body) {
        var args;
        if (args = /projects\/(\d+)\//.exec(url)) {
            return this.data.projects[args[1]];
        }
        if (args = /projects\/all\//.exec(url)) {
            return this.orderProjectsBy(body.order).slice(body.offset, body.offset + body.length);
        }
    },
    orderProjectsBy: function (order) {
        if (this.data.orderedProjects[order]) {
            return this.data.orderedProjects[order];
        }
        return this.data.orderedProjects[order] = this.data.projects.slice(0).sort(order === 'remixes' ? function (a, b) {
            return b.remixes.length - a.remixes.length;
        } : function (a, b) {
            return b[order] - a[order];
        });
    }
});
