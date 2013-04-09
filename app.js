(function (global) {
    var Function = global.Function;
    var Array = global.Array;

    var d = global.d = {};

    if (!Function.prototype.bind) {
        Function.prototype.bind = function (context) {
            var f = this;
            return function () {
                return f.apply(context, arguments);
            };
        };
    }

    d.addClass = function (element, className) {
        if ((' ' + element.className + ' ').indexOf(' ' + className + ' ') === -1) element.className += (element.className ? ' ' : '') + className;
    };
    d.removeClass = function (element, className) {
        var i = (' ' + element.className + ' ').indexOf(' ' + className + ' ');
        if (i !== -1) element.className = element.className.substr(0, i - 1) + element.className.substr(i + className.length);
    };
    d.toggleClass = function (element, className, on) {
        if (on) {
            d.addClass(element, className);
        } else {
            d.removeClass(element, className);
        }
    };
    d.format = function (format) {
        var args = arguments,
            i = 1;
        return format.replace(/%([1-9]\d*)?/g, function (_, n) {
            return n ? args[n] : args[i++];
        });
    };
    d.htmle = function (string) {
        return string.replace(/&/g, '&amp;').replace(/</, '&lt;').replace(/>/, '&gt;').replace(/"/, '&quot;');
    };
    d.htmlu = function (string) {
        return string.replace(/&lt;/, '<').replace(/&gt;/, '>').replace(/&quot;/, '"').replace(/&amp;/g, '&');
    };
    d.bbTouch = function (element, e) {
        var bb = element.getBoundingClientRect();
        return e.x + e.radiusX >= bb.left && e.x - e.radiusX <= bb.right &&
            e.y + e.radiusY >= bb.top && e.y - e.radiusY <= bb.bottom;
    };
    d.inBB = function (e, bb) {
        return e.x + e.radiusX >= bb.left && e.x - e.radiusX <= bb.right &&
            e.y + e.radiusY >= bb.top && e.y - e.radiusY <= bb.bottom;
    };
    d.property = function (object, name, options) {
        var setName = 'set' + name[0].toUpperCase() + name.substr(1),
            _name = '_' + name,
            event = options.event,
            setter = options.hasOwnProperty('set') ?
                options.set :
                function (value) {
                    this[_name] = value;
                },
            getter = options.hasOwnProperty('get') ?
                options.get :
                function () {
                    return this[_name];
                },
            apply = options.apply;

        if (options.hasOwnProperty('value'))
            object[_name] = options.value;

        object[setName] = function (value) {
            var old = this[_name];
            setter.call(this, value);
            if (apply && old !== value) apply.call(this, value, old);
            if (event) this.dispatch(event, new d.PropertyEvent().setObject(this));
            return this;
        };
        object[name] = getter;
    };
    d.Class = function (extend, members, statics) {
        var constructor = members.init || extend.prototype.init,
            klass = function () {
                constructor.apply(this, arguments);
            },
            key, v;
        if (extend) klass.prototype = Object.create(extend.prototype);
        klass.prototype.constructor = klass;
        for (key in members) if (members.hasOwnProperty(key)) {
            if (key[0] === '@') {
                (function (key) {
                    var low = key[0].toLowerCase() + key.substr(1);
                    klass.prototype['on' + key] = function (listener, context) {
                        this.listen(key, listener, context);
                        return this;
                    };
                    klass.prototype['un' + key] = function (listener) {
                        this.unlisten(key, listener);
                        return this;
                    };
                    klass.prototype[low + 'Listeners'] = function () {
                        return this.listeners(key);
                    };
                })(key.substr(1));
                continue;
            }
            if (key[0] === '.') {
                d.property(klass.prototype, key.substr(1), members[key]);
                continue;
            }
            if (typeof (v = members[key]) === 'function')
                v.base = extend && extend.prototype[key];
            klass.prototype[key] = v;
        }
        if (statics) for (key in statics) if (statics.hasOwnProperty(key)) {
            if (typeof (v = statics[key]) === 'function')
                v.base = extend && extend[key];
            klass[key] = v;
        }
        return klass;
    };
    d.Base = d.Class(null, {
        init: function () {},
        base: function (args) {
            return args.callee.base.apply(this, [].slice.call(arguments, 1));
        },
        listen: function (name, handler, context) {
            var key = '$listeners_' + name;
            (this[key] || (this[key] = [])).push({
                listener: handler,
                context: context || this
            });
            return this;
        },
        unlisten: function (name, handler) {
            var a = this[key = '$listeners_' + name],
                i;
            if (!a) return this;

            i = a.length;
            while (i--) {
                if (a[i].listener === handler) {
                    a.splice(i, 1);
                    break;
                }
            }
            return this;
        },
        listeners: function (name) {
            return this['$listeners_' + name] || [];
        },
        dispatch: function (name, event) {
            var a = this[key = '$listeners_' + name],
                listener, i;
            if (!a) return this;

            i = a.length;
            while (i--) {
                listener = a[i];
                listener.listener.call(listener.context, event);
            }
            return this;
        },
    });
    d.Event = d.Class(d.Base, {
        setEvent: function (e) {
            this.alt = e.altKey;
            this.ctrl = e.ctrlKey;
            this.meta = e.metaKey;
            this.shift = e.shiftKey;
            return this;
        },
        withProperties: function (properties) {
            var key;
            for (key in properties) if (properties.hasOwnProperty(key)) {
                this[key] = properties[key];
            }
            return this;
        }
    });
    d.PropertyEvent = d.Class(d.Event, {
        '.object': {}
    });
    d.ControlEvent = d.Class(d.Event, {
        '.control': {}
    });
    d.TouchEvent = d.Class(d.Event, {
        setTouchEvent: function (e, touch) {
            this.setEvent(e);
            this.x = touch.clientX;
            this.y = touch.clientY;
            this.id = 'identifier' in touch ? touch.identifier : 0;
            this.radiusX = 'radiusX' in touch ? touch.radiusX : 10;
            this.radiusY = 'radiusX' in touch ? touch.radiusY : 10;
            this.angle = 'rotationAngle' in touch ? touch.rotationAngle : 0;
            this.force = 'force' in touch ? touch.force : 1;
            return this;
        },
        setMouseEvent: function (e) {
            this.setEvent(e);
            this.x = e.clientX;
            this.y = e.clientY;
            this.id = -1;
            this.radiusX = .5;
            this.radiusY = .5;
            this.angle = 0;
            this.force = 1;
            return this;
        }
    });
    d.WheelEvent = d.Class(d.Event, {
        '.allowDefault': {},
        setWebkitEvent: function (e) {
            this.setEvent(e);
            this.x = -e.wheelDeltaX / 3;
            this.y = -e.wheelDeltaY / 3;
            return this;
        },
        setMozEvent: function (e) {
            this.setEvent(e);
            this.x = 0;
            this.y = e.detail;
            return this;
        }
    });
    d.Control = d.Class(d.Base, {
        init: function () {
            this.children = [];
        },

        '@TouchStart': null,
        '@TouchMove': null,
        '@TouchEnd': null,
        '@ContextMenu': null,
        '@ScrollWheel': null,
        '@DragStart': null,

        '@Live': null,

        initElements: function (elementClass, containerClass, isFlat) {
            this.element = this.newElement(elementClass);
            if (containerClass) {
                this.container = this.newElement(containerClass);
                if (!isFlat) this.element.appendChild(this.container);
            } else {
                this.container = this.element;
            }
            return this;
        },
        newElement: function (className, tagName) {
            var el = document.createElement(tagName || 'div');
            el.control = this;
            if (className) el.className = className;
            return el;
        },
        '.selectable': {
            value: false,
            apply: function (selectable) {
                d.toggleClass(this.element, 'd-selectable', selectable);
            }
        },
        add: function (child) {
            if (child.parent) {
                child.parent.remove(child);
            }
            this.children.push(child);
            child.parent = this;
            this.container.appendChild(child.element);
            child.becomeLive();
            return this;
        },
        becomeLive: function () {
            var children = this.children, i = 0, child;
            if (!this.isLive) {
                this.dispatch('Live', new d.ControlEvent().setControl(this));
                this.isLive = true;
            }
            while (child = children[i++]) {
                child.becomeLive();
            }
        },
        clear: function () {
            var children = this.children, i = 0, child;
            while (child = children[i++]) {
                child.parent = null;
            }
            this.children = [];
            this.container.innerHTML = '';
            return this;
        },
        addClass: function (className) {
            d.addClass(this.element, className);
            return this;
        },
        removeClass: function (className) {
            d.removeClass(this.element, className);
            return this;
        },
        toggleClass: function (className, on) {
            d.toggleClass(this.element, className, on);
        },
        remove: function (child) {
            this.children.splice(this.children.indexOf(child), 1);
            child.parent = null;
            this.container.removeChild(child.element);
            return this;
        },
        replace: function (oldChild, newChild) {
            if (newChild.parent) {
                newChild.parent.remove(newChild);
            }
            this.children.splice(this.children.indexOf(oldChild), 1, newChild);
            oldChild.parent = null;
            newChild.parent = this;
            this.container.replaceChild(newChild.element, oldChild.element);
            newChild.becomeLive();
            return this;
        },
        insert: function (newChild, beforeChild) {
            var i = this.children.indexOf(beforeChild);
            if (newChild.parent) {
                newChild.parent.remove(newChild);
            }
            this.children.splice(i === -1 ? this.children.length : i, 0, newChild);
            newChild.parent = this;
            this.container.insertBefore(newChild.element, beforeChild && beforeChild.element);
            newChild.becomeLive();
            return this;
        },
        hasChild: function (child) {
            var i = 0, ch;
            if (this === child) return true;
            while (ch = this.children[i++]) {
                if (ch.hasChild(child)) return true;
            }
            return false;
        },
        dispatchTouchEvents: function (type, e) {
            var touches = e.changedTouches,
                i = touches.length;
            while (i--) {
                this.dispatch(type, new d.TouchEvent().setTouchEvent(e, touches[i]));
            }
            return this;
        },
        hoistTouchStart: function (e) {
            var control = this;
            while (control = control.parent) {
                if (control.acceptsClick) {
                    this.app().mouseDownControl = control;
                    control.dispatch('TouchStart', e);
                    return;
                }
            }
        },
        app: function () {
            return this.parent && this.parent.app();
        },
        amber: function () {
            return this.parent && this.parent.amber();
        },
        hide: function () {
            this.element.style.display = 'none';
            return this;
        },
        show: function () {
            this.element.style.display = '';
            return this;
        },
        visible: function () {
            return this.element.style.display !== 'none';
        },
        setVisible: function (visible) {
            this.element.style.display = visible ? '' : 'none';
            return this;
        },
        childrenSatisfying: function (predicate) {
            var a = [];
            function add(control) {
                var i = 0, child;
                if (predicate(control)) {
                    a.push(control);
                }
                while (child = control.children[i++]) {
                    add(child);
                }
            }
            add(this);
            return a;
        },
        anyParentSatisfies: function (predicate) {
            var control = this;
            do {
                if (predicate(control)) return true;
            } while (control = control.parent);
            return false;
        }
    });
    d.Label = d.Class(d.Control, {
        init: function (className) {
            this.base(arguments);
            this.initElements(className || 'd-label');
        },
        '.text': {
            get: function () {
                return this.element.textContent;
            },
            set: function (text) {
                this.element.textContent = text;
            }
        },
        '.richText': {
            get: function () {
                return this.element.innerHTML;
            },
            set: function (richText) {
                this.element.innerHTML = richText;
            }
        }
    });
    d.App = d.Class(d.Control, {
        MENU_CLICK_TIME: 250,
        acceptsClick: true,

        app: function () {
            return this;
        },
        '.menu': {
            apply: function (menu) {
                this.menuOriginX = this.mouseX;
                this.menuOriginY = this.mouseY;
                this.menuStart = this.mouseStart;
                this.add(menu);
            }
        },
        touchMoveEvent: function () {
            return new d.TouchEvent().setMouseEvent(this.lastMouseEvent);
        },
        setElement: function (element) {
            var app = this,
                shouldStartDrag = false;
            this.element = this.container = element;
            element.control = this;
            d.addClass(element, 'd-app');
            element.addEventListener('touchstart', function (e) {
                var t = e.target;
                if (t.nodeType === 3) t = t.parentNode;
                if (app._menu && !app._menu.hasChild(t.control)) app._menu.close();
                c = t.control;
                while (c && !c.acceptsClick) {
                    c = c.parent;
                }
                if (!c) return;
                shouldStartDrag = true;
                t.control.dispatchTouchEvents('TouchStart', e);
                e.preventDefault();
            }, true);
            element.addEventListener('touchmove', function (e) {
                var t = e.target;
                if (t.nodeType === 3) t = t.parentNode;
                if (shouldStartDrag) {
                    t.control.dispatchTouchEvents('DragStart', e);
                    shouldStartDrag = false;
                }
                t.control.dispatchTouchEvents('TouchMove', e);
                e.preventDefault();
            }, true);
            element.addEventListener('touchend', function (e) {
                var t = e.target;
                if (t.nodeType === 3) t = t.parentNode;
                t.control.dispatchTouchEvents('TouchEnd', e);
                e.preventDefault();
            }, true);
            element.addEventListener('contextmenu', function (e) {
                if (e.shiftKey || e.target.tagName === 'INPUT' && !e.target.control.isMenu) return;
                e.preventDefault();
            }, true);
            element.addEventListener('mousedown', function (e) {
                var c;
                app.lastMouseEvent = e;
                if (app.mouseDown) return;
                document.addEventListener('mousemove', mousemove, true);
                document.addEventListener('mouseup', mouseup, true);
                if (app._menu && !app._menu.hasChild(e.target.control)) app._menu.close();
                if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') return;
                c = e.target.control;
                while (c && !c.acceptsClick) {
                    if (c.selectable()) return;
                    c = c.parent;
                }
                if (!c) return;
                if (e.button === 2) {
                    c.dispatch('ContextMenu', new d.TouchEvent().setMouseEvent(e));
                    return;
                } else {
                    app.mouseDown = shouldStartDrag = true;
                    app.mouseDownControl = c;

                    app.mouseX = e.clientX;
                    app.mouseY = e.clientY;
                    app.mouseStart = +new Date;
                    c.dispatch('TouchStart', new d.TouchEvent().setMouseEvent(e));
                }
                document.activeElement.blur();
                e.preventDefault();
            }, true);
            function mousemove(e) {
                app.lastMouseEvent = e;
                if (!app.mouseDown || !app.mouseDownControl) return;
                if (shouldStartDrag) {
                    app.mouseDownControl.dispatch('DragStart', new d.TouchEvent().setMouseEvent(e));
                    shouldStartDrag = false;
                }
                app.mouseDownControl.dispatch('TouchMove', new d.TouchEvent().setMouseEvent(e));
                // e.preventDefault();
            }
            function mouseup(e) {
                var not = !app.mouseDown || !app.mouseDownControl,
                    control = app.mouseDownControl;
                app.lastMouseEvent = e;
                app.mouseDown = false;
                app.mouseDownControl = undefined;
                if (not) return;
                if (app._menu && app._menu.hasChild(e.target.control)) {
                    dx = app.mouseX - app.menuOriginX;
                    dy = app.mouseY - app.menuOriginY;
                    if (dx * dx + dy * dy < 4 && +new Date - app.menuStart <= app.MENU_CLICK_TIME) {
                        app.menuStart -= 100;
                        return;
                    }
                }
                control.dispatch('TouchEnd', new d.TouchEvent().setMouseEvent(e));
                // e.preventDefault();
            }
            function mousewheel(f) {
                return function (e) {
                    var t = e.target, event;
                    while (!t.control) {
                        t = t.parentNode;
                        if (!t) return;
                    }
                    t = t.control;
                    while (t && !t.acceptsScrollWheel) {
                        t = t.parent;
                        if (!t) return;
                    }
                    t.dispatch('ScrollWheel', event = new d.WheelEvent()[f](e));
                    if (!event.allowDefault()) e.preventDefault();
                };
            }
            element.addEventListener('mousewheel', mousewheel('setWebkitEvent'), true);
            element.addEventListener('MozMousePixelScroll', mousewheel('setMozEvent'), true);
            return this;
        }
    });
    d.Menu = d.Class(d.Control, {
        TYPE_TIMEOUT: 500,
        acceptsScrollWheel: true,
        acceptsClick: true,
        scrollY: 0,
        isMenu: true,

        '@Execute': {},
        '@Close': {},

        init: function () {
            this.base(arguments);
            this.onScrollWheel(this.scroll);
            this.menuItems = [];
            this.clearSearch = this.clearSearch.bind(this);

            this.initElements('d-menu', 'd-menu-contents');

            this.element.appendChild(this.search = this.newElement('d-menu-search', 'input'));
            this.search.addEventListener('blur', this.refocus.bind(this));
            this.search.addEventListener('keydown', this.controlKey.bind(this));
            this.search.addEventListener('input', this.typeKey.bind(this));

            this.element.insertBefore(this.upIndicator = this.newElement('d-menu-indicator d-menu-up'), this.container);
            this.element.appendChild(this.downIndicator = this.newElement('d-menu-indicator d-menu-down'));
            this.targetElement = this.container;
            window.addEventListener('resize', this.resize = this.resize.bind(this));
        },
        '.transform': {
            value: function (item) {
                return typeof item === 'string' ? {
                        action: item,
                        title: item
                    } : {
                        action: item.action,
                        title: item.title,
                        state: item.state
                    };
            }
        },
        '.items': {
            apply: function (items) {
                var i = 0, item;
                while (item = items[i], i++ < items.length) {
                    this.addItem(item);
                }
            }
        },
        '.target': {},
        addItem: function (item) {
            if (item === d.Menu.separator) {
                this.add(new d.MenuSeparator());
                return;
            }
            this.menuItems.push(item = new d.MenuItem().load(this, this._transform(item)));
            item.index = this.menuItems.length - 1;
            this.add(item);
        },
        activateItem: function (item) {
            if (this.activeItem) {
                d.removeClass(this.activeItem.element, 'd-menu-item-active');
            }
            if (this.activeItem = item) {
                d.addClass(item.element, 'd-menu-item-active');
            }
        },
        popUp: function (control, element, selectedItem) {
            var target, i, targetBB, elementBB;
            if (typeof selectedItem === 'number') {
                target = this.menuItems[selectedItem];
            } else if (typeof selectedItem === 'string' || typeof selectedItem === 'object') {
                i = 0;
                while (target = this.menuItems[i++]) {
                    if (target.action() === selectedItem || selectedItem.$ && target.action().$ === selectedItem.$) break;
                }
            } else {
                throw new TypeError;
            }
            elementBB = element.getBoundingClientRect();
            control.app().setMenu(this);
            if (target) target.setState('checked');
            if (target = target || this.menuItems[0]) target.activate();
            targetBB = (target || this).targetElement.getBoundingClientRect();
            this.element.style.left = elementBB.left - targetBB.left + 'px';
            this.element.style.top = elementBB.top - targetBB.top + 'px';
            this.layout();
            return this;
        },
        popDown: function (control, element, selectedItem) {
            var target, targetBB, elementBB;
            if (typeof selectedItem === 'number') {
                target = this.menuItems[selectedItem];
            } else if (typeof selectedItem === 'string') {
                i = 0;
                while (target = this.menuItems[i++]) {
                    if (target.action() === selectedItem) break;
                }
            }
            if (target) target.setState('checked');
            elementBB = element.getBoundingClientRect();
            control.app().setMenu(this);
            this.element.style.left = elementBB.left + 'px';
            this.element.style.top = elementBB.bottom + 'px';
            this.layout();
            return this;
        },
        show: function (control, position) {
            control.app().setMenu(this);
            this.element.style.left = position.x + 'px';
            this.element.style.top = position.y + 'px';
            this.layout();
            return this;
        },
        scroll: function (e) {
            var top = parseFloat(this.element.style.top),
                max, bottom, delta;
            this.viewHeight = parseFloat(getComputedStyle(this.element).height);
            max = this.container.offsetHeight - this.viewHeight;
            this.scrollY = Math.max(0, Math.min(max, this.scrollY + e.y));
            if (top > 4 && max > 0) {
                this.scrollY -= top - (top = Math.max(4, top - this.scrollY));
                this.element.style.top = top + 'px';
            }
            if (max > 0 && top + this.element.offsetHeight < window.innerHeight - 4) {
                this.element.style.maxHeight = this.viewHeight + max - this.scrollY + 'px';
                this.scrollY = max = this.container.offsetHeight - (this.viewHeight + max - this.scrollY);
            }
            this.upIndicator.style.display = this.scrollY > 0 ? 'block' : 'none';
            this.downIndicator.style.display = this.scrollY < max ? 'block' : 'none';
            this.container.style.top = '-' + this.scrollY + 'px';
        },
        resize: function () {
            var top, height;
            this.scroll(new d.WheelEvent().withProperties({ x: 0, y: 0 }));
            top = parseFloat(this.element.style.top);
            height = this.element.offsetHeight;
            if (top + height + 4 > window.innerHeight) {
                this.element.style.top = Math.max(4, window.innerHeight - height - 4) + 'px';
            }
        },
        layout: function () {
            var maxHeight = parseFloat(getComputedStyle(this.element).height),
                left = parseFloat(this.element.style.left),
                top = parseFloat(this.element.style.top),
                width = this.element.offsetWidth,
                height;
            this.element.style.maxHeight = maxHeight + 'px';
            if (top < 4) {
                this.container.style.top = '-' + (this.scrollY = 4 - top) + 'px';
                this.element.style.maxHeight = (maxHeight -= 4 - top) + 'px';
                this.element.style.top = (top = 4) + 'px';
            }
            if (left < 4) this.element.style.left = (left = 4) + 'px';
            if (left + width + 4 > window.innerWidth) this.element.style.left = (left = Math.max(4, window.innerWidth - width - 4)) + 'px';
            this.element.style.bottom = '4px';
            this.viewHeight = parseFloat(getComputedStyle(this.element).height);
            height = this.element.offsetHeight;
            if (top + height + 4 > window.innerHeight) {
                this.element.style.top = (top = Math.max(4, window.innerHeight - height - 4)) + 'px';
            }
            if (this.viewHeight < maxHeight) {
                this.downIndicator.style.display = 'block';
            }
            if (this.scrollY > 0) {
                this.upIndicator.style.display = 'block';
            }
            setTimeout(function () {
                this.search.focus();
            }.bind(this));
        },
        execute: function (model) {
            if (this._target) {
                if (model.action instanceof Array) {
                    this._target[model.action[0]].apply(this._target, model.action.slice(1));
                } else {
                    this._target[model.action](model);
                }
                return this;
            }
            this.dispatch('Execute', new d.ControlEvent().setControl(this).withProperties({
                item: model
            }));
            return this;
        },
        close: function () {
            if (this.parent) {
                window.removeEventListener('resize', this.resize);
                this.parent.remove(this);
                this.dispatch('Close', new d.ControlEvent().setControl(this));
            }
        },
        clearSearch: function () {
            this.search.value = '';
            this.typeTimeout = undefined;
        },
        controlKey: function (e) {
            var item;
            switch (e.keyCode) {
            case 27:
                e.preventDefault();
                this.close();
                break;
            case 32:
                if (this.typeTimeout) break;
            case 13:
                e.preventDefault();
                if (this.activeItem) {
                    this.activeItem.accept();
                } else {
                    this.close();
                }
                break;
            case 38:
                e.preventDefault();
                if (this.activeItem) {
                    if (item = this.menuItems[this.activeItem.index - 1]) this.activateItem(item);
                } else {
                    this.activateItem(this.menuItems[this.menuItems.length - 1]);
                }
                this.clearSearch();
                break;
            case 40:
                e.preventDefault();
                if (this.activeItem) {
                    if (item = this.menuItems[this.activeItem.index + 1]) this.activateItem(item);
                } else {
                    this.activateItem(this.menuItems[0]);
                }
                this.clearSearch();
                break;
            }
        },
        typeKey: function () {
            var find = this.search.value.toLowerCase(),
                length = find.length,
                i = 0,
                item;
            if (this.typeTimeout) {
                clearTimeout(this.typeTimeout);
                this.typeTimeout = undefined;
            }
            if (find.length === 0) return;
            this.typeTimeout = setTimeout(this.clearSearch, this.TYPE_TIMEOUT);
            while (item = this.menuItems[i++]) {
                if (item.title().substr(0, length).toLowerCase() === find) {
                    item.activate();
                    return;
                }
            }
        },
        refocus: function () {
            this.search.focus();
        }
    }, {
        separator: {}
    });
    d.MenuItem = d.Class(d.Control, {
        acceptsClick: true,
        init: function () {
            this.base(arguments);
            this.initElements('d-menu-item');
            this.element.appendChild(this.state = this.newElement('d-menu-item-state'));
            this.element.appendChild(this.targetElement = this.label = this.newElement('d-menu-item-title'));
            this.onTouchEnd(this.touchEnd);
            this.element.addEventListener('mouseover', this.activate.bind(this));
            this.element.addEventListener('mouseout', this.deactivate.bind(this));
        },
        '.title': {
            get: function () {
                return this.label.textContent;
            },
            set: function (title) {
                this.label.textContent = title;
            }
        },
        '.action': {},
        '.state': {
            apply: function (state) {
                if (state === 'checked') d.addClass(this.state, 'd-menu-item-checked');
                if (state === 'radio') d.addClass(this.state, 'd-menu-item-radio');
                if (state === 'minimized') d.addClass(this.state, 'd-menu-item-minimized');
            }
        },
        load: function (menu, item) {
            this.menu = menu;
            this.model = item;
            if (item.hasOwnProperty('title')) this.setTitle(item.title);
            if (item.hasOwnProperty('action')) this.setAction(item.action);
            if (item.hasOwnProperty('state')) this.setState(item.state);
            return this;
        },
        touchEnd: function (e) {
            if (d.bbTouch(this.element, e)) {
                this.accept();
            }
        },
        activate: function () {
            var app = this.app();
            if (app) {
                app.mouseDownControl = this;
                this.parent.activateItem(this);
            }
        },
        deactivate: function () {
            var app = this.app();
            if (app) {
                app.mouseDownControl = undefined;
                this.parent.activateItem(null);
            }
        },
        accept: function () {
            this.menu.execute(this.model);
            this.menu.close();
        }
    });
    d.MenuSeparator = d.Class(d.Control, {
        init: function () {
            this.base(arguments);
            this.initElements('d-menu-separator');
        }
    });

    d.FormControl = d.Class(d.Control, {
        '@Focus': {},
        '@Blur': {},
        focus: function () {
            this.element.focus();
            return this;
        },
        blur: function () {
            this.element.blur();
            return this;
        },
        fireFocus: function () {
            this.dispatch('Focus', new d.ControlEvent().setControl(this));
        },
        fireBlur: function () {
            this.dispatch('Blur', new d.ControlEvent().setControl(this));
        },
        '.enabled': {
            get: function () {
                return !this.element.disabled;
            },
            set: function (enabled) {
                this.element.disabled = !enabled;
            }
        }
    });
    d.TextField = d.Class(d.FormControl, {
        '@Input': {},
        '@InputDone': {},
        '@KeyDown': {},
        INPUT_DONE_THRESHOLD: 300,
        TAG_NAME: 'input',
        init: function (className) {
            this.base(arguments);
            this.element = this.newElement(className || 'd-textfield', this.TAG_NAME);
            this._inputDone = this._inputDone.bind(this);
            this.element.addEventListener('input', function (e) {
                this.dispatch('Input', new d.ControlEvent().setControl(this));
                if (this._inputDoneTimer) clearTimeout(this._inputDoneTimer);
                this._inputDoneTimer = setTimeout(this._inputDone, this.INPUT_DONE_THRESHOLD);
            }.bind(this));
            this.element.addEventListener('keydown', function (e) {
                this.dispatch('KeyDown', new d.ControlEvent().setControl(this).withProperties({
                    keyCode: e.keyCode
                }));
            }.bind(this));
            this.element.addEventListener('focus', this.fireFocus.bind(this));
            this.element.addEventListener('blur', this.fireBlur.bind(this));
        },
        _inputDone: function () {
            this._inputDoneTimer = undefined;
            this.dispatch('InputDone', new d.ControlEvent().setControl(this));
        },
        select: function () {
            this.element.select();
            return this;
        },
        clear: function () {
            this.setText('');
        },
        '.text': {
            get: function () {
                return this.element.value;
            },
            set: function (text) {
                this.element.value = text;
            }
        },
        '.placeholder': {
            get: function () {
                return this.element.placeholder;
            },
            set: function (placeholder) {
                this.element.placeholder = placeholder;
            }
        }
    });
    d.TextField.Password = d.Class(d.TextField, {
        init: function (className) {
            this.base(arguments, className);
            this.element.type = 'password';
        }
    });
    d.TextField.Multiline = d.Class(d.TextField, {
        TAG_NAME: 'textarea'
    });
    d.Button = d.Class(d.FormControl, {
        acceptsClick: true,
        '@Execute': {},
        init: function (className) {
            this.base(arguments);
            this.element = this.container = this.newElement(className || 'd-button', 'button');
            this.onTouchEnd(function (e) {
                if (d.inBB(e, this.element.getBoundingClientRect())) {
                    this.dispatch('Execute', new d.ControlEvent().setControl(this));
                }
            });
            this.element.addEventListener('keyup', function (e) {
                if (e.keyCode === 32 || e.keyCode === 13) {
                    this.dispatch('Execute', new d.ControlEvent().setControl(this));
                }
            }.bind(this));
            this.element.addEventListener('focus', this.fireFocus.bind(this));
            this.element.addEventListener('blur', this.fireBlur.bind(this));
        },
        '.text': {
            get: function () {
                return this.element.textContent;
            },
            set: function (text) {
                this.element.textContent = text;
            }
        }
    });
    d.Checkbox = d.Class(d.Control, {
        acceptsClick: true,
        '@Change': {},
        init: function (className) {
            this.base(arguments);
            this.initElements('d-checkbox', 'label');
            this.element.appendChild((this.button = new d.Button('d-checkbox-button')
                .onExecute(function () {
                    this.setChecked(!this.checked());
                }, this)).element);
            this.element.appendChild(this.label = this.newElement('d-checkbox-label'));
            this.element.addEventListener('focus', this.fireFocus.bind(this));
            this.element.addEventListener('blur', this.fireBlur.bind(this));
            this.onTouchEnd(function (e) {
                if (d.inBB(e, this.element.getBoundingClientRect())) {
                    this.setChecked(!this.checked());
                }
            });
        },
        focus: function () {
            this.button.focus();
            return this;
        },
        '.checked': {
            event: 'Change',
            apply: function (checked) {
                d.toggleClass(this.button.element, 'd-checkbox-button-checked', checked);
            }
        },
        '.text': {
            get: function () {
                return this.label.textContent;
            },
            set: function (text) {
                this.label.textContent = text;
            }
        }
    });

    d.ProgressBar = d.Class(d.Control, {
        init: function () {
            this.base(arguments);
            this.initElements('d-progress');
            this.element.appendChild(this.bar = this.newElement('d-progress-bar'));
        },
        '.progress': {
            apply: function (progress) {
                this.bar.style.width = progress * 100 + '%';
            }
        }
    });

    d.Container = d.Class(d.Control, {
        init: function (className) {
            this.base(arguments);
            this.element = this.container = this.newElement(className || '');
        }
    });
    d.Form = d.Class(d.Container, {
        '@Submit': {},
        '@Cancel': {},
        init: function (className) {
            this.base(arguments, className);
            this.element.addEventListener('keydown', this.keydown.bind(this));
        },
        keydown: function (e) {
            if (e.keyCode === 13) {
                this.submit();
            }
            if (e.keyCode === 27) {
                this.cancel();
            }
        },
        submit: function () {
            this.dispatch('Submit', new d.ControlEvent().setControl(this));
        },
        cancel: function () {
            this.dispatch('Cancel', new d.ControlEvent().setControl(this));
        }
    });
    d.FormGrid = d.Class(d.Form, {
        init: function (className) {
            this.base(arguments, className || 'd-form-grid');
        },
        addField: function (label, field) {
            this.add(new d.Container('d-form-grid-row')
                .add(new d.Label('d-form-grid-label').setText(label))
                .add(new d.Container('d-form-grid-input')
                    .add(field)));
            return this;
        }
    });

    d.Dialog = d.Class(d.Control, {
        init: function () {
            this.base(arguments);
            this.initElements('d-dialog');
        },
        show: function (app) {
            app.setLightboxEnabled(true).add(this);
            this.layout();
            this.focus();
            return this;
        },
        close: function () {
            this.parent.setLightboxEnabled(false).remove(this);
        },
        focus: function () {
            function descend(child) {
                var i = 0, c;
                if (child.tagName === 'INPUT' || child.tagName === 'BUTTON' || child.tagName === 'TEXTAREA') {
                    child.focus();
                    return true;
                }
                while (c = child.childNodes[i++]) {
                    if (descend(c)) return true;
                }
            }
            descend(this.element);
        },
        layout: function () {
            this.element.style.marginLeft = this.element.offsetWidth * -.5 + 'px';
            this.element.style.marginTop = this.element.offsetHeight * -.5 + 'px';
        }
    });

    d.locale = {};
    d.ServerData = d.Class(d.Base, {
        init: function (amber) {
            this.base(arguments);
            this.amber = amber;
        },
        toJSON: function () {
            throw new Error('Unimplemented toJSON');
        },
        fromJSON: function () {
            throw new Error('Unimplemented fromJSON');
        }
    });
    d.User = d.Class(d.ServerData, {
        '.name': {
            apply: function (name) {
                this.amber.usersByName[name] = this;
            }
        },
        '.id': {
            apply: function (id) {
                this.amber.usersById[id] = this;
            }
        },
        '.rank': {
            value: 'default'
        },
        '.iconURL': {
            get: function () {
                return 'http://scratch.mit.edu/static/icons/buddy/' + this._id + '_sm.png';
            }
        },
        '.profileURL': {
            get: function () {
                return 'http://scratch.mit.edu/users/' + encodeURIComponent(this._name);
            }
        },
        toJSON: function () {
            var rank = this._rank,
                result = {
                    id: this._id,
                    name: this._name
                };
            if (rank !== 'default') result.rank = rank;
            return result;
        },
        fromJSON: function (o) {
            return this.setId(o.id).setName(o.name).setRank(o.rank || 'default');
        }
    });
    d.Project = d.Class(d.ServerData, {
        '.name': {},
        '.notes': {},
        '.stage': {},
        toJSON: function () {
            return {
                name: this._name,
                notes: this._notes,
                stage: this._stage
            }
        },
        fromJSON: function (o) {
            var amber = this.amber;
            return this.setName(o.name).setNotes(o.notes).setStage(new d.Stage(amber).fromJSON(o.stage));
        }
    });
    d.SoundMedia = d.Class(d.ServerData, {
        '.id': {},
        '.name': {},
        '.sound': {},
        fromJSON: function () {
            return this;
        }
    });
    d.ImageMedia = d.Class(d.ServerData, {
        '.name': {},
        '.image': {},
        '.text': {},
        '.centerX': {},
        '.centerY': {},
        '@ImageLoad': {},
        '@ImageChange': {},
        toJSON: function (o) {
            return {
                name: this._name,
                hash: this._hash,
                rotationCenterX: this._centerX,
                rotationCenterY: this._centerY
            };
        },
        fromJSON: function (o) {
            var canvas = document.createElement('canvas'),
                t = this;
            this.amber.loadImage('assets/' + o.hash + '/', function (img) {
                canvas.width = img.width;
                canvas.height = img.height;
                canvas.getContext('2d').drawImage(img, 0, 0);
                t.dispatch('ImageLoad', new d.ControlEvent().setControl(t));
            });
            return this.setName(o.name).setImage(canvas).setCenterX(o.rotationCenterX).setCenterY(o.rotationCenterY);
        }
    });
    d.Scriptable = d.Class(d.ServerData, {
        init: function (amber) {
            this.base(arguments, amber);
            this._filteredImage = document.createElement('canvas');
            this.onCostumeChange(this.updateFilteredImage);
        },
        '@CostumeChange': {},
        '.id': {
            apply: function (id) {
                this.amber.objects[id] = this;
            }
        },
        '.scripts': {
            get: function () {
                var editor = this._editor,
                    amber = this.amber;
                if (editor) return editor;
                this._editor = editor = new d.BlockEditor;
                if (this._scripts) this._scripts.forEach(function (a) {
                    var stack = new d.BlockStack().fromJSON(a, null, amber);
                    editor.add(stack);
                });
                return editor;
            }
        },
        '.costumes': {},
        '.costumeIndex': {
            apply: function () {
                if (this._costumes) this.dispatch('CostumeChange');
            }
        },
        '.sounds': {},
        '.currentCostume': {
            get: function () {
                return this._costumes[this._costumeIndex];
            }
        },
        '.filteredImage': {},
        updateFilteredImage: function () {
            var costume = this.currentCostume().image();
            this._filteredImage.width = costume.width;
            this._filteredImage.height = costume.height;
            this._filteredImage.getContext('2d').drawImage(costume, 0, 0);
        },
        variable: function (name) {
            return this._variables['v_' + name];
        },
        variables: function () {
            var array = [], name;
            for (name in this._variables) if (this._variables.hasOwnProperty(name)) {
                array.push(this._variables[name]);
            }
            return array;
        },
        variableNames: function () {
            var array = [], name;
            for (name in this._variables) if (this._variables.hasOwnProperty(name)) {
                array.push(name.substr(2));
            }
            return array;
        },
        hasVariable: function (name) {
            return this._variables.hasOwnProperty('var_' + name);
        },
        addVariable: function (name) {
            this._variables['v_' + name] = new d.Variable().setName(name).setValue('0');
            return this;
        },
        loadVariables: function (variables) {
            var o = this._variables = {};
            if (variables) variables.forEach(function (variable) {
                o['v_' + variable.name] = new d.Variable().fromJSON(variable);
            });
            return this;
        },
        loadCostumes: function (costumes) {
            if (costumes) this.setCostumes(costumes.map(function (a, i) {
                var image = new d.ImageMedia(this.amber).fromJSON(a);
                if (i === this._costumeIndex) {
                    image.onImageLoad(function () {
                        this.dispatch('CostumeChange', new d.PropertyEvent().setObject(this));
                    }, this);
                }
                return image;
            }, this));
            return this;
        }
    });
    d.Variable = d.Class(d.ServerData, {
        '.name': {},
        '.value': {},
        toJSON: function () {
            return {
                name: this._name,
                value: this._value
            };
        },
        fromJSON: function (o) {
            return this.setName(o.name).setValue(o.value);
        }
    });
    d.Stage = d.Class(d.Scriptable, {
        isStage: true,
        '.children': {},
        '.tempo': {},
        objectWithId: function (id) {
            var i, children, child;
            if (this.id() === id) {
                return this;
            }
            i = 0;
            children = this.children;
            while (child = children[i++]) {
                if (child.id() === id) return child;
            }
        },
        toJSON: function () {
            return {
                id: this._id,
                children: this._children,
                scripts: this._scripts,
                costumes: this._costumes,
                currentCostumeIndex: this._costumeIndex,
                sounds: this._sounds,
                tempo: this._tempo,
                variables: this.variables()
            };
        },
        fromJSON: function (o) {
            var t = this,
                amber = this.amber;
            this._scripts = o.scripts;
            this.setId(o.id).setCostumeIndex(o.currentCostumeIndex || 0).loadCostumes(o.costumes).loadVariables(o.variables).setSounds(o.sounds ? o.sounds.map(function (a) {
                return new d.SoundMedia(amber).fromJSON(a);
            }) : []).setTempo(o.tempo);
            amber.spriteList.addIcon(this);
            this.setChildren(o.children ? o.children.map(function (a) {
                return new d.Sprite(amber).setStage(t).fromJSON(a);
            }) : []);
            return this;
        }
    });
    d.Sprite = d.Class(d.Scriptable, {
        '@PositionChange': {},
        '.name': {},
        '.x': { event: 'PositionChange' },
        '.y': { event: 'PositionChange' },
        '.direction': { event: 'PositionChange' },
        '.rotationStyle': {},
        '.volume': {},
        '.size': {},
        '.visible': {},
        '.stage': {},
        toJSON: function () {
            return {
                id: this._id,
                objName: this._name,
                scripts: this._scripts,
                costumes: this._costumes,
                costumeIndex: this._costumeIndex,
                sounds: this._sounds,
                scratchX: this._x,
                scratchY: this._y,
                direction: this._direction,
                rotationStyle: this._rotationStyle,
                volume: this._volume,
                variables: this.variables()
            };
        },
        fromJSON: function (o) {
            var amber = this.amber;
            this._scripts = o.scripts;
            this.setId(o.id).setName(o.objName).setCostumeIndex(o.currentCostumeIndex || 0).loadCostumes(o.costumes).loadVariables(o.variables).setSounds(o.sounds ? o.sounds.map(function (a) {
                return new d.SoundMedia(amber).fromJSON(a);
            }) : []).setX(o.scratchX).setY(o.scratchY).setDirection(o.direction).setRotationStyle(o.rotationStyle).setVolume(o.volume).setSize(o.scale).setVisible(o.visible);
            amber.spriteList.addIcon(this);
            return this;
        }
    });

    d.Locale = d.Class(d.Base, {
        init: function (id, name) {
            this.base(arguments);
            this.setId(id).setName(name);
        },
        '.id': {},
        '.name': {}
    });
    d.currentLocale = 'en-US';
    d.locales = [
        new d.Locale('en-US', 'English (US)'),
        new d.Locale('en-PT', 'Pirate-speak')
    ];
    d.t = function (id) {
        var locale = d.locale[d.currentLocale],
            result;
        if (!locale.hasOwnProperty(id)) {
            if (d.currentLocale !== 'en-US') {
                console.warn('missing translation key "' + id + '"');
            }
            result = id;
        } else {
            result = locale[id];
        }
        return arguments.length === 1 ? result : d.format.apply(null, [result].concat([].slice.call(arguments, 1)));
    };
    d.t.maybe = function (trans) {
        if (trans && trans.$) {
            return d.t(trans.$);
        }
        return trans;
    };
    d.t.list = function (list) {
        return (d.locale[d.currentLocale].__list || d.locale['en-US'].__list)(list);
    };
    d.t.plural = function (a, b, n) {
        return n === 1 ? d.t(b, n) : d.t(a, n);
    };
    d.Amber = d.Class(d.Control, {
        PROTOCOL_VERSION: '1.1.5',

        init: function () {
            this.base(arguments);
            this.usersByName = {};
            this.usersById = {};
            this.blocks = {};
            this.objects = {};
            this.element = this.container = this.newElement('d-amber d-collapse-user-panel');
            this.element.appendChild(this.lightbox = this.newElement('d-lightbox'));
            this.preloader = new d.Dialog().addClass('d-preloader')
                .add(this._progressLabel = new d.Label())
                .add(this._progressBar = new d.ProgressBar());
            this.add(this.spritePanel = new d.SpritePanel(this))
                .setLightboxEnabled(true);
            this.spriteList.hide();
            this.spritePanel.setToggleVisible(false);
            document.addEventListener('keydown', this.keyDown.bind(this));
        },
        amber: function () {
            return this;
        },
        keyDown: function (e) {
            var none = e.target === document.body;
            switch (e.keyCode) {
            case 32:
                if (none) {
                    this.chat.show();
                    e.preventDefault();
                }
                break;
            case 27:
                if (none || e.target === this.chat.input) {
                    this.userPanel.setCollapsed(true);
                    e.preventDefault();
                }
                break;
            }
        },
        createSocket: function (server, callback) {
            this.socket = new d.Socket(this, server, callback);
        },
        newScriptID: 0,
        createScript: function (x, y, blocks) {
            var id = ++this.newScriptID,
                tracker = [],
                script = new d.BlockStack().fromJSON([x, y, blocks], tracker);
            if (this.tabBar.selectedIndex !== 0) this.tabBar.select(0);
            this.socket.newScripts[id] = tracker;
            this.editor().add(script);
            this.socket.send({
                $: 'script.create',
                script: [x, y, blocks],
                request$id: id,
                object$id: this.selectedSprite().id()
            });
            return script;
        },
        getUser: function (username, callback) {
            var xhr, me = this;
            if (this.usersByName[username]) return callback(this.usersByName[username]);
            xhr = new XMLHttpRequest();
            xhr.open('GET', 'http://scratch.mit.edu/api/getinfobyusername/' + encodeURIComponent(username), true);
            xhr.onload = function () {
                callback(new d.User(me).setName(username).setId(xhr.responseText.split(':')[1]));
            };
            xhr.onerror = function () {
                callback(new d.User(me).setName(username).setId(-1));
            };
            xhr.send();
        },
        getUserById: function (id, callback) {
            var xhr, me = this;
            if (this.usersById[id]) return callback(this.usersById[id]);
            xhr = new XMLHttpRequest();
            xhr.open('GET', 'http://scratch.mit.edu/api/getusernamebyid/' + encodeURIComponent(id), true);
            xhr.onload = function () {
                callback(new d.User(me).setName(xhr.responseText.replace(/^\s+|\s+$/g, '')).setId(id));
            };
            xhr.onerror = function () {
                callback(new d.User(me).setName('Unknown User').setId(id));
            };
            xhr.send();
        },
        initEditMode: function (element) {
            var t = this,
                stage = this.project().stage();
            t.editorLoaded = true;
            t.add(t._tab = new d.BlockEditor())
                .add(t.palette = new d.BlockPalette())
                .add(t.userPanel = new d.UserPanel(t))
                .add(t.tabBar = new d.TabBar(t));
            this.selectSprite(stage.children()[0] || stage);

            for (name in d.BlockSpecs) if (d.BlockSpecs.hasOwnProperty(name)) {
                category = new d.BlockList();
                d.BlockSpecs[name].forEach(function (spec) {
                    var block;
                    if (spec === '-') {
                        category.addSpace();
                    } else if (spec[0] === '&') {
                        category.add(new d.Button().setText(spec[2]).onExecute(function () {
                            t[spec[1]]();
                        }));
                    } else {
                        category.add(d.Block.fromSpec(spec));
                    }
                });
                t.palette.addCategory(name, category);
            };
            return this;
        },
        createVariable: function () {
            var dialog, name;
            dialog = new d.Dialog()
                .add(name = new d.TextField()
                    .setPlaceholder(d.t('Variable Name')))
                .add(new d.Checkbox()
                    .setText(d.t('For this sprite only')))
                .add(new d.Button()
                    .setText(d.t('OK'))
                    .onExecute(function () {
                        var sprite = this.selectedSprite(),
                            variable = name.text();
                        dialog.close();
                        if (/^\s*$/.test(variable) || sprite.hasVariable(variable)) {
                            return;
                        }
                        sprite.addVariable(variable);
                        this.socket.send({
                            $: 'variable.create',
                            object$id: sprite.id(),
                            name: variable
                        });
                    }, this))
                .add(new d.Button()
                    .setText(d.t('Cancel'))
                    .onExecute(function () {
                        dialog.close();
                    }))
                .show(this);
        },
        '.lightboxEnabled': {
            apply: function (lightboxEnabled) {
                this.lightbox.style.display = lightboxEnabled ? 'block' : 'none';
            }
        },
        '.preloaderEnabled': {
            apply: function (preloaderEnabled) {
                if (!this.preloader.parent) this.preloader.show(this);
                this.preloader.setVisible(preloaderEnabled);
                this.setLightboxEnabled(preloaderEnabled);
            }
        },
        '.offline': {
            apply: function (offline) {
                if (offline) {
                    this.socket = new d.OfflineSocket(this);
                }
            }
        },
        '.editor': {},
        '.tab': {
            apply: function (tab, old) {
                this.remove(old);
                this.add(tab);
                if (tab.fit) tab.fit();
            }
        },
        '.selectedSprite': {},
        objectWithId: function (id) {
            return this.objects[id];
        },
        selectSprite: function (object) {
            this.setSelectedSprite(object);
            this.setEditor(object.scripts());
            this.tabBar.children[1].setText(d.t(object.isStage ? 'Backdrops' : 'Costumes'));
            this.tabBar.select(this.tabBar.selectedIndex || 0);
            this.spriteList.select(object);
        },
        '.project': {
            set: function (project) {
                this.setPreloaderEnabled(true);
                this.setProgressText(d.t('Loading resources…'));
                this._project = project = new d.Project(this).fromJSON(project);
                this.stageView.setModel(project.stage());
            }
        },
        '.projectId': {},
        doneLoading: function () {
            this.setPreloaderEnabled(false);
        },
        isBlockVisible: function (block) {
            var scripts = this.selectedSprite().scripts();
            return block.anyParentSatisfies(function (parent) {
                return parent === scripts;
            });
        },
        activeRequests: [],
        updateProgress: function () {
            var p = 0, i = this.activeRequests.length;
            while (i--) {
                p += this.activeRequests[i].progress;
            }
            this.setProgress(p / this.activeRequests.length);
            if (p === this.activeRequests.length) {
                this.doneLoading();
            }
        },
        load: function (method, url, body, callback) {
            var t = this, req = {progress: 0}, xhr = new XMLHttpRequest;
            t.activeRequests.push(req);
            t.updateProgress();
            xhr.open(method, d.API_URL + url, true);
            xhr.onprogress = function (e) {
                if (e.lengthComputable) {
                    req.progress = e.loaded / e.total;
                    t.updateProgress();
                }
            };
            xhr.onload = function () {
                req.progress = 1;
                t.updateProgress();
                if (callback) callback.call(t, req.responseText);
            };
            xhr.onerror = function () {
                t.activeRequests = [];
                t.updateProgress();
                t.setProgressText(d.t('Error.'));
            };
            xhr.send(body);
            return this;
        },
        loadImage: function (url, callback) {
            var t = this, req = {progress: 0}, img = new Image;
            t.activeRequests.push(req);
            t.updateProgress();
            img.onload = function () {
                req.progress = 1;
                t.updateProgress();
                if (callback) callback.call(t, img);
            };
            img.onerror = function (e) {
                t.activeRequests = [];
                t.setProgress(0);
                t.setProgressText(d.t('Error.'));
            };
            img.src = d.API_URL + url;
            return this;
        },
        '.progress': {
            apply: function (progress) {
                this._progressBar.setProgress(progress);
            }
        },
        '.progressText': {
            apply: function (progressText) {
                this._progressLabel.setText(progressText);
            }
        },
        '.editMode': {
            apply: function (editMode) {
                var t = this,
                    app = this.app();
                if (editMode) {
                    this.originalParent = this.parent;
                    this.app().add(this);
                } else if (this.originalParent) {
                    this.originalParent.add(this);
                }
                app.redirect(app.reverse(editMode ? 'project.edit' : 'project.view', this.projectId()));
                d.toggleClass(this.element, 'd-app-edit', editMode);
                document.body.style.overflow = editMode ? 'hidden' : '';
                if (t.editorLoaded) {
                    t._tab.setVisible(editMode);
                    t.palette.setVisible(editMode);
                    t.userPanel.setVisible(editMode);
                    t.tabBar.setVisible(editMode);
                    t.setLightboxEnabled(t.lightboxEnabled() && editMode || t.preloaderEnabled());
                } else if (editMode) {
                    t.initEditMode();
                }
                if (!editMode) {
                    t.spritePanel.setCollapsed(false);
                }
                t.spriteList.setVisible(editMode);
                t.spritePanel.setToggleVisible(editMode);
            }
        }
    });
    d.BlockSpecs = {
        motion: [
            ['c', 'motion', 'forward:', 'move %f steps', 10],
            ['c', 'motion', 'turnRight:', 'turn %icon:right %f degrees', 15],
            ['c', 'motion', 'turnLeft:', 'turn %icon:left %f degrees', 15],
            '-',
            ['vs', {$:'direction'}, 90],
            ['c', 'motion', 'pointTowards:', 'point towards %sprite'],
            '-',
            ['c', 'motion', 'gotoX:y:', 'go to x: %f y: %f', 0, 0],
            ['c', 'motion', 'gotoSpriteOrMouse:', 'go to %sprite'],
            ['c', 'motion', 'glideSecs:toX:y:elapsed:from:', 'glide %f secs to x: %f y: %f', 1, 0, 0],
            '-',
            ['vc', {$:'x position'}],
            ['vs', {$:'x position'}],
            ['vc', {$:'y position'}],
            ['vs', {$:'y position'}],
            '-',
            ['c', 'motion', 'bounceOffEdge', 'if on edge, bounce'],
            '-',
            ['vs', {$:'rotation style'}],
            '-',
            ['v', {$:'x position'}],
            ['v', {$:'y position'}],
            ['v', {$:'direction'}]
        ],
        looks: [
            ['c', 'looks', 'say:duration:elapsed:from:', 'say %s for %f secs', 'Hello!', 2],
            ['c', 'looks', 'say:', 'say %s', 'Hello!'],
            ['c', 'looks', 'think:duration:elapsed:from:', 'think %s for %f secs', 'Hmm\u2026', 2],
            ['c', 'looks', 'think:', 'think %s', 'Hmm\u2026'],
            '-',
            ['c', 'looks', 'show', 'show'],
            ['c', 'looks', 'hide', 'hide'],
            '-',
            ['c', 'looks', 'lookLike:', 'switch costume to %costume'],
            ['c', 'looks', 'nextCostume', 'next costume'],
            ['c', 'looks', 'startScene', 'switch backdrop to %backdrop'],
            '-',
            ['vc', {$:'color effect'}],
            ['vs', {$:'color effect'}],
            ['c', 'looks', 'filterReset', 'clear graphic effects'],
            '-',
            ['vc', {$:'size'}],
            ['vs', {$:'size'}, 100],
            '-',
            ['c', 'looks', 'comeToFront', 'go to front'],
            ['c', 'looks', 'goBackByLayers:', 'go back %i layers', 1],
            '-',
            ['v', {$:'costume #'}],
            ['v', {$:'backdrop name'}],
            ['v', {$:'size'}]
        ],
        sound: [
            ['c', 'sound', 'playSound:', 'play sound %sound'],
            ['c', 'sound', 'doPlaySoundAndWait', 'play sound %sound until done'],
            ['c', 'sound', 'stopAllSounds', 'stop all sounds'],
            '-',
            ['c', 'sound', 'drum:duration:elapsed:from:', 'play drum %drum for %f beats', 48, .2],
            ['c', 'sound', 'rest:elapsed:from:', 'rest for %f beats', .2],
            '-',
            ['c', 'sound', 'noteOn:duration:elapsed:from:', 'play note %note for %f beats', 60, .5],
            ['vs', {$:'instrument'}],
            '-',
            ['vc', {$:'volume'}, -10],
            ['vs', {$:'volume'}, 100],
            ['v', {$:'volume'}],
            '-',
            ['vc', {$:'tempo'}, 20],
            ['vs', {$:'tempo'}, 60],
            ['v', {$:'tempo'}]
        ],
        pen: [
            ['c', 'pen', 'clearPenTrails', 'clear'],
            '-',
            ['c', 'pen', 'stampCostume', 'stamp'],
            '-',
            ['c', 'pen', 'putPenDown', 'pen down'],
            ['c', 'pen', 'putPenUp', 'pen up'],
            '-',
            ['vs', {$:'pen color'}],
            ['vc', {$:'pen hue'}],
            ['vs', {$:'pen hue'}],
            '-',
            ['vc', {$:'pen lightness'}],
            ['vs', {$:'pen lightness'}],
            '-',
            ['vc', {$:'pen size'}],
            ['vs', {$:'pen size'}]
        ],
        data: [
            ['&', 'createVariable', 'Make a Variable'],
            '-',
            ['v', ''],
            '-',
            ['vs', ''],
            ['vc', ''],
            ['c', 'data', 'showVariable:', 'show variable %var', ''],
            ['c', 'data', 'hideVariable:', 'hide variable %var', ''],
            '-',
            ['c', 'lists', 'append:toList:', 'add %s to %list', 'thing', ''],
            '-',
            ['c', 'lists', 'deleteLine:ofList:', 'delete %deletion-index of %list', 1, ''],
            ['c', 'lists', 'insert:at:ofList:', 'insert %s at %index of %list', 'thing', 1, ''],
            ['c', 'lists', 'setLine:ofList:to:', 'replace item %index of %list with %s', 1, '', 'thing'],
            '-',
            ['r', 'lists', 'getLine:ofList:', 'item %index of %list', 1, ''],
            ['r', 'lists', 'lineCountOfList:', 'length of %list'],
            ['b', 'lists', 'list:contains:', '%list contains %s?', '', 'thing'],
            '-',
            ['c', 'lists', 'showList:', 'show list %list', ''],
            ['c', 'lists', 'hideList:', 'hide list %list', '']
        ],
        events: [
            ['h', 'events', 'whenGreenFlag', 'when %icon:flag clicked'],
            ['h', 'events', 'whenKeyPressed', 'when %key key pressed'],
            ['h', 'events', 'whenSpriteClicked', 'when this sprite clicked'],
            ['h', 'events', 'whenSceneStarts', 'when backdrop switches to %backdrop'],
            // '-',
            // ['h', 'events', 'whenSensorGreaterThan', 'when %triggerSensor > %f'],
            '-',
            ['h', 'events', 'whenIReceive', 'when I receive %event'],
            ['c', 'events', 'broadcast:', 'broadcast %event'],
            ['c', 'events', 'doBroadcastAndWait', 'broadcast %event and wait'],
        ],
        control: [
            ['r', 'system', 'commandClosure', '%parameters %slot:command'],
            ['r', 'system', 'reporterClosure', '%parameters %slot:reporter'],
            '-',
            ['c', 'control', 'wait:elapsed:from:', 'wait %f secs', 1],
            '-',
            ['c', 'control', 'doRepeat', 'repeat %i %c', 10],
            ['t', 'control', 'doForever', 'forever %c'],
            '-',
            // ['t', 'control', 'doForeverIf', 'forever if %b %c'],
            ['c', 'control', 'doIf', 'if %b %c'],
            ['c', 'control', 'doIfElse', 'if %b %c else %c'],
            ['c', 'control', 'doWaitUntil', 'wait until %b'],
            ['c', 'control', 'doUntil', 'repeat until %b %c'],
            '-',
            ['t', 'control', 'stopScripts', 'stop %stop'],
            '-',
            ['h', 'control', 'whenCloned', 'clone startup'],
            ['c', 'control', 'createCloneOf', 'create clone of %clonable'],
            ['t', 'control', 'deleteClone', 'delete this clone']
        ],
        sensing: [
            ['b', 'sensing', 'touching:', 'touching %sprite?'],
            ['b', 'sensing', 'touchingColor:', 'touching color %color?'],
            ['b', 'sensing', 'color:sees:', 'color %color is touching %color?'],
            ['r', 'sensing', 'distanceTo:', 'distance to %sprite'],
            '-',
            ['c', 'sensing', 'doAsk', 'ask %s and wait', "What's your name?"],
            ['v', {$:'answer'}],
            '-',
            ['b', 'sensing', 'keyPressed:', 'key %key pressed?'],
            ['v', {$:'mouse down?'}],
            ['v', {$:'mouse x'}],
            ['v', {$:'mouse y'}],
            '-',
            ['v', {$:'loudness'}],
            ['r', 'sensing', 'senseVideoMotion', 'video %videoMotion on %stageOrThis'],
            '-',
            ['v', {$:'timer'}],
            ['vs', {$:'timer'}],
            '-',
            ['r', 'sensing', 'getAttribute:of:', '%attribute of %object'],
            '-',
            ['r', 'sensing', 'timeAndDate', 'current %time', 'minute'],
            ['r', 'sensing', 'timestamp', 'Scratch days'],
            ['r', 'sensing', 'getUserId', 'user id']
        ],
        operators: [
            ['r', 'operators', '+', '%f + %f'],
            ['r', 'operators', '-', '%f - %f'],
            ['r', 'operators', '*', '%f \xd7 %f'],
            ['r', 'operators', '/', '%f / %f'],
            '-',
            ['r', 'operators', 'randomFrom:to:', 'pick random %f to %f'],
            '-',
            ['r', 'operators', '<', '%s < %s'],
            ['r', 'operators', '=', '%s = %s'],
            ['r', 'operators', '>', '%s > %s'],
            '-',
            ['b', 'operators', '&', '%b and %b'],
            ['b', 'operators', '|', '%b or %b'],
            ['b', 'operators', 'not', 'not %b'],
            '-',
            ['b', 'operators', 'true', 'true'],
            ['b', 'operators', 'false', 'false'],
            '-',
            ['r', 'operators', 'concatenate:with:', 'join %s %s', 'hello ', 'world'],
            ['r', 'operators', 'letter:of:', 'letter %i of %s', 1, 'world'],
            ['r', 'operators', 'stringLength:', 'length of %s', 'world'],
            '-',
            ['r', 'operators', '\\\\', '%f mod %f'],
            ['r', 'operators', 'rounded', 'round %f'],
            '-',
            ['r', 'operators', 'computeFunction:of:', '%math of %f', 'sqrt', 10]
        ]
    };
    d.BlockSpecBySelector = {
        'setVar:to:': ['vs', 'var'],
        'changeVar:by:': ['vc', 'var', 1],
        'readVariable': ['v', 'var']
    };
    ~function () {
        var name;
        for (name in d.BlockSpecs) if (d.BlockSpecs.hasOwnProperty(name)) {
            d.BlockSpecs[name].forEach(function (spec) {
                if (spec === '-') return;
                switch (spec[0]) {
                case 'c':
                case 't':
                case 'r':
                case 'b':
                case 'h':
                    d.BlockSpecBySelector[spec[2]] = spec;
                    break;
                }
            });
        }
    }();
    d.BlockAttachType = {
        'slot$command': 0,
        'slot$replace': 1,
        'stack$insert': 2,
        'stack$append': 3
    };
    d.Socket = d.Class(d.Base, {
        init: function (amber, server, callback) {
            this.amber = amber;
            this.server = server;
            this.sent = [];
            this.received = [];
            this.newScripts = {};
            this.slotClaims = {};
            this.socket = new WebSocket(server);
            this.callback = callback;
            this.listen();
        },
        listen: function () {
            this.socket.onopen = this.open.bind(this);
            this.socket.onclose = this.close.bind(this);
            this.socket.onmessage = this.message.bind(this);
            this.socket.onerror = this.error.bind(this);
        },
        open: function () {
            if (this.callback) this.callback();
        },
        close: function (e) {
            console.warn('Socket closed:', e);
        },
        message: function (e) {
            var packet = JSON.parse(e.data);
            packet.$timestamp = +new Date;
            this.received.push(packet);
            this.receive(packet);
        },
        error: function (e) {
            console.warn('Socket error:', e);
        },
        unpackIds: function (source, destination) {
            var i = 0,
                amber = this.amber;
            function unpack(block) {
                var j = 2;
                if (typeof block[0] === 'number') {
                    destination[i++].setId(block[0]).setAmber(amber);
                    while (j < block.length) {
                        if (block[j] instanceof Array) {
                            unpack(block[j]);
                        }
                        ++j;
                    }
                } else {
                    block.forEach(function (b) {
                        unpack(b);
                    });
                }
            }
            unpack(source);
        },
        receive: function (packet) {
            var a, b, bb, tracker;
            switch (packet.$) {
            case 'script.create':
                if (packet.request$id) {
                    this.unpackIds(packet.script[2], this.newScripts[packet.request$id]);
                } else {
                    tracker = [];
                    a = new d.BlockStack().fromJSON(packet.script, tracker);
                    tracker.forEach(function (a) {
                        a.setAmber(this);
                    }, this.amber);
                    a.hide();
                    this.amber.objectWithId(packet.object$id).scripts().add(a);
                }
                break;
            case 'block.move':
                a = this.amber.blocks[packet.block$id].detach();
                if (this.amber.isBlockVisible(a)) {
                    a.setPosition(packet.x, packet.y, function () {
                        a.parent.embed();
                    });
                    return;
                }
                a.initPosition(packet.x, packet.y);
                break;
            case 'block.attach':
                a = this.amber.blocks[packet.target$id];
                b = this.amber.blocks[packet.block$id].detach();
                if (this.amber.isBlockVisible(a)) {
                    switch (packet.type) {
                    case d.BlockAttachType.stack$append:
                        bb = a.getPosition();
                        b.setPosition(bb.x, bb.y + a.element.offsetHeight, function () {
                            a.parent.appendStack(b);
                        }.bind(this));
                        break;
                    case d.BlockAttachType.stack$insert:
                        bb = a.getPosition();
                        b.setPosition(bb.x, bb.y, function () {
                            a.parent.insertStack(b, a);
                        }.bind(this));
                        break;
                    case d.BlockAttachType.slot$command:
                        a = a.arguments[packet.slot$index];
                        bb = a.getPosition();
                        b.setPosition(bb.x, bb.y, function () {
                            b.removePosition();
                            a.setValue(b);
                        }.bind(this));
                        break;
                    case d.BlockAttachType.slot$replace:
                        bb = (tracker = a.arguments[packet.slot$index]).getPosition();
                        b.setPosition(bb.x, bb.y, function () {
                            a.replaceArg(tracker, b.top());
                        }.bind(this));
                        break;
                    }
                    return;
                }
                switch (packet.type) {
                case d.BlockAttachType.stack$append:
                    a.parent.appendStack(b);
                    break;
                case d.BlockAttachType.stack$insert:
                    a.parent.insertStack(b, a);
                    break;
                case d.BlockAttachType.slot$command:
                    a.setValue(b);
                    break;
                case d.BlockAttachType.slot$replace:
                    a.replaceArg(tracker, b.top());
                    break;
                }
                break;
            case 'block.delete':
                a = this.amber.blocks[packet.block$id];
                if (this.amber.isBlockVisible(a)) {
                    bb = d.BlockPalette.palettes[0].element.getBoundingClientRect();
                    a.detach().setPosition(bb.left + 10, bb.top + 10 + (bb.bottom - bb.top - 20) * Math.random(), function () {
                        a.parent.destroy();
                    }.bind(this));
                    return;
                }
                a.parent.destroy();
                break;
            case 'slot.claim':
                if (packet.block$id === -1) {
                    this.slotClaims[packet.user$id].unclaimed();
                } else {
                    this.amber.getUser(packet.user$id, function (user) {
                        (this.slotClaims[packet.user$id] = this.amber.blocks[packet.block$id].arguments[packet.slot$index]).claimedBy(user);
                    }.bind(this));
                }
                break;
            case 'slot.set':
                this.amber.blocks[packet.block$id].arguments[packet.slot$index].setValue(packet.value);
                break;
            case 'user.login':
                if (packet.success) {
                    this.amber.userList.addUser(this.amber.currentUser = new d.User(this.amber).fromJSON(packet.result));
                    break;
                }
                this.amber.authentication.setMessage(packet.result.pop ? d.t.apply(this.amber, packet.result) : d.t(packet.result || 'Sign in failed.'));
                this.amber.authentication.setEnabled(true);
                this.amber.authentication.passwordField.select();
                break;
            case 'user.list':
                packet.users.forEach(function (user) {
                    this.userList.addUser(new d.User(this).fromJSON(user));
                }.bind(this.amber));
                break;
            case 'user.join':
                this.amber.userList.addUser(new d.User(this.amber).fromJSON(packet.user));
                break;
            case 'user.leave':
                this.amber.getUserById(packet.user$id, function (user) {
                    this.amber.userList.removeUser(user);
                }.bind(this));
                break;
            case 'project.data':
                this.amber.setProject(packet.data);
                break;
            case 'variable.create':
                this.amber.objectWithId(packet.object$id).addVariable(packet.name);
                break;
            case 'chat.message':
                this.amber.getUserById(packet.user$id, function (user) {
                    this.chat.showMessage(user, packet.message);
                }.bind(this.amber));
                break;
            case 'chat.history':
                this.amber.chat.addItems(packet.history);
                this.amber.setLightboxEnabled(false);
                this.amber.remove(this.amber.authentication);
                break;
            default:
                console.warn('missed packet', packet);
                break;
            }
        },
        send: function (packet) {
            packet.$timestamp = +new Date;
            this.sent.push(packet);
            packet = JSON.stringify(packet);
            this.socket.send(packet);
        }
    });
    d.OfflineSocket = d.Class(d.Socket, {
        server: '<offline>',
        blockId: 0,
        init: function (amber) {
            this.amber = amber;
            this.sent = [];
            this.received = [];
            this.newScripts = {};
        },
        serve: function (p) {
            var p = JSON.parse(JSON.stringify(p));
            p.$timestamp = +new Date;
            this.received.push(p);
            this.receive(p);
        },
        assignScriptIds: function (s) {
            s.forEach(function (block) {
                this.assignBlockIds(block);
            }, this);
        },
        assignBlockIds: function (b) {
            b[0] = ++this.blockId;
            b.slice(2).forEach(function (block) {
                if (block && block.pop) {
                    if (typeof block[0] === 'number') {
                        this.assignBlockIds(block);
                    } else {
                        this.assignScriptIds(block, true);
                    }
                }
            }, this);
        },
        send: function (p) {
            p.$timestamp = +new Date;
            this.sent.push(p);
            switch (p.$) {
            case 'script.create':
                this.assignScriptIds(p.script[2]);
                this.serve({
                    $: 'script.create',
                    script: p.script,
                    user$id: this.amber.currentUser.id(),
                    request$id: p.request$id,
                    object$id: p.object$id
                });
                break;
            case 'block.move':
                break;
            case 'block.attach':
                break;
            case 'block.delete':
                break;
            case 'slot.set':
                break;
            case 'slot.claim':
                break;
            case 'user.login':
                this.amber.getUser(p.username, function (user) {
                    this.amber.currentUser = user;
                    this.serve({
                        $: 'user.login',
                        success: true,
                        result: user
                    });
                    this.serve({
                        $: 'project.data',
                        data: {
                            name: d.t('Untitled'),
                            notes: '',
                            stage: {
                                id: 1,
                                children: [{
                                    id: 2,
                                    objName: d.t('Sprite 1'),
                                    costumes: [{
                                        name: 'costume1',
                                        rotationCenterX: 47.5,
                                        rotationCenterY: 55.5,
                                        base64: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAF8AAABvCAYAAACKNhxYAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAN1wAADdcBQiibeAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAACAASURBVHic7X13eBRV9%2F%2Fn3pnZTU9IQoAkkNnshgQITUINQUGaUkSKSFEpgiL6IqJiL4gFwY5SpOiLgIKggCDSIVSll1CyyW4SSEIoSUjbMnPv748IUrLZ2ZDA9%2Fm9fp5nH8LOveec%2BczdW8459w7hnONf3B3Qu23A%2FzL%2BJf8u4l%2Fy7yL%2BZ8k3yYYgk2yodzdt%2BJ8k3yQbQkWKHQD63k07apR8k2yYYJINYTWpw1OYZENdvYg9AOIlAfffTVtqlHxC0E4SYDbJhuE1qUcrTLIhUidiX9NI3mBKf0YIQZe7aU%2BNks85rP5e8JUELGxsMvxhkg2RNamvMphkg0EnYl%2BCzOvNG8V0nRpyOBSEmGSD6W7ZVNN9fmawH7etnaiKzSL5faKAMybZMNYkG0gN670BJtkQqxOwL9HEa89%2Bgkl6EQjxAyJroQzAvXfSlutR0%2BRn5BYSoX4wsGgs073Vl3l7S5ipF5Fskg3GGtYNADDJhnhJwJ4ujXmtr4YzSRL%2BuZYYw%2FV3s9%2Bv8ZZfbIPe5iz%2Fz6DWHL9PUqW2Rt5GoEgxyYaJJtlQYzaYZMM9koBdvZrzgE8eZaJwk6Y20ZxS%2Bv8x%2BQCQU%2FjPF3UCgDlPMGnaIKbz88JHehH7TbKhcXUqNckG0SQbRooCkvu34r4fDGACraCja23gsDsRZpINcnXq1wqxJoWbrZYrjYyGkux84msIvdGB16s5R3uTqntvNW26%2Fhg%2FEuDvv0Wv0%2FW9cOmSvSJZJtkQAqARgMYAGkkCZJWhhHEUAyi9%2BnE4HYH%2B3rrHvHUIfvZ%2Bph%2FW3rXjsLY%2FUC8QZTmFuBeAtXruWjtqlHwAEAXk5BSgwhlFsC%2Fw2RAmdjQxjP1W6VpS4swPCwkdFODv%2FweAjoSgr7eERIUhFkCgKECtXwv22HpcFx4E0aEANid4qQOqzQm1zAm%2BJ6VIOpdTKgxs542oYB8A%2Bkrt6xDD9asPkfsBfF%2FtN%2B8GNU4%2B50jPLiQmwHULHNCaolt8bTrg82L9zpMFv0kitfn7%2BUodTFxtLXOdsQ5grM0RGQyBEvjcVJ2g%2FD7%2BvpcgZF70w4o%2FyzBuXj6%2BHBGEzk28XOpuE83p2iOk623faBVAatqfHyMbZvZpwZ%2Be9ggT3JcG%2FrvTibd%2Fuoh7G%2Bnx1aha8Peq%2BqxUZQAlAKlERG4h0HmaAAAGs9VirbKyKqDGfTscyMy8DIfW8o93lHB8Rl146YDWr%2BWioJRVWbdAKyceAOoGAvdEcbuufPpbrQO%2FO9wJx1rGuXzPWq%2BvnmD2k8FY%2FGwIgnxq3sSFo5m%2BZ1NeVxSw3yQbete4wr9xJ8jPvFwCPatC79YqWlf91gBQGHDASvD1FhHzdlCY84APBzLxxZ7MmxKsijEYXqoRxTfhjrR8lYFeKLoDmjQgLQ9I%2BsgLH%2B0wgsWOxYXaQzF5TQQ6TvOBl0QxZwSjOgEfxEYbPq5pW2p8tgMglxKoOQVEqBNwd4P1BaXAM0v88Orb72LAoEE3XLNYLHhl4nj4nMnA50OLxRd%2Fos%2FHGQ3BioqxZqul6gNPJajxlm%2B2WphOxIWcgprW5B6ztnuhQ5detxAPAAaDAUtX%2FoYOfZ%2FBO7%2F54IuhTPL3wnBRwJyasudOtHwQgozsAtTVUvZiMbAlhWBjqj%2BOWZ2ICtMhuraCZnVLMSCBQ3cbFp%2FK88IzY10HryilGPP0eNSqFYoPPn8X3zxWon9iHh1hkg1%2Fma2WuVXX7EJfdQusCA4FqdkF7mc8x88S9PnKB4f5gxjy3Az8tmkbJn%2F4LVr2eQ3JBYnoM9MP205Wfd6fluNA4yZN3JYbOHgw7u89GF9s9cGHA5koUHxtkg3tq6zYBWp8kQUAJtkwpWMMf%2FnbkczlWv9cPjB0nh%2FenfY5unXvXmGZPbt34%2F03JyPS9yI%2BHVQCSdOyrRwqAxLe0%2BPIiVMQRPcVGWMYPXww2tc6gNwCxn7aR1LtChqZrZZqI%2ByOtHy9iDaSWLmuicv9MfbZSS6JB4D2HTpg9cbt0IcnYvIKH3jSbgQKNKjthVRzqqbylFJMfus9LNylx5NJjBKCaAAPadeoQUd1CqsIJtnwBKXo8lZfJrkqc7mEIOMiw2MjRriVRynFjK9mIV%2BKxfQ%2FKnea3YyGdVSknDihuXxcXBxatmqNtccEPNaBi3oR73uk0A1qOnvBVyfg89d7M6luoOty%2By1Am4QWEARt%2FYgkSZi9cDF2Z9fF%2BqPax4DGdUrx155kzeUB4LlJr2DBLi88kcgIBxqaZEMvjwRUgppu%2BeND%2FOHV757K%2B4ej53Ro1d6zUKqfnx9ef%2FcjzN7lr7nOw%2FcwbPrjD%2BSdP6%2B5TqPGjSHpvVFsI%2Bh3DyeSgDEeGVoJajKE5ycJeH1id%2BZ1c%2FjuZvjqnCgu8nwJ3CExEYJ3CHaZtbX%2BIB%2BgfysVc7750mWZ3JxcbN64CaqiXvuuSeM4nM4FujfhAufoYZINnvV3LlCTLf%2B5uoHQ9WruflQMD%2BTIzjRXScnoZyZiwR7trX9EBxtWrVyJ87m5t1zLyszEvUkd8dSYMRg%2Fbty175u0aIPT5ynaRnNIAgSgevJ9aoR8k2zwlwS8OrE786oodnoz6tUCMjMy3JarqFX27t0HB9LtcKqVVLwOoX7Ak0lOjBv9OGw22w3XkpOTr8nevm0bFEUBAHh7%2B8ChUIgCkBjDOYDO2rRVjppq%2Bc%2BEB0Hq2VTbXLBpJIfFmoEMq%2BsHYLVYr7XKZ8Y9fe17QRRQNzQIeVe0Gze6owMm30y8PGE8rl%2FntO%2FQAZSWU9IhMRGiWL6cPnXqJBq26gmAIKYudF4SmmrX5ho1Qr63hBHDOzAvd4GM68pjSBsFC7%2Bd5bLMtq1br7XKHdu2X2uVABARXhc5hZ6tfN%2FtW4qLlr145%2FVX4XCUx3oMBgM2b9uKL2fOxOxvy70JjDEcOXIMsV3GQeg0F6Z63gAQb5INt%2B3v1kQ%2BIUQwNjAmaClrkg1RZU7EdY7zbCE4tI0Dv61ZjYL8%2FAqv39e587WVaWLHjtdaJQD4BwShoNQjdRAp8OXgIuSdXIe%2BD%2FTAkSNHAAD1GzTAg717QZLKlyWffDwdderUQVyjRqCRPdBt3ALUCvAN04k4%2B3ci8M0xZc3Q5F4wNjAmEKruAUg651hMmLDEnGWucIQ0yYYJUSH4cP0k1dtTY97%2F3QclwV0x%2FYuZFV4%2Fd%2B4cjhw6jG49ul8jBwA6tGqOpaPzER7kqUaAxo7Eb1kt8f57U9ExqSPad%2BiAli1bwmq1YuuWrdi9cyd%2BWb0KQbVqXavDncU4tWcFpnyy2HHkeGqZQ8WLZqtlnjtdMZExkVxSPmWEPJeenn5es28nNiI2lEn2wRxkGIB2HPiTcLKY6IQfU1NTL1wt1yTGsGFEIu%2F2fHfPXeB2BRj5nR%2Fa93gML0x%2BVVOdtLQ0jB7aDxsnFN5ybeMxG1bss%2BFKGYe3jsBbAgglUFRAVYHwYAFDXpiD%2BI6DcPnyZWzetAl7d%2B%2FBwQMHEGWQ0alTJzzQqxfq1XO9hyI7ZQsGjXhJuXTx8iyF4fmKfP%2BxEbGhTOd4kXM%2BHiA7iSQ%2BnpqaeqFKjrXYqKholQhDCfgwDkSB4Cu7okzLysq63LShIWNqf9bgwWZV8z8VlALD5%2FvhsadfxvAnRrgt%2F9orr0AQREyZ2B8sfRlYxhrAWYScAhXxL55HnMEIvSRCZQyqygACUEJBKUH%2BlSJcLLbhfF4eiNYBqgI4rpzFqJFPOQ4eSdnsUDDIbLWUxMXF%2BTvLnG0J4T0B9hRAzhCCKakWy6qr9W7bqxljMPTgHB8AMALkU4HgjcVPq1Lz%2BlWXm10AjPzeD%2FEt2%2BGVt6YiPDy8wnLfzPwav69bhx%2BXL4Ovr2%2F5l6oNLGcHCqy70LjvdLSIbYQ6wRX3RyczziK2ZWssWvRDlW29iqyMVLz43DPKwWNmK%2BMoJkBTAHaA7OGcfJ6WkfbbzXWqxaVMCCGmBoZBnPAPAUS%2F1ZdhSLvbk%2BtQgIW7JCzaq8fDjzyKhDbtYTLFICgoENu3bcf633%2FHyZMpWLZiBcLCKt78smHDBjwyaBCaRdeHIbzODddUxrDhr6NYs3Yd2rZte1u2rvrlV0yaOBEREeG4kHeBO52ObwHMicwwHN3Ktyqu6lWrP79hA2MHIrJkL5HTST357T0AXSBonQ64IDXD4i3ncSY9B%2BbUVJw%2Ffx5t27VDj5490b1H9xsGwopw8uRJ9H%2F4YZQVF6FecACi6taGXpKw%2F1QaIo0N8ceGDVW38W8UFxfDZrMhNDQUyT9Pw7hXZx84nmpxOzusVvJNsiGeEBxd%2F4JKQvwJfHWeyyb17oXQ7AWQ4OYAqZ5lCGMMmzZtwtw5c7B%2B%2FXr4eHuhXngEtu%2FYgaCgKkyRKoHj0ik0bvUAB2A0Wy2WyspWdww3i3MQgcJj4ol3HdBWb4M2qP6cJUopunfvju7du6OoqAi7d%2B9Gt27drq1mqxO6kDiEh3rbsy%2BWtQRQKfnVqt1stRSKAspyNMRrrwfxjYTYa6NHxG%2FauBEnU1Lg6S%2FX398fPXr0qBHir6JBeDAAhLorp7nlxzRoYOSC0JUwUsIJKyGUlnBVLQFgYxCCKeUR4DxCpMT54VriPX8UR5DGtZ%2FQ%2FlNA59nP%2F9233kZOTg5CQkLQMSkJHZOSkJjU0eXgeyfh4yUB7nLT4Um3Iwj1AYzmhPuBEz%2FOuB8I9QMgUfAicJwlhJxlHBdKHfCD1l%2BVPgQkzLPZRv7lfOTk5OCnn5cjNzcXO3ck45MZ0%2FHSpEmIjYtFx6ROSOqUhNZt2kCvrxbXu1s8OXIUYuNi0aljO%2Fx5LJMCOO2uzm0PuJ1JZ%2FH66ZRJNrSmBHu3TFZpnQD39UlYW4hdl3ukc2dyMsY99TSOHD92Q%2FeRZjYjeUcydiYnY9%2B%2BfWCqitZt2iCpUxI6JnVCbFysR3q0gnOOn5cvx7rf1uLwwf0oKi4FgHQAfwL8AgA7QO0A7FwlP6ZlpaUCNZQ6Eh9jODIyiTf7T1f3LgYSYITYe6tH8ufMmo1NGzdi%2BcoVLss4nU4c2L8fO3ckIzk5GSknTqB27dpITOqIe1q1gtFohCE6GrVr1%2FZItzscXjcDQ5%2F7%2BpKDYRKAloQjACA6BqYHIXqo9L20zLS%2FgBoi3yQbhgd6Y97O11S92xQZyQ%2FSoBSP5M%2BdPQdbt2zG0mXLNNe5fPkydu3ciZ07kpGSkgJLejpsNhv8%2Ff0RbTTCaDQi2vT3v9HRiJLlGzynmsAUDO6VaD9wMm%2BK2Wr5wF3xmkoXXFbqwBfzdhDd05155VMfZzGglACir2bhUXIUMjIyPTIoODgYffr2RZ%2B%2B5emCnHOcO3cO6WlpSEtLQ7o5Ddu3bsPCefNx6dIlCKKABvUboGv3bpj8qjYn38VT63DoVJ4AwK2HE6jBjDWTbHiQEqxZMJrRttGV6xC7LgMJa6dZ9ulTp9H7gQdw7GQKvLxc77eqKgoLCzHh2Wdx%2BtRpLP9lJSIj3Z9awB1FGNr%2FAcehk%2BcWnEqzjHNbATUYQDdbLesAfDxhMXVcdJOYwE4v8Eh2g6gGoJTi2NGjVTfQBVRFxfRp03Do4CF8u2C%2BJuIBYOXcN9nRU%2BdyFRWTtOqq0bwdxvGGzYmDE5ZQp1rJ2MvObgAv1t6NeHt745HBg%2FHJ9OnVYOU%2FKC4uxpOjRmHb1q348efliG%2BqLVSbfXglXv1kFewKBputFs0xtRol32y1qHYF%2FY%2BdJcUvL6OK4irDgDOwFNfx24ow4YWJOHP6DGZMq54NJDk5ORg8cCDy8%2FOxctUqNGrUSFu9Y2vQ7ZHJKuOYYLZa9nqi805sjshxqmi%2FKYVcGPMddZa62JfIzIvBMlZrlhsaGorvFi3CksWL8c5bb6Os1MMg7nX4deUveKhXb0RFyVi67CfNq%2BSMv35El4efV%2B0OZZzZaqk49lkZOOd35GOMkus1NsonH2wXZcudW587Flfw%2BTGGs0tHuSc4cfw4797lfp7Yrh3%2Fbc0ariiK5rqHDh7kQx4ZzFvEN%2BXfL%2FyOq6qqrSJT%2BL41X%2FDYaIPTGCUP08rBzZ87kp9%2FFSbZEKgXsa6WL1rNGMz0reRbdROfuhA6%2FwAS2FCzXEVRMP%2Fbefhm5kz4%2Bvnh4f4Po%2B9D%2FWAymW7IxeecIycnBzu2bcfiH35A6pkzeKhfP7z0ymSEhrr1gwEASvNS8NKLrzq27T56ya7gMbPVslmzoTfhjpIPACbZoBcpPmYcz%2FZtyfnkB5lwiwNO9IHQdjpoVB%2BPZJeVluKP9X%2Fgl5UrsGf3HhBCEBYWhvCICJSWlsJqsaCsrAyyQcYjgx9F%2F4EDNJPOVTu2%2FvwlH%2F%2FGXM6ZMktRMdlstZR4ZOBNuOPkX4VJNrTUi%2FhOEhD3am%2Bme%2FgefstucRo7CkKzFwHJz2P5RUVFOJuVhexz2cjOzoZOpytfyZqMCA4O1ixHLb2AneuX8Hc%2BWaLknc%2FLsisYbrZa9nhsUAW4a%2BQDwN8HHb0sUrwVFgDyeCLz6ncPR%2BD1GT%2B6ANCGIyDEjgL02km7XRSdPYgfF%2F9X%2BXTeWoFyZa9dwQwAq8xWi8asUPe4K%2BTLslxPBB3mJfInbQpiCcAEASUihV5hEB9oyvmw9ly4IQNC9AY1Pgra6CkQn4qzGW4HzJaP3NS92LdvD%2Ftx1W7H4RNpAgGWKAyfma2WI9WuEHejzzcY%2BgkESyNqAQNaMa%2F7G3OU2AnO5gPWi8D3u6hicwKKCjHAG6xtNEfbaE5byUBMHQ4iiKDyw6DRj4AENwXEKmTrKaWwF2SgIC8Dxw7t5yt%2B32vftCvFSyfw8wrDOpVhA4ANZqvlcnXf%2F%2FW4hXxCSF0AnHOuffuGRsQYDG8R4O1XejH6WIeKH7pTBZ7%2Br4CcfKBROMfxs4RdKgEpsYP46IAmEZzXDwapEwjUCSCQjTGob2qOwIhmkIIbgqkqFEcZnI4yKA4bnI4yFObnI92ageOnsxx%2FHslgpyx5esZBdCIKCbDdrmAdgE1mqyWtuu%2B5MlwjnxBS29%2BLbK1bL8Jkdyqk8FLez4VlbDivhp9GRESET6C3brFOwINfDWe6dsbKRW45SfDqcop9b%2F3TveZdAX4%2FRnE0Czh%2FBSgoJbhSBpQ6wMscINcfrEEJFErhpASOvz95ThUnnCpOAjgDIBVAqtlquav74kUAIITo%2FbzInlX%2F%2FVDuPOhlAZxh7udTBk56dWo%2BgGdvR4HRaGwQ5K37PTwIxrkjVV1k5Wk2AIAzuUDkTWNrWADwRGKFDiLCOVDqKM90%2B3ozVf44TgSu8vGnrNZq3zVenbjqXnjoqccfCu88aLIAEIAIGDvxHd0jA3uP8tIJE6oqPMZg6KEHO5LYkJtWPKvqtRCfeQmYu53gqfu0J9oSAvjqgZg6wOdDmdi8PggImR0jy%2BOravudAOGcI9iXJh%2F7c0PHiCY3HjWmluahUePmpakZuV045%2Fu0Cu1MOovZsnUqB176T1dGxt7HNeWhFtmAUfMFNAjh%2BOTRqh%2F0sWg3wY%2F7CM7mQ3EoeMVstX6itW50dHRzwnlnMHq8Vu1a2%2Ffv3%2B%2BssiFuQDjnCPAV8wuLbEGE3hrYyjmxHg0THswstvGGnPMKj128HjGRMZF6L%2BcvPl6k2ZdDma4iF0JFOH8FGPudAEngmD%2BK3TjX9xCzthIcsBCMTOIY%2Bx1VuUr6p2amV%2Bq1i4mKHq6T%2BHSnijBjGLdlXiYSOMwOJxuUmpGhfee0B6AAEBRc27ci4gGgXpOe%2BPTd5%2Bv66%2BmH7oQlJCRIem9lY8so0nzt86pm4g9mEAyeJaBuAMeiMRUTTyO7QeyyGGLvrZAGHIaQ%2BBVoZHeA3ro7JzsfqB0IJMZwvNGHCVTkyxoaDC0q0h0fFu%2FXJMawWJLYwpcfZHX3vqnS1ROYz67XVKlbEx5DBfpXbFRUtKYb8RCUEOIbER5eKUtPvvCBrknTJuMIIZUmfxZevPiSvx6GL4erkpaEKc6B%2BTsIRsyj6NeS45vHGbxv5lL0hpA0B0Kn%2BSB1k0ACjIA%2BGDTqIQid5kHqfwA0sscNVfakUbT%2B%2B8EPaccxuC0TRQEbYmT52skhhBBilOVhPKAkLTIIA355jolD23H4%2Fx2V9NUD0wczsV00REmit59DXgFEznlJtFx5Mj0RvbDu16VeDeNbryaExHPOK1x8EEJM3eK53q%2BSPCXGgfwSQBSAycsEHM0Cvn6MIalhBSZQHcQuS0BCW7kWqAuE0GkuyIlvoB6djlPZHNkFwL3X7Ql7rRcXRMpCFu2mO%2BOMhvUCgdLYKMcRAsNzXZn0WAfu8gSTsfcxafQC2tK1AVWHCABXLuecZc4yI5Vcd7S1IppgxfefhvV59Jk%2FCCEdOOe3DESMc8XmBEf5QaMVYvFuwr%2FfTYiiEkTU4vj1PwxhLpKrqGlY5cRfAwFtMh689BwWLluCro05Qq5LhhAo8GovTns3Z1h1iDzoowMCvTn63cMR4sZnV2QDeGUnst4GKACoKjuel%2BHefdGp71PChNF9mwV400UuipzebyWVDsqPtuOkQQhBsR34ajh3STwAEG%2FP8i4dEQ9h3RGCsfdWzFXTSI43%2BjC80INhdCf3xDMOzNtOHYTUzFG%2FFAAKSvmCGZ9%2BUVZhCaUMLGs92Kn5YCfn4PWneujk2lJvX73w9i1FgSVZl6E7me16XikJwDePqTDV4XjuBwK7y30bAEtbAqg21wVuQvrZAgT7gQf4VE9D%2FWwDZSnZKLapfEq1CLwJhHMOQojo5y1cuHj2TJA%2B%2BJ%2BBnZmXQD0yHbBfuqFSboGKNq%2BfLy2182%2BvlLHXOOfXAqjxMYZtg1vzTq%2F0ZpXO7C%2BXAENmC4irx%2FHZEAZXxwTQJs9BaK7hmEuuYvDAQezIoUNHCEGzTx5lQrcmVXsIThV4dxVRfj1InYzx%2B1Ot1mrx398MCgCcc0VV1dmL5n12rR%2FnRelQ%2F3rjFuIBoG6QgMPT6vr0TfAa6%2B9NrISQa4n1dgeZv%2FIgcRkov4pgX%2BDbkSr2Wwk%2B%2Ft11HJ%2BlfA120r2XYMeq2fzEsUMHTqVb7nEomDRhCWXzkz3fYXihCBgym9p%2FO0yzmcoSaop44EbHmk9okPcZ84n9EYHhjcGOfw716KduBew6bcfI2ZdL8kvUPwtL%2BMyAgIBtEbWDDz7egTeY1LPy1g8AR88SDJ1N8dM4FU0iXJejpqEQWk8FyK3rkeKc42jT6WHV4XR2M1utWwEgJiq6DxX48ofvYdI7%2FTh1d%2BwM58Cvhwg%2BWkvtdiffWaqSgRZLzTrebnApE0IS4uMM2w8f2OtD0hZDPfaZJiFOlWP%2BlhK%2BdFdJ8QGLUx8S4JvlHxgavXaiSqJC3Nd%2FfSXB5WKCWY%2B7dinkFADrLnTB02%2FMBYR%2FFgPMWYL%2BD%2FVTUlJS3zljtd5wDFeMLLeURGxoHE4Cvhiq6lwN7oczCd5dTW1puVAdHG%2BkW61fcs5r5CDT63FDe%2BCc709Pz3h%2FyOD%2BZQUF2uMIkkDwdDc%2Fsv2dOv7n50bovhnlZawb4CTvr9GWFtQzHjiaVfmPxFcPrN%2BwjU%2Bd%2FBSH%2Bnefxhlef%2FF555kz5p9vJh4AUq3WQ04iNT6ZzZN7fS44Np0guPr%2BliIbsDmFYNgcah86h7LUXL6I2XVymsXy%2BZ0gHnARyfLSCc%2F7eWHq2sm1fe%2Bp4uEalosEfb%2BgeH8AQ98W7v33L%2F5E8ddbKirrHortwJiFlDVt2xVvTZtFf5gzXf3wk3mHnURITE1NdTnFJYQQY5RhkkD5VMagC%2FKBI78UeklEEWPkeycwIz093f2BP9UMl2FEQkgfbx1ZOm1YkPeo%2B3ypTvR88Fp9iODNXyg%2BG8LQpVHFegpKgTELBbSM4nitt%2FsGV%2BYAxnxHFadfHD118nSejZMW6enpmqJunUlnMTMysxERWWNGyCmLxXK0OoJFVUWlMVxCSFN%2Fb%2FKFSEmbyX39vcZ29Rf8PHyTw7I%2FCaaspujTgmFi938WVUU2YOcZgqlrKErswJt9GQYkaOPB5gSe%2Bp7aD2eSHNWudDydlXXOI6P%2Bj0BTAJ0Q0szfm0xhDN37tfZG%2B4Z674RoHeLrS3D3i9h2kuCdVRRlTuBKWfmrmoJ8gdTzgL8Xx4hEDh8dwYz1BM%2FezzD2Pm0PwKEA438QHH%2Bl87wyRjvejW7jduFR9gIhxAjggVq%2BtBPnaFti5%2FWiw4SyxDi93lRX0ktC%2BeArCUB%2BmYjNp%2FTIKRQxMoljfBeGrMtAai5BXhHQSuZoFI5ri6tdqQQvLKW4rxHH%2B%2F0ZNJy4C0UFJiyljp2nyWWnU%2B2Ympl5RwPgt4vbSh0hhPgAaA4gwVtCtECpXhLFoKCg4DaC5BXdI57zlx5gVOshRJaLBGMXUhhqA18OU%2BHl8gzaf6Ay4MVl1LklhRTYGElKT093uwXz%2FwqqJW%2BnM%2Bksnq2f8aBOx59xqOjWNBLO1%2FswfbNIz2WfzQeGz6GoE0iUb0eoYoCGiBbjwGs%2FE%2BX3o7TI4RQ6mTPNx6twG3ccmsk31jfGEEF9jIP6Es7Pi4Qvd6qCSEU2WqIYQyn8%2B7RkwiOtQeMjqvZAk88QvP0LtV8sRgEhuBQeCOP3Y1R9ZZ7Pq%2BAcePtXov56kJYoKr8v1Wo9VCUj7iC0nbEmy4sIyDBTGHKjQrlkvUj0aXnwA4CmkdwxpB3XP9CUa%2BomKkJuIfDBb1TZnEIIIWRaqdM5lTFGAr2kVbV8SdJ%2Fx6j6BhpWygAwdQ1Rl%2F1JylRGup6xWDQH%2Fe8G3JJvlOX%2BAiFLVzzLdHH1%2Fil7OpdApBzG2zjqQGXAf3cTfLGRKIRgb6lCn7y%2Bz05ISJBKCy794CWh3%2FdP3qi%2FMsxYT9l3O4miMD40zWp1vVP6LsM9%2BQbD6v4tefsPBjJtiewaoKjAqsMEMzdS2%2BUSlDoYxpstlh8rNJAQEmswzJREPmbuE0xKMGh7AIv3EHzwG2WM85c9SR25k3DrfKGcXJGE6tks7VTLF133fyzY3%2F2VFuYU4V0m6WVXxAPlSaOn0tPH25x4f9QCsHFlEwAABGtJREFUQdmcom2RN6w9xzePM6oX8VGc0TCbEOLBeybuDNy2fJMsf3lfHIbNepxVOTnergAr9xN8s4U6iuwotil4z%2BZwzD137pxHu9hiZPkZEPLVm30ZHdJW2y%2FgVA7BqAXUXmLDDlrk2%2F943vHiKt1EDcAt%2BTFR0X10Or5835uqXu9B%2By%2ByAdtPE6w%2FRuzJZwgFcMGu4j0qigsrc4K5Q0xU9EAqsKVP3wfxWQ0HawDlA%2FroBYL9bD7MzKF2P5WZmV1V%2FdUJt%2BQnJCRIRZcv5c0YzILcHUx9sQjYfJJg4wnC9qYRiALyFZX%2FxDhZbrZakznn1bKrwyTLnUVK1vZPYPq3H%2BJUy0nlpQ7gucXU8Vc6KXAyrPQR0RAU4eBgIHACRCGcKxxw2BVuVTnZxQjZk56eXv3b3P%2BGpqmmSZa%2FalEfo5aOY5WmQr2%2BguLPdIL8Un6xzMZHpmZmrq0pr2FDg6GFSLG5U2z5%2B821vD9LZcDnGwm7XAxEBoOG%2BZevDxRW%2FlFZ%2BWQg4zLYn2nElnmJeOskHHUomJBqsWyv7nvQRr7JVF9gauoXQ5n%2B%2Fsauy9ucgJcEjJwvOA5nYvvxVIvrV%2F9UA%2BJk2SCIZFt8BOrNHqFKlSVrVQWXioGZm4m67E9KJAHzTpgtT1WnfM0r3BiD4Z2wALy8YZLq7a6V5RYCPT%2Bhil0lg8wWy6%2FVYKdru2Jiauvg3FK%2FFmm4cLSqC9X%2BEgnNOH6O4NFZVFU5Blbn%2FWje%2Fl%2FqcHycX4zCrzZTt6Nc3UBgaDsIXiLeuS3rNCA1NfUCKfRrfzYfewZ9Izgybk22uG3ER3BM7MEEHcWC%2BLB4z%2FeluoBm8s%2BdO1fqZHh4YTLYphPuR7iRSYw4VcSbZLlaXnFRGY7nHS%2F2Cgzpll%2BKXwfMFJx706p%2BKLUrDGjF4VBRy%2B51pY770trg0cEXqRbLXoWT%2F7y0jDrTL1RetrY%2F0M7IVRDS83YM1Ir9%2B%2Fc7T6RaBtscmDp6AWVL91XvA7jqt1IEoYoerFvh8akjaRbLLMb5j8PmCI4zuZXfYJ0ASALhrg%2BfrwGctlimcEYGv7%2BGOqasJqyyc348wVU5VKHVRn6V%2FPmEECEuWp4niRg2fySTWjS4VYZDAR74VLBn55OXzBnpX1WHsZ7AFBXVSieR9V4SCQjx5UqwH0iIL6QQf4i1fIBavhy1fMrfnRXoU55WrfJyklX1n78LSoET5wg2phDb%2BUJkFNmVDllZWdWyP%2Fe2gilx0fLHjJNJQ9tzPHs%2Fo1d3lJy%2FAkxdTZXkMyS72MlaZGRkVPwilBpGdHR0HcpYB3AaSigPZZyEihRhkoh6hPMwDoQ4VdRSGa6GbDghYJRApYBCKBRKUMo5DjkUvhOSNDM1NdWD9xJVjtuOZJlkubO3hC9BSKwcwhW9BBw7S%2FSSgL1lNjri6gGe%2F5fRmXQWt2Ebr64VuFZU58sLenNABoEXY9ibnpnu2Rsg%2FwdxV08d%2BV%2FHHXkZ8b%2BoGP%2BSfxfxL%2Fl3Ef%2BSfxfx%2FwD8ZNWgjncncgAAAABJRU5ErkJggg%3D%3D'
                                    }],
                                    scratchX: 0,
                                    scratchY: 0,
                                    direction: 90,
                                    rotationStyle: 0,
                                    volume: 100,
                                    scale: 100,
                                    visible: true
                                }],
                                costumes: [{
                                    name: 'backdrop1',
                                    base64: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAeAAAAFoCAYAAACPNyggAAAEfElEQVR42u3VMQ0AAAzDsPIn3WokdtkQ8iQFAN5FAgAwYAAwYADAgAHAgAEAAwYAAwYADBgADBgAMGAAMGAAMGAAwIABwIABAAMGAAMGAAwYAAwYADBgADBgADBgAMCAAcCAAQADBgADBgAMGAAMGAAwYAAwYAAwYADAgAHAgAEAAwYAAwYADBgADBgAMGAAMGAAMGAAwIABwIABAAMGAAMGAAwYAAwYADBgADBgADBgAMCAAcCAAQADBgADBgAMGAAMGAAwYAAwYAAwYADAgAHAgAEAAwYAAwYADBgADBgAMGAAMGAAMGAAwIABwIABAAMGAAMGAAwYAAwYADBgADBgADBgAMCAAcCAAQADBgADBgAMGAAMGAAwYAAwYAAwYADAgAHAgAEAAwYAAwYADBgADBgAMGAAMGAAwIABwIABwIABAAMGAAMGAAwYAAwYADBgADBgAMCAAcCAAcCAAQADBgADBgAMGAAMGAAwYAAwYADAgAHAgAHAgAEAAwYAAwYADBgADBgAMGAAMGAAwIABwIABwIABAAMGAAMGAAwYAAwYADBgADBgAMCAAcCAAcCAAQADBgADBgAMGAAMGAAwYAAwYADAgAHAgAHAgAEAAwYAAwYADBgADBgAMGAAMGAAwIABwIABwIABAAMGAAMGAAwYAAwYADBgADBgAMCAAcCAAcCAAQADBgADBgAMGAAMGAAwYAAwYADAgAHAgAHAgAEAAwYAAwYADBgADBgAMGAAMGAAwIABwIABAAMGAAMGAAMGAAwYAAwYADBgADBgAMCAAcCAAQADBgADBgADBgAMGAAMGAAwYAAwYADAgAHAgAEAAwYAAwYAAwYADBgADBgAMGAAMGAAwIABwIABAAMGAAMGAAMGAAwYAAwYADBgADBgAMCAAcCAAQADBgADBgADBgAMGAAMGAAwYAAwYADAgAHAgAEAAwYAAwYAAwYADBgADBgAMGAAMGAAwIABwIABAAMGAAMGAAMGAAwYAAwYADBgADBgAMCAAcCAAQADBgADBgADBgAMGAAMGAAwYAAwYADAgAHAgAEAAwYAAwYAAwYADBgADBgAMGAAMGAAwIABwIABAAMGAAMGAAOWAAAMGAAMGAAwYAAwYADAgAHAgAEAAwYAAwYADBgADBgADBgAMGAAMGAAwIABwIABAAMGAAMGAAwYAAwYAAwYADBgADBgAMCAAcCAAQADBgADBgAMGAAMGAAMGAAwYAAwYADAgAHAgAEAAwYAAwYADBgADBgADBgAMGAAMGAAwIABwIABAAMGAAMGAAwYAAwYAAwYADBgADBgAMCAAcCAAQADBgADBgAMGAAMGAAMGAAwYAAwYADAgAHAgAEAAwYAAwYADBgADBgADBgAMGAAMGAAwIABwIABAAMGAAMGAAwYAAwYAAwYADBgADBgAMCAAcCAAQADBgADBgAMGAAMGAAMGAAwYAAwYADAgAHAgAEAAwYAAwYADBgADBgAMGAAMGAAMGAAwIABwIABAAMGAAMGAAwYAAwYADgDl60Rn%2FvvglQAAAAASUVORK5CYII%3D'
                                }],
                                tempo: 120
                            }
                        }
                    });
                    this.serve({
                        $: 'user.list',
                        users: [this.amber.currentUser]
                    });
                    this.serve({
                        $: 'chat.history',
                        history: []
                    });
                }.bind(this));
                break;
            }
        }
    });
    d.AuthenticationPanel = d.Class(d.Control, {
        defaultServers: '{"ws://mpblocks.cloudno.de/:9182":1,"ws://localhost:9182":1}',
        init: function (amber) {
            var savedServer, savedUsername;
            this.amber = amber;
            this.base(arguments);

            this.initElements('d-dialog');
            this.element.appendChild(this.serverSelect = this.newElement('d-authentication-server-select', 'select'));
            this.add(this.serverField = new d.TextField('d-textfield d-authentication-server')
                .setPlaceholder(d.t('Server'))
                .onInput(this.serverInput, this)
                .setText((savedServer =
                    localStorage.getItem('d.authentication-panel.server')) ? savedServer :
                    'ws://mpblocks.cloudno.de/:9182'));
            this.add(this.usernameField = new d.TextField()
                .setPlaceholder(d.t('Scratch Username'))
                .onInput(this.userInput, this));
            this.add(this.passwordField = new d.TextField.Password()
                .setPlaceholder(d.t('Password'))
                .onKeyDown(this.passwordKeyDown, this));
            this.add(this.signInButton = new d.Button()
                .setText(d.t('Sign In'))
                .onExecute(this.submit, this));
            this.add(this.registerButton = new d.Button()
                .setText(d.t('Register'))
                .onExecute(this.register, this));
            this.add(this.offlineButton = new d.Button()
                .setText(d.t('Offline'))
                .onExecute(this.offlineMode, this));
            this.element.appendChild(this.messageField = this.newElement('d-authentication-message'));

            this.serverSelect.onchange = this.serverChange.bind(this);
            this.serverSelect.onmousedown = this.serverClick.bind(this);
            this.updateServerSelect();

            if (savedUsername = localStorage.getItem('d.authentication-panel.username')) {
                this.usernameField.setText(savedUsername);
                this.hasSavedUsername = true;
            }
        },
        register: function () {
            window.open('http://scratch.mit.edu/signup');
        },
        offlineMode: function () {
            this.amber.setOffline(true);
            this.setEnabled(false);
            this.send();
        },
        submit: function () {
            this.savedServers[this.serverField.text()] = 1;
            localStorage.setItem('d.authentication-panel.servers', JSON.stringify(this.savedServers));
            this.setEnabled(false);
            this.amber.createSocket(this.serverField.text(), this.send.bind(this));
        },
        send: function () {
            this.amber.socket.send({
                $: 'user.login',
                version: this.amber.PROTOCOL_VERSION,
                username: this.usernameField.text(),
                password: this.passwordField.text()
            });
        },
        '.enabled': {
            value: true,
            apply: function (enabled) {
                this.serverSelect.disabled = !enabled;
                this.serverField.setEnabled(enabled);
                this.usernameField.setEnabled(enabled);
                this.passwordField.setEnabled(enabled);
                this.signInButton.setEnabled(enabled);
                this.registerButton.setEnabled(enabled);
                this.offlineButton.setEnabled(enabled);
                if (enabled) {
                    d.removeClass(this.signInButton.element, 'd-button-pressed');
                    d.removeClass(this.offlineButton.element, 'd-button-pressed');
                } else {
                    d.addClass((this.amber.offline() ? this.offlineButton : this.signInButton).element, 'd-button-pressed');
                }
            }
        },
        shown: function () {
            return !!this.parent;
        },
        userInput: function () {
            localStorage.setItem('d.authentication-panel.username', this.usernameField.text());
        },
        serverInput: function () {
            localStorage.setItem('d.authentication-panel.server', this.serverField.text());
        },
        updateServerSelect: function () {
            var i, servers, server;
            this.serverSelect.innerHTML = '';
            this.serverSelect.options[0] = new Option(this.serverField.text());
            servers = this.savedServers = JSON.parse(localStorage.getItem('d.authentication-panel.servers') || this.defaultServers);
            i = 1;
            for (server in servers) if (servers.hasOwnProperty(server)) {
                this.serverSelect.options[i++] = new Option(server);
            }
            this.serverSelect.options[i++] = new Option(d.t('Clear Server List'), '__clear__');
        },
        serverChange: function () {
            if (this.serverSelect.value === '__clear__') {
                localStorage.setItem('d.authentication-panel.servers', this.defaultServers);
                this.updateServerSelect();
                return;
            }
            this.serverField.setText(this.serverSelect.value);
            localStorage.setItem('d.authentication-panel.server', this.serverSelect.value);
            this.serverField.focus();
        },
        serverClick: function () {
            this.serverSelect.options[0] = new Option(this.serverField.text());
            this.serverSelect.selectedIndex = 0;
        },
        passwordKeyDown: function (e) {
            if (e.keyCode === 13) {
                this.submit();
            }
        },
        layout: function () {
            this.element.style.marginLeft = this.element.offsetWidth * -.5 + 'px';
            this.element.style.marginTop = this.element.offsetHeight * -.5 + 'px';
            (this.hasSavedUsername ? this.passwordField : this.usernameField).focus();
        },
        '.message': {
            apply: function (message) {
                this.messageField.textContent = message;
            }
        }
    });
    d.UserPanel = d.Class(d.Control, {
        init: function (amber) {
            this.amber = amber;
            this.base(arguments);
            this.initElements('d-user-panel');
            this.add(amber.userList = new d.UserList(amber));
            this.add(amber.chat = new d.Chat(amber));
            this.element.appendChild(this.toggleButton = this.newElement('d-user-panel-toggle'));
            this.toggleButton.addEventListener('click', this.toggle.bind(this));
        },
        collapsed: true,
        toggle: function () {
            d.toggleClass(this.amber.element, 'd-collapse-user-panel', this.collapsed = !this.collapsed);
            if (!this.collapsed) {
                this.amber.chat.focus();
            }
        },
        setCollapsed: function (collapsed) {
            if (this.collapsed !== collapsed) {
                this.toggle();
            }
            if (this.collapsed) {
                this.amber.chat.blur();
            }
        }
    });
    d.UserList = d.Class(d.Control, {
        init: function (amber) {
            this.amber = amber;
            this.base(arguments);
            this.initElements('d-user-list');
            this.element.appendChild(this.title = this.newElement('d-panel-title'));
            this.element.appendChild(this.contents = this.newElement('d-panel-contents d-scrollable'));
            // this.title.appendChild(this.newElement('d-panel-title-shadow'));
            this.title.appendChild(this.titleLabel = this.newElement('d-panel-title-label'));
            this.titleLabel.textContent = d.t('Chat');
            this.users = {};
        },
        addUser: function (user) {
            if (this.users[user.id()]) return;
            this.contents.appendChild(this.users[user.id()] = this.createUserItem(user));
        },
        removeUser: function (user) {
            this.contents.removeChild(this.users[user.id()]);
            delete this.users[user.id()];
        },
        createUserItem: function (user) {
            var d = this.newElement('d-user-list-item', 'a'),
                icon = this.newElement('d-user-list-icon', 'img'),
                label = this.newElement('d-user-list-label');
            d.href = user.profileURL();
            d.target = '_blank';
            icon.src = user.iconURL();
            label.textContent = user.name();
            d.appendChild(icon);
            d.appendChild(label);
            return d;
        }
    });
    d.Chat = d.Class(d.Control, {
        selectable: true,
        notificationCount: 0,
        init: function (amber) {
            this.amber = amber;
            this.base(arguments);
            this.initElements('d-chat');
            this.element.appendChild(this.title = this.newElement('d-panel-title'));
            this.element.appendChild(this.contents = this.newElement('d-panel-contents d-scrollable'));
            // this.title.appendChild(this.newElement('d-panel-title-shadow'));
            this.title.appendChild(this.input = this.newElement('d-chat-input', 'input'));
            this.input.addEventListener('keydown', this.keyDown.bind(this));
        },
        keyDown: function (e) {
            if (e.keyCode === 13 && this.input.value !== '') {
                this.amber.socket.send({
                    $: 'chat.message',
                    message: this.input.value
                });
                this.showMessage(this.amber.currentUser, this.input.value);
                this.input.value = '';
            }
            if (e.keyCode === 32 && this.input.value === '') {
                e.preventDefault();
            }
        },
        focus: function () {
            this.removeNotification();
            this.input.focus();
            this.autoscroll();
        },
        blur: function () {
            this.input.blur();
        },
        show: function () {
            if (this.amber.userPanel.collapsed) {
                this.amber.userPanel.toggle();
            } else {
                this.focus();
            }
        },
        autoscroll: function () {
            this.contents.scrollTop = this.contents.scrollHeight;
        },
        notify: function () {
            if (!this.notification) {
                this.notification = this.newElement('d-chat-notification');
                this.amber.userPanel.element.appendChild(this.notification);
            }
            this.notification.textContent = ++this.notificationCount;
        },
        removeNotification: function () {
            if (this.notification) {
                this.amber.userPanel.element.removeChild(this.notification);
                this.notification = undefined;
                this.notificationCount = 0;
            }
        },
        addItems: function (history) {
            var i = 0,
                t = this;
            function next() {
                var item = history[i++];
                if (item) {
                    t.amber.getUserById(item[0], function (user) {
                        var line = t.createLine(user, item[1]);
                        t.contents.appendChild(line);
                        next();
                    });
                } else {
                    t.autoscroll();
                }
            }
            next();
        },
        createLine: function (user, chat) {
            var line = this.newElement('d-chat-line'),
                username = this.newElement('d-chat-username'),
                hidden = this.newElement('d-chat-line-hidden'),
                message = this.newElement('d-chat-message');
            username.textContent = user.name();
            hidden.textContent = ': ';
            message.textContent = chat;
            line.appendChild(username);
            line.appendChild(hidden);
            line.appendChild(message);
            return line;
        },
        showMessage: function (user, chat) {
            var line = this.createLine(user, chat);
            this.contents.appendChild(line);
            this.autoscroll();
            if (this.amber.userPanel.collapsed) {
                this.notify();
            }
        }
    });
    d.SpritePanel = d.Class(d.Control, {
        init: function (amber) {
            this.amber = amber;
            this.base(arguments);
            this.initElements('d-sprite-panel');
            this.add(amber.stageControls = new d.StageControls(amber))
                .add(amber.stageView = new d.StageView(amber))
                .add(amber.spriteList = new d.SpriteList(amber));
            this.element.appendChild(this.toggleButton = this.newElement('d-sprite-panel-toggle'));
            this.toggleButton.addEventListener('click', this.toggle.bind(this));
        },
        collapsed: false,
        setToggleVisible: function (toggleVisible) {
            this.toggleButton.style.display = toggleVisible ? '' : 'none';
        },
        toggle: function () {
            d.toggleClass(this.amber.element, 'd-collapse-sprite-panel', this.collapsed = !this.collapsed);
        },
        setCollapsed: function (collapsed) {
            if (this.collapsed !== collapsed) {
                this.toggle();
            }
        }
    })
    d.StageControls = d.Class(d.Control, {
        init: function (amber) {
            this.amber = amber;
            this.base(arguments);
            this.initElements('d-stage-controls');
            this.add(new d.Button('d-stage-control d-stage-control-go'))
                .add(new d.Button('d-stage-control d-stage-control-stop'))
                .add(new d.Button('d-stage-control d-stage-control-edit').onExecute(function () {
                    this.setEditMode(!this.editMode());
                }, amber));
        },
    });
    d.StageView = d.Class(d.Control, {
        init: function (amber) {
            this.amber = amber;
            this.base(arguments);
            this.initElements('d-stage');
        },
        createBackdrop: function () {
            var image = this._model.filteredImage();
            image.control = this;
            this.element.appendChild(this.image = image, this.element.firstChild);
        },
        '.model': {
            apply: function (model) {
                this.element.innerHTML = '';
                this.createBackdrop();
                model.children().forEach(function (sprite) {
                    this.add(new d.SpriteView(this.amber).setModel(sprite));
                }, this);
            }
        }
    });
    d.SpriteView = d.Class(d.Control, {
        init: function (amber) {
            this.amber = amber;
            this.base(arguments);
            this.initElements('d-sprite');
        },
        createCostume: function () {
            var image = this._model.filteredImage();
            image.control = this;
            this.element.appendChild(this.image = image, this.element.firstChild);
        },
        updateCostume: function () {
            var costume = this._model.currentCostume();
            this.image.style.WebkitTransform = 'translate(' + -costume.centerX() + 'px,' + -costume.centerY() + 'px)';
        },
        updatePosition: function () {
            var x = this._model.x() + 240,
                y = 180 - this._model.y();
            this.element.style.WebkitTransform = 'translate(' + x + 'px,' + y + 'px) rotate(' + (this._model.direction() - 90) + 'deg)';
        },
        '.model': {
            apply: function (model) {
                this.createCostume();
                this.updatePosition();
                model.onCostumeChange(this.updateCostume, this);
                model.onPositionChange(this.updatePosition, this);
            }
        }
    });
    d.SpriteList = d.Class(d.Control, {
        init: function (amber) {
            this.amber = amber;
            this.base(arguments);
            this.initElements('d-sprite-list');
            this.element.appendChild(this.container = this.newElement('d-panel-contents d-scrollable'));
            this.element.appendChild(this.title = this.newElement('d-panel-title'));
            // this.title.appendChild(this.titleShadow = this.newElement('d-panel-title-shadow'));
            this.title.appendChild(this.titleLabel = this.newElement('d-panel-title-label'));
            this.titleLabel.textContent = d.t('Sprites');
            this.icons = {};
        },
        addIcon: function (object) {
            return this.add(this.icons[object.id()] = new d.SpriteIcon(this.amber, object));
        },
        select: function (object) {
            if (this.selectedIcon) this.selectedIcon.deselect();
            (this.selectedIcon = this.icons[object.id()]).select();
        }
    });
    d.SpriteIcon = d.Class(d.Control, {
        acceptsClick: true,
        init: function (amber, object) {
            this.amber = amber;
            this.object = object;
            this.base(arguments);
            this.initElements('d-sprite-icon');
            this.element.appendChild(this.image = this.newElement('d-sprite-icon-image', 'canvas'));
            this.element.appendChild(this.label = this.newElement('d-sprite-icon-label'));
            this.onTouchStart(function () {
                amber.selectSprite(object);
            });
            this.updateLabel();
            object.onCostumeChange(this.updateImage, this);
        },
        updateImage: function () {
            var image = this.image,
                size = 200,
                x = image.getContext('2d'),
                costume = this.object.currentCostume().image(),
                ow = costume.width,
                oh = costume.height,
                ratio = Math.min(size / ow, size / oh),
                tw = Math.min(ow, ow * ratio),
                th = Math.min(oh, oh * ratio);
            image.width = size;
            image.height = size;
            x.drawImage(costume, (size - tw) / 2, (size - th) / 2, tw, th);
        },
        updateLabel: function () {
            this.label.textContent = this.object.name ? this.object.name() : d.t('Stage');
        },
        select: function () {
            d.addClass(this.element, 'd-sprite-icon-selected');
        },
        deselect: function () {
            d.removeClass(this.element, 'd-sprite-icon-selected');
        }
    });
    d.TabBar = d.Class(d.Control, {
        init: function (amber) {
            this.amber = amber;
            this.base(arguments);
            this.initElements('d-tab-bar');
            this.order = [];
            this.addTab(d.t('Scripts'));
            this.addTab(d.t('Costumes'));
            this.addTab(d.t('Sounds'));
        },
        addTab: function (label) {
            var i = this.children.length;
            this.order.push(i);
            return this.add(new d.Button('d-tab').setText(label).onExecute(function () {
                this.select(i);
            }, this));
        },
        select: function (i) {
            var j = this.order.length;
            if (this.selectedIndex != null) d.removeClass(this.children[this.selectedIndex].element, 'd-tab-selected');
            d.addClass(this.children[this.selectedIndex = i].element, 'd-tab-selected');
            this.order.splice(this.order.indexOf(i), 1);
            this.order.unshift(i);
            while (j--) {
                this.children[this.order[j]].element.style.zIndex = -j;
            }
            switch (i) {
            case 0:
                this.amber.setTab(this.amber.selectedSprite().scripts());
                break;
            case 1:
                this.amber.setTab(new d.CostumeEditor(this.amber.selectedSprite()));
                break;
            case 2:
                this.amber.setTab(new d.SoundEditor(this.amber.selectedSprite()));
                break;
            }
        }
    });
    d.CostumeEditor = d.Class(d.Control, {
        init: function (object) {
            var icons = this.icons = {},
                id = 0,
                selectedId = object.costumeIndex() + 1;
            this.base(arguments);
            this.initElements('d-costume-editor d-editor', 'd-costume-editor-list d-scrollable');
            this.element.appendChild(this.contents = this.newElement('d-costume-editor-contents'));
            (this.object = object).costumes().forEach(function (costume) {
                costume.$$editorId = ++id;
                this.add(icons[id] = new d.CostumeEditor.Icon(this, costume));
                if (id === selectedId) {
                    this.selectedCostume = costume;
                    icons[id].select();
                }
            }, this);
        },
        select: function (costume) {
            if (this.selectedCostume) {
                this.icons[this.selectedCostume.$$editorId].deselect();
            }
            this.icons[(this.selectedCostume = costume).$$editorId].select();
            this.object.setCostumeIndex(costume.$$editorId - 1);
        }
    });
    d.CostumeEditor.Icon = d.Class(d.Control, {
        acceptsClick: true,
        init: function (editor, costume) {
            this.costume = costume;
            this.base(arguments);
            this.initElements('d-costume-icon');
            this.element.appendChild(this.image = this.newElement('d-costume-icon-image', 'canvas'));
            this.element.appendChild(this.label = this.newElement('d-costume-icon-label'));
            this.onTouchStart(function () {
                editor.select(costume);
            });
            this.updateLabel();
            costume.onImageChange(this.updateImage, this);
            this.updateImage();
        },
        updateImage: function () {
            var image = this.image,
                size = 200,
                x = image.getContext('2d'),
                costume = this.costume.image(),
                ow = costume.width,
                oh = costume.height,
                ratio = Math.min(size / ow, size / oh),
                tw = Math.min(ow, ow * ratio),
                th = Math.min(oh, oh * ratio);
            image.width = size;
            image.height = size;
            x.drawImage(costume, (size - tw) / 2, (size - th) / 2, tw, th);
        },
        updateLabel: function () {
            this.label.textContent = this.costume.name();
        },
        select: function () {
            d.addClass(this.element, 'd-costume-icon-selected');
        },
        deselect: function () {
            d.removeClass(this.element, 'd-costume-icon-selected');
        }
    });
    d.SoundEditor = d.Class(d.Control, {
        init: function () {
            this.base(arguments);
            this.initElements('d-sound-editor d-editor d-scrollable');
        }
    });
    d.BlockEditor = d.Class(d.Control, {
        padding: 10,
        acceptsScrollWheel: true,
        init: function () {
            this.base(arguments);
            this.initElements('d-block-editor d-editor d-scrollable');
            this.fill = this.newElement('d-block-editor-fill');
            this.element.appendChild(this.fill);
            this.element.addEventListener('scroll', this.fit.bind(this));
            this.onScrollWheel(this.scrollWheel);
        },
        scrollWheel: function (e) {
            var newTop = this.element.scrollTop + e.y,
                newLeft = this.element.scrollLeft + e.x,
                delta;
            if ((delta = newLeft - this.element.scrollWidth + this.element.offsetWidth) > 0) {
                this.fill.style.width = (this.fillWidth += delta) + 'px';
            }
            if ((delta = newTop - this.element.scrollHeight + this.element.offsetHeight) > 0) {
                this.fill.style.height = (this.fillHeight += delta) + 'px';
            }
            this.element.scrollLeft = newLeft;
            this.element.scrollTop = newTop;
        },
        fit: function () {
            var bb = this.fill.getBoundingClientRect(),
                p = this.padding,
                c = this.children,
                i = c.length,
                w = 0,
                h = 0,
                x = 0,
                y = 0,
                b, v;
            while (i--) {
                b = c[i].element.getBoundingClientRect();
                if ((v = b.left - bb.left - p) < x) {
                    w += x - v;
                    x = v;
                }
                w = Math.max(w, v + c[i].element.offsetWidth - x);
                if ((v = b.top - bb.top - p) < y) {
                    h += y - v;
                    y = v;
                }
                h = Math.max(h, v + c[i].element.offsetHeight - y);
            }
            if (x < 0 || y < 0) {
                i = c.length;
                while (i--) {
                    b = c[i].getPosition();
                    c[i].initPosition(b.x - x, b.y - y);
                }
                x = 0;
                y = 0;
            }
            this.fill.style.width = (this.fillWidth = Math.max(w + p * 2, this.element.scrollLeft + this.element.offsetWidth)) + 'px';
            this.fill.style.height = (this.fillHeight = Math.max(h + p * 2, this.element.scrollTop + this.element.offsetHeight)) + 'px';
            this.fill.style.left = x + 'px';
            this.fill.style.top = y + 'px';
        }
    });
    d.BlockStack = d.Class(d.Control, {
        isStack: true,
        init: function () {
            this.base(arguments);
            this.onTouchMove(this.touchMove);
            this.onTouchEnd(this.touchEnd);
            this.initElements('d-block-stack');
        },
        setPosition: function (x, y, callback) {
            setTimeout(function () {
                this.element.style.WebkitTransition =
                    this.element.style.MozTransition = 'top .3s ease, left .3s ease';
                this.element.style.left = x + 'px';
                this.element.style.top = y + 'px';
                setTimeout(function () {
                    this.element.style.WebkitTransition =
                        this.element.style.MozTransition = '';
                    if (callback) callback();
                }.bind(this), 300);
            }.bind(this), 16);
            return this;
        },
        removePosition: function () {
            this.element.style.left =
                this.element.style.top = '';
        },
        initPosition: function (x, y) {
            this.element.style.left = x + 'px';
            this.element.style.top = y + 'px';
            return this;
        },
        getPosition: function () {
            var app = this.amber(), e, bb, bbe;
            if (!app) {
                return {
                    x: parseInt(this.element.style.left),
                    y: parseInt(this.element.style.top)
                };
            }
            e = app.editor().element;
            bb = this.element.getBoundingClientRect();
            bbe = e.getBoundingClientRect();
            return {
                x: bb.left + e.scrollLeft - bbe.left,
                y: bb.top + e.scrollTop - bbe.top
            };
        },
        x: function () {
            var e = this.amber().editor().element;
            return this.element.getBoundingClientRect().left + e.scrollLeft - e.getBoundingClientRect().left;
        },
        y: function () {
            var e = this.amber().editor().element;
            return this.element.getBoundingClientRect().top + e.scrollTop - e.getBoundingClientRect().top;
        },
        toJSON: function (inline) {
            var children = this.children.map(function (block) {
                    return block.toJSON();
                }), bb;
            return inline ? children : [(bb = this.getPosition()).x, bb.y, children];
        },
        fromJSON: function (a, tracker, amber, inline) {
            if (!inline) {
                this.element.style.left = a[0] + 'px';
              this.element.style.top = a[1] + 'px';
            }
            (inline ? a : a[2]).forEach(function (block) {
                this.add(d.Block.fromJSON(block, tracker, amber));
            }, this);
            return this;
        },
        copy: function () {
            var copy = new this.constructor(), i = 0, child;
            while (child = this.children[i++]) {
                copy.add(child.copy());
            }
            return copy;
        },
        reporter: function () {
            return this.children.length && this.children[0].isReporter;
        },
        terminal: function () {
            return this.children.length && this.children[this.children.length - 1].terminal();
        },
        hat: function () {
            return this.children.length && this.children[0].isHat;
        },
        top: function () {
            return this.children[0];
        },
        insertStack: function (stack, next) {
            var children = stack.children, child;
            while (child = children[0]) {
                this.insert(child, next);
            }
            stack.destroy();
            this.amber().editor().fit();
            return this;
        },
        appendStack: function (stack) {
            var children = stack.children, child;
            while (child = children[0]) {
                this.add(child);
            }
            stack.destroy();
            this.amber().editor().fit();
            return this;
        },
        splitStack: function (top) {
            var i = this.children.indexOf(top), stack, child;
            if (top === this.top()) {
                return this;
            }
            stack = new d.BlockStack;
            while (child = this.children[i]) {
                stack.add(child);
            }
            return stack;
        },
        dragStack: function (e, top) {
            var bb = top.element.getBoundingClientRect(),
                app = this.amber(),
                topTop = top === this.top(),
                stack = this.splitStack(top);
            if (topTop && this.parent && this.parent.isStackSlot) {
                this.parent.setValue();
            }
            stack.startDrag(app, e, bb);
        },
        startDrag: function (app, e, bb) {
            this.feedback = this.newElement('d-block-feedback');
            d.addClass(this.element, 'd-block-stack-dragging');
            app.element.appendChild(this.feedback);
            this.element.style.position = 'fixed';
            this.element.style.left = bb.left + 'px';
            this.element.style.top = bb.top + 'px';
            app.mouseDown = true;
            app.mouseDownControl = this;
            app.add(this);
            this.dragStartEvent = e;
            this.dragStartBB = bb;
        },
        touchMove: function (e) {
            var tolerance = 12,
                stackTolerance = 20,
                t = this,
                isTerminal, isHat, stacks, blocks, i,
                stack, last, target, targetDistance;
            function closer(test, newTarget) {
                var dx = (test.left + test.right) / 2 - e.x,
                    dy = (test.top + test.bottom) / 2 - e.y;
                    distance = dx * dx + dy * dy;
                if (!target || distance < targetDistance || newTarget.argument && target.argument.hasChild(newTarget.argument)) {
                    target = newTarget;
                    targetDistance = distance;
                    return;
                }
            }
            // this.element.style.left = this.dragStartBB.left + e.x - this.dragStartEvent.x + 'px';
            // this.element.style.top = this.dragStartBB.top + e.y - this.dragStartEvent.y + 'px';
            this.element.style.left = (e.x = this.dragStartBB.left + e.x - this.dragStartEvent.x) + 'px';
            this.element.style.top = (e.y = this.dragStartBB.top + e.y - this.dragStartEvent.y) + 'px';
            if (this.reporter()) {
                function add(block) {
                    var j, stack, k, arg, bb, test;
                    if (!(t.hasChild(block))) {
                        j = block.arguments.length;
                        while (j--) {
                            arg = block.arguments[j];
                            if (arg.isStackSlot && (stack = arg.value())) {
                                stack = stack.children;
                                k = stack.length;
                                while (k--) {
                                    add(stack[k]);
                                }
                            }
                            bb = arg.element.getBoundingClientRect();
                            if (d.inBB(e, test = {
                                left: bb.left - tolerance,
                                right: bb.right + tolerance,
                                top: bb.top - tolerance,
                                bottom: bb.bottom + tolerance
                            }) && arg.acceptsReporter(t.children[0])) closer(test, {
                                type: 'argument',
                                block: block,
                                argument: arg,
                                bb: bb
                            });
                            if (arg.isBlock) {
                                add(arg);
                            }
                        }
                    }
                }
                blocks = this.amber().editor().children;
                i = blocks.length;
                while (i--) {
                    blocks[i].children.forEach(function (block) {
                        add(block);
                    });
                }
            } else {
                isTerminal = this.terminal();
                isHat = this.hat();
                stacks = this.amber().editor().childrenSatisfying(function (child) {
                    return child.isStack || child.isStackSlot && !child.anyParentSatisfies(function (p) {
                        return p.isPalette;
                    });
                });
                i = stacks.length;
                while (i--) {
                    if ((stack = stacks[i]) !== this) {
                        if (stack.isStackSlot) {
                            if (!stack.value() && !isHat) {
                                bb = stack.element.getBoundingClientRect();
                                if (d.inBB(e, test = {
                                    left: bb.left - stackTolerance,
                                    right: bb.left + stackTolerance,
                                    top: bb.top - stackTolerance,
                                    bottom: bb.top + stackTolerance
                                })) closer(test, {
                                    type: 'stack-slot',
                                    slot: stack,
                                    bb: bb
                                });
                            }
                        } else if (!stack.reporter()) {
                            j = stack.children.length;
                            while (j--) {
                                block = stack.children[j];
                                bb = block.element.getBoundingClientRect();
                                if (!isTerminal && (j === 0 && !stack.parent.parent.isBlock || !isHat) && (j !== 0 || !stack.hat()) && d.inBB(e, test = {
                                    left: bb.left - stackTolerance,
                                    right: bb.left + stackTolerance,
                                    top: bb.top - stackTolerance,
                                    bottom: bb.top + stackTolerance
                                })) closer(test, {
                                    type: 'above',
                                    block: block,
                                    bb: bb
                                });
                                if (j === stack.children.length - 1 && !isHat && !stack.terminal()) {
                                    if (d.inBB(e, test = {
                                        left: bb.left - stackTolerance,
                                        right: bb.left + stackTolerance,
                                        top: bb.bottom - stackTolerance,
                                        bottom: bb.bottom + stackTolerance
                                    })) closer(test, {
                                        type: 'below',
                                        block: block,
                                        bb: bb
                                    });
                                }
                            }
                        }
                    }
                }
            }
            if (this.dropTarget = target) {
                this.feedback.style.display = 'block';
                switch (target.type) {
                case 'above':
                case 'below':
                    this.feedback.style.left = target.bb.left - 2 + 'px';
                    this.feedback.style.top = target.bb[target.type === 'above' ? 'top' : 'bottom'] - 2 + 'px';
                    this.feedback.style.width = target.bb.right - target.bb.left + 4 + 'px';
                    this.feedback.style.height = '4px';
                    break;
                case 'stack-slot':
                    this.feedback.style.left = target.bb.left + 2 + 'px';
                    this.feedback.style.top = target.bb.top + 2 + 'px';
                    this.feedback.style.width = target.bb.right - target.bb.left - 4 + 'px';
                    this.feedback.style.height = '4px';
                    break;
                case 'argument':
                    this.feedback.style.left = target.bb.left - 6 + 'px';
                    this.feedback.style.top = target.bb.top - 6 + 'px';
                    this.feedback.style.width = target.bb.right - target.bb.left + 12 + 'px';
                    this.feedback.style.height = target.bb.bottom - target.bb.top + 12 + 'px';
                    break;
                }
            } else {
                this.feedback.style.display = 'none';
            }
        },
        touchEnd: function (e) {
            var palettes = d.BlockPalette.palettes,
                i = palettes.length,
                block, slot;
            d.removeClass(this.element, 'd-block-stack-dragging');
            this.amber().element.removeChild(this.feedback);
            while (i--) {
                if (d.bbTouch(palettes[i].element, e)) {
                    this.top().send(function () {
                        return {
                            $: 'block.delete',
                            block$id: this.id()
                        };
                    });
                    this.amber().editor().fit();
                    this.destroy();
                    return;
                }
            }
            if (this.dropTarget) {
                switch (this.dropTarget.type) {
                case 'above':
                    block = this.dropTarget.block;
                    this.top().send(function () {
                        return {
                            $: 'block.attach',
                            block$id: this.id(),
                            type: d.BlockAttachType.stack$insert,
                            target$id: block.id()
                        };
                    });
                    block.parent.insertStack(this, block);
                    break;
                case 'below':
                    block = this.dropTarget.block;
                    this.top().send(function () {
                        return {
                            $: 'block.attach',
                            block$id: this.id(),
                            type: d.BlockAttachType.stack$append,
                            target$id: block.id()
                        };
                    });
                    block.parent.appendStack(this);
                    break;
                case 'stack-slot':
                    slot = this.dropTarget.slot;
                    block = slot.parent;
                    this.top().send(function () {
                        return {
                            $: 'block.attach',
                            block$id: this.id(),
                            type: d.BlockAttachType.slot$command,
                            target$id: block.parent.id(),
                            slot$index: block.parent.slotIndex(block)
                        };
                    });
                    slot.setValue(this);
                    break;
                case 'argument':
                    slot = this.dropTarget.argument;
                    block = this.dropTarget.block;
                    this.top().send(function () {
                        return {
                            $: 'block.attach',
                            block$id: this.id(),
                            type: d.BlockAttachType.slot$replace,
                            target$id: block.id(),
                            slot$index: block.slotIndex(slot)
                        };
                    });
                    block.replaceArg(slot, this.children[0]);
                    this.destroy();
                    break;
                }
            } else {
                this.top().send(function () {
                    return {
                        $: 'block.move',
                        block$id: this.id(),
                        x: this.x(),
                        y: this.y()
                    };
                });
                this.embed();
            }
        },
        embed: function () {
            var editor = this.amber().editor(),
                bbe = editor.element.getBoundingClientRect(),
                bbb = this.element.getBoundingClientRect();
            editor.add(this);
            this.element.style.position = 'absolute';
            this.element.style.left = bbb.left + editor.element.scrollLeft - bbe.left + 'px';
            this.element.style.top = bbb.top + editor.element.scrollTop - bbe.top + 'px';
            editor.fit();
            return this;
        },
        destroy: function () {
            if (this.parent) {
                this.parent.remove(this);
            }
        }
    });
    d.CategorySelector = d.Class(d.Control, {
        acceptsClick: true,

        init: function () {
            this.base(arguments);
            this.initElements('d-panel-title');
            // this.element.appendChild(this.shadow = this.newElement('d-panel-title-shadow'));
            this.buttons = [];
            this.categories = [];
            this.byCategory = {};
            this.onTouchStart(this.touchStart);
        },

        '@CategorySelect': null,

        addCategory: function (category) {
            var button = this.newElement('d-category-button'),
                color = this.newElement('d-category-button-color'),
                i, width;
            color.style.backgroundColor = d.categoryColors[category];
            button.appendChild(color);
            this.element.appendChild(button);
            this.buttons.push(button);
            this.categories.push(category);
            this.byCategory[category] = button;
            if ((i = this.buttons.length) === 1) {
                this.selectCategory('motion');
            }
            width = 100 / i + '%';
            while (i--) {
                this.buttons[i].style.width = width;
            }
            return this;
        },
        selectCategory: function (category) {
            if (this.selectedCategory) {
                d.removeClass(this.byCategory[this.selectedCategory], 'active');
            }
            if (this.selectedCategory = category) {
                d.addClass(this.byCategory[category], 'active');
            }
            this.dispatch('CategorySelect', new d.ControlEvent().setControl(this).withProperties({
                category: category
            }));
        },
        touchStart: function (e) {
            var i = this.buttons.length;
            while (i--) {
                if (d.bbTouch(this.buttons[i], e)) {
                    this.selectCategory(this.categories[i]);
                }
            }
        }
    });
    d.BlockPalette = d.Class(d.Control, {
        isPalette: true,
        init: function () {
            this.base(arguments);
            this.initElements('d-block-palette');
            this.add(this.categorySelector = new d.CategorySelector().onCategorySelect(this.selectCategory, this));
            this.blockLists = {};
            d.BlockPalette.palettes.push(this);
        },
        addCategory: function (category, blockList) {
            this.blockLists[category] = blockList;
            this.categorySelector.addCategory(category);
            return this;
        },
        selectCategory: function (e) {
            if (this.selectedBlockList) {
                this.remove(this.selectedBlockList);
            }
            this.insert(this.selectedBlockList = this.blockLists[e.category], this.categorySelector);
        }
    }, {
        palettes: []
    });
    d.BlockList = d.Class(d.Control, {
        init: function () {
            this.base(arguments);
            this.initElements('d-panel-contents d-scrollable', 'd-block-list-contents');
            this.list = this.container;
        },
        add: function (child) {
            this.list.appendChild(this.container = this.newElement('d-block-list-item'));
            return this.base(arguments, child);
        },
        addSpace: function () {
            this.list.appendChild(this.newElement('d-block-list-space'));
            return this;
        }
    });
    d.arg = {};
    d.arg.Base = d.Class(d.Control, {
        acceptsReporter: function (reporter) {
            return false;
        },
        toJSON: function () {
            return this.value();
        },
        claimEdits: function () {},
        unclaimEdits: function () {},
        claim: function () {
            var id = this.parent.id();
            if (id === -1) return;
            this.amber().socket.send({
                $: 'slot.claim',
                block$id: id,
                slot$index: this.parent.slotIndex(this)
            });
        },
        unclaim: function () {
            if (this.parent.id() === -1) return;
            this.amber().socket.send({
                $: 'slot.claim',
                block$id: -1
            });
        },
        sendEdit: function (value) {
            this.amber().socket.send({
                $: 'slot.set',
                block$id: this.parent.id(),
                slot$index: this.parent.slotIndex(this),
                value: value
            });
        },
        edited: function () {
            this.sendEdit(this.value());
        },
        claimedBy: function (user) {
            d.addClass(this.element, 'd-arg-claimed');
            this.claimEdits();
            this.claimedUser = user;
            this._isClaimed = true;
        },
        unclaimed: function () {
            d.removeClass(this.element, 'd-arg-claimed');
            this.unclaimEdits();
            this._isClaimed = false;
        },
        isClaimed: function () {
            return this._isClaimed;
        },
        getPosition: function () {
            var e = this.amber().editor().element,
                bb = this.element.getBoundingClientRect(),
                bbe = e.getBoundingClientRect();
            return {
                x: bb.left + e.scrollLeft - bbe.left,
                y: bb.top + e.scrollTop - bbe.top
            };
        },
        '.value': {
            get: function () {
                return null;
            }
        }
    });
    d.arg.Label = d.Class(d.arg.Base, {
        init: function () {
            this.base(arguments);
            this.initElements('d-block-text');
        },
        copy: function () {
            var copy = new this.constructor().setText(this._text);
            if (this._color !== '#fff') copy.setColor(this._color);
            return copy;
        },
        '.text': {
            apply: function (text) {
                this.element.textContent = text;
            }
        },
        '.value': {
            set: function (v) {
                this.setText(v);
            },
            get: function () {
                return this._text;
            }
        },
        '.color': {
            value: '#fff',
            apply: function (color) {
                this.element.style.color = color;
            }
        }
    });
    d.arg.TextField = d.Class(d.arg.Base, {
        acceptsClick: true,
        acceptsReporter: function (reporter) {
            return !this._numeric || !reporter.isBoolean;
        },
        init: function () {
            this.base(arguments);
            this.initElements('d-block-string');
            this.element.appendChild(this.input = this.newElement('', 'input'));
            this.menuButton = this.newElement('d-block-field-menu');
            this.onTouchStart(this.touchStart);
            this.input.addEventListener('input', this.autosize.bind(this));
            this.input.addEventListener('input', this.edited.bind(this));
            this.input.addEventListener('keypress', this.key.bind(this));
            this.input.addEventListener('focus', this.focus.bind(this));
            this.input.addEventListener('blur', this.blur.bind(this));
            this.input.style.width = '1px';
        },
        copy: function () {
            var copy = new this.constructor().setText(this.text());
            if (this._numeric) copy.setNumeric(true);
            if (this._integral) copy.setIntegral(true);
            if (this._inline) copy.setInline(true);
            if (this._items) copy.setItems(this._items);
            return copy;
        },
        edited: function () {
            this.sendEdit(this.text());
        },
        '.text': {
            set: function (v) {
                this.input.value = v;
                this.autosize();
            },
            get: function () {
                return this.input.value;
            }
        },
        '.value': {
            set: function (v) {
                this.setText(v);
            },
            get: function () {
                var v = this.text();
                if (this._numeric) {
                    v = +v;
                    if (v !== v) throw new TypeError('Not a number.');
                }
                return v;
            }
        },
        '.numeric': {
            apply: function (numeric) {
                this.element.className = numeric ? 'd-block-number' : 'd-block-string';
            }
        },
        '.integral': {},
        '.inline': {
            apply: function (inline) {
                d.toggleClass(this.element, 'd-block-field-inline', inline);
            }
        },
        '.items': {
            apply: function (items) {
                if (items) {
                    this.element.appendChild(this.menuButton);
                } else if (this.menuButton.parentNode) {
                    this.menuButton.parentNode.removeChild(this.menuButton);
                }
            }
        },
        claimEdits: function () {
            this.input.disabled = true;
        },
        unclaimEdits: function () {
            this.input.disabled = false;
        },
        focus: function () {
            if (this._numeric && /[^0-9\.+-]/.test(this.input.value)) this.setText('');
            this.claim();
        },
        blur: function () {
            this.unclaim();
        },
        touchStart: function (e) {
            if (d.bbTouch(this.menuButton, e) && this._items) {
                new d.Menu().onExecute(function (e) {
                    var item = e.item;
                    this.setText(typeof item === 'string' ? item : item.hasOwnProperty('value') ? item.value : item.action);
                }.bind(this)).setItems(this._items).popDown(this, this.menuButton, this.text());
            }
        },
        autosize: function (e) {
            var cache = d.arg.TextField.cache,
                measure = d.arg.TextField.measure;
            // (document.activeElement === this.input ? /[^0-9\.+-]/.test(this.input.value) :
            if (e && this._numeric && (this._integral ? isNaN(this.input.value) || +this.input.value % 1 : isNaN(this.input.value))) {
                this.input.value = (this._integral ? parseInt : parseFloat)(this.input.value) || 0;
                this.input.focus();
                this.input.select();
            }
            if (!(width = cache[this.input.value])) {
                measure.style.display = 'inline-block';
                measure.textContent = this.input.value;
                width = cache[this.input.value] = measure.offsetWidth + 1; // Math.max(1, measure.offsetWidth)
                measure.style.display = 'none';
            }
            this.input.style.width = width + 'px';
        },
        key: function (e) {
            var v;
            if (this._numeric) {
                v = this.input.value;
                if (!e.charCode || e.metaKey || e.ctrlKey ||
                    (this.input.selectionStart !== 0 || v[0] !== '-' && v[0] !== '+') && (
                        e.charCode >= 0x30 && e.charCode <= 0x39 ||
                        !this._integral && e.charCode === 0x2e && v.indexOf('.') === -1) ||
                    (e.charCode === 0x2d ||
                        e.charCode === 0x2b) &&
                        v[0] !== '-' && v[0] !== '+' &&
                        this.input.selectionStart === 0) return;
                e.preventDefault();
                return;
            }
        }
    });
    d.arg.TextField.measure = document.createElement('div');
    d.arg.TextField.measure.className = 'd-block-field-measure';
    d.arg.TextField.cache = {};
    document.body.appendChild(d.arg.TextField.measure);
    d.arg.Enum = d.Class(d.arg.Base, {
        acceptsClick: true,
        acceptsReporter: function () {
            return true;
        },
        init: function () {
            this.base(arguments);
            this.initElements('d-block-enum');
            this.element.appendChild(this.label = this.newElement('', 'span'));
            this.element.appendChild(this.menuButton = this.newElement('d-block-enum-menu-button'));
            this.onTouchStart(this.touchStart);
        },
        copy: function () {
            var copy = new this.constructor().setItems(this._items).setValue(this.value());
            if (this._inline) copy.setInline(true);
            return copy;
        },
        '.items': {
            apply: function (items) {
                if (items[0]) this.setValue(items[0]);
            }
        },
        '.text': {
            set: function (v) {
                this.label.textContent = v;
            },
            get: function () {
                return this.label.textContent;
            }
        },
        '.value': {
            set: function (v) {
                this._value = v;
                if (typeof v == 'object') {
                    this.setText(d.t(v.$));
                } else {
                    this.setText(v);
                }
            },
            get: function () {
                return this._value;
            }
        },
        '.inline': {
            apply: function (inline) {
                d.toggleClass(this.element, 'd-block-enum-inline', inline);
            }
        },
        touchStart: function (e) {
            if (this._inline && !d.bbTouch(this.menuButton, e)) {
                this.hoistTouchStart(e);
                return;
            }
            new d.Menu().onExecute(function (e) {
                var item = e.item;
                this.setValue(
                    typeof item === 'string' ? item :
                    item.hasOwnProperty('value') ? item.value : item.action);
                this.sendEdit(this.value());
            }.bind(this)).setItems((typeof this._items === 'function' ? this._items() : this._items).map(function (item) {
                return item.$ ? { title: d.t(item.$), action: item } : item;
            })).popUp(this, this.label, this.value());
        }
    });
    d.arg.Var = d.Class(d.arg.Enum, {
        init: function () {
            this.base(arguments);
        },
        setValue: function (value) {
            this.base(arguments, value);
            if (this.parent) {
                this.parent.setCategory(value.$ ? d.VariableColors[value.$] : 'data');
                if (this.parent.varChanged) this.parent.varChanged();
            }
            return this;
        }
    });
    d.arg.Bool = d.Class(d.arg.Base, {
        acceptsReporter: function (reporter) {
            return true;
        },
        init: function () {
            this.base(arguments);
            this.initElements('d-block-bool');
            this.element.appendChild(this.newElement('d-block-bool-fill'));
            this.element.appendChild(this.newElement('d-block-bool-fill-rt'));
            this.element.appendChild(this.newElement('d-block-bool-fill-rb'));
            this.element.appendChild(this.newElement('d-block-bool-fill-lt'));
            this.element.appendChild(this.newElement('d-block-bool-fill-lb'));
        },
        copy: function () {
            return new this.constructor();
        },
        '.value': {
            set: function () {},
            get: function () {
                return false;
            }
        }
    });
    d.arg.Color = d.Class(d.arg.Base, {
        acceptsClick: true,
        init: function () {
            function h() { return '0123456789abcdef'[Math.random() * 16 | 0]; }
            this.base(arguments);
            this.initElements('d-block-color');
            this.element.appendChild(this.picker = this.newElement('d-block-color-input', 'input'));
            this.picker.type = 'color';
            this.picker.addEventListener('input', this.colorSelected.bind(this));
            this.setValue('#' + h() + h() + h() + h() + h() + h());
        },
        colorSelected: function () {
            this.setValue(this.picker.value);
            this.edited();
        },
        copy: function () {
            return new this.constructor();
        },
        '.value': {
            apply: function (color) {
                this.element.style.backgroundColor = this.picker.value = color;
            }
        }
    });
    d.arg.List = d.Class(d.arg.Enum, {
        init: function () {
            this.base(arguments);
            this.setItems(['var', 'a', 'b', 'c', d.Menu.separator, 'global', 'counter']);
        },
        acceptsReporter: function (reporter) {
            return !reporter.isBoolean;
        },
        '.value': {
            set: function (v) {
                // console.warn('List set is unimplemented');
                this.setText(v);
            },
            get: function () {
                console.warn('List get is unimplemented');
                return null;
            }
        }
    });
    d.arg.CommandSlot = d.Class(d.arg.Base, {
        isStackSlot: true,
        reporter: function () {
            return false;
        },
        acceptsReporter: function (reporter) {
            return false;
        },
        toJSON: function () {
            return this.children.length ? this.children[0].toJSON()[2] : null;
        },
        init: function () {
            this.base(arguments);
            this.initElements('d-block-c');
            this.element.appendChild(this.newElement('d-block-c-puzzle'));
        },
        copy: function () {
            var copy = new this.constructor();
            if (this._value) copy.setValue(this._value.copy());
            return copy;
        },
        '.value': {
            set: function (value) {
                if (this._value) {
                    this.remove(this._value);
                }
                if (this._value = value) {
                    this.add(value);
                }
                d.toggleClass(this.element, 'd-block-c-has-content', value);
            }
        }
    });
    d.arg.ReporterSlot = d.Class(d.arg.Base, {
        acceptsReporter: function (reporter) {
            return true;
        },
        init: function () {
            this.base(arguments);
            this.initElements('d-block-reporter');
        },
        copy: function () {
            return new this.constructor();
        }
    });
    d.arg.Parameters = d.Class(d.arg.Base, {
        DEFAULT_PARAMETERS: 'abcdefghijklmnopqrstuvwxyz',
        acceptsClick: true,
        isPalette: true,
        init: function () {
            this.base(arguments);
            this.onTouchStart(this.touchStart);
            this.initElements('d-block-parameters', 'd-block-parameters-container');
            this.element.appendChild(this.removeButton = this.newElement('d-block-parameters-remove'));
            this.element.appendChild(this.addButton = this.newElement('d-block-parameters-add'));
            this.element.appendChild(this.arrow = this.newElement('d-block-parameters-arrow'));
            this.removeButton.style.display = 'none';
            this.arrow.style.display = 'none';
            this.parameters = [];
        },
        copy: function () {
            var copy = new this.constructor(),
                i = 0,
                l = this.parameters.length;
            while (i < l) {
                copy.addParameter(this.parameters[i++]);
            }
            return copy;
        },
        touchStart: function (e) {
            if (d.bbTouch(this.addButton, e)) {
                this.addParameter(this.DEFAULT_PARAMETERS[this.parameters.length] || '' + this.parameters.length);
            } else if (d.bbTouch(this.removeButton, e)) {
                this.removeParameter();
            } else {
                this.hoistTouchStart(e);
            }
        },
        addParameter: function (name) {
            if (!this.parameters.length) {
                this.removeButton.style.display = '';
                this.arrow.style.display = '';
                d.addClass(this.element, 'd-block-parameters-enabled');
            }
            this.parameters.push(name);
            this.add(new d.ReporterBlock().setSpec('%var:template').setArgs(name).setTemplateSpec('%var:inline').setTemplateArgs(name).setCategory('parameter'));
        },
        removeParameter: function (i) {
            if (i == null) i = this.children.length - 1;
            this.parameters.splice(i, 1);
            this.remove(this.children[i]);
            if (!this.parameters.length) {
                this.removeButton.style.display = 'none';
                this.arrow.style.display = 'none';
                d.removeClass(this.element, 'd-block-parameters-enabled');
            }
        }
    });
    d.categoryColors = {
        // motion: 'rgb(29%, 42%, 83%)',
        // motor: 'rgb(11%, 31%, 73%)',
        // looks: 'rgb(56%, 34%, 89%)',
        // sound: 'rgb(81%, 29%, 85%)',
        // pen: 'rgb(0%, 63%, 47%)',
        // control: 'rgb(90%, 66%, 13%)',
        // sensing: 'rgb(2%, 58%, 86%)',
        // operators: 'rgb(38%, 76%, 7%)',
        // variables: 'rgb(95%, 46%, 11%)',
        // lists: 'rgb(85%, 30%, 7%)',
        // other: 'rgb(62%, 62%, 62%)'
        system: 'rgb(50%, 50%, 50%)',

        // Object.keys(d.categoryColors).reduce(function (o,k) { var c = d.categoryColors[k].toString(16); o[k] = '#' + '000000'.substr(c.length) + c; return o }, {});
        // 'undefined': 13903912,
        // motion: 4877524,
        // looks: 9065943,
        // sound: 12272323,
        // pen: 957036,
        // events: 13140784,
        // control: 14788890,
        // sensing: 2926050,
        // operators: 6076178,
        // data: 15629590,
        // custom: 5447321,
        // parameter: 5851057,
        // lists: 13392674,
        // extensions: 6761849
        control: '#e1a91a',
        custom: '#531e99',
        data: '#ee7d16',
        events: '#c88330',
        extensions: '#672d79',
        lists: '#cc5b22',
        looks: '#8a55d7',
        motion: '#4a6cd4',
        operators: '#5cb712',
        parameter: '#5947b1',
        pen: '#0e9a6c',
        sensing: '#2ca5e2',
        sound: '#bb42c3',
        undefined: '#d42828'
    };
    d.Block = d.Class(d.Control, {
        isBlock: true,
        acceptsClick: true,
        init: function () {
            this.base(arguments);
            this.fill = [];
            this.onDragStart(this.dragStart);
            this.onContextMenu(this.showContextMenu)
        },
        toJSON: function () {
            if (this.selector() === 'cClosure') {
                return this.arguments[0].toJSON();
            }
            return [this._id, this.selector()].concat(this.arguments.map(function (a) {
                return a.toJSON();
            }));
        },
        '.id': {
            value: -1
        },
        slotIndex: function (arg) {
            return this.arguments.indexOf(arg);
        },
        setAmber: function (amber) {
            var socket;
            if (this._id !== -1) {
                amber.blocks[this._id] = this;
                if (this.sendQueue) {
                    socket = amber.socket;
                    this.sendQueue.forEach(function (f) {
                        socket.send(f.call(this));
                    }, this);
                    this.sendQueue = null;
                }
            }
        },
        detach: function () {
            var stack,
                bb = this.getPosition(),
                editor = this;
            do {
                editor = editor.parent;
            } while (editor && !(editor instanceof d.BlockEditor));
            if (this.parent.isStack) {
                ;
                if (this.parent.top() === this) {
                    if (this.parent.parent && this.parent.parent.isStackSlot) {
                        this.parent.parent.setValue(null);
                        this.parent.initPosition(bb.x, bb.y);
                    }
                    editor.add(this.parent);
                    return this.parent.show();
                }
                stack = this.parent.splitStack(this);
                stack.initPosition(bb.x, bb.y);
                editor.add(stack);
                return stack;
            }
            stack = new d.BlockStack();
            stack.initPosition(bb.x, bb.y);
            editor.add(stack);
            this.parent.restoreArg(this);
            return stack.add(this);
        },
        send: function (f) {
            var socket = this.amber().socket;
            if (this._id === -1) {
                (this.sendQueue || (this.sendQueue = [])).push(f);
                return this;
            }
            socket.send(f.call(this));
            return this;
        },
        getPosition: function () {
            var e = this.amber().editor().element,
                bb = this.element.getBoundingClientRect(),
                bbe = e.getBoundingClientRect();
            return {
                x: bb.left + e.scrollLeft - bbe.left,
                y: bb.top + e.scrollTop - bbe.top
            };
        },
        x: function () {
            var e = this.amber().editor().element;
            return this.element.getBoundingClientRect().left + e.scrollLeft - e.getBoundingClientRect().left;
        },
        y: function () {
            var e = this.amber().editor().element;
            return this.element.getBoundingClientRect().top + e.scrollTop - e.getBoundingClientRect().top;
        },
        dragStart: function (e) {
            var app, bb;
            if (this._embedded) return;
            if (this.anyParentSatisfies(function (p) {
                return p.isPalette;
            })) {
                bb = this.element.getBoundingClientRect();
                (app = this.amber()).createScript(10, 10, [this.copy().toJSON()]).startDrag(app, e, bb);
            } else if (this.parent.isStack) {
                this.parent.dragStack(e, this);
            } else if (this.parent.isBlock) {
                app = this.amber();
                bb = this.element.getBoundingClientRect();
                this.parent.restoreArg(this);
                new d.BlockStack().add(this).startDrag(app, e, bb);
            }
        },
        showContextMenu: function (e) {
            var me = this;
            new d.Menu().setItems([{title: d.t('Duplicate'), action: 'duplicate'}]).onExecute(function (e) {
                var app, bb, copy;
                switch (e.item.action) {
                case 'duplicate':
                    app = me.amber();
                    bb = me.getPosition();
                    copy = app.createScript(bb.x, bb.y, me.parent.isStack ? me.parent.toJSON(true) : [me.toJSON()]);
                    copy.startDrag(app, Object.create(e), copy.top().element.getBoundingClientRect());
                    copy.touchMove(app.touchMoveEvent());
                    break;
                }
            }).show(this, e);
        },
        copy: function () {
            var copy = new this.constructor().setCategory(this._category).setSelector(this._selector);
            if (this._templateSpec) {
                copy.setSpec(this._templateSpec).setArgs(this._templateArgs);
            } else {
                copy.setSpec(this._spec).setArguments(this.arguments);
            }
            if (this._terminal) copy.setTerminal(true);
            if (this._embedded) copy.setEmbedded(true);
            if (this._fillsLine) copy.setFillsLine(true);
            return copy;
        },
        '.selector': {},
        '.category': {
            apply: function (category) {
                var i = this.fill.length;
                this.element.style.color = d.categoryColors[category]
                while (i--) {
                    this.fill[i].style.backgroundColor =
                        this.fill[i].style.color = d.categoryColors[category];
                }
            }
        },
        '.spec': {
            apply: function (spec) {
                var start = 0,
                    args = this.arguments = [],
                    i, label, ex;
                spec = d.t(spec);
                this.container.innerHTML = '';
                while ((i = spec.indexOf('%', start)) !== -1) {
                    if (!/^\s*$/.test(label = spec.substring(start, i))) {
                        this.add(new d.arg.Label().setText(label));
                    }
                    if (ex = /\%(\d+\$)?([\w\-:]+)/.exec(spec.substr(i))) {
                        this.add(label = this.argFromSpec(ex[2]));
                        if (ex[2].substr(0, 5) !== 'icon:') {
                            if (ex[1]) {
                                args.splice(ex[1] - 1, 0, label);
                            } else {
                                args.push(label);
                            }
                        }
                        start = i + ex[0].length;
                    } else {
                        this.add(new d.arg.Label().setText('%'));
                        start = i + 1;
                    }
                }
                if (start < spec.length) {
                    this.add(new d.arg.Label().setText(spec.substr(start)));
                }
                this.defaultArguments = args.slice(0);
            }
        },
        '.templateSpec': {},
        '.templateArgs': {},
        argFromSpec: function (spec) {
            var arg;
            switch (spec) {

            // Temporary
            case 'note': return new d.arg.TextField().setNumeric(true).setIntegral(true);

            // Basic
            case 's': return new d.arg.TextField();
            case 'i': return new d.arg.TextField().setNumeric(true).setIntegral(true);
            case 'f': return new d.arg.TextField().setNumeric(true);
            case 'b': return new d.arg.Bool();
            case 'c': return new d.arg.CClosure();

            // Closures
            case 'command': return new d.ReporterBlock().setEmbedded(true).setCategory('system').setSpec('%parameters %slot:command');
            case 'reporter': return new d.ReporterBlock().setEmbedded(true).setCategory('system').setSpec('%parameters %slot:reporter');
            case 'slot:command': return new d.arg.CommandSlot();
            case 'slot:reporter': return new d.arg.ReporterSlot();
            case 'color': return new d.arg.Color();
            case 'parameters': return new d.arg.Parameters();

            // Field + Menu
            case 'direction':
                return new d.arg.TextField().setNumeric(true).setValue('90').setItems([
                    { title: 'right', action: '90' },
                    { title: 'left', action: '-90' },
                    { title: 'up', action: '0' },
                    { title: 'down', action: '180' }
                ]);
            case 'layer':
                return new d.arg.TextField().setNumeric(true).setValue('1').setItems(['1', 'last', 'any']);
            case 'deletion-index': return new d.arg.TextField().setNumeric(true).setIntegral(true).setValue('1').setItems(['1', 'last', d.Menu.separator, 'all']);
            case 'index': return new d.arg.TextField().setNumeric(true).setIntegral(true).setValue('1').setItems(['1', {$:'last'}, {$:'any'}]);

            // Open Enumerations (temporary)
            case 'list': return new d.arg.List();
            case 'var': return new d.arg.Var().setItems(function () {
                    var object = this.amber().selectedSprite(),
                        result = [],
                        vars;
                    if (!object.isStage) {
                        result.push({$:'x position'}, {$:'y position'}, {$:'direction'}, {$:'rotation style'}, {$:'costume #'}, {$:'size'}, {$:'layer'}, {$:'instrument'}, {$:'volume'}, {$:'pen down?'}, {$:'pen color'}, {$:'pen hue'}, {$:'pen lightness'}, {$:'pen size'}, d.Menu.separator, {$:'color effect'}, {$:'fisheye effect'}, {$:'whirl effect'}, {$:'pixelate effect'}, {$:'mosaic effect'}, {$:'brightness effect'}, {$:'ghost effect'}, d.Menu.separator);
                    }
                    result.push({$:'tempo'}, {$:'answer'}, {$:'timer'}, {$:'backdrop name'});
                    vars = object.variableNames();
                    if (vars.length) {
                        result.push(d.Menu.separator);
                        result.push.apply(result, vars);
                    }
                    if (!object.isStage) {
                        vars = object.stage().variableNames();
                        if (vars.length) {
                            result.push(d.Menu.separator);
                            result.push.apply(result, vars);
                        }
                    }
                    return result
                });
            case 'var:inline': return this.argFromSpec('var').setInline(true);
            case 'var:template': return new d.arg.Label();
            case 'event': return new d.arg.Enum().setItems(['event 1', 'event 2']);
            case 'sprite': return new d.arg.Enum().setItems(function () {
                    var result = [{$:'mouse'}],
                        stage = this.amber().project().stage(),
                        children = stage.children();
                    if (children.length) {
                        result.push(d.Menu.separator);
                        children.forEach(function (child) {
                            result.push(child.name());
                        });
                    }
                    return result;
                }).setValue({$:'mouse'});
            case 'object': return new d.arg.Enum().setItems(function () {
                    var result = [{$:'Stage'}],
                        stage = this.amber().project().stage(),
                        children = stage.children();
                    if (children.length) {
                        result.push(d.Menu.separator);
                        children.forEach(function (child) {
                            result.push(child.name());
                        });
                    }
                    return result;
                }).setValue({$:'Stage'});
            case 'clonable': return new d.arg.Enum().setItems(function () {
                    var result = [{$:'myself'}],
                        stage = this.amber().project().stage(),
                        children = stage.children();
                    if (children.length) {
                        result.push(d.Menu.separator);
                        children.forEach(function (child) {
                            result.push(child.name());
                        });
                    }
                    return result;
                }).setValue({$:'myself'});
            case 'attribute': return (arg = new d.arg.Enum()).setItems(function () {
                return arg.parent.arguments[1].text() === 'Stage' ? [{$:'backdrop #'}, {$:'volume'}, d.Menu.separator, 'global', 'counter'] : [{$:'x position'}, {$:'y position'}, {$:'direction'}, {$:'rotation style'}, {$:'costume #'}, {$:'size'}, {$:'volume'}, d.Menu.separator, 'var', 'a', 'b', 'c'];
            }).setValue({$: 'x position'});
            case 'costume': return new d.arg.Enum().setItems(['costume1', 'costume2', 'costume3']);
            case 'backdrop': return new d.arg.Enum().setItems(['backdrop1', 'backdrop2', 'backdrop']);
            case 'sound': return new d.arg.Enum().setItems(['meow']);

            // Closed Enumerations
            case 'math': return new d.arg.Enum().setItems([{$:'abs'}, {$:'floor'}, {$:'ceiling'}, {$:'sqrt'}, {$:'sin'}, {$:'cos'}, {$:'tan'}, {$:'asin'}, {$:'acos'}, {$:'atan'}, {$:'ln'}, {$:'log'}, {$:'e ^ '}, {$:'10 ^ '}]).setValue({$:'sqrt'});
            case 'sensor': return new d.arg.Enum().setItems([{$:'slider'}, {$:'light'}, {$:'sound'}, {$:'resistance-A'}, {$:'resistance-B'}, {$:'resistance-C'}, {$:'resistance-D'}, d.Menu.separator, {$:'tilt'}, {$:'distance'}]);
            case 'stop': return new d.arg.Enum().setItems([{$:'all'}, {$:'this script'}, {$:'other scripts in sprite'}]);
            case 'time': return new d.arg.Enum().setItems([{$:'year'}, {$:'month'}, {$:'day of year'}, {$:'date'}, {$:'day of week'}, d.Menu.separator, {$:'hour'}, {$:'minute'}, {$:'second'}]);
            case 'videoMotion': return new d.arg.Enum().setItems([{$:'motion'}, {$:'direction'}]);
            case 'rotationStyle': return new d.arg.Enum().setItems([{$:'all around'}, {$:'left to right'}, {$:'don\'t rotate'}]);
            case 'stageOrThis': return new d.arg.Enum().setItems([{$:'Stage'}, {$:'this sprite'}]).setValue({$:'this sprite'});
            case 'sensor:bool': return new d.arg.Enum().setItems([{$:'button pressed'}, {$:'A connected'}, {$:'B connected'}, {$:'C connected'}, {$:'D connected'}]);
            case 'instrument':
                return new d.arg.TextField().setNumeric(true).setIntegral(true).setValue('1').setItems([
                    { title: 'Acoustic Grand', action: '1' },
                    { title: 'Bright Acoustic', action: '2' },
                    { title: 'Electric Grand', action: '3' },
                    { title: 'Honky-Tonk', action: '4' },
                    { title: 'Electric Piano 1', action: '5' },
                    { title: 'Electric Piano 2', action: '6' },
                    { title: 'Harpsichord', action: '7' },
                    { title: 'Clavinet', action: '8' },
                    { title: 'Celesta', action: '9' },
                    { title: 'Glockenspiel', action: '10' },
                    { title: 'Music Box', action: '11' },
                    { title: 'Vibraphone', action: '12' },
                    { title: 'Marimba', action: '13' },
                    { title: 'Xylophone', action: '14' },
                    { title: 'Tubular Bells', action: '15' },
                    { title: 'Dulcimer', action: '16' },
                    { title: 'Drawbar Organ', action: '17' },
                    { title: 'Percussive Organ', action: '18' },
                    { title: 'Rock Organ', action: '19' },
                    { title: 'Church Organ', action: '20' },
                    { title: 'Reed Organ', action: '21' },
                    { title: 'Accordion', action: '22' },
                    { title: 'Harmonica', action: '23' },
                    { title: 'Tango Accordion', action: '24' },
                    { title: 'Nylon String Guitar', action: '25' },
                    { title: 'Steel String Guitar', action: '26' },
                    { title: 'Electric Jazz Guitar', action: '27' },
                    { title: 'Electric Clean Guitar', action: '28' },
                    { title: 'Electric Muted Guitar', action: '29' },
                    { title: 'Overdriven Guitar', action: '30' },
                    { title: 'Distortion Guitar', action: '31' },
                    { title: 'Guitar Harmonics', action: '32' },
                    { title: 'Acoustic Bass', action: '33' },
                    { title: 'Electric Bass (finger)', action: '34' },
                    { title: 'Electric Bass (pick)', action: '35' },
                    { title: 'Fretless Bass', action: '36' },
                    { title: 'Slap Bass 1', action: '37' },
                    { title: 'Slap Bass 2', action: '38' },
                    { title: 'Synth Bass 1', action: '39' },
                    { title: 'Synth Bass 2', action: '40' },
                    { title: 'Violin', action: '41' },
                    { title: 'Viola', action: '42' },
                    { title: 'Cello', action: '43' },
                    { title: 'Contrabass', action: '44' },
                    { title: 'Tremolo Strings', action: '45' },
                    { title: 'Pizzicato Strings', action: '46' },
                    { title: 'Orchestral Strings', action: '47' },
                    { title: 'Timpani', action: '48' },
                    { title: 'String Ensemble 1', action: '49' },
                    { title: 'String Ensemble 2', action: '50' },
                    { title: 'SynthStrings 1', action: '51' },
                    { title: 'SynthStrings 2', action: '52' },
                    { title: 'Choir Aahs', action: '53' },
                    { title: 'Voice Oohs', action: '54' },
                    { title: 'Synth Voice', action: '55' },
                    { title: 'Orchestra Hit', action: '56' },
                    { title: 'Trumpet', action: '57' },
                    { title: 'Trombone', action: '58' },
                    { title: 'Tuba', action: '59' },
                    { title: 'Muted Trumpet', action: '60' },
                    { title: 'French Horn', action: '61' },
                    { title: 'Brass Section', action: '62' },
                    { title: 'SynthBrass 1', action: '63' },
                    { title: 'SynthBrass 2', action: '64' },
                    { title: 'Soprano Sax', action: '65' },
                    { title: 'Alto Sax', action: '66' },
                    { title: 'Tenor Sax', action: '67' },
                    { title: 'Baritone Sax', action: '68' },
                    { title: 'Oboe', action: '69' },
                    { title: 'English Horn', action: '70' },
                    { title: 'Bassoon', action: '71' },
                    { title: 'Clarinet', action: '72' },
                    { title: 'Piccolo', action: '73' },
                    { title: 'Flute', action: '74' },
                    { title: 'Recorder', action: '75' },
                    { title: 'Pan Flute', action: '76' },
                    { title: 'Blown Bottle', action: '77' },
                    { title: 'Shakuhachi', action: '78' },
                    { title: 'Whistle', action: '79' },
                    { title: 'Ocarina', action: '80' },
                    { title: 'Lead 1 (square)', action: '81' },
                    { title: 'Lead 2 (sawtooth)', action: '82' },
                    { title: 'Lead 3 (calliope)', action: '83' },
                    { title: 'Lead 4 (chiff)', action: '84' },
                    { title: 'Lead 5 (charang)', action: '85' },
                    { title: 'Lead 6 (voice)', action: '86' },
                    { title: 'Lead 7 (fifths)', action: '87' },
                    { title: 'Lead 8 (bass+lead)', action: '88' },
                    { title: 'Pad 1 (new age)', action: '89' },
                    { title: 'Pad 2 (warm)', action: '90' },
                    { title: 'Pad 3 (polysynth)', action: '91' },
                    { title: 'Pad 4 (choir)', action: '92' },
                    { title: 'Pad 5 (bowed)', action: '93' },
                    { title: 'Pad 6 (metallic)', action: '94' },
                    { title: 'Pad 7 (halo)', action: '95' },
                    { title: 'Pad 8 (sweep)', action: '96' },
                    { title: 'FX 1 (rain)', action: '97' },
                    { title: 'FX 2 (soundtrack)', action: '98' },
                    { title: 'FX 3 (crystal)', action: '99' },
                    { title: 'FX 4 (atmosphere)', action: '100' },
                    { title: 'FX 5 (brightness)', action: '101' },
                    { title: 'FX 6 (goblins)', action: '102' },
                    { title: 'FX 7 (echoes)', action: '103' },
                    { title: 'FX 8 (sci-fi)', action: '104' },
                    { title: 'Sitar', action: '105' },
                    { title: 'Banjo', action: '106' },
                    { title: 'Shamisen', action: '107' },
                    { title: 'Koto', action: '108' },
                    { title: 'Kalimba', action: '109' },
                    { title: 'Bagpipe', action: '110' },
                    { title: 'Fiddle', action: '111' },
                    { title: 'Shanai', action: '112' },
                    { title: 'Tinkle Bell', action: '113' },
                    { title: 'Agogo', action: '114' },
                    { title: 'Steel Drums', action: '115' },
                    { title: 'Woodblock', action: '116' },
                    { title: 'Taiko Drum', action: '117' },
                    { title: 'Melodic Tom', action: '118' },
                    { title: 'Synth Drum', action: '119' },
                    { title: 'Reverse Cymbal', action: '120' },
                    { title: 'Guitar Fret Noise', action: '121' },
                    { title: 'Breath Noise', action: '122' },
                    { title: 'Seashore', action: '123' },
                    { title: 'Bird Tweet', action: '124' },
                    { title: 'Telephone Ring', action: '125' },
                    { title: 'Helicopter', action: '126' },
                    { title: 'Applause', action: '127' },
                    { title: 'Gunshot', action: '128' }
                ]);
            case 'drum':
                return new d.arg.TextField().setNumeric(true).setIntegral(true).setValue('48').setItems([
                    { title: 'Acoustic Bass Drum', action: '35' },
                    { title: 'Bass Drum 1', action: '36' },
                    { title: 'Side Stick', action: '37' },
                    { title: 'Acoustic Snare', action: '38' },
                    { title: 'Hand Clap', action: '39' },
                    { title: 'Electric Snare', action: '40' },
                    { title: 'Low Floor Tom', action: '41' },
                    { title: 'Closed Hi-Hat', action: '42' },
                    { title: 'High Floor Tom', action: '43' },
                    { title: 'Pedal Hi-Hat', action: '44' },
                    { title: 'Low Tom', action: '45' },
                    { title: 'Open Hi-Hat', action: '46' },
                    { title: 'Low-Mid Tom', action: '47' },
                    { title: 'Hi-Mid Tom', action: '48' },
                    { title: 'Crash Cymbal 1', action: '49' },
                    { title: 'High Tom', action: '50' },
                    { title: 'Ride Cymbal 2', action: '51' },
                    { title: 'Chinese Cymbal', action: '52' },
                    { title: 'Ride Bell', action: '53' },
                    { title: 'Tambourine', action: '54' },
                    { title: 'Splash Cymbal', action: '55' },
                    { title: 'Cowbell', action: '56' },
                    { title: 'Crash Cymbal 2', action: '57' },
                    { title: 'Vibraslap', action: '58' },
                    { title: 'Ride Cymbal 2', action: '59' },
                    { title: 'Hi Bongo', action: '60' },
                    { title: 'Low Bongo', action: '61' },
                    { title: 'Mute Hi Conga', action: '62' },
                    { title: 'Open Hi Conga', action: '63' },
                    { title: 'Low Conga', action: '64' },
                    { title: 'High Timbale', action: '65' },
                    { title: 'Low Timbale', action: '66' },
                    { title: 'High Agogo', action: '67' },
                    { title: 'Low Agogo', action: '68' },
                    { title: 'Cabasa', action: '69' },
                    { title: 'Maracas', action: '70' },
                    { title: 'Short Whistle', action: '71' },
                    { title: 'Long Whistle', action: '72' },
                    { title: 'Short Guiro', action: '73' },
                    { title: 'Long Guiro', action: '74' },
                    { title: 'Claves', action: '75' },
                    { title: 'Hi Wood Block', action: '76' },
                    { title: 'Low Wood Block', action: '77' },
                    { title: 'Mute Cuica', action: '78' },
                    { title: 'Open Cuica', action: '79' },
                    { title: 'Mute Triangle', action: '80' },
                    { title: 'Open Triangle', action: '81' }
                ]);
            case 'key':
                return new d.arg.Enum().setItems([{$:'up arrow'}, {$:'down arrow'}, {$:'right arrow'}, {$:'left arrow'}, {$:'space'}, 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']).setValue({$:'space'});

            // Icons
            case 'icon:right': return new d.arg.Label().setText('\u27f3');
            case 'icon:left': return new d.arg.Label().setText('\u27f2');
            case 'icon:repeat': return new d.arg.Label().setText('\u2b0f');
            case 'icon:stop': return new d.arg.Label().setText('\u2b23').setColor('#a00');
            case 'icon:flag': return new d.arg.Label().setText('\u2691').setColor('#080');
            }
            console.warn('unknown arg spec %' + spec);
            return new d.arg.TextField();
        },
        addFill: function (fill) {
            this.fill.push(fill);
            this.element.appendChild(fill);
        },
        restoreArg: function (arg) {
            var i = this.arguments.indexOf(arg);
            this.replace(arg, this.arguments[i] = this.defaultArguments[i]);
        },
        replaceArg: function (oldArg, newArg) {
            var i = this.arguments.indexOf(oldArg),
                bb = oldArg.isBlock && oldArg.element.getBoundingClientRect(),
                amber = this.amber(),
                stack;
            this.replace(oldArg, this.arguments[i] = newArg);
            if (oldArg.isBlock && !oldArg._embedded) {
                this.amber().add(stack = new d.BlockStack().add(oldArg));
                stack.element.style.left = bb.left + 20 + 'px';
                stack.element.style.top = bb.top - 20 + 'px';
            }
            if (amber) amber.editor().fit();
        },
        getArgs: function () {
            var values = [],
                i = this.arguments.length;
            while (i--) {
                values.push(this.arguments.value());
            }
            return values;
        },
        setArgs: function (/* values... */) {
            var i = arguments.length;
            while (i--) {
                this.arguments[i].setValue(arguments[i]);
            }
            return this;
        },
        setArguments: function (args) {
            var i = args.length;
            while (i--) {
                this.replace(this.arguments[i], this.defaultArguments[i] = this.arguments[i] = args[i].copy());
            }
            return this;
        },
        '.embedded': {
            apply: function (embedded) {
                this.acceptsClick = !embedded;
            }
        },
        '.fillsLine': {
            apply: function (fillsLine) {
                d.toggleClass(this.element, 'd-block-fill-line', fillsLine);
            }
        }
    }, {
        fromJSON: function (a, tracker, amber) {
            var selector = a[0],
                spec = d.BlockSpecBySelector[selector],
                block;
            if (!spec) {
                console.warn('missing block spec mapping for selector #' + selector);
                spec = ['c', 'undefined', selector, '#' + selector];
                a = [a[0]];
            }
            block = d.Block.fromSpec(spec);
            block.setSelector(selector);
            if (amber) block.setAmber(amber);
            if (tracker) {
                tracker.push(block);
            }
            a.slice(1).forEach(function (arg, i) {
                if (arg instanceof Array) {
                    if (typeof arg[0] === 'string') {
                        block.replaceArg(block.arguments[i], d.Block.fromJSON(arg, tracker, amber));
                    } else {
                        block.arguments[i].setValue(new d.BlockStack().fromJSON(arg, tracker, amber, true));
                    }
                } else {
                    if (i > block.arguments.length) {
                        console.warn('Bad block serial form.');
                    } else {
                        block.arguments[i].setValue(arg);
                    }
                }
            });
            return block;
        },
        fromSpec: function (spec) {
            var block;
            switch (spec[0]) {
            case 'c':
            case 't':
            case 'r':
            case 'b':
            case 'e':
            case 'h':
                block = new (spec[0] == 'h' ? d.HatBlock : spec[0] === 'r' || spec[0] === 'e' ? d.ReporterBlock : spec[0] === 'b' ? d.BooleanReporterBlock : d.CommandBlock)().setCategory(spec[1]).setSelector(spec[2]).setSpec(spec[3]);
                switch (spec[0]) {
                case 't':
                    block.setTerminal(true);
                    break;
                case 'e':
                    block.setEmbedded(true).setFillsLine(true);
                    break;
                }
                block.setArgs.apply(block, spec.slice(4));
                return block;
            case 'v':
                return new d.VariableBlock().setVar(spec[1]);
            case 'vs':
            case 'vc':
                block = new d.SetterBlock().setIsChange(spec[0] === 'vc').setVar(spec[1]);
                if (spec.length > 2) {
                    block.setValue(spec[2])
                }
                return block;
            }
        }
    });
    d.CommandBlock = d.Class(d.Block, {
        init: function () {
            this.base(arguments);
            this.initElements('d-block d-command-block');
            this.addFill(this.newElement('d-command-block-fill-l'));
            this.addFill(this.newElement('d-command-block-fill-r'));
            this.addFill(this.newElement('d-command-block-fill-p'));
            this.element.appendChild(this.container = this.newElement('d-command-block-label'));
        },
        '.terminal': {
            apply: function (terminal) {
                d.toggleClass(this.element, 'd-block-terminal', terminal);
            }
        }
    });
    d.ReporterBlock = d.Class(d.Block, {
        isReporter: true,
        acceptsReporter: function (reporter) {
            return reporter.isBoolean === this.isBoolean;
        },
        init: function () {
            this.base(arguments);
            this.initElements('d-block d-reporter-block');
            this.addFill(this.newElement('d-reporter-block-fill'));
            this.element.appendChild(this.container = this.newElement('d-reporter-block-label'));
        }
    });
    d.BooleanReporterBlock = d.Class(d.Block, {
        isReporter: true,
        isBoolean: true,
        acceptsReporter: d.ReporterBlock.prototype.acceptsReporter,
        init: function () {
            this.base(arguments);
            this.initElements('d-block d-boolean-reporter-block');
            this.addFill(this.newElement('d-boolean-reporter-block-fill-rt'));
            this.addFill(this.newElement('d-boolean-reporter-block-fill-rb'));
            this.addFill(this.newElement('d-boolean-reporter-block-fill-lt'));
            this.addFill(this.newElement('d-boolean-reporter-block-fill-lb'));
            this.addFill(this.newElement('d-boolean-reporter-block-fill'));
            this.element.appendChild(this.container = this.newElement('d-boolean-reporter-block-label'));
        }
    });
    d.VariableColors = {
        'x position': 'motion',
        'y position': 'motion',
        'direction': 'motion',
        'rotation style': 'motion',
        'costume #': 'looks',
        'color effect': 'looks',
        'fisheye effect': 'looks',
        'whirl effect': 'looks',
        'pixelate effect': 'looks',
        'mosaic effect': 'looks',
        'brightness effect': 'looks',
        'ghost effect': 'looks',
        'size': 'looks',
        'layer': 'looks',
        'instrument': 'sound',
        'volume': 'sound',
        'tempo': 'sound',
        'pen down?': 'pen',
        'pen color': 'pen',
        'pen hue': 'pen',
        'pen lightness': 'pen',
        'pen size': 'pen',
        'answer': 'sensing',
        'mouse x': 'sensing',
        'mouse y': 'sensing',
        'mouse down?': 'sensing',
        'timer': 'sensing',
        'loudness': 'sensing',
        'loud?': 'sensing',
        'backdrop name': 'looks',
    };
    d.VariableBlock = d.Class(d.ReporterBlock, {
        init: function () {
            this.base(arguments);
            this.setSpec('%var:inline').setSelector('readVariable');
        },
        '.var': {
            get: function () {
                return this.arguments[0].value();
            },
            set: function (name) {
                this.arguments[0].setValue(name);
            }
        }
    });
    d.SetterBlock = d.Class(d.CommandBlock, {
        init: function () {
            this.base(arguments);
        },
        '.isChange': {
            apply: function (isChange) {
                if (isChange) {
                    this.setSpec('change %var by %f').setSelector('changeVar:by:');
                } else {
                    this.setSpec('set %var to %s').setSelector('setVar:to:');
                }
                this.add(this.unitLabel = new d.arg.Label());
            }
        },
        '.var': {
            get: function () {
                return this.arguments[0].value();
            },
            set: function (name) {
                this.arguments[0].setValue(name);
            }
        },
        '.value': {
            get: function () {
                return this.arguments[1].value();
            },
            set: function (value) {
                this.arguments[1].setValue(value);
            }
        },
        varChanged: function () {
            var arg;
            this.unit = '';
            arg = this.getDefaultArg(this.arguments[0].value());
            if (this.unit) {
                this.unitLabel.element.style.display = '';
                this.unitLabel.setValue(this.unit);
            } else {
                this.unitLabel.element.style.display = 'none';
            }
            if (this.arguments[1] === this.defaultArguments[1]) {
                this.replaceArg(this.arguments[1], arg);
            }
            this.defaultArguments[1] = arg;
        },
        getDefaultArg: function (variable) {
            if (variable.$) {
                if (this._isChange) {
                    switch (variable.$) {
                    case 'costume #':
                    case 'layer':
                    case 'instrument':
                        return this.argFromSpec('i').setValue(1);
                    case 'direction':
                        return this.argFromSpec('f').setValue(15);
                    case 'tempo':
                        return this.argFromSpec('f').setValue(20);
                    case 'volume':
                        return this.argFromSpec('f').setValue(-10);
                    case 'pen size':
                    case 'answer':
                    case 'timer':
                        return this.argFromSpec('f').setValue(1);
                    }
                    return this.argFromSpec('f').setValue(d.VariableColors[variable.$] ? 10 : 1);
                }
                switch (variable.$) {
                case 'x position':
                case 'y position':
                case 'pen hue':
                case 'timer':
                    return this.argFromSpec('f').setValue(0);
                case 'direction':
                    return this.argFromSpec('direction');
                case 'costume #':
                    return this.argFromSpec('i').setValue(1);
                case 'layer':
                    return this.argFromSpec('layer');
                case 'instrument':
                    return this.argFromSpec('instrument');
                case 'size':
                case 'volume':
                    this.unit = '%';
                    return this.argFromSpec('f').setValue(100);
                case 'tempo':
                    this.unit = 'bpm';
                    return this.argFromSpec('f').setValue(60);
                case 'pen down?':
                    return this.argFromSpec('b');
                case 'pen color':
                    return this.argFromSpec('color');
                case 'pen lightness':
                    return this.argFromSpec('f').setValue(50);
                case 'pen size':
                    return this.argFromSpec('f').setValue(1);
                case 'answer':
                    return this.argFromSpec('s');
                case 'rotation style':
                    return this.argFromSpec('rotationStyle');
                }
                if (variable.$.substr(variable.$.length - 7) === ' effect') {
                    return this.argFromSpec('f').setValue(0);
                }
            }
            return this.argFromSpec('s').setValue(0);
        }
    });
    d.arg.CClosure = d.Class(d.ReporterBlock, {
        init: function () {
            this.base(arguments);
            this.setEmbedded(true).setFillsLine(true).setCategory('system').setSelector('cClosure').setSpec('%slot:command');
        },
        setValue: function (value) {
            this.arguments[0].setValue(value);
        },
        slotIndex: function () {
            return this.parent.slotIndex(this);
        }
    });
    d.HatBlock = d.Class(d.Block, {
        init: function () {
            this.base(arguments);
            this.initElements('d-block d-command-block d-hat-block');
            this.addFill(this.newElement('d-hat-block-fill-l'));
            this.addFill(this.newElement('d-hat-block-fill-r'));
            this.addFill(this.newElement('d-hat-block-fill-p'));
            this.addFill(this.newElement('d-hat-block-fill-t'));
            this.element.appendChild(this.container = this.newElement('d-hat-block-label'));
        },
        isHat: true,
        '.terminal': {
            readonly: true,
            get: function () {
                return false;
            }
        }
    });

    d.r = {};
    d.r.urls = [
        [/^$/, 'index'],
        [/^search\/$/, 'search'],
        [/^search\/(.+)\/$/, 'search'],
        [/^projects\/new\/$/, 'project.new'],
        [/^projects\/(\d+)\/$/, 'project.view'],
        [/^projects\/(\d+)\/edit\/$/, 'project.edit'],
        [/^users\/([\w-]+)\/$/, 'user.profile'],
        [/^settings\/$/, 'settings'],
        [/^help\/$/, 'help'],
        [/^help\/about\/$/, 'help.about'],
        [/^help\/tos\/$/, 'help.tos'],
        [/^help\/educators\/$/, 'help.educators'],
        [/^help\/contact\/$/, 'contact'],
        [/^explore\/$/, 'explore'],
        [/^forums\/$/, 'forums.index'],
        [/^forums\/(\d+)\/$/, 'forums.forum.view'],
        [/^forums\/t\/(\d+)\/$/, 'forums.topic.view'],
        [/^forums\/p\/(\d+)\/$/, 'forums.post.link']
    ];
    d.r.views = {
        index: function () {
            var projectCount;
            this.reloadOnAuthentication = true;
            if (this.user()) {

            } else {
                this.page
                    .add(new d.Label('d-r-splash-title').setText(d.t('Amber')))
                    .add(new d.Label('d-r-splash-subtitle').setText(d.t('Collaborate in realtime with others around the world')))
                    .add(new d.Label('d-r-splash-subtitle').setText(d.t('Create your own interactive stories, games, music & art')))
                    .add(new d.r.Link('d-r-splash-link').setURL(this.reverse('project.new'))
                        .add(new d.Label('d-r-splash-link-title').setText(d.t('Get Started')))
                        .add(new d.Label('d-r-splash-link-subtitle').setText(d.t('Make an Amber project'))))
                    .add(new d.r.Link('d-r-splash-link').setURL(this.reverse('explore'))
                        .add(new d.Label('d-r-splash-link-title').setText(d.t('Explore')))
                        .add(projectCount = new d.Label('d-r-splash-link-subtitle').setText(d.t('% projects', 0))))
                    .add(new d.r.Link('d-r-splash-link').onExecute(this.showSignIn, this)
                        .add(new d.Label('d-r-splash-link-title').setText(d.t('Sign In')))
                        .add(new d.Label('d-r-splash-link-subtitle').setText(d.t('With your Scratch Account'))))
                    .add(new d.Container('d-r-splash-footer')
                        .add(new d.r.Link('d-r-link d-r-splash-footer-link').setText(d.t('About Amber')).setURL(this.reverse('help.about')))
                        .add(new d.r.Link('d-r-link d-r-splash-footer-link').setText(d.t('Terms of Service')).setURL(this.reverse('help.tos')))
                        .add(new d.r.Link('d-r-link d-r-splash-footer-link').setText(d.t('For Educators')).setURL(this.reverse('help.educators'))));
                this.query('projects.count', {}, function (result) {
                    projectCount.setText(d.t('% projects', result));
                });
            }
            this.page
                .add(new d.r.ProjectCarousel().setTitle(d.t('Featured Projects')).setQuery('featured'));
            if (this.user()) {
                this.page
                    .add(new d.r.ProjectCarousel().setTitle(d.t('Projects by Users I\'m Following')).setQuery('user.byFollowing'))
                    .add(new d.r.ProjectCarousel().setTitle(d.t('Projects Loved by Users I\'m Following')).setQuery('user.lovedByFollowing'))
            }
            this.page
                .add(new d.r.ProjectCarousel().setTitle(d.t('What the Community is Remixing')).setQuery('topRemixed'))
                .add(new d.r.ProjectCarousel().setTitle(d.t('What the Community is Loving')).setQuery('topLoved'))
                .add(new d.r.ProjectCarousel().setTitle(d.t('What the Community is Viewing')).setQuery('topViewed'));
        },
        notFound: function (args) {
            this.page
                .add(new d.Label('d-r-title').setText(d.t('Page Not Found')))
                .add(new d.Label('d-r-paragraph').setText(d.t('The page at the URL "%" could not be found.', args[0])));
        },
        forbidden: function (args) {
            this.page
                .add(new d.Label('d-r-title').setText(d.t('Authentication Required')))
                .add(new d.Label('d-r-paragraph').setText(d.t('You need to log in to see this page.')));
        },
        help: function (args) {
            this.page
                .add(new d.Label('d-r-title').setText(d.t('Help')))
                .add(new d.Label('d-r-paragraph').setText(d.t('This is a placeholder help section.')));
        },
        'help.about': function (args) {
            this.page
                .add(new d.Label('d-r-title').setText(d.t('About Amber')))
                .add(new d.Label('d-r-paragraph').setText(d.t('Copyright \xa9 2013 Nathan Dinsmore and Truman Kilen.')));
        },
        'help.tos': function () {
            this.page
                .add(new d.Label('d-r-title').setText(d.t('Terms of Service')))
                .add(new d.Label('d-r-paragraph').setText(d.t('You just do what the **** you want to.')));
        },
        search: function () {
            this.page
                .add(new d.Label('d-r-title').setText(d.t('Search')))
                .add(new d.Label('d-r-paragraph').setText('This is a placeholder search page.'));
        },
        settings: function () {
            this.requireAuthentication();
            this.page
                .add(new d.Label('d-r-title').setText(d.t('Settings')))
                .add(new d.FormGrid('d-form-grid d-r-form')
                    .addField(d.t('Username:'), new d.TextField().setText(this.user().name()))
                    .addField(d.t('About Me: (demo)'), new d.TextField.Multiline)
                    .addField(d.t('What I\'m Working On: (demo)'), new d.TextField.Multiline));
        },
        'project.view': function (args, isEdit) {
            var title, authors, player, notes, favorites, loves, views, remixes;
            this.page
                .add(new d.Container('d-r-project-container')
                    .add(title = new d.Label('d-r-project-title'))
                    .add(new d.Label('d-r-project-notes-title').setText(d.t('Notes')))
                    .add(new d.Container('d-r-project-player-wrap')
                        .add(authors = new d.Label('d-r-project-authors').setText(d.t('by %', '')))
                        .add(new d.Container('d-r-project-player')
                            .add(player = new d.Amber().setProjectId(args[1])))
                        .add(new d.Container('d-r-project-stats')
                            .add(favorites = new d.Label('d-r-project-stat').setText(d.t.plural('% Favorites', '% Favorite', 0)))
                            .add(loves = new d.Label('d-r-project-stat').setText(d.t.plural('% Loves', '% Love', 0)))
                            .add(views = new d.Label('d-r-project-stat').setText(d.t.plural('% Views', '% View', 0)))
                            .add(remixes = new d.Label('d-r-project-stat').setText(d.t.plural('% Remixes', '% Remix', 0)))))
                    .add(notes = new d.Label('d-r-project-notes d-scrollable'))
                    .add(new d.Label('d-r-project-comments-title').setText(d.t('Comments')))
                    .add(new d.Label('d-r-project-remixes-title').setText(d.t('Remixes')))
                    .add(new d.Container('d-r-project-comments')));
            this.request('GET', 'projects/' + args[1] + '/', null, function (info) {
                title.setText(info.project.name);
                authors.setRichText(d.t('by %', d.t.list(info.project.authors.map(function (author) {
                    return '<a class=d-r-link href="' + this.abs(d.htmle(this.reverse('user.profile', author))) + '">' + d.htmle(author) + '</a>';
                }, this))));
                notes.setText(info.project.notes);
                favorites.setText(d.t.plural('% Favorites', '% Favorite', info.favorites));
                loves.setText(d.t.plural('% Loves', '% Love', info.loves));
                views.setText(d.t.plural('% Views', '% View', info.views));
                remixes.setText(d.t.plural('% Remixes', '% Remix', info.remixes.length));
                player.setProject(info.project);
                if (isEdit) {
                    player.setEditMode(true);
                }
            }, function (status) {
                if (status === 404) {
                    this.notFound();
                }
            });
            this.unload = function () {
                player.parent.remove(player);
            };
        },
        'project.edit': function (args) {
            return d.r.views['project.view'].call(this, args, true);
        },
        'user.profile': function (args) {
            this.page
                .add(new d.Container('d-r-user-icon'))
                .add(new d.Label('d-r-title d-r-user-title').setText(args[1]))
                .add(new d.Container('d-r-user-icon'))
                .add(new d.Container('d-r-user-activity')
                    .add(new d.Label('d-r-title').setText('About Me'))
                    .add(new d.Label('d-r-user-about').setText('Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.'))
                    .add(new d.Label('d-r-title d-r-user-title-alternate').setText('What I\'m Working On'))
                    .add(new d.Label('d-r-user-about d-r-user-about-alternate').setText('Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'))
                    .add(new d.Label('d-r-title d-r-user-activity-title').setText('What I\'ve Been Doing'))
                    .add(new d.Container('d-r-user-activity-item')
                        .add(new d.Label('d-r-activity-message').setRichText(d.t('% loved %', '<strong>' + d.htmle(args[1]) + '</strong>', '<a class=d-r-link href="' + this.abs(this.reverse('project.view', 3)) + '">Some Project</a>')))
                        .add(new d.Label('d-r-activity-date').setText(d.t('2 days, 8 hours ago'))))
                    .add(new d.Container('d-r-user-activity-item')
                        .add(new d.Label('d-r-activity-message').setRichText(d.t('% shared the project %', '<strong>' + d.htmle(args[1]) + '</strong>', '<a class=d-r-link href="' + this.abs(this.reverse('project.view', 3)) + '">Summer</a>')))
                        .add(new d.Label('d-r-activity-date').setText(d.t('4 days, 1 hour ago'))))
                    .add(new d.Container('d-r-user-activity-item')
                        .add(new d.Label('d-r-activity-message').setRichText(d.t('% favorited the project %', '<strong>' + d.htmle(args[1]) + '</strong>', '<a class=d-r-link href="' + this.abs(this.reverse('project.view', 3)) + '">Another Project</a>')))
                        .add(new d.Label('d-r-activity-date').setText(d.t('4 days, 1 hour ago'))))
                    .add(new d.Container('d-r-user-activity-item')
                        .add(new d.Label('d-r-activity-message').setRichText(d.t('% loved the project %', '<strong>' + d.htmle(args[1]) + '</strong>', '<a class=d-r-link href="' + this.abs(this.reverse('project.view', 3)) + '">This Project</a>')))
                        .add(new d.Label('d-r-activity-date').setText(d.t('4 days, 1 hour ago'))))
                    .add(new d.Container('d-r-user-activity-item')
                        .add(new d.Label('d-r-activity-message').setRichText(d.t('% followed %', '<strong>' + d.htmle(args[1]) + '</strong>', '<a class=d-r-link href="' + this.abs(this.reverse('user.profile', 'MathWizz')) + '">MathWizz</a>')))
                        .add(new d.Label('d-r-activity-date').setText(d.t('4 days, 1 hour ago'))))
                    .add(new d.Container('d-r-user-activity-item')
                        .add(new d.Label('d-r-activity-message').setRichText(d.t('% subscribed to %', '<strong>' + d.htmle(args[1]) + '</strong>', '<a class=d-r-link href="#">Awesome Projects</a>')))
                        .add(new d.Label('d-r-activity-date').setText(d.t('4 days, 1 hour ago')))))
                .add(new d.Container('d-r-user-carousels')
                    .add(new d.r.Carousel().setTitle(d.t('Shared Projects')))
                    .add(new d.r.Carousel().setTitle(d.t('Favorite Projects')))
                    .add(new d.r.Carousel().setTitle(d.t('Collections')))
                    .add(new d.r.Carousel().setTitle(d.t('Following')))
                    .add(new d.r.Carousel().setTitle(d.t('Followers'))));
        },
        'forums.index': function () {
            this.query('forums.categories', {}, function (categories) {
                categories.forEach(function (category) {
                    this.page
                        .add(new d.Label('d-r-title').setText(d.t.maybe(category.name)));
                    category.forums.forEach(function (forum) {
                        this.page
                            .add(new d.Container('d-r-forum-list')
                                .add(new d.r.Link('d-r-forum-list-item')
                                     .add(new d.Label('d-r-forum-list-item-title').setText(d.t.maybe(forum.name)))
                                     .add(new d.Label('d-r-forum-list-item-description').setText(d.t.maybe(forum.description)))
                                     .setURL(this.reverse('forums.forum.view', forum.id))));
                    }, this);
                }, this);
            }.bind(this));
        },
        'forums.forum.view': function (args) {
            var t = this, title, subtitle;
            this.page
                .add(title = new d.Label('d-r-title'))
                .add(subtitle = new d.Label('d-r-subtitle'))
                .add(new d.r.LazyList('d-r-topic-list')
                     .setItemHeight(48)
                     .setLoader(function (offset, length, callback) {
                        return this.query('forums.topics', {
                            forum$id: args[1],
                            offset: offset,
                            length: length
                        }, callback);
                    }.bind(this))
                    .setTransformer(function (topic) {
                        var userLabel, link;
                        link = new d.r.Link('d-r-topic-list-item')
                            .setURL(t.reverse('forums.topic.view', topic.id))
                            .add(new d.Container('d-r-topic-list-item-title')
                                .add(new d.Label('d-r-topic-list-item-name').setText(topic.name))
                                .add(userLabel = new d.Label('d-r-topic-list-item-author').setText(d.t('by %', ''))))
                            .add(new d.Label('d-r-topic-list-item-description').setText(d.t.plural('% posts', '% post', topic.posts) + ' \xb7 ' + d.t.plural('% views', '% view', topic.views)))
                        t.getUser(topic.author, function (user) {
                            userLabel.setText(d.t('by %', user.name()));
                        });
                        return link;
                    }));
            this.query('forums.forum', {
                forum$id: args[1]
            }, function (forum) {
                title.setText(d.t.maybe(forum.name));
                subtitle.setText(d.t.maybe(forum.description));
            });
        }
    };
    d.r.App = d.Class(d.App, {
        init: function () {
            this.base(arguments);
            this.setConfig({});
            this.pendingRequests = 0;
        },
        setElement: function (element) {
            this.base(arguments, element)
                .add((this.signInForm = new d.Form('d-r-header-sign-in'))
                    .hide()
                    .onSubmit(this.signIn, this)
                    .onCancel(this.hideSignIn, this)
                    .add(this.signInUsername = new d.TextField('d-textfield d-r-header-sign-in-field').setPlaceholder(d.t('Username')))
                    .add(this.signInPassword = new d.TextField.Password('d-textfield d-r-header-sign-in-field').setPlaceholder(d.t('Password')))
                    .add(this.signInButton = new d.Button().setText(d.t('Sign In')).onExecute(this.signInForm.submit, this.signInForm))
                    .add(this.signUpLink = new d.r.Link().setText(d.t('Register')).setExternalURL('http://scratch.mit.edu/signup'))
                    .add(this.signInError = new d.Label('d-label d-r-header-sign-in-error').hide()))
                .add(new d.Container('d-r-header')
                    .add(this.panelLink('Amber', 'index'))
                    .add(this.panelLink('Create', 'project.new'))
                    .add(this.panelLink('Explore', 'explore'))
                    .add(this.panelLink('Discuss', 'forums.index'))
                    .add(this.userButton = new d.Button('d-r-panel-button d-r-header-user')
                        .onExecute(this.toggleUserPanel, this)
                        .add(this.userLabel = new d.Label('d-r-header-user-label').setText(d.t('Sign In')))
                        .add(new d.Label('d-r-header-user-arrow')))
                    .add(this.search = new d.TextField('d-textfield d-r-header-search').setPlaceholder(d.t('Search\u2026')).onInputDone(function () {
                        if (this.search.text()) {
                            this.show('search', this.search.text());
                        } else {
                            this.show('search');
                        }
                    }, this))
                    .add(this.spinner = new d.Container('d-r-spinner').hide())
                    .add(this.connectionWarning = new d.Container('d-r-connection-warning').hide()))
                .add(this.wrap = new d.Container('d-r-wrap').addClass('d-scrollable')
                    .add(this.page = new d.Container('d-r-page').setSelectable(true))
                    .add(new d.Container('d-r-footer')
                        .add(this.panelLink('Help', 'help'))
                        .add(this.panelLink('About', 'help.about'))
                        .add(this.panelLink('Feedback', 'forums.topic.view', 1))
                        .add(this.panelLink('Contact', 'contact'))));
            window.addEventListener('hashchange', function () {
                if (this.isRedirect) {
                    this.isRedirect = false;
                    return;
                }
                this.go(location.hash.substr(1), true);
            }.bind(this));
            return this;
        },
        '.config': {},
        '.server': {
            apply: function (server) {
                server.setApp(this);
                this.go(location.hash.substr(1));
            }
        },
        '.connected': {
            apply: function (connected) {
                this.connectionWarning.setVisible(!connected);
            }
        },
        '.user': {
            value: null,
            apply: function (user) {
                if (user) {
                    this.signInForm.hide();
                    this.signInError.hide();
                    this.userButton.removeClass('d-r-panel-button-pressed');
                    this.userLabel.setText(user.name());
                } else {
                    this.userLabel.setText(d.t('Sign In'));
                }
                if (this.reloadOnAuthentication) {
                    this.reload();
                }
            }
        },
        showSignIn: function (autohide) {
            if (this.signInForm.visible()) return;
            this.signInAutohide = autohide;
            this.signInForm.show();
            this.signInUsername.clear();
            this.signInPassword.clear();
            this.signInError.hide();
            this.signInButton.setEnabled(true);
            this.signInButton.removeClass('d-button-pressed');
            this.signInUsername.focus();
            this.userButton.addClass('d-r-panel-button-pressed');
        },
        hideSignIn: function () {
            this.userButton.removeClass('d-r-panel-button-pressed');
            this.signInForm.hide();
        },
        toggleUserPanel: function () {
            if (this.user()) {
                this.userButton.addClass('d-r-panel-button-pressed');
                new d.Menu().addClass('d-r-header-user-menu').setItems([
                    {title: d.t('Profile'), action: ['show', 'user.profile', this.user().name()]},
                    {title: d.t('Settings'), action: ['show', 'settings']},
                    d.Menu.separator,
                    {title: d.t('Sign Out'), action: 'signOut'}
                ]).setTarget(this).onClose(function () {
                    this.userButton.removeClass('d-r-panel-button-pressed');
                }, this).show(this.userButton, this.userButton.element);
            } else {
                if (this.signInForm.visible() && this.signInButton.enabled()) {
                    this.hideSignIn();
                } else {
                    this.showSignIn();
                }
            }
        },
        authenticationError: {},
        requireAuthentication: function () {
            this.reloadOnAuthentication = true;
            if (!this.user()) {
                this.showSignIn(true);
                throw this.authenticationError;
            }
        },
        signOut: function () {
            if (!this.user()) return;
            this.server().signOut();
        },
        signIn: function () {
            this.signInButton.addClass('d-button-pressed').setEnabled(false);
            this.server().signIn(this.signInUsername.text(), this.signInPassword.text(), function (message) {
                this.signInButton.removeClass('d-button-pressed').setEnabled(true);
                this.signInError.show().setText(d.t(message));
            }.bind(this));
        },
        request: function () {
            ++this.pendingRequests;
            this.spinner.show();
        },
        requestEnd: function () {
            if (!--this.pendingRequests) {
                this.spinner.hide();
            }
        },
        query: function (name, options, callback) {
            var t = this;
            this.request();
            this.server().query(name, options, function (result) {
                t.requestEnd();
                callback(result);
            });
        },
        getUser: function (id, callback, context) {
            var t = this;
            this.request();
            this.server().getUser(id, function (result) {
                t.requestEnd();
                callback.call(context, result);
            });
        },
        panelLink: function (t, view) {
            return new d.r.Link('d-r-panel-button').setText(d.t(t)).setURL(this.reverse.apply(this, [].slice.call(arguments, 1)));
        },
        notFound: function () {
            this.page.clear();
            d.r.views.notFound.call(this, [this.url]);
            return this;
        },
        abs: function (url) {
            return '#/' + url;
        },
        reverse: function (view) {
            var urls = d.r.urls, i = 0, url, args = [].slice.call(arguments, 1), arg, source, out;
            while (url = urls[i++]) {
                if (url[1] === view) {
                    source = url[0].source.replace(/^\^/, '').replace(/\\\//g, '/').replace(/\$$/, '');
                    arg = 0;
                    out = source.replace(/\((?:[^\)]|\\\))+\)/g, function () {
                        return args[arg++];
                    });
                    if (args.length === arg) {
                        return out;
                    }
                }
            }
            throw new Error('No reverse match for "' + view + '" with arguments [' + args + ']');
        },
        show: function (view) {
            return this.go(this.reverse.apply(this, arguments));
        },
        redirect: function (loc) {
            if (loc[loc.length - 1] !== '/') {
                loc = loc + '/';
            }
            if (loc[0] !== '/') {
                loc = '/' + loc;
            }
            if (loc === this.url) return;
            this.isRedirect = true;
            this.url = loc;
            location.hash = '#' + loc;
            return this;
        },
        go: function (loc, soft) {
            var urls = d.r.urls, i = 0, url, request, match;
            if (loc[loc.length - 1] !== '/') {
                return this.go(loc + '/', soft);
            }
            if (loc[0] !== '/') {
                return this.go('/' + loc, soft);
            }
            if (!soft) location.hash = loc;
            if (this.url === loc) return;
            if (this.signInForm.visible() && this.signInAutohide) {
                this.hideSignIn();
            }
            if (this.unload) {
                this.unload();
                this.unload = undefined;
            }
            this.reloadOnAuthentication = false;
            this.url = loc;
            this.page.clear();
            this.page.element.scrollTop = 0;
            try {
                while (url = urls[i++]) {
                    if (match = url[0].exec(loc.substr(1))) {
                        if (!d.r.views[url[1]]) {
                            console.error('Undefined view ' + url[1]);
                            break;
                        }
                        return d.r.views[url[1]].call(this, match);
                    }
                }
                d.r.views.notFound.call(this, [loc]);
            } catch (e) {
                if (e === this.authenticationError) {
                    d.r.views.forbidden.call(this, [loc]);
                } else {
                    throw e;
                }
            }
            return this;
        },
        reload: function () {
            var url = this.url;
            this.url = null;
            this.go(url);
            return this;
        }
    });
    d.r.Server = d.Class(d.Base, {
        PACKETS: {"Client:connect":["sessionId"],"Server:connect":["user","sessionId"],"Client:auth.signIn":["username","password"],"Server:auth.signIn.failed":["message"],"Server:auth.signIn.succeeded":["user"],"Client:auth.signOut":[],"Server:auth.signOut.succeeded":[],"Client:query.users.user":["request$id","user$id"],"Client:query.projects.count":["request$id"],"Client:query.projects.featured":["request$id","offset","length"],"Client:query.projects.topLoved":["request$id","offset","length"],"Client:query.projects.topViewed":["request$id","offset","length"],"Client:query.projects.topRemixed":["request$id","offset","length"],"Client:query.projects.user.lovedByFollowing":["request$id","offset","length"],"Client:query.projects.user.byFollowing":["request$id","offset","length"],"Client:query.forums.categories":["request$id"],"Client:query.forums.forum":["request$id","forum$id"],"Client:query.forums.topics":["request$id","forum$id","offset","length"],"Server:query.result":["request$id","result"],"Server:query.error":["request$id","message"]},
        INITIAL_REOPEN_DELAY: 100,
        init: function (socketURL, assetStoreURL) {
            this.socketURL = socketURL;
            this.assetStoreURL = assetStoreURL;
            this.requestId = 0;
            this.requests = {};
            this.usersByName = {};
            this.usersById = {};
            this.log = [];
            this._sessionId = localStorage.getItem('d.r.sessionId');
            this.reopenDelay = this.INITIAL_REOPEN_DELAY;
            (this.open = this.open.bind(this))();
        },
        open: function () {
            this.socket = new WebSocket(this.socketURL);
            this.socket.onopen = this.listeners.open.bind(this);
            this.socket.onclose = this.listeners.close.bind(this);
            this.socket.onmessage = this.listeners.message.bind(this);
            this.socket.onerror = this.listeners.error.bind(this);
            this.socketQueue = [];
        },
        '.app': {},
        '.sessionId': {
            apply: function (sessionId) {
                localStorage.setItem('d.r.sessionId', sessionId);
            }
        },
        on: {
            'connect': function (p) {
                this.app().setUser(p.user ? new d.r.User(this).fromJSON(p.user) : null);
                this.setSessionId(p.sessionId);
            },
            'auth.signIn.failed': function (p) {
                this.app().requestEnd();
                if (this.signInErrorCallback) {
                    this.signInErrorCallback(p.message);
                    this.signInErrorCallback = undefined;
                }
            },
            'auth.signIn.succeeded': function (p) {
                this.app().requestEnd();
                this.app().setUser(new d.r.User(this).fromJSON(p.user));
            },
            'auth.signOut.succeeded': function () {
                this.app().requestEnd();
                this.app().setUser(null);
            },
            'query.result': function (p) {
                var request = this.requests[p.request$id];
                if (!request) {
                    console.warn('Invalid request id:', p);
                    return;
                }
                request.callback(p.result);
                delete this.requests[p.request$id];
            },
            'query.error': function (p) {
                var request = this.requests[p.request$id];
                if (!request) {
                    console.warn('Invalid request id:', p);
                    return;
                }
                console.error('QueryError: ' + p.message + ' in ' + request.name, request.options);
                delete this.requests[p.request$id];
            }
        },
        listeners: {
            open: function () {
                var socketQueue = this.socketQueue, packet = {
                    sessionId: this.sessionId()
                };
                this.app().setConnected(true);
                this.reopenDelay = this.INITIAL_REOPEN_DELAY;
                this.socket.send(JSON.stringify(this.encodePacket('Client', 'connect', packet)));
                packet.$type = 'connect';
                packet.$time = new Date;
                packet.$side = 'Client';
                this.log.splice(this.log.length - socketQueue.length, 0, packet);
                if (this.app().config().livePacketLog) this.logPacket(packet);
                while (packet = socketQueue.pop()) {
                    if (this.app().config().livePacketLog) this.logPacket(this.log[this.log.length - socketQueue.length - 1]);
                    this.socket.send(packet);
                }
            },
            close: function () {
                this.app().setConnected(false);
                console.warn('Socket closed. Reopening.');
                if (this.signInErrorCallback) {
                    this.signInErrorCallback('Connection lost.');
                    this.signInErrorCallback = undefined;
                }
                setTimeout(this.open, this.reopenDelay);
                this.reopenDelay *= 2;
            },
            message: function (e) {
                var packet = this.decodePacket('Server', e.data);
                if (!packet) return;
                packet.$time = new Date;
                packet.$side = 'Server';
                this.log.push(packet);
                if (this.app().config().livePacketLog) this.logPacket(packet);
                if (this.on.hasOwnProperty(packet.$type)) {
                    this.on[packet.$type].call(this, packet);
                } else {
                    this.warn('Missed packet:', packet);
                }
            },
            error: function (e) {
                console.warn('Socket error:', e);
            }
        },
        decodePacket: function (side, packet) {
            var type, info, i, result;
            try {
                packet = JSON.parse(packet);
            } catch (e) {
                console.warn('Packet syntax error:', packet);
                return;
            }
            if (!packet || !(packet instanceof Array)) {
                console.warn('Invalid packet:', e);
                return;
            }
            type = packet[0];
            info = this.PACKETS[side + ':' + type];
            if (!info) {
                console.warn('Invalid packet type:', packet);
                return;
            }
            i = info.length;
            result = {};
            result.$type = type;
            while (i--) {
                result[info[i]] = packet[i + 1];
            }
            return result;
        },
        encodePacket: function (side, type, properties) {
            var info = this.PACKETS[side + ':' + type], i, l, result;
            if (!info) {
                console.warn('Invalid packet type:', type, properties);
                return;
            }
            i = 0;
            l = info.length;
            result = [type];
            while (i < l) {
                result.push(properties[info[i++]]);
            }
            return result;
        },
        send: function (type, properties, censorFields) {
            var p = this.encodePacket('Client', type, properties), packet, log, key;
            log = {};
            log.$type = type;
            for (key in properties) if (properties.hasOwnProperty(key)) {
                log[key] = censorFields && censorFields[key] ? '********' : properties[key];
            }
            log.$time = new Date;
            log.$side = 'Client';
            this.log.push(log);
            if (!p) return;
            packet = JSON.stringify(p);
            if (this.socket.readyState === 0) {
                this.socketQueue.push(packet);
                return;
            }
            if (this.app().config().livePacketLog) this.logPacket(log);
            this.socket.send(packet);
        },
        query: function (name, options, callback) {
            var id = ++this.requestId;
            this.requests[id] = {
                name: name,
                options: options,
                callback: callback
            };
            options.request$id = id;
            this.send('query.' + name, options);
        },
        signIn: function (username, password, errorCallback) {
            this.app().request();
            this.send('auth.signIn', {
                username: username,
                password: password
            }, {password: true});
            this.signInErrorCallback = errorCallback;
        },
        signOut: function () {
            this.app().request();
            this.send('auth.signOut');
        },
        getAsset: function (hash) {
            return this.assetStoreURL + hash + '/';
        },
        getUser: function (id, callback, context) {
            var t = this;
            if (this.usersById[id]) {
                return callback.call(context, this.usersById[id]);
            }
            this.query('users.user', {
                user$id: id
            }, function (result) {
                callback.call(context, new d.r.User(t).fromJSON(result));
            });
        },
        logPacket: function (packet) {
            function log(object, dollar) {
                var key;
                for (key in object) if (object.hasOwnProperty(key) && (!dollar || key[0] !== '$')) {
                    if (object[key] && typeof object[key] === 'object') {
                        console.group(key + ':');
                        log(object[key]);
                        console.groupEnd();
                    } else {
                        console.log(key + ':', object[key]);
                    }
                }
            }
            console.groupCollapsed('[' + packet.$time.toLocaleTimeString() + '] ' + packet.$side + ':' + packet.$type);
            log(packet, true);
            console.groupEnd();
        },
        showLog: function () {
            var s = [], i = 0;
            while (i < this.log.length) {
                this.logPacket(this.log[i++]);
            }
        }
    });
    d.r.User = d.Class(d.Base, {
        init: function (server) {
            this.base(arguments);
            this.setServer(server);
        },
        '.server': {},
        '.name': {
            apply: function (name) {
                this.server().usersByName[name] = this;
            }
        },
        '.id': {
            apply: function (id) {
                this.server().usersById[id] = this;
            }
        },
        '.rank': {
            value: 'default'
        },
        avatarURL: function () {
            var id = '' + this.id(),
                trim = id.length - 4;
            return 'http://beta.scratch.mit.edu/static/site/users/avatars/' + id.substr(0, trim) + '/' + id.substr(trim) + '.png';
        },
        profileURL: function () {
            return 'http://beta.scratch.mit.edu/users/' + encodeURIComponent(this.name());
        },
        toJSON: function () {
            var rank = this.rank(),
                result = {
                    id: this.id(),
                    name: this.name()
                };
            if (rank !== 'default') result.rank = rank;
            return result;
        },
        fromJSON: function (o) {
            return this.setId(o.id).setName(o.name).setRank(o.rank || 'default');
        }
    });
    d.r.Link = d.Class(d.Button, {
        init: function (className) {
            this.base(arguments);
            this.element = this.container = this.newElement(className || 'd-r-link', 'a');
            this.element.tabIndex = 0;
        },
        setView: function (view) {
            return this.setURL(d.r.App.prototype.reverse.apply(null, arguments));
        },
        '.URL': {
            apply: function (url) {
                this.element.target = '';
                this.element.href = this._externalURL = d.r.App.prototype.abs(url);
            }
        },
        '.externalURL': {
            apply: function (url) {
                this._url = null;
                this.element.target = '_blank';
                this.element.href = url;
            }
        }
    });
    d.r.Carousel = d.Class(d.Control, {
        acceptsScrollWheel: true,
        init: function () {
            this.items = [];
            this.visibleItems = [];
            this.base(arguments);
            this.initElements('d-r-carousel');
            this.element.appendChild(this.header = this.newElement('d-r-carousel-header'));
            this.element.appendChild(new d.Button('d-r-carousel-button d-r-carousel-button-left').onExecute(function () {
                if (this.offset > 0) {
                    this.scroll(-1);
                }
            }, this).element);
            this.element.appendChild(new d.Button('d-r-carousel-button d-r-carousel-button-right').onExecute(function () {
                if (this.loaded === this.items.length || this.offset + this.maxVisibleItemCount() !== this.loaded) {
                    if (this.scroll(1)) {
                        this.load();
                    }
                }
            }, this).element);
            this.element.appendChild(this.wrap = this.newElement('d-r-carousel-wrap'));
            this.wrap.appendChild(this.container = this.newElement('d-r-carousel-container'));
            this.onLive(function () {
                this.clear();
                this.offset = 0;
                this.scrollX = 0;
                this.max = -1;
                this.load();
            });
            this.onScrollWheel(this.scrollWheel);
        },
        '.title': {
            apply: function (title) {
                this.header.textContent = title;
            }
        },
        '.hasDetails': {
            apply: function (hasDetails) {
                d.toggleClass(this.element, 'd-r-carousel-detail', hasDetails);
            }
        },
        '.loader': {},
        '.transformer': {},
        ITEM_WIDTH: 194.6458333731,
        scrollLoadAmount: 10,
        scrollWheel: function (e) {
            var t = this, offset, max = this.max > -1 ? Math.max(0, this.max * this.ITEM_WIDTH - this.wrap.offsetWidth) : this.container.offsetWidth;
            this.scrollX += e.x;
            if (this.scrollX < 0) this.scrollX = 0;
            if (this.scrollX > max) this.scrollX = max;
            if ((offset = Math.ceil(this.scrollX / this.ITEM_WIDTH)) !== this.offset) {
                this.offset = offset;
                this.container.style.left = -this.offset * this.ITEM_WIDTH + 'px';
                if (this.offset + this.maxVisibleItemCount() > this.loaded) {
                    this.load();
                }
            }
            e.setAllowDefault(true);
        },
        visibleItemCount: function () {
            return Math.max(1, Math.floor(this.wrap.offsetWidth / this.ITEM_WIDTH));
        },
        maxVisibleItemCount: function () {
            return Math.max(1, Math.ceil(this.wrap.offsetWidth / this.ITEM_WIDTH));
        },
        scroll: function (screens) {
            var length = this.visibleItemCount();
            if (screens > 0 && this.max > -1 && this.offset + length >= this.max) {
                return false;
            }
            this.offset += screens * length;
            if (this.offset < 0) this.offset = 0;
            this.scrollX = this.offset * this.ITEM_WIDTH;
            this.container.style.left = -this.offset * this.ITEM_WIDTH + 'px';
            return true;
        },
        loaded: 0,
        loadItems: function (offset, length, callback) {
            var t = this, cached, delta;
            if (!this._loader) return;
            if (offset + length < this.loaded) {
                callback.call(this, []);
                return;
            }
            if (offset < this.loaded) {
                delta = this.loaded - offset;
                this._loader(offset + delta, length - delta, function (result) {
                    if (result.length < length - delta) {
                        t.max = offset + delta + result.length;
                    }
                    callback.call(t, result);
                });
            } else {
                this._loader(offset, length, function (result) {
                    if (result.length < length) {
                        t.max = offset + result.length;
                    }
                    callback.call(t, result);
                });
            }
            this.loaded = offset + length;
        },
        load: function () {
            var t = this, offset, length;
            if (this.max !== -1) return;
            offset = this.offset;
            length = this.maxVisibleItemCount() * 2;
            this.loadItems(offset, length, function (items) {
                var i = 0, item;
                while (item = items[i++]) {
                    t.add(t.items[offset + i - 1] = t._transformer(item));
                }
            });
        }
    });
    d.r.CarouselItem = d.Class(d.r.Link, {
        init: function () {
            this.base(arguments, 'd-r-carousel-item');
            this.element.appendChild(this.thumbnailImage = this.newElement('d-r-carousel-item-thumbnail', 'img'));
            this.element.appendChild(this.labelElement = this.newElement('d-r-carousel-item-label'));
            this.element.appendChild(this.detailElement = this.newElement('d-r-carousel-item-detail'));
        },
        '.label': {
            apply: function (label) {
                this.labelElement.textContent = label;
            }
        },
        '.detail': {
            apply: function (detail) {
                this.detailElement.textContent = detail;
                this.detailElement.style.display = detail ? 'block' : 'none';
            }
        },
        '.thumbnail': {
            apply: function (url) {
                this.thumbnailImage.src = url;
            }
        }
    });
    d.r.ProjectCarousel = d.Class(d.r.Carousel, {
        _loader: function (offset, length, callback) {
            this.app().query('projects.' + this.query(), {
                offset: offset,
                length: length
            }, function (result) {
                callback(result);
            });
        },
        _transformer: function (project) {
            var query = this.query();
            return new d.r.ProjectCarouselItem().setProject(project).setDetail(
                query === 'topViewed' ? d.t.plural('% Views', '% View', project.views) :
                query === 'topLoved' ? d.t.plural('% Loves', '% Love', project.loves) :
                query === 'topRemixed' ? d.t.plural('% Remixes', '% Remix', project.remixes.length) : '');
        },
        '.query': {
            apply: function (query) {
                this.setHasDetails(query === 'topViewed' || query === 'topLoved' || query === 'topRemixed');
            }
        }
    });
    d.r.ProjectCarouselItem = d.Class(d.r.CarouselItem, {
        '.project': {
            apply: function (info) {
                this.setView('project.view', info.id);
                this.setLabel(info.project.name);
                this.onLive(function () {
                    this.setThumbnail(this.app().server().getAsset(info.project.thumbnail));
                });
            }
        }
    });
    d.r.LazyList = d.Class(d.Container, {
        init: function (className) {
            this.items = [];
            this.visibleItems = [];
            this.base(arguments, className || 'd-r-list');
            this.onLive(function () {
                this.clear();
                this.offset = 0;
                this.scrollX = 0;
                this.max = -1;
                this.load();
            });
            this.onScrollWheel(this.scrollWheel);
        },
        '.loader': {},
        '.transformer': {},
        '.itemHeight': { value: Infinity },
        scrollLoadAmount: 10,
        scrollWheel: function (e) {
            var t = this, offset = Math.ceil(this.app().wrap.element.scrollTop / this.itemHeight());
            if (offset + this.maxVisibleItemCount() > this.loaded) {
                this.load();
            }
            e.setAllowDefault(true);
        },
        visibleItemCount: function () {
            return Math.max(1, Math.floor(this.app().wrap.element.offsetHeight / this.itemHeight()));
        },
        maxVisibleItemCount: function () {
            return Math.max(1, Math.ceil(this.app().wrap.element.offsetHeight / this.itemHeight()));
        },
        loaded: 0,
        loadItems: function (offset, length, callback) {
            var t = this, cached, delta;
            if (!this._loader) return;
            if (offset + length < this.loaded) {
                callback.call(this, []);
                return;
            }
            if (offset < this.loaded) {
                delta = this.loaded - offset;
                this._loader(offset + delta, length - delta, function (result) {
                    if (result.length < length - delta) {
                        t.max = offset + delta + result.length;
                    }
                    callback.call(t, result);
                });
            } else {
                this._loader(offset, length, function (result) {
                    if (result.length < length) {
                        t.max = offset + result.length;
                    }
                    callback.call(t, result);
                });
            }
            this.loaded = offset + length;
        },
        load: function () {
            var t = this, offset, length;
            if (this.max !== -1) return;
            offset = this.offset;
            length = this.maxVisibleItemCount() * 2;
            this.loadItems(offset, length, function (items) {
                var i = 0, item;
                while (item = items[i++]) {
                    t.add(t.items[offset + i - 1] = t._transformer(item));
                }
            });
        }
    });

})(this);
