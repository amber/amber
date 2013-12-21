Amber.mock = (function() {
  'use strict';

  var create = Amber.create;

  var RequestError = {
    NOT_FOUND: 0,
    INCORRECT_CREDENTIALS: 1,
    INVALID_REQUEST: 2
  };

  var Backend = create('Backend', {

    data: {
      latency: { value: 50 },
    },

    objects: {
      user: {

      }
    },

    onopen: null,
    onclose: null,
    onmessage: null,
    onerror: null,
    verbosePackets: false,

    send: function(data) {
      var p = Amber.Socket.prototype.decodePacket('Client', data);

      if (!p) return;

      if (p.request) {
        var promise = Amber.Promise();
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
            user: this.user = this.makeUser(p.user),
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
          promise.fulfill(this.makeUser(p.user));
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
          promise.fulfill(this.makeUser(p.user));
        }
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
        group: name === 'administrator' || name === 'moderator' || name === 'limited' ? name : 'default'
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
