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


  function Base() {}

  Base.prototype.on = function(name, handler) {
    var k = '$l_' + name;
    if (this[k]) {
      this[k].push(handler);
    } else {
      this[k] = [handler];
    }
    return this;
  };

  Base.prototype.once = function(name, handler) {
    return this.on(name, function listener() {
      handler.apply(null, arguments);
      this.removeListener(name, listener);
    }.bind(this));
  };

  Base.prototype.removeListener = function(name, handler) {
    var k = '$l_' + name;
    if (this[k]) {
      var i = this[k].indexOf(handler);
      this[k].splice(i, 1);
    }
    return this;
  };

  Base.prototype.removeAllListeners = function(name) {
    delete this['$l_' + name];
    return this;
  };

  Base.prototype.listeners = function(name) {
    return this['$l_' + name] || [];
  };

  Base.prototype.emit = function(name) {
    var listeners = this['$l_' + name];
    if (listeners) {
      var args = slice.call(arguments, 1);
      for (var i = 0; i < listeners.length; i++) {
        listeners[i].apply(null, args);
      }
    }
    return this;
  };

  Base.prototype.set = function(data) {
    for (var key in data) if (hasOwnProperty.call(data, key)) {
      this[key] = data[key];
    }
    return this;
  };


  inherits(Promise, Base);
  function Promise() {
    this.complete = false;
  }

  Promise.prototype.isPromise = true;

  Promise.prototype.on = function(event, handler) {
    if ((event === 'success' || event === 'failure') && this.complete) {
      if (event === 'success' && this.success) {
        handler.apply(null, this.results);
      } else if (event === 'failure' && !this.success) {
        handler(this.reason);
      }
    } else {
      Base.prototype.on.call(this, event, handler);
    }
  };

  Promise.prototype.then = function(success, failure) {
    var promise = new Promise;

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
  };

  Promise.prototype.fulfill = function() {
    if (this.complete) return;
    this.complete = true;
    this.success = true;
    var args = slice.call(arguments);
    this.results = args;
    this.emit.apply(this, ['success'].concat(args));
    this.emit.apply(this, ['resolve', null].concat(args));
    return this;
  };

  Promise.prototype.reject = function(err) {
    if (this.complete) return;
    this.complete = true;
    this.success = false;
    this.reason = err;
    this.emit('failure', err);
    this.emit('resolve', err);
    return this;
  };

  Promise.all = function() {
    var components = slice.call(arguments);
    var all = new Promise;
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
  };

  Promise.some = function() {
    var components = slice.call(arguments);
    var some = new Promise;
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
  };

  Promise.any = function() {
    var components = slice.call(arguments);
    var any = new Promise;
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
  };


  inherits(Locale, Base);
  function Locale(id, name) {
    this.id = id;
    this.name = name;
  }

  Locale.strings = {};
  Locale.current = 'en-US';

  Locale.list = [
    new Locale('en-US', 'English (US)'),
    new Locale('en-PT', 'Pirate-speak')
  ];

  Locale.getText = function(id) {
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
  };

  Locale.maybeGetText = function(trans) {
    return trans && trans.$ ? getText(trans.$) : trans;
  };

  Locale.getList = function(list) {
    return (Locale.strings[Locale.current].__list || Locale.strings['en-US'].__list)(list);
  };

  Locale.getPlural = function(a, b, n) {
    return n === 1 ? Locale.getText(b, n) : Locale.getText(a, n);
  };


  var T = Locale.getText;
  T.maybe = Locale.maybeGetText;
  T.list = Locale.getList;
  T.plural = Locale.getPlural;


  inherits(Event, Base);
  function Event() {}

  Event.prototype.fromDOM = function(e) {
    this.alt = e.altKey;
    this.ctrl = e.ctrlKey;
    this.meta = e.metaKey;
    this.shift = e.shiftKey;
  };


  inherits(PropertyEvent, Event);
  function PropertyEvent(object, value, previousValue) {
    this.object = object;
    this.value = value;
    this.previousValue = previousValue;
  }


  inherits(ControlEvent, Event);
  function ControlEvent(control) {
    this.control = control;
  }


  inherits(TouchEvent, Event);
  function TouchEvent() {}

  TouchEvent.prototype.fromTouch = function(e, touch) {
    this.fromDOM(e);
    this.x = touch.clientX;
    this.y = touch.clientY;
    this.id = touch.identifier || 0;
    this.radiusX = touch.radiusX != null ? touch.radiusX : 10;
    this.radiusY = touch.radiusY != null ? touch.radiusY : 10;
    this.angle = touch.rotationAngle || 0;
    this.force = touch.force != null ? touch.force : 1;
    return this;
  };

  TouchEvent.prototype.fromMouse = function(e) {
    this.fromDOM(e);
    this.x = e.clientX;
    this.y = e.clientY;
    this.id = -1;
    this.radiusX = .5;
    this.radiusY = .5;
    this.angle = 0;
    this.force = 1;
    return this;
  };


  inherits(WheelEvent, Event);
  function WheelEvent() {
    this.allowDefault = false;
    this.x = 0;
    this.y = 0;
  }

  WheelEvent.prototype.fromWebkit = function(e) {
    this.fromDOM(e);
    this.x = -e.wheelDeltaX / 3;
    this.y = -e.wheelDeltaY / 3;
    return this;
  };

  WheelEvent.prototype.fromMoz = function(e) {
    this.fromDOM(e);
    this.x = 0;
    this.y = e.detail;
    return this;
  };


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


  inherits(Server, Base);
  function Server(url) {
    this.url = url;
    this.rawPacketLog = false;
    this.livePacketLog = false;
    this.verbosePackets = false;

    this.connected = false;
    this.log = [];

    this.$token = localStorage.getItem('Amber.Server.token');

    this.requestMap = {};
    this.userMap = {};

    this.reopenDelay = Server.INITIAL_REOPEN_DELAY;
    this.open();
  }

  Server.INITIAL_REOPEN_DELAY = 100;

  Server.REQUEST_ERRORS = [
    'Not found',
    'Incorrect credentials'
  ];

  Server.CENSORED_FIELDS = {
    'Client:auth.signIn': ['password']
  };

  defineGetter(Server.prototype, 'socketURL', function() {
    return 'ws://' + this.url;
  });

  defineGetter(Server.prototype, 'assetStoreURL', function() {
    return 'http://' + this.url + 'api/asset/';
  });

  Server.prototype.getAssetURL = function(hash) {
    return this.assetStoreURL + hash + '/';
  };

  defineSetter(Server.prototype, 'token', function(token) {
    localStorage.setItem('Amber.Server.token', token);
  });

  Server.prototype.send = function(type, properties) {
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
  };

  Server.prototype.request = function(type, options) {
    if (!options) {
      options = {};
    }

    var promise = new Promise;

    var id = getUID();
    this.requestMap[id] = {
      type: type,
      options: options,
      promise: promise
    };

    options.request$id = id;
    this.send(type, options);

    return promise;
  };

  Server.prototype.getUser = function(name) {
    if (this.userMap[name]) {
      return new Promise().fulfill(this.userMap[name]);
    }
    return this.request('users.user', { user: name }).then(function(data) {
      return data && this.createUser(data);
    }.bind(this));
  };


  Server.prototype.on = {
    connect: function(p) {
      this.user = p.user && this.createUser(p.user);
      this.token = p.token;
    },

    result: function(p) {
      var request = this.popRequest(p.request$id);
      if (request) {
        request.promise.fulfill(p.result);
      }
    },

    requestError: function(p) {
      var request = this.popRequest(p.request$id);
      if (request) {
        console.error(format('Request error: % in %', Server.REQUEST_ERRORS[p.reason], request.type), request.options);
        request.promise.reject(p);
      }
    }
  };


  Server.prototype.onOpen = function() {
    var queue = this.queue;
    this.queue = [];

    this.connected = true;
    this.reopenDelay = Server.INITIAL_REOPEN_DELAY;

    var p = {
      $type: 'connect'
    };

    var encoded = this.encodePacket('Client', p);
    if (this.rawPacketLog) {
      console.log('C->S:', encoded);
    }
    this.socket.send(encoded);

    p.$time = new Date;
    p.$side = 'Client';
    this.log.splice(this.log.length - queue.length, 0, p);

    if (this.livePacketLog) {
      this.logPacket(p);
    }

    while (encoded = queue.shift()) {
      if (this.rawPacketLog) {
        console.log('C->S:', p);
      }
      if (this.livePacketLog) {
        this.logPacket(this.log[this.log.length - queue.length - 1]);
      }
      this.socket.send(encoded);
    }
  };

  Server.prototype.onClose = function() {
    this.connected = false;
    console.warn('Lost connection.');

    setTimeout(this.open.bind(this), this.reopenDelay);
    if (this.reopenDelay < 5 * 60 * 1000) {
      this.reopenDelay *= 2;
    }
  };

  Server.prototype.onMessage = function(e) {
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

    if (hasOwnProperty.call(this.on, p.$type)) {
      this.on[p.$type].call(this, p);
    }
    this.emit(p.$type, p);
  };

  Server.prototype.onError = function(e) {
    console.warn('Socket error:', e);
  };


  Server.prototype.popRequest = function(id) {
    var request = this.requestMap[id];

    if (!request) {
      console.warn('Invalid request ID:', p);
      return;
    }

    delete this.requestMap[id];
    return request;
  };

  Server.prototype.createUser = function(data) {
    if (this.userMap[data.name]) {
      return this.userMap[data.name];
    }

    var user = new User(this);
    user.fromJSON(data);
    this.userMap[user.name] = user;
    return user;
  };

  Server.prototype.open = function() {
    this.socket = new WebSocket(this.socketURL);
    this.socket.onopen = this.onOpen.bind(this);
    this.socket.onclose = this.onClose.bind(this);
    this.socket.onmessage = this.onMessage.bind(this);
    this.socket.onerror = this.onError.bind(this);
    this.queue = [];
  };

  Server.prototype.encodePacket = function(side, p) {
    if (this.verbosePackets) {
      return JSON.stringify(p);
    }

    unimplemented();
  };

  Server.prototype.decodePacket = function(side, p) {
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
  };

  Server.prototype.logPacket = function(p) {
    console.groupCollapsed(format('[%] %:%', p.$time.toLocaleTimeString(), p.$side, p.$type));
    this.logObject(p, true);
    console.groupEnd();
  };

  Server.prototype.logObject = function(object, dollar) {
    for (var key in object) if (hasOwnProperty.call(object, key) && (!dollar || key.charAt(0) !== '$')) {
      if (isObject(object[key])) {
        console.group(key);
        this.logObject(object[key]);
        console.groupEnd();
      } else {
        console.log(key + ':', object[key]);
      }
    }
  };





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
    PropertyEvent: PropertyEvent,
    ControlEvent: ControlEvent,
    TouchEvent: TouchEvent,
    WheelEvent: WheelEvent,
    User: User,
    Server: Server
  };

})();
