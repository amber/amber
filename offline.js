(function () {

    var paragraphs = [
        'Fusce a metus eu diam varius congue nec nec sapien. Vestibulum orci tortor, sollicitudin ac euismod non, placerat ac augue. Nunc convallis accumsan justo. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Donec malesuada vehicula lectus, viverra sodales ipsum gravida nec. Integer gravida nisi ut magna mollis molestie. Nullam pharetra accumsan sagittis. Proin tristique rhoncus orci, eget vulputate nisi sollicitudin et. Quisque lacus augue, mollis non mollis et, ullamcorper in purus. Morbi et sem orci. Praesent accumsan odio in ante ullamcorper id pellentesque mauris rhoncus. Duis vitae neque dolor. Duis sed purus at eros bibendum cursus nec a nulla. Donec turpis quam, ultricies id pretium sit amet, gravida eget leo.',
        'Maecenas eu placerat ante. Fusce ut neque justo, et aliquet enim. In hac habitasse platea dictumst. Nullam commodo neque erat, vitae facilisis erat. Cras at mauris ut tortor vestibulum fringilla vel sed metus. Donec interdum purus a justo feugiat rutrum. Sed ac neque ut neque dictum accumsan. Cras lacinia rutrum risus, id viverra metus dictum sit amet. Fusce venenatis, urna eget cursus placerat, dui nisl fringilla purus, nec tincidunt sapien justo ut nisl. Curabitur lobortis semper neque et varius. Etiam eget lectus risus, a varius orci. Nam placerat mauris at dolor imperdiet at aliquet lectus ultricies. Duis tincidunt mi at quam condimentum lobortis.',
        'In facilisis scelerisque dui vel dignissim. Sed nunc orci, ultricies congue vehicula quis, facilisis a orci. In aliquet facilisis condimentum. Donec at orci orci, a dictum justo. Sed a nunc non lectus fringilla suscipit. Vivamus pretium sapien sit amet mauris aliquet eleifend vel vitae arcu. Fusce pharetra dignissim nisl egestas pretium.',
        'Proin ornare ligula eu tellus tempus elementum. Aenean bibendum iaculis mi, nec blandit lacus interdum vitae. Vestibulum non nibh risus, a scelerisque purus. Ut vel arcu ac tortor adipiscing hendrerit vel sed massa. Fusce sem libero, lacinia vulputate interdum non, porttitor non quam. Aliquam sed felis ligula. Duis non nulla magna.',
        'Etiam aliquam sem ac velit feugiat elementum. Nunc eu elit velit, nec vestibulum nibh. Curabitur ultrices, diam non ullamcorper blandit, nunc lacus ornare nisi, egestas rutrum magna est id nunc. Pellentesque imperdiet malesuada quam, et rhoncus eros auctor eu. Nullam vehicula metus ac lacus rutrum nec fermentum urna congue. Vestibulum et risus at mi ultricies sagittis quis nec ligula. Suspendisse dignissim dignissim luctus. Duis ac dictum nibh. Etiam id massa magna. Morbi molestie posuere posuere.',
        'Nullam eros mi, mollis in sollicitudin non, tincidunt sed enim. Sed et felis metus, rhoncus ornare nibh. Ut at magna leo. Suspendisse egestas est ac dolor imperdiet pretium. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam porttitor, erat sit amet venenatis luctus, augue libero ultrices quam, ut congue nisi risus eu purus. Cras semper consectetur elementum. Nulla vel aliquet libero. Vestibulum eget felis nec purus commodo convallis. Aliquam erat volutpat.',
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus ac magna non augue porttitor scelerisque ac id diam. Mauris elit velit, lobortis sed interdum at, vestibulum vitae libero. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque iaculis ligula ut ipsum mattis viverra. Nulla a libero metus. Integer gravida tempor metus eget condimentum. Integer eget iaculis tortor. Nunc sed ligula sed augue rutrum ultrices eget nec odio. Morbi rhoncus, sem laoreet tempus pulvinar, leo diam varius nisi, sed accumsan ligula urna sed felis. Mauris molestie augue sed nunc adipiscing et pharetra ligula suscipit. In euismod lectus ac sapien fringilla ut eleifend lacus venenatis.',
        'Nullam eros mi, mollis in sollicitudin non, tincidunt sed enim. Sed et felis metus, rhoncus ornare nibh. Ut at magna leo. Suspendisse egestas est ac dolor imperdiet pretium. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam porttitor, erat sit amet venenatis luctus, augue libero ultrices quam, ut congue nisi risus eu purus. Cras semper consectetur elementum. Nulla vel aliquet libero. Vestibulum eget felis nec purus commodo convallis. Aliquam erat volutpat.',
        'Maecenas eu placerat ante. Fusce ut neque justo, et aliquet enim. In hac habitasse platea dictumst. Nullam commodo neque erat, vitae facilisis erat. Cras at mauris ut tortor vestibulum fringilla vel sed metus. Donec interdum purus a justo feugiat rutrum. Sed ac neque ut neque dictum accumsan. Cras lacinia rutrum risus, id viverra metus dictum sit amet. Fusce venenatis, urna eget cursus placerat, dui nisl fringilla purus, nec tincidunt sapien justo ut nisl. Curabitur lobortis semper neque et varius. Etiam eget lectus risus, a varius orci. Nam placerat mauris at dolor imperdiet at aliquet lectus ultricies. Duis tincidunt mi at quam condimentum lobortis.',
        'Proin suscipit luctus orci placerat fringilla. Donec hendrerit laoreet risus eget adipiscing. Suspendisse in urna ligula, a volutpat mauris. Sed enim mi, bibendum eu pulvinar vel, sodales vitae dui. Pellentesque sed sapien lorem, at lacinia urna. In hac habitasse platea dictumst. Vivamus vel justo in leo laoreet ullamcorper non vitae lorem. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin bibendum ullamcorper rutrum.',
        'Maecenas eu placerat ante. Fusce ut neque justo, et aliquet enim. In hac habitasse platea dictumst. Nullam commodo neque erat, vitae facilisis erat. Cras at mauris ut tortor vestibulum fringilla vel sed metus. Donec interdum purus a justo feugiat rutrum. Sed ac neque ut neque dictum accumsan. Cras lacinia rutrum risus, id viverra metus dictum sit amet. Fusce venenatis, urna eget cursus placerat, dui nisl fringilla purus, nec tincidunt sapien justo ut nisl. Curabitur lobortis semper neque et varius. Etiam eget lectus risus, a varius orci. Nam placerat mauris at dolor imperdiet at aliquet lectus ultricies. Duis tincidunt mi at quam condimentum lobortis.',
        'In facilisis scelerisque dui vel dignissim. Sed nunc orci, ultricies congue vehicula quis, facilisis a orci. In aliquet facilisis condimentum. Donec at orci orci, a dictum justo. Sed a nunc non lectus fringilla suscipit. Vivamus pretium sapien sit amet mauris aliquet eleifend vel vitae arcu. Fusce pharetra dignissim nisl egestas pretium.',
        'Etiam aliquam sem ac velit feugiat elementum. Nunc eu elit velit, nec vestibulum nibh. Curabitur ultrices, diam non ullamcorper blandit, nunc lacus ornare nisi, egestas rutrum magna est id nunc. Pellentesque imperdiet malesuada quam, et rhoncus eros auctor eu. Nullam vehicula metus ac lacus rutrum nec fermentum urna congue. Vestibulum et risus at mi ultricies sagittis quis nec ligula. Suspendisse dignissim dignissim luctus. Duis ac dictum nibh. Etiam id massa magna. Morbi molestie posuere posuere.',
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus ac magna non augue porttitor scelerisque ac id diam. Mauris elit velit, lobortis sed interdum at, vestibulum vitae libero. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque iaculis ligula ut ipsum mattis viverra. Nulla a libero metus. Integer gravida tempor metus eget condimentum. Integer eget iaculis tortor. Nunc sed ligula sed augue rutrum ultrices eget nec odio. Morbi rhoncus, sem laoreet tempus pulvinar, leo diam varius nisi, sed accumsan ligula urna sed felis. Mauris molestie augue sed nunc adipiscing et pharetra ligula suscipit. In euismod lectus ac sapien fringilla ut eleifend lacus venenatis.',
        'Integer elementum massa at nulla placerat varius. Suspendisse in libero risus, in interdum massa. Vestibulum ac leo vitae metus faucibus gravida ac in neque. Nullam est eros, suscipit sed dictum quis, accumsan a ligula. In sit amet justo lectus. Etiam feugiat dolor ac elit suscipit in elementum orci fringilla. Aliquam in felis eros. Praesent hendrerit lectus sit amet turpis tempus hendrerit. Donec laoreet volutpat molestie. Praesent tempus dictum nibh ac ullamcorper. Sed eu consequat nisi. Quisque ligula metus, tristique eget euismod at, ullamcorper et nibh. Duis ultricies quam egestas nibh mollis in ultrices turpis pharetra. Vivamus et volutpat mi. Donec nec est eget dolor laoreet iaculis a sit amet diam.',
        'In facilisis scelerisque dui vel dignissim. Sed nunc orci, ultricies congue vehicula quis, facilisis a orci. In aliquet facilisis condimentum. Donec at orci orci, a dictum justo. Sed a nunc non lectus fringilla suscipit. Vivamus pretium sapien sit amet mauris aliquet eleifend vel vitae arcu. Fusce pharetra dignissim nisl egestas pretium.',
        'In facilisis scelerisque dui vel dignissim. Sed nunc orci, ultricies congue vehicula quis, facilisis a orci. In aliquet facilisis condimentum. Donec at orci orci, a dictum justo. Sed a nunc non lectus fringilla suscipit. Vivamus pretium sapien sit amet mauris aliquet eleifend vel vitae arcu. Fusce pharetra dignissim nisl egestas pretium.',
        'Fusce a metus eu diam varius congue nec nec sapien. Vestibulum orci tortor, sollicitudin ac euismod non, placerat ac augue. Nunc convallis accumsan justo. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Donec malesuada vehicula lectus, viverra sodales ipsum gravida nec. Integer gravida nisi ut magna mollis molestie. Nullam pharetra accumsan sagittis. Proin tristique rhoncus orci, eget vulputate nisi sollicitudin et. Quisque lacus augue, mollis non mollis et, ullamcorper in purus. Morbi et sem orci. Praesent accumsan odio in ante ullamcorper id pellentesque mauris rhoncus. Duis vitae neque dolor. Duis sed purus at eros bibendum cursus nec a nulla. Donec turpis quam, ultricies id pretium sit amet, gravida eget leo.'
    ];
    var words = 'fusce a metus eu diam varius congue nec nec sapien vestibulum orci tortor sollicitudin ac euismod non placerat ac augue nunc convallis accumsan justo pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas donec malesuada vehicula lectus viverra sodales ipsum gravida nec integer gravida nisi ut magna mollis molestie nullam pharetra accumsan sagittis proin tristique rhoncus orci eget vulputate nisi sollicitudin et quisque lacus augue mollis non mollis et ullamcorper in purus morbi et sem orci praesent accumsan odio in ante ullamcorper id pellentesque mauris rhoncus duis vitae neque dolor duis sed purus at eros bibendum cursus nec a nulla donec turpis quam ultricies id pretium sit amet gravida eget leo'.split(' ');
    var clauses = 'etiam aliquam sem ac velit feugiat elementum. nunc eu elit velit. nec vestibulum nibh. curabitur ultrices. diam non ullamcorper blandit. nunc lacus ornare nisi. egestas rutrum magna est id nunc. pellentesque imperdiet malesuada quam. et rhoncus eros auctor eu. nullam vehicula metus ac lacus rutrum nec fermentum urna congue. vestibulum et risus at mi ultricies sagittis quis nec ligula. suspendisse dignissim dignissim luctus. duis ac dictum nibh. etiam id massa magna. morbi molestie posuere posuere. lorem ipsum dolor sit amet. consectetur adipiscing elit. phasellus ac magna non augue porttitor scelerisque ac id diam. mauris elit velit. lobortis sed interdum at. vestibulum vitae libero. lorem ipsum dolor sit amet. consectetur adipiscing elit. quisque iaculis ligula ut ipsum mattis viverra. nulla a libero metus. integer gravida tempor metus eget condimentum. integer eget iaculis tortor. nunc sed ligula sed augue rutrum ultrices eget nec odio. morbi rhoncus. sem laoreet tempus pulvinar. leo diam varius nisi. sed accumsan ligula urna sed felis. mauris molestie augue sed nunc adipiscing et pharetra ligula suscipit. in euismod lectus ac sapien fringilla ut eleifend lacus venenatis'.split('. ');

    function rint(min, max) {
        return Math.random() * (max - min + 1) + min | 0;
    }
    function rfloat(min, max) {
        return Math.random() * (max - min + 1) + min;
    }
    function rpunctuation() {
        return punctuation[Math.random() * punctuation.length | 0];
    }
    function rword() {
        return words[Math.random() * words.length | 0];
    }
    function rclause(min, max) {
        return clauses[Math.random() * clauses.length | 0].split(' ').slice(0, rint(min, max)).join(' ');
    }
    function rsentencep(min, max) {
        var r = Math.random();
        return r < .03 ? rsentencep(min, max) + ', ' + rsentencep(min, max) :
            r < .01 ? rsentencep(min, max) + ';  ' + rsentencep(min, max) : rclause(min, max);
    }
    function rsentence(min, max) {
        return rparagraph(1, 1, min, max);
    }
    function rparagraph(min, max, mins, maxs) {
        return paragraphs[Math.random() * paragraphs.length | 0].split('.').slice(0, rint(min, max)).map(function (sentence) {
            return sentence.split(' ').slice(0, rint(mins, maxs)).join(' ');
        }).join('.') + '.';
    }
    function ressay(min, max, minp, maxp, mins, maxs) {
        return Array(Math.random() * (max - min + 1) + min | 0).join(',').split(',').map(function () {
            return rparagraph(minp, maxp, mins, maxs);
        }).join('\n\n');
    }
    function capitalize(string) {
        return string[0].toUpperCase() + string.substr(1);
    }
    var punctuation = '..............?!';

    d.r.OfflineServer = d.Class(d.r.Server, {
        openTime: 0,
        latency: 200,
        userRank: 'default',
        acceptSignIn: true,
        _postId: 0,
        _topicId: 0,
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
            clientRequest: function (p) {
                var f = this.onServer.request[p.$name];
                if (f) {
                    setTimeout(function () {
                        try {
                            this.sendServer('request.result', {
                                request$id: p.request$id,
                                result: typeof f === 'function' ? f.call(this, p) : this.fetch(f, p.offset, p.length)
                            });
                        } catch (e) {
                            if (typeof e === 'number') {
                                this.sendServer('request.error', {
                                    request$id: p.request$id,
                                    code: e
                                });
                            } else {
                                throw e;
                            }
                        }
                    }.bind(this), this.latency);
                } else {
                    console.error('RequestError: Undefined request in', p.$name);
                }
            },
            request: {
                'users.user': function (id) {
                    return {
                        name: 'nXIII'
                    };
                },
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
                'forums.categories': function () {
                    return this.data.categories.map(function (category) {
                        return {
                            name: category.name,
                            forums: category.forums.map(function (forum) {
                                return {
                                    id: forum.id,
                                    name: forum.name,
                                    description: forum.description,
                                    isUnread: false
                                };
                            })
                        };
                    });
                },
                'forums.forum': function (options) {
                    var forum = this.data.forums[options.forum$id];
                    return {
                        id: forum.id,
                        name: forum.name,
                        description: forum.description,
                        isUnread: false,
                        topics: forum.topicCount,
                        posts: forum.postCount
                    };
                },
                'forums.topics': function (options) {
                    return this.data.forums[options.forum$id].topics.slice(options.offset, options.offset + options.length).map(function (topic) {
                        return this.onServer.request['forums.topic'].call(this, {
                            topic$id: topic.id
                        });
                    }, this);
                },
                'forums.topic': function (options) {
                    var topic = this.data.topics[options.topic$id];
                    return {
                        forum$id: topic.forum$id,
                        id: topic.id,
                        name: topic.name,
                        authors: topic.authors,
                        isUnread: false,
                        views: topic.viewCount,
                        posts: topic.postCount
                    };
                },
                'forums.topic.view': function (options) {
                    ++this.data.topics[options.topic$id].views;
                    return null;
                },
                'forums.topic.add': function (options) {
                    this.data.forums[options.forum$id].topics.unshift(this.data.topics[++this._topicId] = {
                        forum$id: options.forum$id,
                        id: this._topicId,
                        name: options.name,
                        authors: [this.app().user().name()],
                        isUnread: false,
                        viewCount: 0,
                        postCount: 1,
                        posts: [this.data.posts[++this._postId] = {
                            topic$id: this._topicId,
                            id: this._postId,
                            authors: [this.app().user().name()],
                            body: options.body
                        }]
                    });
                    return {
                        topic$id: this._topicId,
                        post$id: this._postId
                    };
                },
                'forums.posts': function (options) {
                    var topic = this.data.topics[options.topic$id];
                    var posts = topic.posts, i;
                    if (!posts) {
                        i = topic.postCount;
                        topic.posts = posts = [];
                        while (i--) {
                            posts.push(this.data.posts[++this._postId] = {
                                id: this._postId,
                                authors: rclause(1, rint(2, 5)).split(' '),
                                body: ressay(1, rint(1, 4), 1, rint(2, 8), 3, 24)
                            });
                        }
                    }
                    return posts.slice(options.offset, options.offset + options.length);
                },
                'forums.post.add': function (options) {
                    var topic = this.data.topics[options.topic$id];
                    topic.posts.push(this.data.posts[++this._postId] = {
                        id: this._postId,
                        authors: [this.app().user().name()],
                        body: options.body
                    });
                    ++topic.postCount;
                    return this._postId;
                },
                'forums.post.edit': function (options) {
                    var post = this.data.posts[options.post$id];
                    post.body = options.body;
                }
            }
        },
        init: function () {
            var i, id, data;
            this.base(arguments);
            this.data = data = {
                categories: [
                    {
                        name: {$:'Welcome'},
                        forums: [
                            { name: {$:'Announcements'}, description: {$:'Updates from the Amber team.'} }
                        ]
                    },
                    {
                        name: {$:'About Amber'},
                        forums: [
                            { name: {$:'Bugs and Glitches'}, description: {$:'Report a bug you found in Amber.'} },
                            { name: {$:'Questions about Amber'}, description: {$:'Post general questions about Amber.'} },
                            { name: {$:'Feedback'}, description: {$:'Share your thoughts and impressions of Amber'} }
                        ]
                    },
                    {
                        name: {$:'Making Amber Projects'},
                        forums: [
                            { name: {$:'Help with Scripts'}, description: {$:'Need help with your Amber project? Ask here!'} },
                            { name: {$:'Show and Tell'}, description: {$:'Tell everyone about your projects and collections'} }
                        ]
                    }
                ],
                projects: [],
                forums: {},
                topics: {},
                posts: {}
            };
            this.userId = 0;
            this.usersById = {};
            this.usersByName = {};
            i = 732;
            while (i--) {
                data.projects.push({
                    id: data.projects.length,
                    favorites: rfloat(0, 10) * rfloat(0, 10) | 0,
                    loves: rfloat(0, 10) * rfloat(0, 30) | 0,
                    views: rfloat(0, 10) * rfloat(0, 10) * rfloat(0, 10) | 0,
                    versions: rint(1, 5),
                    featured: rfloat(1, 5) > 4,
                    remixes: [],
                    project: {
                        created: +new Date,
                        authors: rclause(1, rint(1, 3)).split(' '),
                        name: capitalize(rclause(1, rint(5, 10))),
                        notes: ressay(1, 8, 1, 10, 3, 24),
                        thumbnail: 'project:' + rint(10000, 3000000)
                    }
                });
            }
            id = 0;
            this._topicId = 0;
            data.categories.forEach(function (category) {
                category.forums.forEach(function (forum) {
                    var topic;
                    forum.id = ++id;
                    data.forums[id] = forum;
                    forum.topics = [];
                    i = 100;
                    while (i--) {
                        forum.topics.push(topic = {
                            forum$id: forum.id,
                            id: ++this._topicId,
                            name: capitalize(rclause(3, 10)),
                            authors: rclause(1, rint(1, 3)).split(' '),
                            viewCount: rfloat(0, 10) * rfloat(0, 10) * rfloat(0, 10) | 0,
                            postCount: rint(1, rint(5, 100))
                        });
                        data.topics[this._topicId] = topic;
                    }
                    forum.topicCount = forum.topics.length;
                }, this);
            }, this);
            this.socket.send = this.socket.send.bind(this);
        },
        socket: {
            readyState: 0,
            send: function (data) {
                var packet = this.decodePacket('Client', data);
                if (!packet) return;
                packet.$time = new Date;
                packet.$side = 'Client';
                if (packet.$type.substr(0, 8) === 'request.') {
                    packet.$name = packet.$type.substr(8);
                    return this.onServer.clientRequest.call(this, packet);
                }
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
                this.socket.readyState = 1;
                this.listeners.open.call(this);
            }.bind(this), this.openTime);
        },
        getAsset: function (hash) {
            var x = /^project\:(\d+)$/.exec(hash);
            if (x) {
                return 'http://scratch.mit.edu/static/site/projects/thumbnails/' + (x[1].substr(0, x[1].length - 4) || 0) + '/' + x[1].substr(x[1].length - 4) + '.png';
            }
            return 'data:image/gif;base64,R0lGODlhAQABAIAAAP7//wAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw==';
        },
        sendServer: function (type, properties) {
            if (this.app().config().verbosePackets) {
                var p = properties || {};
                p.$type = type;
            } else {
                p = this.encodePacket('Server', type, properties);
            }
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

}());
