Amber.mock = (function() {
  'use strict';

  var create = Amber.create;

  var RequestError = {
    NOT_FOUND: 1,
    INCORRECT_CREDENTIALS: 2,
    INVALID_REQUEST: 3
  };

  var Backend = create('Backend', {

    data: {
      latency: { value: 50 },
    },

    onopen: null,
    onclose: null,
    onmessage: null,
    onerror: null,
    verbosePackets: false,

    send: function(data) {
      var p = Amber.Socket.prototype.decodePacket('Client', data);

      if (!p) return;

      var promise = Amber.Promise();
      if (p.request) {
        promise.then(function(data) {
          this.yield('result', {
            request: p.request,
            result: data
          });
        }, function(reason) {
          this.yield('requestError', {
            request: p.request,
            reason: reason
          });
        }, this);
      }

      try {
        this.handle[p.$type].call(this, p, promise);
      } catch (e) {
        this.yield('error', {
          name: e.name,
          message: e.message,
          stack: e.stack
        });
      }
    },

    close: function() {
      setTimeout(function() {
        this.readyState = 2;
        setTimeout(function() {
          this.readyState = 3;
          if (this.onclose) {
            setTimeout(this.onclose.bind(this));
          }
        }.bind(this), this.latency);
      }.bind(this), this.latency);
    },


    handle: {
      'connect': function(p) {
        if (p.user && p.token) {
          this.yield('connect', {
            user: this.userInfo(this.user = this.makeUser(p.user)),
            token: this.makeToken()
          });
        } else {
          this.yield('connect');
        }
      },

      'auth.signOut': function(p, promise) {
        if (!this.user) {
          return promise.reject(RequestError.INVALID_REQUEST);
        }
        this.user = null;
        promise.fulfill();
      },

      'auth.signIn': function(p, promise) {
        if (this.user) return promise.reject(RequestError.INVALID_REQUEST);
        if (p.password === 'invalid') {
          promise.reject(RequestError.INCORRECT_CREDENTIALS);
        } else {
          promise.fulfill(this.userInfo(this.makeUser(p.user)));
        }
      },

      'project': function(p, promise) {
        if (p.project === 404) {
          return promise.reject(RequestError.NOT_FOUND);
        }
        promise.fulfill(this.makeProject(p.project));
      },

      'user.info': function(p, promise) {
        if (p.user === 'invalid') {
          promise.reject(RequestError.NOT_FOUND);
        } else {
          promise.fulfill(this.userInfo(this.makeUser(p.user)));
        }
      },

      'user': function(p, promise) {
        if (p.user === 'invalid') {
          promise.reject(RequestError.NOT_FOUND);
        } else {
          promise.fulfill(this.makeUser(p.user));
        }
      },

      'user.follow': function(p, promise) {
        var user = this.makeUser(p.user);
        user.isFollowing = !user.isFollowing;
        promise.fulfill();
      },

      'unwatch': function() {},

      'forumCategories': function(p, promise) {
        promise.fulfill([
          {
            name: {$:'Welcome to Amber'},
            forums: [
              {
                id: 'announcements',
                name: {$:'Announcements'},
                description: {$:'Updates from the Amber team'},
                isUnread: false,
                topicCount: 20,
                postCount: 442
              }
            ]
          },
          {
            name: {$:'About Amber'},
            forums: [
              {
                id: 'feedback',
                name: {$:'Feedback'},
                description: {$:'Report bugs and share your thoughts and ideas'},
                isUnread: false,
                topicCount: 723,
                postCount: 1987
              },
              {
                id: 'questions',
                name: {$:'Questions'},
                description: {$:'Ask anything about Amber'},
                isUnread: true,
                topicCount: 142,
                postCount: 1847
              }
            ]
          }
        ]);
      }
    },


    init: function() {
      this.userMap = {};
      this.projectMap = {};

      setTimeout(function() {
        this.readyState = 1;
        if (this.onopen) {
          setTimeout(this.onopen.bind(this));
        }
      }.bind(this), this.latency);
    },


    makeToken: function() {
      var s = '';
      var chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      for (var i = 0; i < 32; i++) {
        s += chars[Math.random() * chars.length | 0];
      }
      return s;
    },

    makeUser: function(name) {
      if (this.userMap[name]) {
        return this.userMap[name];
      }
      return this.userMap[name] = {
        name: name,
        scratchId: this.makeToken(),
        group: name === 'administrator' || name === 'moderator' || name === 'limited' ? name : 'default',
        about: this.makePhrase(name, 'about'),
        // objectId(Project) __featuredProject__
        // objectId(ActivityFeed) __activity__
        // objectId(Collection) __projects__
        // objectId(Collection) __lovedProjects__
        // CollectionStub[] __collections__
        followers: [],
        following: [],
        // objectId(Topic) __topic__
        isFollowing: name === 'following'
      };
    },

    userInfo: function(user) {
      return {
        scratchId: user.scratchId,
        group: user.group
      };
    },

    makeProject: function(id) {
      if (this.projectMap[id]) {
        return this.projectMap[id];
      }
      return this.projectMap[id] = {
        name: this.makeWord(id, 'name'),
        authors: this.makeUsers(id, 'authors'),
        created: this.makeDate(id, 'create'),
        // modified: ,
        // thumbnail: ,
        // notes: ,
        // topic: ,
        // scriptCount: ,
        // spriteCount: ,
        // viewCount: ,
        // loveCount: ,
        // remixCount: ,
        // activity: ,
        // tags: ,
        // remixes: ,
        // collections: ,
        // isLoved:
      }
    },

    makePhrase: function(seed, key) {
      var result = '';
      for (var i = this.makeInt(seed, key, 7) + 3; i > 0; i--) {
        var word = this.makeWord(seed, key + i);
        result += result ? ' ' + word.toLowerCase() : word;
      }
      return result;
    },

    makeWord: function(seed, key) {
      var words = 'Lorem Ipsum Dolor Sit Amet Consectetur Adipisicing Elit Sed Do Eiusmod Tempor Incididunt Ut Labore Et Dolore Magna Aliqua Ut Enim Ad Minim Veniam Quis Nostrud Exercitation Ullamco Laboris Nisi Ut Aliquip Ex Ea Commodo Consequat Duis Aute Irure Dolor In Reprehenderit In Voluptate Velit Esse Cillum Dolore Eu Fugiat Nulla Pariatur Excepteur Sint Occaecat Cupidatat Non Proident Sunt In Culpa Qui Officia Deserunt Mollit Anim Id Est Laborum'.split(' ');
      return words[this.makeInt(seed, key, words.length)];
    },

    makeUsers: function(seed, key) {
      var names = 'aUser alpha beta gamma'.split(' ');
      return this.makeUser(names[this.makeInt(seed, key, names.length)]);
    },

    makeInt: function(seed, key, limit) {
      var s = 0;
      seed += key;
      for (var i = 0; i < seed.length; i++) {
        s = (s + seed.charCodeAt(i) * 513231) % limit;
      }
      return s;
    },


    yield: function(type, options) {
      (options || (options = {})).$type = type;
      var data = Amber.Socket.prototype.encodePacket.call(this, 'Server', options);

      if (this.onmessage) {
        setTimeout(this.onmessage.bind(this, {
          data: data
        }), this.latency);
      }
    }
  });

  var Socket = create('Socket', {
    extend: Amber.Socket,

    createSocket: function() {
      return this.backend = Backend({ verbosePackets: this.backendVerbosePackets });
    }

  });


  return {
    Backend: Backend,
    Socket: Socket
  };

}());
