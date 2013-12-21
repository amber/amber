var Amber = (function(debug) {
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

  if (typeof console !== 'undefined') {
    ['error', 'warn', 'log', 'info', 'debug'].forEach(function(method) {
      console[method] = console[method].bind(console);
    });
  }


  function unimplemented() {
    debugger;
  }


  function extend(o, p) {
    for (var key in p) if (hasOwnProperty.call(p, key)) {
      o[key] = p[key];
    }
    return o;
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


  function nameFunction(f, name, scope) {
    if (!scope) scope = {};
    return f.name ? f : Function.apply(null, Object.keys(scope).concat('return function ' + name + '(' + f.toString().replace(/^.*?\(/, '') + ';')).apply(null, Object.keys(scope).map(function(key) { return scope[key] }));
  }

  function create(className, config) {
    function named(prefix, key, f, scope) {
      if (!debug) return f;
      if (!isFunction(f)) {
        scope = f;
        f = key;
        key = prefix;
        prefix = null;
      }
      return nameFunction(f, (className ? className + '_' : '') + (prefix ? prefix + '_' : '') + key, scope);
    }

    if (isObject(className)) {
      config = className;
      className = null;
    }

    var parent = config.extend || Base;
    delete config.extend;

    var outer = function() {
      var instance = new constructor;
      instance.construct.apply(instance, arguments);
      return instance;
    };
    var constructor = function () {};

    if (className && debug) {
      constructor = nameFunction(constructor, className);
      outer = nameFunction(outer, className, { constructor: constructor });
    }

    constructor.prototype = Object.create(parent ? parent.prototype : Object.prototype);
    constructor.prototype.constructor = constructor;

    outer.prototype = constructor.prototype;

    if (config.init) {
      var superInit = parent && parent.prototype.init;
      var init = config.init;
      delete config.init;

      constructor.prototype.init = superInit ? named('init', function() {
        superInit.apply(this, arguments);
        init.apply(this, arguments);
      }, { superInit: superInit, init: init }) : init;
    }

    if (config.finalize) {
      var superFinalize = parent && parent.prototype.finalize;
      var finalize = config.finalize;
      delete config.finalize;

      constructor.prototype.finalize = superFinalize ? named('finalize', function() {
        superFinalize.apply(this, arguments);
        finalize.apply(this, arguments);
      }, { superFinalize: superFinalize, finalize: finalize }) : finalize;
    }

    if (config.data) {
      var data = config.data;
      delete config.data;

      Object.keys(data).forEach(function(key) {
        var k = '$d_' + key;

        constructor.prototype[k] = data[key].value === null ? undefined : data[key].value;

        Object.defineProperty(constructor.prototype, key, {
          get: named('get', key, function() {
            return this[k];
          }, { k: k }),
          set: named('set', key, function(value) {
            if (value === null) value = undefined;
            var previousValue = this[k];
            if (previousValue === value) return;
            this[k] = value;
            this.emit(key + 'Changed', Event({
              object: this,
              value: value,
              previousValue: previousValue
            }));
          }, { k: k, key: key, Event: Event })
        });
      });

      constructor.data = outer.data = extend(parent ? extend({}, parent.data) : {}, data);
    }

    if (config.properties) {
      var properties = config.properties;
      delete config.properties;

      Object.keys(properties).forEach(function(key) {
        var c = properties[key];

        if (isFunction(c)) {
          Object.defineProperty(constructor.prototype, key, { get: c });
        } else if (c.apply) {
          var k = '$p_' + key;
          var apply = c.apply;

          Object.defineProperty(constructor.prototype, key, {
            get: named('get', key, function() {
              return this[k];
            }, { k: k }),
            set: named('set', key, function(value) {
              if (value === null) value = undefined;
              var old = this[k];
              if (old === value) return;
              this[k] = value;
              this[apply](value, old);
            }, { apply: apply, k: k })
          });
        }
      });

      constructor.properties = outer.properties = extend(parent ? extend({}, parent.properties) : {}, properties);
    }

    if (config.statics) {
      var statics = config.statics;
      delete config.statics;

      extend(outer, statics);
    }

    extend(constructor.prototype, config);

    return outer;
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


    construct: function(c) {
      this.init();
      if (c) this.set(c);
      this.finalize();
    },
    init: function() {},
    finalize: function() {}

  });

  var Promise = create('Promise', {

    isPromise: true,

    on: function(event, handler) {
      if ((event === 'success' || event === 'failure' || event === 'complete') && this.complete) {
        if (event === 'success' && this.success) {
          handler.apply(null, this.results);
        } else if (event === 'failure' && !this.success) {
          handler(this.reason);
        } else if (event === 'complete') {
          handler.apply(null, this.success ? [null].concat(this.results) : [this.reason]);
        }
      } else {
        Base.prototype.on.call(this, event, handler);
      }
      return this;
    },

    then: function(success, failure, context) {
      if (!isFunction(failure)) {
        context = failure;
        failure = null;
      }

      var promise = Promise();

      this.on('success', function(result) {
        result = success && success.apply(context, arguments) || result;
        if (result && result.isPromise) {
          result.then(promise.fulfill, promise.reject);
        } else {
          promise.fulfill(result);
        }
      });
      this.on('failure', function(err) {
        if (failure) failure.call(context, err);
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
      this.emit.apply(this, ['complete', null].concat(args));
      return this;
    },

    reject: function(err) {
      if (this.complete) return;
      this.complete = true;
      this.success = false;
      this.reason = err;
      this.emit('failure', err);
      this.emit('complete', err);
      return this;
    },

    statics: {

      fulfilled: function() {
        return this({
          complete: true,
          success: true,
          results: slice.call(arguments)
        });
      },

      rejected: function(err) {
        return this({
          complete: true,
          success: false,
          reason: err
        });
      },

      all: function() {
        var components = slice.call(arguments);
        var all = this();
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
        var some = this();
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
        var any = this();
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


  function http(method, url, body) {
    if (!url) {
      url = method;
      method = 'GET';
    }

    var promise = Promise();

    var xhr = new XMLHttpRequest;
    xhr.open(method, url, true);

    xhr.onload = function() {
      if (xhr.status === 200) {
        promise.fulfill(xhr.responseText);
      } else {
        promise.reject(xhr);
      }
    };

    xhr.onerror = function(e) {
      promise.reject(xhr);
    };

    xhr.send(body);

    return promise;
  }


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


  var Socket = create('Socket', {

    data: {
      url: {},
      connected: { value: false }
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

      options.request = id;
      this.send(type, options);

      return promise;
    },

    watch: function(model, type, options) {
      var promise = this.request(type, options);

      model.watch = options.request;
      this.watchMap[model.watch] = model;

      return promise.then(function(data) {
        return model.fromJSON(data);
      });
    },

    unwatch: function(model) {
      if (!model.watch) return;

      delete this.watchMap[model.watch];
      this.send('unwatch', { watch: model.watch });

      delete model.watch;
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
      return this;
    },

    connect: function() {
      this.socket = this.createSocket();
      this.socket.onopen = this.onOpen.bind(this);
      this.socket.onclose = this.onClose.bind(this);
      this.socket.onmessage = this.onMessage.bind(this);
      this.socket.onerror = this.onError.bind(this);
      this.queue = [];
    },


    init: function() {
      this.rawPacketLog = false;
      this.livePacketLog = false;
      this.verbosePackets = false;

      this.connected = false;
      this.log = [];

      this.requestMap = {};
      this.watchMap = {};

      this.reopenDelay = Socket.INITIAL_REOPEN_DELAY;
    },


    onOpen: function() {
      var queue = this.queue;
      this.queue = [];

      this.connected = true;
      this.reopenDelay = Socket.INITIAL_REOPEN_DELAY;

      var p;
      while (p = queue.shift()) {
        if (this.rawPacketLog) {
          console.log('C->S:', p);
        }
        if (this.livePacketLog) {
          this.logPacket(this.log[this.log.length - queue.length - 1]);
        }
        this.socket.send(p);
      }
      this.emit('open', Event({ object: this }));
    },

    onClose: function(e) {
      if (this.connected) {
        this.emit('close', Event({ object: this }));
      }
      this.connected = false;
      console.warn('Lost connection.', e);

      setTimeout(this.connect.bind(this), this.reopenDelay);
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

      this.log.push(p);

      if (this.livePacketLog) {
        this.logPacket(p);
      }

      if (p.$type === 'result' || p.$type === 'requestError') {
        var request = this.popRequest(p.request);
        if (request) {
          if (p.$type === 'result') {
            request.promise.fulfill(p.result);
          } else {
            request.promise.reject(p);
          }
        }
      } else if (p.$type === 'update') {
        if (this.watchMap[p.watch]) {
          this.watchMap[p.watch].update(p.data);
        } else {
          console.warn('Invalid watcher ID:', p.watch);
        }
      } else {
        this.emit(p.$type, p);
      }
    },

    onError: function(e) {
      console.warn('Socket error:', e);
    },


    popRequest: function(id) {
      var request = this.requestMap[id];

      if (!request) {
        console.warn('Invalid request ID:', id);
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
    },

    createSocket: function() {
      return new WebSocket(this.url);
    }

  });


  var Server = create('Server', {

    data: {
      connected: { value: false },
      user: {}
    },

    properties: {
      url: {},
      token: { apply: 'applyToken' },
      lastUser: { apply: 'applyLastUser' },
      socket: { apply: 'applySocket' },

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

    signIn: function(user, password) {
      return this.socket.request('auth.signIn', {
        user: user,
        password: password
      }).then(function(data) {
        this.user = data && this.makeUserInfo(data, user);
        return this.user;
      }, this);
    },

    signOut: function() {
      return this.socket.request('auth.signOut').then(function() {
        this.user = null;
      }, this);
    },

    getProject: function(id) {
      if (this.projectMap[id]) {
        return Promise.fulfilled(this.projectMap[id]);
      }
      return this.socket.watch(this.makeProject(id), 'project', {
        project: id
      });
    },

    createProject: function() {
      return this.socket.request('project.create');
    },

    getUser: function(name) {
      if (this.userMap[name]) {
        return Promise.fulfilled(this.userMap[name]);
      }
      return this.socket.watch(this.makeUser(name), 'user', {
        user: name
      });
    },

    getUserInfo: function(name) {
      if (this.userInfoMap[name]) {
        return Promise.fulfilled(this.userInfoMap[name]);
      }
      return this.socket.request('user.info', {
        user: name
      }).then(function(data) {
        return data && this.makeUserInfo(data, name);
      }, this);
    },

    getList: function(contents) {
      return WatchList({
        server: this,
        contents: contents
      });
    },

    getModel: function(type, data) {
      if (type === 'date') {
        return new Date(data);
      }
      return this['get' + type.charAt(0).toUpperCase() + type.slice(1)](data);
    },


    connect: function(config) {
      if (this.socket) {
        this.socket.set(config || {});
      } else {
        this.socket = Socket(extend({
          url: this.socketURL
        }, config || {}));
      }

      this.socket.connect();

      return this;
    },

    applySocket: function(socket, old) {
      if (old) {
        old.close();
      }

      Object.keys(this.handle).forEach(function(event) {
        socket.on(event, this.handle[event].bind(this));
      }, this);
    },


    init: function() {
      this.socket = null;
      this.token = localStorage.getItem('Amber.token') || null;
      this.lastUser = localStorage.getItem('Amber.lastUser') || null;
      this.userInfoMap = {};
      this.userMap = {};
      this.projectMap = {};
    },


    handle: {

      open: function() {
        this.socket.send('connect', {
          token: this.token,
          user: this.lastUser
        });
      },

      close: function() {
        this.connected = false;
      },

      connect: function(p) {
        this.connected = true;
        this.user = p.user && this.makeUserInfo(p.user, this.lastUser);
        this.token = p.token;
      }
    },


    applyToken: function(token) {
      localStorage.setItem('Amber.token', token);
    },

    applyLastUser: function(lastUser) {
      localStorage.setItem('Amber.lastUser', lastUser);
    },

    makeUserInfo: function(data, name) {
      if (this.userInfoMap[name]) {
        return this.userInfoMap[name];
      }

      return UserInfo({
        name: name,
        scratchId: data.scratchId,
        group: data.group || 'default'
      });
    },

    makeUser: function(name) {
      if (this.userMap[name]) {
        return this.userMap[name];
      }

      return this.userMap[name] = model.User({
        server: this,
        name: name
      });
    },

    makeProject: function(id) {
      if (this.projectMap[id]) {
        return Promise.fulfilled(this.projectMap[id]);
      }

      return this.projectMap[id] = model.Project({
        server: this,
        id: id
      });
    }
  });


  var UserInfo = create('UserInfo', {});


  function model(name, config) {
    config.extend = config.extend || model.Model;
    model[name] = create(name, config);
  }


  model('Model', {

    extend: Base,

    isModel: true,


    fromJSON: function(data) {
      Object.keys(data).forEach(function(key) {
        var config = this.constructor.data[key];
        if (config && config.type) {
          this[key] = this.server.getModel(config.type, data[key])
        } else {
          this[key] = data[key];
        }
      }, this);
      return this;
    },

    update: function(data) {
      Object.keys(data).forEach(function(key) {
        this.updateKey(key, data[key]);
      }, this);
      return this;
    },

    updateKey: function(key, data) {
      if (this[key].isPromise) {
        this[key].then(function(model) {
          model.update(data[key]);
        });
      } else if (this[key].isModel) {
        this[key].update(data[key]);
      } else {
        this[key] = data[key];
      }
    },

    destroy: function() {
      if (this.watch) {
        this.server.socket.unwatch(this);
      }
      Object.keys(this.constructor.data).forEach(function(key) {
        if (this[key] && this[key].isModel) {
          this[key].destroy();
        }
      }, this);
    }

  });


  var ListChangeType = {
    ADD: 1,
    CHANGE: 2,
    REMOVE: 3
  };

  var WatchList = create('WatchList', {

    data: {
      contents: {}
    },

    update: function(data) {
      data.forEach(this.updateTuple, this);
    },

    updateTuple: function(u) {
      var i = u[1];
      var x = u[2];
      switch (u[0]) {
        case ListChangeType.ADD:
          if (i >= this.contents.length) return;
          if (i === this.contents.length) {
            this.contents.push(x);
            return;
          }
          this.insert(i, x);
          return;
        case ListChangeType.CHANGE:
          if (i >= this.contents.length) return;
          this.contents[i] = x;
          return;
        case ListChangeType.REMOVE:
          this.contents.splice(i, 1);
          return;
      }
    }

  });


  model('User', {

    data: {
      scratchId: {},
      group: { value: 'default' },
      about: {},
      featuredProject: { type: 'project' },
      activity: { type: 'activity' },
      projects: { type: 'collection' },
      lovedProjects: { type: 'collection' },
      collections: { type: 'list' },
      followers: { type: 'list' },
      following: { type: 'list' },
      topic: { type: 'topic' },
      isFollowing: { type: 'boolean' }
    },

    properties: {

      avatarURL: function() {
        var id = '' + this.scratchId;
        return format("http://scratch.mit.edu/static/site/users/avatars/%/%.png", id.slice(0, -4), id.slice(-4));
      },

      profileURL: function() {
        return urls.reverse('user profile', this.name);
      }
    },

    statics: {

      ADMINISTRATOR: 'administrator',
      MODERATOR: 'moderator',
      DEFAULT: 'default',
      LIMITED: 'limited'
    },

    avatarURLOfSize: function(size) {
      return format("http://cdn.scratch.mit.edu/get_image/user/%1_%2x%2.png", this.scratchId, size);
    }
  });


  model('Project', {

    data: {
      name: {},
      authors: { type: 'list' },
      created: { type: 'date' },
      modified: { type: 'date' },
      thumbnail: {},
      notes: {},
      topic: { type: 'topic' },
      scriptCount: {},
      spriteCount: {},
      viewCount: {},
      loveCount: {},
      remixCount: {},
      activity: { type: 'activity' },
      tags: { type: 'list' },
      remixes: { type: 'collection' },
      collections: { type: 'list' },
      isLoved: {}
    },

    properties: {

      thumbnailURL: function() {
        return this.server.getAssetURL(this.thumbnail);
      }
    },

    view: function() {
      return this.server.socket.send('project.view', {
        project: this.id
      });
    },

    love: function() {
      return this.server.socket.send('project.love', {
        project: this.id
      });
    },

    addTag: function(name) {
      return this.server.socket.send('project.addTag', {
        project: this.id,
        tag: name
      });
    },

    removeTag: function(name) {
      return this.server.socket.send('project.removeTag', {
        project: this.id,
        tag: name
      });
    }
  });


  function view(name, config) {
    config.extend = config.extend || view.View;

    if (config.template) {
      var template = config.template;
      delete config.template;
    }

    if (config.events) {
      config.events = Object.keys(config.events).map(function(description) {
        var parts = description.trim().split(/\s+/);
        return {
          event: parts[0],
          name: parts[1],
          handler: config.events[description]
        };
      });
      var superEvents = config.extend && config.extend.prototype.events;
      if (superEvents) {
        config.events = config.events.concat(superEvents);
      }
    }

    var v = create(name, config);

    if (template) {
      if (template.charAt(0) === '<') {
        v.prototype.template = Template({
          prototype: v.prototype,
          source: template
        });
      } else {
        v.prototype.template = Template.getTemplate(template, v.prototype).then(function(template) {
          v.prototype.template = template;
          return template;
        });
      }
    }

    view[name] = v;
    return v;
  }


  var Template = create('Template', {

    install: function(instance) {

      instance.el = this.el.cloneNode(true);

      for (var i = 0; i < this.references.length; i++) {
        var ref = this.references[i];

        var el = instance.el;
        for (var j = 0; j < ref.path.length; j++) {
          el = el.childNodes[ref.path[j]];
        }

        instance[ref.name] = el;
      }
    },


    statics: {

      getTemplate: function(id, prototype) {
        if (Template.cache) {
          return Promise.fulfilled(Template.getCached(id, prototype));
        }

        if (!Template.httpRequest) {
          Template.httpRequest = http('static/templates.html');
        }

        return Template.httpRequest.then(function(result) {
          Template.cache = document.createElement('div');
          Template.cache.innerHTML = result;

          return Template.getCached(id, prototype);
        });
      },


      getCached: function(id, prototype) {
        var el = Template.cache.querySelector('[id=' + JSON.stringify(id) + ']');
        return el && Template({
          el: el,
          prototype: prototype
        });
      }
    },


    init: function() {
      this.references = [];
    },

    finalize: function() {
      if (!this.el) {
        var d = document.createElement('div');
        d.innerHTML = this.source;
        this.el = d.children[0];
      }

      this.renderNode(this.el);
    },

    addReference: function(name, el) {
      var path = [];

      while (el !== this.el) {
        var p = el.parentNode;
        if (!p) throw new Error("Can't add a reference to an orphan");

        var i = [].indexOf.call(p.childNodes, el);
        path.push(i);

        el = p;
      }

      path.reverse();
      this.references.push({
        name: name,
        path: path
      });
    },

    renderNode: function(el) {
      if (el.nodeType === 3) {

        var text = el.nodeValue;
        var changed = false;
        for (;;) {
          var x = /^([^]*?)\{\{\s*(\w+)\s*\}\}/.exec(text);

          if (!x) {
            if (changed) el.nodeValue = text;
            break;
          }

          changed = true;
          el.parentNode.insertBefore(document.createTextNode(x[1]), el);

          (function(name) {

            var k = '$v_' + name;
            var ck = '$c_' + name;

            var container = document.createElement('span');
            el.parentNode.insertBefore(container, el);
            this.addReference(ck, container);

            Object.defineProperty(this.prototype, name, {
              set: function(value) {
                if (this[k]) {
                  this[ck].removeChild(this[k].el);
                }
                this[ck].style.display = value ? 'inline' : 'none';
                if (value) {
                  value.use(function() {
                    this[ck].appendChild(value.el);
                  }.bind(this));
                }
                this[k] = value;
              },
              get: function() {
                return this[k];
              }
            });
          }).call(this, x[2]);

          text = text.slice(x[0].length);
        }

      } else if (el.nodeType === 1) {

        var id = el.dataset.id;
        if (id) this.addReference(id, el);

        var nodes = el.childNodes;
        for (var i = 0; i < nodes.length; i++) {
          this.renderNode(nodes[i]);
        }
      }
    }

  });


  view('View', {

    extend: Base,

    template: '<div></div>',

    subscribe: [],
    events: {},


    use: function(cb) {
      this.promise.then(cb);
      return this;
    },


    construct: function(model, c) {
      this.promise = Promise();

      this.init();
      if (c) this.set(c);
      this.finalize();

      if (model.isPromise) {
        model.then(function(model) {
          this.constructWithModel(model, c);
        }.bind(this));
      } else {
        this.constructWithModel(model);
      }
    },

    constructWithModel: function(model, c) {
      this.model = model;

      this.subscribe.forEach(function(event) {
        model.on(event, function(e) {
          this[event](model, e);
        }.bind(this));
      }, this);

      if (this.template.isPromise) {
        this.template.then(function(template) {
          this.constructWithTemplate(template, c);
        }.bind(this));
      } else {
        this.constructWithTemplate(this.template, c);
      }
    },

    constructWithTemplate: function(template, c) {
      template.install(this);

      this.events.forEach(function(e) {
        var handler = typeof e.handler === 'string' ? this[e.handler] : e.handler;
        this[e.name].addEventListener(e.event, handler.bind(this));
      }, this);

      this.render(this.model);

      this.promise.fulfill(this);
    }
  });


  view('Key', {

    template: '<span></span>',

    construct: function(model, key, config) {
      this.key = key;
      view.View.prototype.construct.call(this, model, config);
    },

    render: function(model) {
      model.on(this.key + 'Changed', this.keyChanged.bind(this));
      this.keyChanged();
    },

    keyChanged: function() {
      this.el.textContent = this.model[this.key];
    }

  });


  view('App', {

    template: 'amber-app',

    routes: {

      '/': 'Homepage',
      '/hello': 'HelloWorld'
    },

    render: function(model) {
      this.compiledRoutes = [];
      for (var url in this.routes) if (this.routes.hasOwnProperty(url)) {
        var names = [];
        var source = '^' + url.replace(/:(\w+)/g, function(_, name) {
          names.push(name);
          return '[^/]+';
        }) + '$';
        this.compiledRoutes.push({
          template: url,
          regex: new RegExp(source),
          names: names,
          view: this.routes[url]
        });
      }

      this.route();
      window.addEventListener('hashchange', this.route.bind(this));
    },

    route: function() {
      var url = this.url = location.pathname;
      for (var i = 0; i < this.compiledRoutes.length; i++) {
        var route = this.compiledRoutes[i];

        var x = route.regex.exec(url);
        if (x) {

          var dict = {};
          for (var j = 0; j < route.names.length; j++) {
            dict[route.names[j]] = x[j + 1];
          }

          this.page = view[route.view].call(this, this.model, dict);

          return;
        }
      }

      this.page = view.NotFound.call(this, this.model, {
        requestURL: url
      });
    }

  });


  view('NotFound', {

    template: 'amber-notfound',

    render: function() {
      this.url.textContent = this.requestURL;
    }

  });


  view('Homepage', {

    template: 'amber-homepage',

    subscribe: ['userChanged'],

    render: function (model) {
      ['featured', 'topRemixed', 'topLoved', 'topViewed'].forEach(function(v) {
        this[v] = view.Carousel(model.getCollection(v));
      }, this);

      this.userChanged(model);
    },

    userChanged: function(model) {
      this.hasUser = !!model.user;
      this.news = view.Activity(model.getActivity('all'));
      ['byFollowing', 'lovedByFollowing'].forEach(function(v) {
        this[v] = model.user && view.Carousel(model.getCollection('user.' + v));
      }, this);
    }
  });


  view('HelloWorld', {

    template: 'amber-helloworld',

    render: function(model) {

    }

  });


  function host(el, view) {
    view.use(function() {
      addClass(el === document.body ? document.documentElement : el, 'amber-host');
      addClass(view.el, 'amber-hosted');

      el.appendChild(view.el);
    });
  }


  return {
    unimplemented: unimplemented,
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
    create: create,
    Base: Base,
    Promise: Promise,
    Locale: Locale,
    Event: Event,
    TouchEvent: TouchEvent,
    WheelEvent: WheelEvent,
    Server: Server,
    Socket: Socket,
    model: model,
    view: view,
    host: host
  };

})(true);
