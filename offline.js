d.r.OfflineServer = d.Class(d.r.Server, {
    openTime: 0,
    latency: 10,
    userRank: 'default',
    acceptSignIn: true,
    queries: {
        'projects.count': function () {
            return this.data.projects.length;
        },
        'projects.topLoved': {
            model: 'projects',
            order: 'loves'
        },
        'projects.topViewed': {
            model: 'projects',
            order: 'views'
        },
        'projects.topRemixed': {
            model: 'projects',
            order: 'remixCount'
        },
        'projects.featured': {
            model: 'projects',
            filter: function (p) {
                return p.featured;
            }
        },
        'forum.categories': function () {
            return [
                {
                    name: {$:'Welcome'},
                    forums: [
                        { name: {$:'Announcements'}, description: {$:'Updates from the Amber team.'}, id: 1 }
                    ]
                },
                {
                    name: {$:'About Amber'},
                    forums: [
                        { name: {$:'Bugs and Glitches'}, description: {$:'Report a bug you found in Amber.'}, id: 2 },
                        { name: {$:'Questions about Amber'}, description: {$:'Post general questions about Amber.'}, id: 3 },
                        { name: {$:'Feedback'}, description: {$:'Share your thoughts and impressions of Amber'}, id: 4 }
                    ]
                },
                {
                    name: {$:'Making Amber Projects'},
                    forums: [
                        { name: {$:'Help with Scripts'}, description: {$:'Need help with your Amber project? Ask here!'}, id: 5 },
                        { name: {$:'Show and Tell'}, description: {$:'Tell everyone about your projects and collections'}, id: 6 }
                    ]
                }
            ];
        }
    },
    onServer: {
        connect: function (p) {
            this.sendServer('connect', {
                sessionId: p.sessionId,
                user: null
            });
        },
        'auth.signIn': function (p) {
            if (this.acceptSignIn) {
                this.sendServer('auth.signIn.succeeded', {
                    user: { name: p.username, id: 1, rank: this.userRank }
                });
            } else {
                this.sendServer('auth.signIn.failed', {
                    message: 'acceptSignIn is disabled'
                });
            }
        },
        'auth.signOut': function () {
            this.sendServer('auth.signOut.succeeded', {});
        },
        query: function (p) {
            if (this.queries[p.name]) {
                setTimeout(function () {
                    this.sendServer('query.result', {
                        request$id: p.request$id,
                        result: typeof this.queries[p.name] === 'function' ?
                            this.queries[p.name].call(this, p.options) :
                            this.fetch(this.queries[p.name], p.options.offset, p.options.length)
                    });
                }.bind(this), this.latency);
            } else {
                console.error('QueryError: Undefined query in', p.name);
            }
        }
    },
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
        this.userId = 0;
        this.usersById = {};
        this.usersByName = {};
        i = 100;
        while (i--) {
            this.data.projects.push({
                id: this.data.projects.length,
                favorites: rfloat(0, 10) * rfloat(0, 10) | 0,
                loves: rfloat(0, 10) * rfloat(0, 30) | 0,
                views: rfloat(0, 10) * rfloat(0, 10) * rfloat(0, 10) | 0,
                versions: rint(1, 5),
                featured: rfloat(1, 5) > 4,
                remixes: [],
                project: {
                    created: +new Date,
                    authors: rclause(1, rint(2, 5)).split(' '),
                    name: capitalize(rclause(1, rint(5, 10))),
                    notes: ressay(1, 8, 1, 10, 3, 24)
                }
            });
        }
        this.socket.send = this.socket.send.bind(this);
    },
    socket: {
        readyState: 1,
        send: function (data) {
            var packet = this.decodePacket('Client', data);
            if (!packet) return;
            packet.$time = new Date;
            packet.$side = 'Client';
            if (this.onServer.hasOwnProperty(packet.$type)) {
                this.onServer[packet.$type].call(this, packet);
            } else {
                console.warn('Invalid packet: Client:' + packet.$type);
            }
        }
    },
    open: function () {
        this.socketQueue = [];
        setTimeout(function () {
            this.listeners.open.call(this);
        }.bind(this), this.openTime);
    },
    getAsset: function (hash) {
        return 'data:image/gif;base64,R0lGODlhAQABAIAAAP7//wAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw==';
    },
    sendServer: function (type, properties) {
        var p = this.encodePacket('Server', type, properties);
        if (!p) return;
        setTimeout(function () {
            this.listeners.message.call(this, {
                data: JSON.stringify(p)
            });
        }.bind(this), this.latency);
    },
    fetch: function (config, offset, length) {
        var order = config.order || 'id',
            model = config.model;
        return (this.data[model + '_' + order] || (
                this.data[model + '_' + order] = this.data[model].slice(0).sort(order === 'remixCount' ? function (a, b) {
                    return b.remixes.length - a.remixes.length;
                } : function (a, b) {
                    return b[order] - a[order];
                }))).filter(config.filter || function () {return true}).slice(offset, offset + length);
    }
});
