var Amber = (function () {
  'use strict';


  var slice = [].slice;
  var hasOwnProperty = {}.hasOwnProperty;
  var defineProperty = Object.defineProperty;


  if (!Function.prototype.bind) {
    Function.prototype.bind = function(context) {
      var self = this;
      var args = slice.call(arguments);

      return function() {
        return self.apply(context, args.concat(slice.call(arguments)));
      };
    };
  }


  function unimplemented() {
    debugger;
  }


  function inherits(sub, sup) {
    sub.prototype = Object.create(sup.prototype);
    sub.prototype.constructor = sub;
  }

  function extend(o, p) {
    for (var key in p) if (hasOwnProperty.call(p, key)) {
      o[key] = p[key];
    }
    return o;
  }

  function defineSetter(object, name, apply) {
    var k = '$' + name;
    defineProperty(object, name, {
      set: function(value) {
        if (this[k] === value) return;
        apply(value, this[k]);
        this[k] = value;
      },
      get: function() {
        return this[k];
      }
    });
  }

  function defineGetter(object, name, get) {
    defineProperty(object, name, { get: get });
  }

  function defineEvented(object, name) {
    var k = '$' + name;
    defineProperty(object, name, {
      set: function(value) {
        var previous = this[k];
        this[k] = value;
        this.emit(name + ' change', new PropertyEvent(this, value, previous));
      },
      get: function() {
        return this[k]
      }
    });
  }


  var $lastUID = '';

  function getUID() {
    var string = '';
    var i = $lastUID.length - 1;
    while ($lastUID.charAt(i) === 'z') {
      string += 'a';
      i -= 1;
    }
    if (i === -1) {
      string = 'a' + string;
    } else {
      string = $lastUID.slice(0, i) + String.fromCharCode($lastUID.charCodeAt(i) + 1) + string;
    }
    return $lastUID = string;
  }


  function isFunction(thing) {
    return typeof thing === 'function';
  }

  function isObject(thing) {
    return thing && typeof thing === 'object';
  }

  function isArray(thing) {
    return Object.prototype.toString.call(thing) === '[object Array]';
  }


  function addClass(element, name) {
    if ((' ' + element.className + ' ').indexOf(' ' + name + ' ') === -1) {
      element.className += (element.className ? ' ' : '') + name;
    }
  }

  function removeClass(element, name) {
    var i = (' ' + element.className + ' ').indexOf(' ' + name + ' ');
    if (i !== -1) {
      element.className = element.className.slice(0, i - 1) + element.className.slice(i + name.length);
    }
  }

  function toggleClass(element, name, active) {
    if (active == null) active = hasClass(element, name);
    (active ? addClass : removeClass)(element, name);
  }

  function hasClass(element, name) {
    return (' ' + element.className + ' ').indexOf(' ' + name + ' ') !== -1;
  }


  function format(string) {
    var args = arguments;
    var i = 1;
    return string.replace(/%([1-9]\d*)?/g, function(_, n) {
      return n ? args[n] : args[i++];
    });
  }


  function escapeXML(string) {
    return string
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }


  function bbTouch(element, e) {
    return inBB(e, element.getBoundingClientRect());
  }

  function inBB(e, bb) {
    return e.x + e.radiusX >= bb.left && e.x - e.radiusX <= bb.right &&
    e.y + e.radiusY >= bb.top && e.y - e.radiusY <= bb.bottom;
  }




/*
  var UserGroup = {
    ADMINISTRATOR: 'administrator',
    MODERATOR: 'moderator',
    DEFAULT: 'default',
    LIMITED: 'limited'
  };


  inherits(User, Base);
  function User(server) {
    this.server = server;
    this.name = '';
    this.id = null;
    this.group = 'default';
  }

  defineProperty(User.prototype, 'avatarURL', function() {
    var id = '' + this.id;
    return format("http://scratch.mit.edu/static/site/users/avatars/%/%.png", id.slice(0, -4), id.slice(-4));
  });

  User.prototype.getAvatarURLOfSize = function(size) {
    return format("http://cdn.scratch.mit.edu/get_image/user/%1_%2x%2.png", this.id, size);
  };

  defineProperty(User.prototype, 'profileURL', function() {
    return urls.reverse('user profile', this.name);
  });

  User.prototype.toJSON = function() {
    return {
      scratchId: this.id,
      name: this.name,
      group: this.group === 'default' ? undefined : group
    };
  };

  User.prototype.fromJSON = function(data) {
    this.name = data.name;
    this.id = data.scratchId;
    this.group = data.group || 'default';
  };
*/

  var debug = true;
  function nameFunction(f, name) {
    return f.name ? f : new Function('inner', 'return function ' + name + '() { return inner.apply(this, arguments); };')(f);
  }
  function create(className, config) {
    function named(prefix, key, f) {
      if (!debug) return f;
      if (f == null) {
        f = key;
        key = prefix;
        prefix = null;
      }
      return nameFunction(f, (className ? className + '_' : '') + (prefix ? prefix + '_' : '') + key);
    }

    if (isObject(className)) {
      config = className;
      className = null;
    }

    var extend = config.extend || Base;
    delete config.extend;

    var outer = function(c) {
      var instance = new constructor;
      instance.init();
      if (c) instance.set(c);
      instance.construct();
      return instance;
    };
    var constructor = function () {};

    if (className && debug) {
      outer = nameFunction(outer, className);
      constructor = nameFunction(constructor, className);
    }

    constructor.prototype = Object.create(extend ? extend.prototype : Object.prototype);
    constructor.prototype.constructor = constructor;

    outer.prototype = constructor.prototype;

    if (config.init) {
      var superInit = extend && extend.prototype.init;
      var init = config.init;
      delete config.init;

      constructor.prototype.init = named('init', superInit ? function() {
        superInit.call(this);
        init.call(this);
      } : init);
    }

    if (config.construct) {
      var superConstruct = extend && extend.prototype.construct;
      var construct = config.construct;
      delete config.construct;

      constructor.prototype.construct = named('construct', superConstruct ? function() {
        superConstruct.call(this);
        construct.call(this);
      } : construct);
    }

    if (config.data) {
      var data = config.data;
      delete config.data;

      Object.keys(data).forEach(function(key) {
        var k = '$d_' + key;

        Object.defineProperty(constructor.prototype, key, {
          get: named('get', key, function() {
            return this[k];
          }),
          set: named('set', key, function(value) {
            var previousValue = this[k];
            this.emit(key + 'Changed', Event({
              object: this,
              value: value,
              previousValue: previousValue
            }));
            this[k] = value;
          })
        });
      });
    }

    if (config.properties) {
      var properties = config.properties;
      delete config.properties;

      Object.keys(properties).forEach(function(key) {
        var c = properties[key];

        if (isFunction(c)) {
          Object.defineProperty(constructor.prototype, key, {
            get: debug ? nameFunction(c, (className ? className + '_' : '') + 'get_' + key) : c,
          });
        } else if (c.apply) {
          var k = '$p_';
          var apply = c.apply;

          Object.defineProperty(constructor.prototype, key, {
            get: named('get', key, function() {
              return this[k];
            }),
            set: named('set', key, function(value) {
              var old = this[k];
              if (old === value) return;
              this[k] = value;
              this[apply](value, old);
            })
          });
        }
      });
    }

    if (config.statics) {
      var statics = config.statics;
      delete config.statics;

      Object.keys(statics).forEach(function(key) {
        outer[key] = isFunction(statics[key]) ? named('static', key, statics[key]) : statics[key];
      });
    }

    Object.keys(config).forEach(function(key) {
      constructor.prototype[key] = isFunction(config[key]) ? named(key, config[key]) : config[key];
    });

    return outer;
  }

  function model(name, config) {
    model[name] = create(name, config);
  }

  var Base = create('Base', {

    on: function(name, handler) {
      var k = '$l_' + name;
      if (this[k]) {
        this[k].push(handler);
      } else {
        this[k] = [handler];
      }
      return this;
    },

    once: function(name, handler) {
      return this.on(name, function listener() {
        handler.apply(null, arguments);
        this.removeListener(name, listener);
      }.bind(this));
    },

    removeListener: function(name, handler) {
      var k = '$l_' + name;
      if (this[k]) {
        var i = this[k].indexOf(handler);
        this[k].splice(i, 1);
      }
      return this;
    },

    removeAllListeners: function(name) {
      delete this['$l_' + name];
      return this;
    },

    listeners: function(name) {
      return this['$l_' + name] || [];
    },

    emit: function(name) {
      var listeners = this['$l_' + name];
      if (listeners) {
        var args = slice.call(arguments, 1);
        for (var i = 0; i < listeners.length; i++) {
          listeners[i].apply(null, args);
        }
      }
      return this;
    },

    set: function(data) {
      for (var key in data) if (hasOwnProperty.call(data, key)) {
        this[key] = data[key];
      }
      return this;
    },


    init: function() {},
    construct: function() {}

  });

  var Promise = create('Promise', {

    isPromise: true,

    on: function(event, handler) {
      if ((event === 'success' || event === 'failure') && this.complete) {
        if (event === 'success' && this.success) {
          handler.apply(null, this.results);
        } else if (event === 'failure' && !this.success) {
          handler(this.reason);
        }
      } else {
        Base.prototype.on.call(this, event, handler);
      }
      return this;
    },

    then: function(success, failure) {
      var promise = Promise();

      this.on('success', function(result) {
        result = success ? success.apply(null, arguments) : result;
        if (result && result.isPromise) {
          result.then(promise.fulfill, promise.reject);
        } else {
          promise.fulfill(result);
        }
      });
      this.on('failure', function(err) {
        if (failure) failure(err);
        promise.reject(err);
      });

      return promise;
    },

    fulfill: function() {
      if (this.complete) return;
      this.complete = true;
      this.success = true;
      var args = slice.call(arguments);
      this.results = args;
      this.emit.apply(this, ['success'].concat(args));
      this.emit.apply(this, ['resolve', null].concat(args));
      return this;
    },

    reject: function(err) {
      if (this.complete) return;
      this.complete = true;
      this.success = false;
      this.reason = err;
      this.emit('failure', err);
      this.emit('resolve', err);
      return this;
    },

    statics: {

      all: function() {
        var components = slice.call(arguments);
        var all = Promise();
        var results = [];
        var count = 0;
        components.forEach(function(promise, i) {
          promise.then(function(result) {
            results[i] = result;
            count += 1;
            if (count === components.length) {
              all.fulfill(results);
            }
          }, function(err) {
            promise.reject(err);
          });
        });
        return all;
      },

      some: function() {
        var components = slice.call(arguments);
        var some = Promise();
        var failures = [];
        var count = 0;
        components.forEach(function(promise, i) {
          promise.then(function(result) {
            some.fulfill(result);
          }, function(err) {
            failures[i] = result;
            count += 1;
            if (count === components.length) {
              promise.reject(failures);
            }
          });
        });
        return some;
      },

      any: function() {
        var components = slice.call(arguments);
        var any = Promise();
        var failures = [];
        var count = 0;
        components.forEach(function(promise, i) {
          promise.then(function(result) {
            any.fulfill(result);
          }, function(err) {
            any.reject(err);
          });
        });
        return any;
      }
    },


    init: function() {
      this.complete = false;
    }
  });


  var Locale = create('Locale', {

    statics: {
      strings: {},
      impl: {},
      current: 'en-US',

      getText: function(id) {
        var l = Locale.strings[Locale.current];
        var result;
        if (hasOwnProperty.call(l, id)) {
          result = l[id];
        } else {
          if (Locale.current !== 'en-US') {
            console.warn('Missing translation key "' + id + '"');
          }
          result = id;
        }

        if (arguments.length === 1) {
          return result;
        }
        return format.apply(null, [result].concat(slice.call(arguments, 1)));
      },

      maybeGetText: function(trans) {
        return trans && trans.$ ? getText(trans.$) : trans;
      },

      getList: function(list) {
        return (Locale.impl[Locale.current] && Locale.impl[Locale.current].list || Locale.impl['en-US'].list)(list);
      },

      getPlural: function(a, b, n) {
        return n === 1 ? Locale.getText(b, n) : Locale.getText(a, n);
      }
    }
  });

  Locale.list = [
    Locale({ id: 'en-US', name: 'English (US)' }),
    Locale({ id: 'en-PT', name: 'Pirate-speak' })
  ];

  var T = Locale.getText;
  T.maybe = Locale.maybeGetText;
  T.list = Locale.getList;
  T.plural = Locale.getPlural;


  var Event = create('Event', {

    fromDOM: function(e) {
      return this.set({
        alt: e.altKey,
        ctrl: e.ctrlKey,
        meta: e.metaKey,
        shift: e.shiftKey
      });
    }
  });


  var TouchEvent = create('TouchEvent', {

    fromTouch: function(e, touch) {
      return this.fromDOM(e).set({
        x: touch.clientX,
        y: touch.clientY,
        id: touch.identifier || 0,
        radiusX: touch.radiusX != null ? touch.radiusX : 10,
        radiusY: touch.radiusY != null ? touch.radiusY : 10,
        angle: touch.rotationAngle || 0,
        force: touch.force != null ? touch.force : 1
      });
      return this;
    },

    fromMouse: function(e) {
      return this.fromDOM(e).set({
        x: e.clientX,
        y: e.clientY,
        id: -1,
        radiusX: .5,
        radiusY: .5,
        angle: 0,
        force: 1
      });
    }
  });


  var WheelEvent = create('WheelEvent', {

    fromWebkit: function(e) {
      return this.fromDOM(e).set({
        x: -e.wheelDeltaX / 3,
        y: -e.wheelDeltaY / 3
      });
      return this;
    },

    fromMoz: function(e) {
      return this.fromDOM(e).set({
        x: 0,
        y: e.detail
      });
      return this;
    },

    init: function() {
      this.allowDefault = false;
    }
  });


  model('Socket', {

    data: {
      url: {},
      connected: {}
    },

    statics: {
      REQUEST_ERRORS: ['Not found', 'Incorrect credentials'],
      INITIAL_REOPEN_DELAY: 100
    },

    request: function(type, options) {
      if (!options) options = {};

      var promise = Promise();

      var id = getUID();
      this.requestMap[id] = {
        type: type,
        options: options,
        promise: promise
      };

      options.request$id = id;
      this.send(type, options);

      return promise;
    },

    send: function(type, properties) {
      if (!properties) properties = {};
      properties.$type = type;

      var p = this.encodePacket('Client', properties);
      if (!p) return this;

      var log = extend({}, properties);
      log.$time = new Date;
      log.$side = 'Client';
      this.log.push(log);

      if (this.socket.readyState !== 1) {
        this.queue.push(p);
        return this;
      }

      if (this.rawPacketLog) {
        console.log('C->S:', p);
      }
      if (this.livePacketLog) {
        this.logPacket(log);
      }

      this.socket.send(p);

      return this;
    },

    close: function() {
      this.socket.onclose = null;
      this.socket.close();
    },


    init: function() {
      this.rawPacketLog = false;
      this.livePacketLog = false;
      this.verbosePackets = false;

      this.connected = false;
      this.log = [];

      this.requestMap = {};

      this.reopenDelay = Socket.INITIAL_REOPEN_DELAY;
      this.open();
    },


    onOpen: function() {
      var queue = this.queue;
      this.queue = [];

      this.connected = true;
      this.reopenDelay = Socket.INITIAL_REOPEN_DELAY;

      while (encoded = queue.shift()) {
        if (this.rawPacketLog) {
          console.log('C->S:', p);
        }
        if (this.livePacketLog) {
          this.logPacket(this.log[this.log.length - queue.length]);
        }
        this.socket.send(encoded);
      }
    },

    onClose: function() {
      this.connected = false;
      console.warn('Lost connection.');

      setTimeout(this.open.bind(this), this.reopenDelay);
      if (this.reopenDelay < 5 * 60 * 1000) {
        this.reopenDelay *= 2;
      }
    },

    onMessage: function(e) {
      if (this.rawPacketLog) {
        console.log('S->C:', e.data);
      }

      var p = this.decodePacket('Server', e.data);
      if (!p) return;

      p.$time = new Date;
      p.$side = 'Server';

      if (this.livePacketLog) {
        this.logPacket(p);
      }

      if (p.$type === 'result' || p.$type === 'requestError') {
        var request = this.popRequest(p.request$id);
        if (request) {
          if (p.$type === 'result') {
            request.promise.fulfill(p.result);
          } else {
            request.promise.reject(p);
          }
        }
      } else {
        this.emit(p.$type, p);
      }
    },

    onError: function(e) {
      console.warn('Socket error:', e);
    },


    open: function() {
      this.socket = new WebSocket(this.socketURL);
      this.socket.onopen = this.onOpen.bind(this);
      this.socket.onclose = this.onClose.bind(this);
      this.socket.onmessage = this.onMessage.bind(this);
      this.socket.onerror = this.onError.bind(this);
      this.queue = [];
    },

    popRequest: function(id) {
      var request = this.requestMap[id];

      if (!request) {
        console.warn('Invalid request ID:', p);
        return;
      }

      delete this.requestMap[id];
      return request;
    },

    encodePacket: function(side, p) {
      if (this.verbosePackets) {
        return JSON.stringify(p);
      }

      unimplemented();
    },

    decodePacket: function(side, p) {
      try {
        p = JSON.parse(p);
      } catch (e) {
        console.warn('Packet syntax error:', p);
        return;
      }

      if (!isObject(p)) {
        console.warn('Invalid packet:', p);
        return;
      }

      if (!isArray(p)) {
        return p;
      }

      unimplemented();
    },

    logPacket: function(p) {
      console.groupCollapsed(format('[%] %:%', p.$time.toLocaleTimeString(), p.$side, p.$type));
      this.logObject(p, true);
      console.groupEnd();
    },

    logObject: function(object, dollar) {
      for (var key in object) if (hasOwnProperty.call(object, key) && (!dollar || key.charAt(0) !== '$')) {
        if (isObject(object[key])) {
          console.group(key);
          this.logObject(object[key]);
          console.groupEnd();
        } else {
          console.log(key + ':', object[key]);
        }
      }
    }

  });

  model('Server', {

    data: {
      connected: {},
      user: {}
    },

    properties: {
      url: { apply: 'applyURL' },
      token: { apply: 'applyToken' },

      assetStoreURL: function() {
        return 'http://' + this.url + 'api/asset/';
      },

      socketURL: function() {
        return 'ws://' + this.url;
      }
    },

    getAssetURL: function(hash) {
      return this.assetStoreURL + hash + '/';
    },

    getUser: function(name) {
      if (this.userMap[name]) {
        return Promise().fulfill(this.userMap[name]);
      }
      return this.request('users.user', { user: name }).then(function(data) {
        return data && this.createUser(data);
      }.bind(this));
    },


    init: function() {
      this.socket = null;
      this.token = localStorage.getItem('Amber.Server.token');
      this.userMap = {};
    },


    applyURL: function() {
      if (this.socket) {
        this.socket.close();
      }
      this.socket = Socket({ url: this.socketURL });
    },

    applyToken: function(token) {
      localStorage.setItem('Amber.Server.token', token);
    },

    createUser: function(data) {
      if (this.userMap[data.name]) {
        return this.userMap[data.name];
      }

      var user = User({
        server: this
      });
      user.fromJSON(data);
      this.userMap[user.name] = user;
      return user;
    },

    connect: function(p) {
      this.user = p.user && this.createUser(p.user);
      this.token = p.token;
    }

  });


/*
  var routes = {
    '/': 'Homepage'
  };

  view('Homepage', {

    template: 'amber-homepage',

    subscribe: ['userChanged'],

    init: function (model) {
      ['featured', 'topRemixed', 'topLoved', 'topViewed'].forEach(function(v) {
        this[v] = view.Carousel(model.collection(v));
      }, this);

      this.userChanged(model);
    },

    userChanged: function(model) {
      this.hasUser = !!model.user;
      this.news = view.Activity(model.activity('all'));
      ['byFollowing', 'lovedByFollowing'].forEach(function(v) {
        this[v] = model.user && view.Carousel(model.collection('user.' + v));
      }, this);
    }

  });
*/

  return {
    unimplemented: unimplemented,
    inherits: inherits,
    defineSetter: defineSetter,
    defineGetter: defineGetter,
    defineEvented: defineEvented,
    getUID: getUID,
    isObject: isObject,
    isFunction: isFunction,
    isArray: isArray,
    extend: extend,
    addClass: addClass,
    removeClass: removeClass,
    toggleClass: toggleClass,
    hasClass: hasClass,
    format: format,
    escapeXML: escapeXML,
    bbTouch: bbTouch,
    inBB: inBB,
    Base: Base,
    Promise: Promise,
    Locale: Locale,
    Event: Event,
    TouchEvent: TouchEvent,
    WheelEvent: WheelEvent,
    // User: User,
    model: model
  };

})();
