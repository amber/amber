var d = {};

if (!Function.prototype.bind) {
	Function.prototype.bind = function (context) {
		var f = this;
		return function () {
			return f.apply(context, arguments);
		};
	};
}

d.addClass = function (element, className) {
	if ((' ' + element.className + ' ').indexOf(' ' + className + ' ') === -1) element.className += ' ' + className;
};
d.removeClass = function (element, className) {
	var i = (' ' + element.className + ' ').indexOf(' ' + className + ' ');
	if (i !== -1) element.className = element.className.substr(0, i - 1) + element.className.substr(i + className.length + 1);
};
d.toggleClass = function (element, className, on) {
	if (on) {
		d.addClass(element, className);
	} else {
		d.removeClass(element, className);
	}
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
		setter.call(this, value);
		if (apply) apply.call(this, value);
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
	}
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
	setWebkitEvent: function (e) {
		this.setEvent(e);
		this.x = e.wheelDeltaX / 3;
		this.y = e.wheelDeltaY / 3;
		return this;
	},
	setMozEvent: function (e) {
		this.setEvent(e);
		this.x = 0;
		this.y = -e.detail;
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
	add: function (child) {
		if (child.parent) {
			child.parent.remove(child);
		}
		this.children.push(child);
		child.parent = this;
		this.container.appendChild(child.element);
		return this;
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
	setElement: function (element) {
		var app = this,
			mouseDown = false,
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
				t.control.dispatch('DragStart', new d.TouchEvent().setMouseEvent(e));
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
			if (e.shiftKey || e.target.tagName === 'INPUT' && !e.target.control.isMenu) return true;
			e.preventDefault();
		}, true);
		element.addEventListener('mousedown', function (e) {
			var dx, dy, c;
			if (app._menu && !app._menu.hasChild(e.target.control)) app._menu.close();
			if (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT') return true;
			c = e.target.control;
			while (c && !c.acceptsClick) {
				c = c.parent;
			}
			if (!c) return;
			if (e.button === 2 && !e.shiftKey) {
				c.dispatch('ContextMenu', new d.TouchEvent().setMouseEvent(e));
				return;
			} else {
				mouseDown = shouldStartDrag = true;
				app.mouseDownControl = c;

				app.mouseX = e.clientX;
				app.mouseY = e.clientY;
				app.mouseStart = +new Date;
				c.dispatch('TouchStart', new d.TouchEvent().setMouseEvent(e));
			}
			document.activeElement.blur();
			e.preventDefault();
		}, true);
		element.addEventListener('mousemove', function (e) {
			if (!mouseDown || !app.mouseDownControl) return true;
			if (shouldStartDrag) {
				app.mouseDownControl.dispatch('DragStart', new d.TouchEvent().setMouseEvent(e));
				shouldStartDrag = false;
			}
			app.mouseDownControl.dispatch('TouchMove', new d.TouchEvent().setMouseEvent(e));
			// e.preventDefault();
		}, true);
		element.addEventListener('mouseup', function (e) {
			if (!mouseDown || !app.mouseDownControl) return true;
			mouseDown = false;
			if (app._menu && app._menu.hasChild(e.target.control)) {
				dx = app.mouseX - app.menuOriginX;
				dy = app.mouseY - app.menuOriginY;
				if (dx * dx + dy * dy < 4 && +new Date - app.menuStart <= app.MENU_CLICK_TIME) {
					app.menuStart -= 100;
					return true;
				}
			}
			app.mouseDownControl.dispatch('TouchEnd', new d.TouchEvent().setMouseEvent(e));
			// e.preventDefault();
		}, true);
		function mousewheel(f) {
			return function (e) {
				var t = e.target;
				if (t.nodeType === 3) t = t.parentNode;
				t = t.control;
				while (t && !t.acceptsScrollWheel) {
					t = t.parent;
					if (!t) return true;
				}
				t.dispatch('ScrollWheel', new d.WheelEvent()[f](e));
				e.preventDefault();
			};
		}
		element.addEventListener('mousewheel', mousewheel('setWebkitEvent'), true);
		element.addEventListener('MozMousePixelScroll', mousewheel('setMozEvent'), true);
		return this;
	},
	'.fullscreen': {
		apply: function (fullscreen) {
			d.toggleClass(this.element, 'd-fullscreen', fullscreen);
		}
	}
});
d.Menu = d.Class(d.Control, {
	TYPE_TIMEOUT: 500,
	acceptsScrollWheel: true,
	acceptsClick: true,
	scrollY: 0,
	isMenu: true,

	init: function () {
		this.base(arguments);
		this.onScrollWheel(this.scroll);
		this.menuItems = [];
		this.clearSearch = this.clearSearch.bind(this);

		this.initElements('d-menu', 'd-menu-contents');

		this.element.appendChild(this.search = this.newElement('d-menu-search', 'input'));
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
	'.action': {},
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
		} else if (typeof selectedItem === 'string') {
			i = 0;
			while (target = this.menuItems[i++]) {
				if (target.action() === selectedItem) break;
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
	},
	show: function (control, position) {
		control.app().setMenu(this);
		this.element.style.left = position.x + 'px';
		this.element.style.top = position.y + 'px';
		this.layout();
	},
	scroll: function (e) {
		var top = parseFloat(this.element.style.top),
			max, bottom, delta;
		this.viewHeight = parseFloat(getComputedStyle(this.element).height);
		max = this.container.offsetHeight - this.viewHeight;
		this.scrollY = Math.max(0, Math.min(max, this.scrollY - e.y));
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
	close: function () {
		window.removeEventListener('resize', this.resize);
		if (this.parent) this.parent.remove(this);
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
		if (typeof this._action === 'string') {
			this.menu.action()(this.model);
		} else {
			this._action();
		}
		this.menu.close();
	}
});
d.MenuSeparator = d.Class(d.Control, {
	init: function () {
		this.base(arguments);
		this.initElements('d-menu-separator');
	}
});

// == Amber ==

d.locale = {};
d.ServerData = d.Class(d.Base, {
	init: function (amber) {
		this.base(arguments);
		this.amber = amber;
	},
	fromSerial: function () {
		throw new Error('Unimplemented fromSerial');
	}
});
d.User = d.Class(d.ServerData, {
	init: function (amber) {
		this.base(arguments);
		this.amber = amber;
	},
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
	'.rank': {},
	fromSerial: function (o) {
		return this.setId(o[0]).setName(o[1]).setRank(o[2] || 'default');
	}
});
d.Project = d.Class(d.ServerData, {
	'.name': {},
	'.notes': {},
	'.stage': {},
	fromSerial: function (o) {
		var amber = this.amber;
		return this.setName(o[0]).setNotes(o[1]).setStage(new d.Stage(this.amber).fromSerial(o[2]));
	}
});
d.SoundMedia = d.Class(d.ServerData, {
	'.name': {},
	'.sound': {},
	fromSerial: function (o) {
		throw new Error('Unimplemented');
	}
});
d.ImageMedia = d.Class(d.ServerData, {
	'.name': {},
	'.image': {},
	'.text': {},
	fromSerial: function (o) {
		var img = new Image();
		img.src = o[1];
		return this.setName(o[0]).setImage(img).setText(o[2] ? {
			text: o[2],
			font: o[3],
			x: [4],
			y: [5]
		} : null);
	}
});
d.Stage = d.Class(d.ServerData, {
	'.sprites': {},
	'.watchers': {},
	'.scripts': {},
	'.backgrounds': {},
	'.backgroundIndex': {},
	'.sounds': {},
	'.tempo': {},
	fromSerial: function (o) {
		var amber = this.amber;
		return this.setSprites(o[0] ? o[0].map(function (a) {
			return new d.Sprite(amber).fromSerial(a);
		}) : []).setScripts(o[2] ? o[2].map(function (a) {
			var stack = new d.BlockStack().fromSerial(a, null, amber);
			amber.add(stack);
			return stack;
		}) : []).setBackgrounds(o[3] ? o[3].map(function (a) {
			return new d.ImageMedia(amber).fromSerial(a);
		}) : []).setBackgroundIndex(o[4]).setSounds(o[5] ? o[5].map(function (a) {
			return new d.SoundMedia(amber).fromSerial(a);
		}) : []).setTempo(o[6]);
	}
});
d.Amber = d.Class(d.App, {
	PROTOCOL_VERSION: '1.0.1.4',

	init: function () {
		this.base(arguments);
		this.locale = d.locale['en-US'];
		this.usersByName = {};
		this.usersById = {};
		this.blocks = {};
	},
	createSocket: function (server, callback) {
		this.socket = new d.Socket(this, server, callback);
	},
	newScriptID: 0,
	createScript: function (x, y, blocks) {
		var id = ++this.newScriptID,
			tracker = [],
			script = new d.BlockStack().fromSerial([x, y, blocks], tracker);
		this.socket.newScripts[id] = tracker;
		this.add(script);
		this.socket.send('script.create', [x, y, blocks], id);
		return script;
	},
	t: function (id) {
		return this.locale[id];
	},
	getUser: function (username, callback) {
		var xhr, me = this;
		if (this.usersByName[username]) return callback(this.usersByName[username]);
		xhr = new XMLHttpRequest();
		xhr.open('GET', 'http://scratch.mit.edu/api/getinfobyusername/' + encodeURIComponent(username), true);
		xhr.onload = function () {
			callback(new d.User(me).setName(username).setId(xhr.responseText.split(':')[1]));
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
		xhr.send();
	},
	setElement: function (element) {
		var name, category;
		this.base(arguments, element);
		this.element.appendChild(this.lightbox = this.newElement('d-lightbox'));
		this.add(this.editor = new d.BlockEditor()).
			add(this.palette = new d.BlockPalette()).
			add(this.userList = new d.UserList(this)).
			add(this.authentication = new d.AuthenticationPanel(this)).
			setLightboxEnabled(true);
		this.authentication.layout();

		for (name in d.BlockSpecs) if (d.BlockSpecs.hasOwnProperty(name)) {
			category = new d.BlockList();
			d.BlockSpecs[name].forEach(function (spec) {
				var block;
				if (spec === '-') {
					category.addSpace();
				} else {
					category.add(d.Block.fromSpec(spec));
				}
			});
			this.palette.addCategory(name, category);
		}

		return this;
	},
	'.lightboxEnabled': {
		apply: function (lightboxEnabled) {
			this.lightbox.style.display = lightboxEnabled ? 'block' : 'none';
		}
	}
});
d.BlockSpecs = {
	motion: [
		['c', 'motion', 'forward:', 'move %f steps', 10],
		['c', 'motion', 'turnRight:', 'turn %icon:right %f degrees', 15],
		['c', 'motion', 'turnLeft:', 'turn %icon:left %f degrees', 15],
		'-',
		['vs', 'direction', 90],
		['c', 'motion', 'pointTowards:', 'point towards %sprite'],
		'-',
		['c', 'motion', 'gotoX:y:', 'go to x: %f y: %f', 0, 0],
		['c', 'motion', 'gotoSpriteOrMouse:', 'go to %sprite'],
		['c', 'motion', 'glideSecs:toX:y:elapsed:from:', 'glide %f secs to x: %f y: %f', 1, 0, 0],
		'-',
		['vc', 'x position'],
		['vs', 'x position'],
		['vc', 'y position'],
		['vs', 'y position'],
		'-',
		['c', 'motion', 'bounceOffEdge', 'if on edge, bounce'],
		'-',
		['v', 'x position'],
		['v', 'y position'],
		['v', 'direction']
	],
	looks: [
		['c', 'looks', 'lookLike:', 'switch to costume %costume'],
		['c', 'looks', 'nextCostume', 'next costume'],
		['v', 'costume #'],
		'-',
		['c', 'looks', 'say:duration:elapsed:from:', 'say %s for %f secs', 'Hello!', 2],
		['c', 'looks', 'say:duration:', 'say %s', 'Hello!'],
		['c', 'looks', 'think:duration:elapsed:from:', 'think %s for %f secs', 'Hmm\u2026', 2],
		['c', 'looks', 'think:duration:', 'think %s', 'Hmm\u2026'],
		'-',
		['vc', 'color effect'],
		['vs', 'color effect'],
		['c', 'looks', 'filterReset', 'clear graphic effects'],
		'-',
		['vc', 'size'],
		['vs', 'size', 100],
		['v', 'size'],
		'-',
		['c', 'looks', 'show', 'show'],
		['c', 'looks', 'hide', 'hide'],
		'-',
		['c', 'looks', 'comeToFront', 'go to front'],
		['c', 'looks', 'goBackByLayers:', 'go back %i layers', 1]
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
		['vs', 'instrument'],
		'-',
		['vc', 'volume', -10],
		['vs', 'volume', 100],
		['v', 'volume'],
		'-',
		['vc', 'tempo', 20],
		['vs', 'tempo', 60],
		['v', 'tempo']
	],
	pen: [
		['c', 'pen', 'clear', 'clear'],
		'-',
		['c', 'pen', 'putPenDown', 'pen down'],
		['c', 'pen', 'putPenUp', 'pen up'],
		'-',
		['vs', 'pen color'],
		['vc', 'pen hue'],
		['vs', 'pen hue'],
		'-',
		['vc', 'pen shade'],
		['vs', 'pen shade'],
		'-',
		['vc', 'pen size'],
		['vs', 'pen size']
	],
	control: [
		// ['h', 'control', 'whenStartClicked', 'When %icon:flag clicked'],
		// ['h', 'control', 'whenKeyPressed:', 'When %key key pressed'],
		// ['h', 'control', 'whenSpriteClicked', 'When %sprite clicked'],
		// '-',
		['r', 'system', 'commandClosure', '%parameters %slot:command'],
		['r', 'system', 'reporterClosure', '%parameters %slot:reporter'],
		'-',
		['c', 'control', 'wait:elapsed:from:', 'wait %f secs', 1],
		'-',
		['t', 'control', 'doForever', 'forever %c'],
		['c', 'control', 'doRepeat', 'repeat %i %c', 10],
		'-',
		['c', 'control', 'broadcast:', 'broadcast %event'],
		['c', 'control', 'doBroadcastAndWait', 'broadcast %event and wait'],
		// ['h', 'control', 'whenMessageReceived:', 'When I receive %event'],
		'-',
		['t', 'control', 'doForeverIf', 'forever if %b %c'],
		['c', 'control', 'doIf', 'if %b %c'],
		['c', 'control', 'doIfElse', 'if %b %c else %c'],
		['c', 'control', 'doWaitUntil', 'wait until %b'],
		['c', 'control', 'doUntil', 'repeat until %b %c'],
		'-',
		['t', 'control', 'doReturn', 'stop script'],
		['t', 'control', 'stopAll', 'stop all %icon:stop']
	],
	sensing: [
		['b', 'sensing', 'touching:', 'touching %sprite?'],
		['b', 'sensing', 'touchingColor:', 'touching color %color?'],
		['b', 'sensing', 'color:sees:', 'color %color is touching %color?'],
		'-',
		['c', 'sensing', 'doAsk', 'ask %s and wait', "What's your name?"],
		['v', 'answer'],
		'-',
		['v', 'mouse x'],
		['v', 'mouse y'],
		['v', 'mouse down?'],
		'-',
		['b', 'sensing', 'keyPressed:', 'key %key pressed?'],
		'-',
		['r', 'sensing', 'distanceTo:', 'distance to %sprite'],
		'-',
		['v', 'timer'],
		['vs', 'timer'],
		'-',
		['r', 'sensing', 'attribute:of:', '%attribute of %object'],
		'-',
		['v', 'loudness'],
		['v', 'loud?']
	],
	operators: [
		['r', 'operators', '+', '%f + %f'],
		['r', 'operators', '-', '%f - %f'],
		['r', 'operators', '*', '%f * %f'],
		['r', 'operators', '/', '%f \xd7 %f'],
		'-',
		['r', 'operators', 'randomFrom:to:', 'pick random %f to %f'],
		'-',
		['r', 'operators', '<', '%s < %s'],
		['r', 'operators', '=', '%s = %s'],
		['r', 'operators', '>', '%s > %s'],
		'-',
		['r', 'operators', '&', '%b and %b'],
		['r', 'operators', '|', '%b or %b'],
		['r', 'operators', 'not', 'not %b'],
		'-',
		['r', 'operators', 'concatenate:with:', 'join %s %s', 'hello ', 'world'],
		['r', 'operators', 'letter:of:', 'letter %i of %s', 1, 'world'],
		['r', 'operators', 'stringLength:', 'length of %s', 'world'],
		'-',
		['r', 'operators', '\\\\', '%f mod %f'],
		['r', 'operators', 'rounded', 'round %f'],
		'-',
		['r', 'operators', 'computeFunction:of:', '%math of %f', 'sqrt', 10]
	],
	variables: [
		['v', 'var'],
		'-',
		['vs', ''],
		['vc', ''],
		['c', 'variables', 'showVariable:', 'show variable %var', ''],
		['c', 'variables', 'hideVariable:', 'hide variable %var', ''],
		'-',
		['c', 'lists', 'append:toList:', 'add %s to %list', 'thing', ''],
		'-',
		['c', 'lists', 'deleteLine:ofList:', 'delete %deletion-index of %list', 1, ''],
		['c', 'lists', 'insert:at:ofList:', 'insert %s at %index of %list', 'thing', 1, ''],
		['c', 'lists', 'setLine:ofList:to:', 'replace item %index of %list with %s', 1, '', 'thing'],
		'-',
		['r', 'lists', 'getLine:ofList:', 'item %index of %list', 1, ''],
		['r', 'lists', 'lineCountOfList:', 'length of %list'],
		['b', 'lists', 'list:contains:', '%list contains %s', '', 'thing']
	]
};
d.BlockSpecBySelector = {
	'setVar:to:': ['vs', 'var'],
	'changeVar:by:': ['vc', 'var', 1],
	'getVar:': ['v', 'var']
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
				d.BlockSpecBySelector[spec[2]] = spec;
				break;
			}
		});
	}
}();
d.Selectors = [
	// Motion
	'forward:',
	'turnLeft:',
	'turnRight:',
	'pointTowards:',
	'gotoX:y:',
	'gotoSpriteOrMouse:',
	'glideSecs:toX:y:elapsed:from:',
	'bounceOffEdge',

	// Looks
	'lookLike:',
	'nextCostume',
	'nextBackground',
	'say:duration:elapsed:from:',
	'say:',
	'think:duration:elapsed:from:',
	'think:',
	'filterReset',
	'show',
	'hide',
	'comeToFront',
	'goBackByLayers:',

	// Sound
	'playSound:',
	'doPlaySoundAndWait:',
	'stopAllSounds',
	'drum:duration:elapsed:from:',
	'noteOn:duration:elapsed:from:',

	// Pen
	'clear',
	'putPenDown',
	'putPenUp',
	'stampCostume',

	// Control
	'whenStartClicked',
	'whenKeyPressed:',
	'whenSpriteClicked',
	'wait:elapsed:from:',
	'doForever',
	'doRepeat',
	'broadcast:',
	'doBroadcastAndWait',
	'whenMessageReceived:',
	'doForeverIf',
	'doIf',
	'doIfElse',
	'doWaitUntil',
	'doUntil',
	'doReturn',
	'stopAll',

	// Sensing
	'touching:',
	'touchingColor:',
	'color:sees:',
	'doAsk',
	'keyPressed:',
	'distanceTo:',
	'getAttribute:of:',
	'sensor:',
	'sensorPressed:',

	// Operators
	'+',
	'-',
	'*',
	'/',
	'<',
	'=',
	'>',
	'&',
	'|',
	'not',
	'concatenate:with:',
	'letter:of:',
	'stringLength:',
	'\\\\',
	'rounded',
	'computeFunction:of:',

	// Variables
	'getVar:',
	'setVar:to:',
	'changeVar:by:',
	'showVariable:',
	'hideVariable:',
	'append:toList:',
	'deleteLine:ofList:',
	'insert:at:ofList:',
	'setLine:ofList:to:',
	'getLine:ofList:',
	'lineCountOfList:',
	'list:contains:',

	// Amber
	'commandClosure',
	'reporterClosure',
	'booleanClosure'
];
d.BlockSelector = { };
~function () {
	d.Selectors.forEach(function (sel, i) {
		d.BlockSelector[sel] = i;
	});
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
		this.received.push(e.data);
		this.receive(JSON.parse(e.data));
	},
	error: function (e) {
		console.warn('Socket error:', e);
	},
	unpackIds: function (source, destination) {
		var i = 0,
			amber = this.amber;
		function unpack(block) {
			var j = 0;
			if (typeof block[0] === 'number') {
				destination[i++].setId(block[0]).amber(amber);
				while (j < block[2].length) {
					if (block[2][j] instanceof Array) {
						unpack(block[2][j]);
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
	PACKETS: {
		'script.create': ['script', 'user$id', 'temp$id'],
		'block.move': ['user$id', 'block$id', 'x', 'y'],
		'block.attach': ['user$id', 'block$id', 'type', 'target$id', 'slot$index'],
		'block.delete': ['user$id', 'block$id'],
		'slot.set': ['user$id', 'block$id', 'slot$index', 'value'],
		'slot.claim': ['user$id', 'block$id', 'slot$index'],
		'user.login': ['success', 'result'],
		'user.join': ['user'],
		'user.leave': ['user$id'],
		'project.data': ['data']
	},
	receive: function (packet) {
		var info = this.PACKETS[packet[0]],
			i = info && info.length,
			a, bb, tracker;
		while (i--) {
			packet[info[i]] = packet[i + 1];
		}
		switch (packet[0]) {
		case 'script.create':
			if (packet.temp$id) {
				this.unpackIds(packet.script[2], this.newScripts[packet.temp$id]);
			} else {
				tracker = [];
				a = new d.BlockStack().fromSerial(packet.script, tracker);
				tracker.forEach(function (a) {
					a.amber(this);
				}, this.amber);
				this.amber.add(a);
			}
			break;
		case 'block.move':
			a = this.amber.blocks[packet.block$id];
			a.detach().setPosition(packet.x, packet.y);
			break;
		case 'block.attach':
			switch (packet.type) {
			case d.BlockAttachType.stack$append:
				bb = this.amber.blocks[packet.target$id].parent.element.getBoundingClientRect();
				this.amber.blocks[packet.block$id].detach().setPosition(bb.left, bb.bottom, function () {
					this.amber.blocks[packet.target$id].parent.appendStack(this.amber.blocks[packet.block$id].parent);
				}.bind(this));
				break;
			case d.BlockAttachType.stack$insert:
				bb = this.amber.blocks[packet.target$id].element.getBoundingClientRect();
				this.amber.blocks[packet.block$id].detach().setPosition(bb.left, bb.top, function () {
					a = this.amber.blocks[packet.target$id];
					a.parent.insertStack(this.amber.blocks[packet.block$id].parent, a);
				}.bind(this));
				break;
			}
			break;
		case 'block.delete':
			bb = d.BlockPalette.palettes[0].element.getBoundingClientRect();
			(a = this.amber.blocks[packet.block$id]).detach().setPosition(bb.left + 10, bb.top + 10 + (bb.bottom - bb.top - 20) * Math.random(), function () {
				a.parent.destroy();
			}.bind(this));
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
				this.amber.userList.addUser(this.amber.currentUser = new d.User(this.amber).fromSerial(packet.result));
				this.amber.setLightboxEnabled(false);
				this.amber.remove(this.amber.authentication);
				break;
			}
			this.amber.authentication.setMessage(packet.result);
			this.amber.authentication.setEnabled(true);
			this.amber.authentication.passwordField.select();
			break;
		case 'user.join':
			this.amber.userList.addUser(new d.User(this.amber).fromSerial(packet.user));
			break;
		case 'user.leave':
			this.amber.getUserById(packet.user$id, function (user) {
				this.amber.userList.removeUser(user);
			});
			break;
		case 'project.data':
			this.amber.currentProject = new d.Project(this.amber).fromSerial(packet.data);
			break;
		default:
			console.warn('Missed packet', packet);
			break;
		}
	},
	send: function (type /*, args... */) {
		var packet = JSON.stringify([].slice.call(arguments));
		this.sent.push(packet);
		this.socket.send(packet);
	}
});
d.AuthenticationPanel = d.Class(d.Control, {
	init: function (amber) {
		var savedServer, savedUsername, option;
		this.amber = amber;
		this.base(arguments);

		this.initElements('d-authentication-panel');
		this.element.appendChild(this.serverSelect = this.newElement('d-authentication-server-select', 'select'));
		this.element.appendChild(this.serverField = this.newElement('d-authentication-input d-authentication-server', 'input'));
		this.element.appendChild(this.usernameField = this.newElement('d-authentication-input', 'input'));
		this.element.appendChild(this.passwordField = this.newElement('d-authentication-input', 'input'));
		this.element.appendChild(this.signInButton = this.newElement('d-authentication-button', 'input'));
		this.element.appendChild(this.registerButton = this.newElement('d-authentication-button', 'input'));
		this.element.appendChild(this.messageField = this.newElement('d-authentication-message'));

		this.serverField.placeholder = amber.t('authentication-panel.server');
		this.serverField.oninput = this.serverInput.bind(this);
		this.serverField.value = (savedServer = localStorage.getItem('d.authentication-panel.server')) ? savedServer : 'ws://mpblocks.cloudno.de/:9182';
		this.serverSelect.onchange = this.serverChange.bind(this);
		this.serverSelect.onmousedown = this.serverClick.bind(this);
		this.serverSelect.options[0] = new Option(this.serverField.value);
		this.serverSelect.options[1] = new Option('ws://mpblocks.cloudno.de/:9182');
		this.serverSelect.options[2] = new Option('ws://localhost:9182');

		this.usernameField.placeholder = amber.t('authentication-panel.username');
		this.usernameField.oninput = this.userInput.bind(this);
		if (savedUsername = localStorage.getItem('d.authentication-panel.username')) {
			this.usernameField.value = savedUsername;
			this.hasSavedUsername = true;
		}

		this.passwordField.type = 'password';
		this.passwordField.onkeydown = this.passwordKeyDown.bind(this);
		this.passwordField.placeholder = amber.t('authentication-panel.password');

		this.signInButton.onclick = this.submit.bind(this);
		this.signInButton.value = amber.t('authentication-panel.signIn');
		this.signInButton.type = 'button';

		this.registerButton.onclick = this.register.bind(this);
		this.registerButton.value = amber.t('authentication-panel.register');
		this.registerButton.type = 'button';
	},
	register: function () {
		window.open('http://scratch.mit.edu/signup');
	},
	submit: function () {
		this.setEnabled(false);
		this.amber.createSocket(this.serverField.value, function () {
			this.amber.socket.send('user.login', this.amber.PROTOCOL_VERSION, this.usernameField.value, this.passwordField.value);
		}.bind(this));
	},
	'.enabled': {
		value: true,
		apply: function (enabled) {
			this.serverSelect.disabled =
				this.serverField.disabled =
				this.usernameField.disabled = 
				this.passwordField.disabled =
				this.signInButton.disabled = !enabled;
		}
	},
	userInput: function () {
		localStorage.setItem('d.authentication-panel.username', this.usernameField.value);
	},
	serverInput: function () {
		localStorage.setItem('d.authentication-panel.server', this.serverField.value);
	},
	serverChange: function () {
		localStorage.setItem('d.authentication-panel.server', this.serverField.value = this.serverSelect.value);
	},
	serverClick: function () {
		this.serverSelect.options[0] = new Option(this.serverField.value);
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
d.UserList = d.Class(d.Control, {
	init: function (amber) {
		this.base(arguments);
		this.initElements('d-user-list');
		this.element.appendChild(this.title = this.newElement('d-user-list-title'));
		this.title.textContent = amber.t('user-list.title');
		this.users = {};
	},
	addUser: function (user) {
		if (this.users[user.id()]) return;
		this.element.appendChild(this.users[user.id()] = this.createUserItem(user));
	},
	removeUser: function (user) {
		this.element.removeChild(this.users[user.id()]);
	},
	createUserItem: function (user) {
		var d = this.newElement('d-user-list-item', 'a'),
			icon = document.createElement('img');
		d.href = 'http://scratch.mit.edu/users/' + encodeURIComponent(user.name());
		d.target = '_blank';
		icon.src = 'http://scratch.mit.edu/static/icons/buddy/' + user.id() + '_sm.png';
		d.appendChild(icon);
		d.appendChild(document.createTextNode(user.name()));
		return d;
	}
});
d.BlockEditor = d.Class(d.Control, {
	init: function () {
		this.base(arguments);
		this.initElements('d-block-editor');
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
	initPosition: function (x, y) {
		this.element.style.left = x + 'px';
		this.element.style.top = y + 'px';
		return this;
	},
	x: function () {
		return this.element.getBoundingClientRect().left;
	},
	y: function () {
		return this.element.getBoundingClientRect().top;
	},
	toSerial: function () {
		return [this.x(), this.y(), this.children.map(function (block) {
			return block.toSerial();
		})];
	},
	fromSerial: function (a, tracker, amber) {
		this.element.style.left = a[0] + 'px';
		this.element.style.top = a[1] + 'px';
		a[2].forEach(function (block) {
			this.add(d.Block.fromSerial(block, tracker, amber));
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
		return this.children[0].isReporter;
	},
	terminal: function () {
		return this.children[this.children.length - 1].terminal();
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
		return this;
	},
	appendStack: function (stack) {
		var children = stack.children, child;
		while (child = children[0]) {
			this.add(child);
		}
		stack.destroy();
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
			app = this.app(),
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
		app.mouseDownControl = this;
		app.add(this);
		this.dragStartEvent = e;
		this.dragStartBB = bb;
	},
	touchMove: function (e) {
		var tolerance = 12,
			stackTolerance = 20,
			isTerminal, stacks, blocks, i,
			stack, j, block, arg, bb, test, last,
			target, targetDistance;
		function closer(test, newTarget) {
			var distance;
			function d(x, y) {
				var dx = x - e.x,
					dy = y - e.y;
				return dx * dx + dy * dy;
			}
			// distance = Math.min(
			// 	d(test.left, test.top),
			// 	d(test.left, test.bottom),
			// 	d(test.right, test.top),
			// 	d(test.right, test.bottom),
			// 	d((test.left + test.right) / 2, (test.top + test.bottom) / 2));
			distance = d((test.left + test.right) / 2, (test.top + test.bottom) / 2);
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
			blocks = d.Block.blocks;
			i = blocks.length;
			while (i--) {
				block = blocks[i];
				if (!(this.hasChild(block))) {
					j = block.arguments.length;
					while (j--) {
						arg = block.arguments[j];
						bb = arg.element.getBoundingClientRect();
						if (d.inBB(e, test = {
							left: bb.left - tolerance,
							right: bb.right + tolerance,
							top: bb.top - tolerance,
							bottom: bb.bottom + tolerance
						}) && arg.acceptsReporter(this.children[0])) closer(test, {
							type: 'argument',
							block: block,
							argument: arg,
							bb: bb
						});
					}
				}
			}
		} else {
			isTerminal = this.terminal();
			stacks = this.app().childrenSatisfying(function (child) {
				return child.isStack || child.isStackSlot && !child.anyParentSatisfies(function (p) {
					return p.isPalette;
				});
			});
			i = stacks.length;
			while (i--) {
				if ((stack = stacks[i]) !== this) {
					if (stack.isStackSlot) {
						if (!stack.value()) {
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
							last = j === stack.children.length - 1;
							if (!isTerminal && d.inBB(e, test = {
								left: bb.left - stackTolerance,
								right: bb.left + stackTolerance,
								top: bb.top - stackTolerance,
								bottom: bb.top + stackTolerance
							})) closer(test, {
								type: 'above',
								block: block,
								bb: bb
							});
							if (last && !stack.terminal()) {
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
		this.app().element.removeChild(this.feedback);
		while (i--) {
			if (d.bbTouch(palettes[i].element, e)) {
				this.top().send(function () {
					return ['block.delete', this.id()];
				});
				this.destroy();
				return;
			}
		}
		if (this.dropTarget) {
			switch (this.dropTarget.type) {
			case 'above':
				block = this.dropTarget.block;
				this.top().send(function () {
					return ['block.attach', this.id(), d.BlockAttachType.stack$insert, block.id()];
				});
				block.parent.insertStack(this, block);
				break;
			case 'below':
				block = this.dropTarget.block;
				this.top().send(function () {
					return ['block.attach', this.id(), d.BlockAttachType.stack$append, block.id()];
				});
				block.parent.appendStack(this);
				break;
			case 'stack-slot':
				slot = this.dropTarget.slot;
				block = slot.parent;
				this.top().send(function () {
					return ['block.attach', this.id(), d.BlockAttachType.slot$command, block.id(), block.slotIndex(slot)];
				});
				slot.setValue(this);
				break;
			case 'argument':
				slot = this.dropTarget.argument;
				block = this.dropTarget.block;
				this.top().send(function () {
					return ['block.attach', this.id(), d.BlockAttachType.slot$replace, block.id(), block.slotIndex(slot)];
				});
				block.replaceArg(slot, this.children[0]);
				this.destroy();
				break;
			}
		} else {
			this.top().send(function () {
				return ['block.move', this.id(), this.x(), this.y()];
			});
		}
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
		this.initElements('d-category-selector');
		this.element.appendChild(this.shadow = this.newElement('d-category-selector-shadow'));
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
		this.initElements('d-block-list', 'd-block-list-contents');
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
	toSerial: function () {
		return this.value();
	},
	claimEdits: function () {},
	unclaimEdits: function () {},
	claim: function () {
		this.app().socket.send('slot.claim', this.parent.id(), this.parent.slotIndex(this));
	},
	unclaim: function () {
		this.app().socket.send('slot.claim', -1);
	},
	sendEdit: function (value) {
		this.app().socket.send('slot.set', this.parent.id(), this.parent.slotIndex(this), value);
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
			new d.Menu().setAction(function (item) {
				this.setText(typeof item === 'string' ? item : item.hasOwnProperty('value') ? item.value : item.action);
			}.bind(this)).setItems(this._items).popDown(this, this.menuButton, this.text());
		}
	},
	autosize: function (e) {
		var measure = d.arg.TextField.measure;
		// (document.activeElement === this.input ? /[^0-9\.+-]/.test(this.input.value) :
		if (e && this._numeric && (this._integral ? isNaN(this.input.value) || +this.input.value % 1 : isNaN(this.input.value))) {
			this.input.value = (this._integral ? parseInt : parseFloat)(this.input.value) || 0;
			this.input.focus();
			this.input.select();
		}
		measure.style.display = 'inline-block';
		measure.textContent = this.input.value;
		// this.input.style.width = Math.max(1, measure.offsetWidth) + 'px';
		this.input.style.width = measure.offsetWidth + 1 + 'px';
		measure.style.display = 'none';
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
		var copy = new this.constructor().setItems(this._items).setText(this.text());
		if (this._inline) copy.setInline(true);
		return copy;
	},
	'.items': {
		apply: function (items) {
			if (items[0]) this.setText(items[0]);
		}
	},
	'.text': {
		set: function (v) {
			this.label.textContent = this.selectedItem = v;
		},
		get: function () {
			return this.label.textContent;
		}
	},
	'.value': {
		set: function (v) {
			this.setText(v);
		},
		get: function () {
			return this.selectedItem;
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
		new d.Menu().setAction(function (item) {
			this.setText(this.selectedItem =
				typeof item === 'string' ? item :
				item.hasOwnProperty('value') ? item.value : item.action);
			this.sendEdit(this.text());
		}.bind(this)).setItems(typeof this._items === 'function' ? this._items() : this._items).popUp(this, this.label, this.text());
	}
});
d.arg.Var = d.Class(d.arg.Enum, {
	init: function () {
		this.base(arguments);
	},
	setText: function (value) {
		this.base(arguments, value);
		if (this.parent) {
			this.parent.setCategory(d.VariableColors[value] || 'variables');
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
		this.base(arguments);
		this.initElements('d-block-color');
		console.warn('Color pickers are not implemented');
	},
	copy: function () {
		return new this.constructor();
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
		this.add(new d.ReporterBlock().setSpec('%var:template').setArgs(name).setTemplateSpec('%var:inline').setTemplateArgs(name).setCategory('variables'));
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
	motion: 'rgb(29%, 42%, 83%)',
	motor: 'rgb(11%, 31%, 73%)',
	looks: 'rgb(56%, 34%, 89%)',
	sound: 'rgb(81%, 29%, 85%)',
	pen: 'rgb(0%, 63%, 47%)',
	control: 'rgb(90%, 66%, 13%)',
	sensing: 'rgb(2%, 58%, 86%)',
	operators: 'rgb(38%, 76%, 7%)',
	variables: 'rgb(95%, 46%, 11%)',
	lists: 'rgb(85%, 30%, 7%)',
	system: 'rgb(50%, 50%, 50%)',
	other: 'rgb(62%, 62%, 62%)'
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
	toSerial: function () {
		return [this._id, d.BlockSelector[this.selector()], this.arguments.map(function (a) {
			return a.toSerial();
		})];
	},
	'.id': {
		value: -1
	},
	slotIndex: function (arg) {
		return this.arguments.indexOf(arg);
	},
	amber: function (amber) {
		var socket;
		if (this._id !== -1) {
			amber.blocks[this._id] = this;
			if (this.sendQueue) {
				socket = amber.socket;
				this.sendQueue.forEach(function (f) {
					socket.send.apply(socket, f.call(this));
				}, this);
				this.sendQueue = null;
			}
		}
	},
	detach: function () {
		var stack, app, bb;
		if (this.parent.isStack) {
			if (this.parent.top() === this) return this.parent;
			app = this.app();
			bb = this.element.getBoundingClientRect();
			stack = this.parent.splitStack(this);
			stack.initPosition(bb.left, bb.top);
			app.add(stack);
			return stack;
		}
		bb = this.element.getBoundingClientRect();
		stack = new d.BlockStack();
		stack.initPosition(bb.left, bb.top);
		this.app().add(stack);
		return stack.add(this);
	},
	send: function (f) {
		var socket = this.app().socket;
		if (this._id === -1) {
			(this.sendQueue || (this.sendQueue = [])).push(f);
			return this;
		}
		socket.send.apply(socket, f.call(this));
		return this;
	},
	x: function () {
		return this.element.getBoundingClientRect().left;
	},
	y: function () {
		return this.element.getBoundingClientRect().top;
	},
	dragStart: function (e) {
		var app, bb;
		if (this._embedded) return;
		if (this.anyParentSatisfies(function (p) {
			return p.isPalette;
		})) {
			bb = this.element.getBoundingClientRect();
			(app = this.app()).createScript(this.x(), this.y(), [this.copy().toSerial()]).startDrag(app, e, bb);
		} else if (this.parent.isStack) {
			this.parent.dragStack(e, this);
		}
		// } else if (this.parent.isBlock) {
		// 	app = this.app();
		// 	bb = this.element.getBoundingClientRect();
		// 	this.parent.restoreArg(this);
		// 	new d.BlockStack().add(this).startDrag(app, e, bb);
		// }
	},
	showContextMenu: function (e) {
		var me = this;
		new d.Menu().setItems(['duplicate']).setAction(function (item) {
			var copy;
			switch (item.action) {
			case 'duplicate':
				copy = new d.BlockStack();
				if (me.parent && me.parent.isStack) {
					copy.appendStack(me.parent.copy())
				} else {
					copy.add(me.copy());
				}
				me.app().add(copy);
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
			this.container.innerHTML = '';
			while ((i = spec.indexOf('%', start)) !== -1) {
				if (!/^\s*$/.test(label = spec.substring(start, i))) {
					this.add(new d.arg.Label().setText(label));
				}
				if (ex = /\%([\w\-:]+)/.exec(spec.substr(i))) {
					this.add(label = this.argFromSpec(ex[1]));
					if (ex[1].substr(0, 5) !== 'icon:') {
						args.push(label);
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
		case 'c': return new d.ReporterBlock().setEmbedded(true).setFillsLine(true).setCategory('system').setSpec('%slot:command');

		// Closures
		case 'command': return new d.ReporterBlock().setEmbedded(true).setCategory('system').setSpec('%parameters %slot:command');
		case 'reporter': return new d.ReporterBlock().setEmbedded(true).setCategory('system').setSpec('%parameters %slot:reporter');
		case 'slot:command': return new d.arg.CommandSlot();
		case 'slot:reporter': return new d.arg.ReporterSlot();
		case 'color': return new d.arg.Color();
		case 'parameters': return new d.arg.Parameters();

		// Field + Menu
		case 'direction':
			return new d.arg.TextField().setNumeric(true).setText('90').setItems([
				{ title: 'right', action: '90' },
				{ title: 'left', action: '-90' },
				{ title: 'up', action: '0' },
				{ title: 'down', action: '180' }
			]);
		case 'deletion-index': return new d.arg.TextField().setNumeric(true).setIntegral(true).setText('1').setItems(['1', 'last', d.Menu.separator, 'all']);
		case 'index': return new d.arg.TextField().setNumeric(true).setIntegral(true).setText('1').setItems(['1', 'last', 'any']);

		// Open Enumerations (temporary)
		case 'list': return new d.arg.List();
		case 'var': return new d.arg.Var().setItems(['x position', 'y position', 'direction', 'costume #', 'size', 'layer', 'instrument', 'volume', 'pen down?', 'pen color', 'pen hue', 'pen shade', d.Menu.separator, 'color effect', 'fisheye effect', 'whirl effect', 'pixelate effect', 'mosaic effect', 'brightness effect', 'ghost effect', d.Menu.separator, 'tempo', 'answer', 'timer', d.Menu.separator, 'var', 'a', 'b', 'c', d.Menu.separator, 'global', 'counter']);
		case 'var:inline': return this.argFromSpec('var').setInline(true);
		case 'var:template': return new d.arg.Label();
		case 'event': return new d.arg.Enum().setItems(['event 1', 'event 2']);
		case 'sprite': return new d.arg.Enum().setItems(['mouse', d.Menu.separator, 'Sprite1', 'Sprite2']);
		case 'object': return new d.arg.Enum().setItems(['Stage', d.Menu.separator, 'Sprite1', 'Sprite2']).setText('Sprite1');
		case 'attribute': return (arg = new d.arg.Enum()).setItems(function () {
			return arg.parent.arguments[1].text() === 'Stage' ? ['background #', 'volume', d.Menu.separator, 'a'] : ['x position', 'y position', 'direction', 'costume #', 'size', 'volume', d.Menu.separator, 'var', 'a', 'b', 'c'];
		}).setText('x position');
		case 'costume': return new d.arg.Enum().setItems(['costume1', 'costume2']);
		case 'sound': return new d.arg.Enum().setItems(['meow']);

		// Closed Enumerations
		case 'math': return new d.arg.Enum().setItems(['abs', 'sqrt', 'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'ln', 'log', 'e ^ ', '10 ^ ']).setText('sqrt');
		case 'sensor': return new d.arg.Enum().setItems(['slider', 'light', 'sound', 'resistance-A', 'resistance-B', 'resistance-C', 'resistance-D', d.Menu.separator, 'tilt', 'distance']);
		case 'gfx': return new d.arg.Enum().setItems(['color', 'fisheye', 'whirl', 'pixelate', 'mosaic', 'brightness', 'ghost']);
		case 'sensor:bool': return new d.arg.Enum().setItems(['button pressed', 'A connected', 'B connected', 'C connected', 'D connected']);
		case 'instrument':
			return new d.arg.TextField().setNumeric(true).setIntegral(true).setText('1').setItems([
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
			return new d.arg.TextField().setNumeric(true).setIntegral(true).setText('48').setItems([
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
			return new d.arg.Enum().setItems(['up arrow', 'down arrow', 'right arrow', 'left arrow', 'space', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']).setText('space');

		// Icons
		case 'icon:right': return new d.arg.Label().setText('\u27f3');
		case 'icon:left': return new d.arg.Label().setText('\u27f2');
		case 'icon:repeat': return new d.arg.Label().setText('\u2b0f');
		case 'icon:stop': return new d.arg.Label().setText('\u2b23').setColor('#a00');
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
			stack;
		this.replace(oldArg, this.arguments[i] = newArg);
		if (oldArg.isBlock && !oldArg._embedded) {
			this.app().add(stack = new d.BlockStack().add(oldArg));
			stack.element.style.left = bb.left + 20 + 'px';
			stack.element.style.top = bb.top - 20 + 'px';
		}
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
	fromSerial: function (a, tracker, amber) {
		var selector = d.Selectors[a[1]],
			spec = d.BlockSpecBySelector[selector],
			block = d.Block.fromSpec(spec);
		block.setId(a[0]);
		if (amber) block.amber(amber);
		if (tracker) {
			tracker.push(block);
		}
		a[2].forEach(function (arg, i) {
			if (arg instanceof Array) {
				if (typeof arg[0] === 'number') {
					block.replaceArg(block.arguments[i], d.Block.fromSerial(arg, tracker, amber));
				} else {
					// TODO command slot stack fromSerial
				}
			} else {
				block.arguments[i].setValue(arg);
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
			block = new (spec[0] === 'r' ? d.ReporterBlock : spec[0] === 'b' ? d.BooleanReporterBlock : d.CommandBlock)().setCategory(spec[1]).setSelector(spec[2]).setSpec(spec[3]);
			if (spec[0] === 't') {
				block.setTerminal(true);
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
			} else {
				block.setValue(block.isChange() ? 10 : 0);
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
	acceptsReporter: d.ReporterBlock.prototype.isReporter,
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
	'pen shade': 'pen',
	'pen size': 'pen',
	'answer': 'sensing',
	'mouse x': 'sensing',
	'mouse y': 'sensing',
	'mouse down?': 'sensing',
	'timer': 'sensing',
	'loudness': 'sensing',
	'loud?': 'sensing'
};
d.VariableBlock = d.Class(d.ReporterBlock, {
	init: function () {
		this.base(arguments);
		this.setSpec('%var:inline').setSelector('getVar:');
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
	}
});
