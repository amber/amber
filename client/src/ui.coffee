{ Base, extend, addClass, removeClass, toggleClass, hasClass, format, htmle, htmlu, bbTouch, inBB } = amber.util
{ getText: tr } = amber.locale
{ Event, PropertyEvent, ControlEvent, TouchEvent, WheelEvent } = amber.event

class Control extends Base
    constructor: ->
        @children = []
        @element = @newElement @element
        if @container
            @container = @newElement @container
            @element.appendChild @container
        else
            @container = @element

    @event 'TouchStart'
    @event 'TouchMove'
    @event 'TouchEnd'
    @event 'ContextMenu'
    @event 'ScrollWheel'
    @event 'Scroll'
    @event 'DragStart'
    @event 'Live'
    @event 'Unlive'

    initElements: (elementClass, containerClass, isFlat) ->
        @element = @newElement elementClass
        if containerClass
            @container = @newElement containerClass
            @element.appendChild @container unless isFlat
        else
            @container = @element
        @

    newElement: (className, tag = 'div') ->
        el = document.createElement tag
        el.control = @
        el.className = className if className
        el

    @property 'selectable',
        value: false
        apply: (selectable) ->
            toggleClass @element, 'd-selectable', selectable

    @property 'tooltip',
        value: ''
        apply: (tooltip) -> @element.title = tooltip

    @property 'scrollLeft',
        get: -> @container.scrollLeft
        set: (scrollLeft) ->
            @container.scrollLeft = if scrollLeft is 'max' then @container.scrollWidth else scrollLeft

    @property 'scrollTop',
        get: -> @container.scrollTop
        set: (scrollTop) ->
            @container.scrollTop = if scrollTop is 'max' then @container.scrollHeight else scrollTop

    @property 'maxScrollLeft', -> @container.scrollWidth - @container.offsetWidth

    @property 'maxScrollTop', -> @container.scrollHeight - @container.offsetHeight

    _hasScrollEvent: false

    withScrollEvent: ->
        unless @_hasScrollEvent
            @element.addEventListener 'scroll', =>
                @dispatch 'Scroll', new ControlEvent @
            @_hasScrollEvent = true
        @

    add: (child) ->
        child.parent.remove child if child.parent
        @children.push child
        child.parent = @
        @container.appendChild child.element
        child.becomeLive() if @isLive
        @

    becomeLive: (target = true) ->
        if !!@isLive isnt target
            event = if target then 'Live' else 'Unlive'
            @isLive = target
            @dispatch event, new ControlEvent @

        for child in @children
            child.becomeLive target

    clear: ->
        if @children.length
            for child in @children
                child.parent = null
            @children = []
            @container.innerHTML = ''
        @

    setChildren: (children) ->
        @clear()
        @children = children
        for c in children
            c.parent = @
            container.appendChild c.element
        @

    addClass: (className) ->
        addClass @element, className
        @

    removeClass: (className) ->
        removeClass @element, className
        @

    toggleClass: (className, active) ->
        toggleClass @element, className, active
        @

    hasClass: (className) ->
        hasClass @element, className

    remove: (child) ->
        return @ if child.parent isnt @

        child.becomeLive false if @isLive

        i = @children.indexOf child
        @children.splice i, 1 if -1 isnt i
        child.parent = null

        @container.removeChild child.element
        @

    replace: (oldChild, newChild) ->
        if oldChild.parent isnt @
            return @add newChild
        if newChild.parent
            newChild.parent.remove newChild

        oldChild.becomeLive false if @isLive

        i = @children.indexOf oldChild
        @children.splice i, 1, newChild if -1 isnt i
        oldChild.parent = null
        newChild.parent = @

        @container.replaceChild newChild.element, oldChild.element

        newChild.becomeLive() if @isLive
        @

    insert: (newChild, beforeChild) ->
        if not beforeChild or beforeChild.parent isnt @
            return @add newChild
        if newChild.parent
            newChild.parent.remove newChild

        i = @children.indexOf beforeChild
        @children.splice (if i is -1 then @children.length else i), 0, newChild
        newChild.parent = @

        @container.insertBefore newChild.element, beforeChild.element

        newChild.becomeLive() if @isLive
        @

    hasChild: (child) ->
        return true if @ is child
        for c in @children
            return true if c.hasChild child
        false

    dispatchTouchEvents: (type, e) ->
        touches = e.changedTouches
        for touch in touches
            @dispatch type, new TouchEvent().setTouchEvent e, touch
        @

    hoistTouchStart: (e) ->
        control = @
        while control = control.parent
            if control.acceptsClick
                @app.mouseDownControl = control
                control.dispatch('TouchStart', e)
                return

    @property 'app', -> @parent and @parent.app

    hide: ->
        @element.style.display = 'none'
        @

    show: ->
        @element.style.display = ''
        @

    @property 'visible',
        get: -> @element.style.display isnt 'none'
        set: (visible) ->
            @element.style.display = if visible then '' else 'none'
            @

    childrenSatisfying: (predicate) ->
        array = []
        add = (control) ->
            if predicate control
                array.push control
            add child for child in control.children
        add(@)
        array

    anyParentSatisfies: (predicate) ->
        control = @
        while control
            return true if predicate control
            control = control.parent
        false

class Label extends Control
    constructor: (className = 'd-label', text = '') ->
        super()
        @initElements className
        @text = text

    @property 'text',
        get: -> @element.textContent
        set: (text) -> @element.textContent = text

    @property 'richText',
        get: -> @element.innerHTML
        set: (richText) -> @element.innerHTML = richText

class RelativeDateLabel extends Label

    constructor: (className = 'd-label', date) ->
        super className
        @date = date
        @onLive ->
            RelativeDateLabel.instances.push @
        @onUnlive ->
            i = RelativeDateLabel.instances.indexOf @
            RelativeDateLabel.instances.splice i, 1 if i isnt -1

    format: (date) ->
        now = +new Date
        old = +date
        d = (now - old) / 1000
        if d < 60 then return tr 'now'
        d /= 60
        if d < 2 then return tr 'a minute ago'
        if d < 60 then return tr '% minutes ago', Math.floor d
        d /= 60
        if d < 2 then return tr 'an hour ago'
        if d < 24 then return tr '% hours ago', Math.floor d
        d /= 24
        if d < 2 then return tr 'a day ago'
        if d < 7 then return tr '% days ago', Math.floor d
        d /= 7
        if d < 2 then return tr 'a week ago'
        if d < 4 then return tr '% weeks ago', Math.floor d
        d /= 4
        if d < 2 then return tr 'a month ago'
        if d < 12 then return tr '% months ago', Math.floor d
        d /= 12
        if d < 2 then return tr 'a year ago'
        return tr '% years ago', Math.floor d

    @instances: []
    @update: ->
        for label in RelativeDateLabel.instances
            label.update()

    update: ->
        @text = @format @date

    @property 'date', apply: -> @update()

setInterval RelativeDateLabel.update, 1000 * 60

class Image extends Control
    constructor: (className = 'd-image') ->
        super()
        @element = @container = @newElement className, 'img'

    @property 'URL',
        get: -> @element.src
        set: (url) -> @element.src = url

class App extends Control
    MENU_CLICK_TIME: 250
    acceptsClick: true
    isLive: true

    constructor: ->
        @lightbox = @newElement 'd-lightbox'
        super()

    @property 'app', -> @

    @property 'lightboxEnabled', apply: (lightboxEnabled) ->
        @lightbox.style.display = if lightboxEnabled then 'block' else 'none'

    @property 'menu',
        apply: (menu) ->
            @menuOriginX = @mouseX
            @menuOriginY = @mouseY
            @menuStart = @mouseStart
            @add menu

    touchMoveEvent: -> new TouchEvent().setMouseEvent @lastMouseEvent

    @property 'element', apply: (element) ->
        app = @
        shouldStartDrag = false
        @element = @container = element
        element.control = @
        addClass element, 'd-app'

        element.appendChild @lightbox
        @lightboxEnabled = false

        element.addEventListener('touchstart', (e) ->
            t = e.target
            t = t.parentNode if t.nodeType is 3
            c = t.control
            app._menu.close() if app._menu and not app._menu.hasChild c
            while c and not c.acceptsClick
                c = c.parent

            return unless c
            shouldStartDrag = true
            t.control.dispatchTouchEvents 'TouchStart', e
            e.preventDefault()
        , true)

        element.addEventListener('touchmove', (e) ->
            t = e.target
            t = t.parentNode if t.nodeType is 3
            if shouldStartDrag
                t.control.dispatchTouchEvents 'DragStart', e
                shouldStartDrag = false

            t.control.dispatchTouchEvents 'TouchMove', e
            e.preventDefault()
        , true)

        element.addEventListener('touchend', (e) ->
            t = e.target
            t = t.parentNode if t.nodeType is 3
            t.control.dispatchTouchEvents 'TouchEnd', e
            e.preventDefault()
        , true)

        element.addEventListener('contextmenu', (e) ->
            return if e.target.tagName is 'INPUT' and not e.target.control.isMenu
            e.preventDefault()
        , true)

        element.addEventListener('mousedown', (e) ->
            app.lastMouseEvent = e
            return if app.mouseDown
            document.addEventListener 'mousemove', mousemove, true
            document.addEventListener 'mouseup', mouseup, true

            c = e.target.control
            app._menu.close() if app._menu and not app._menu.hasChild c

            tag = e.target.tagName
            return if tag is 'INPUT' or tag is 'TEXTAREA' or tag is 'SELECT'

            context = e.button is 2

            while c and not (if context then c.acceptsContextMenu else c.acceptsClick)
                return if c.selectable
                c = c.parent

            return unless c
            if context
                c.dispatch 'ContextMenu', new TouchEvent().setMouseEvent e
                return
            else
                app.mouseDown = shouldStartDrag = true
                app.mouseDownControl = c

                app.mouseX = e.clientX
                app.mouseY = e.clientY
                app.mouseStart = +new Date
                c.dispatch 'TouchStart', new TouchEvent().setMouseEvent e

            document.activeElement.blur()
            e.preventDefault()
        , true)

        mousemove = (e) ->
            app.lastMouseEvent = e
            return unless app.mouseDown and app.mouseDownControl
            if shouldStartDrag
                app.mouseDownControl.dispatch 'DragStart', new TouchEvent().setMouseEvent e
                shouldStartDrag = false

            app.mouseDownControl.dispatch 'TouchMove', new TouchEvent().setMouseEvent e
            # e.preventDefault()

        mouseup = (e) ->
            pass = app.mouseDown and app.mouseDownControl
            control = app.mouseDownControl
            app.lastMouseEvent = e
            app.mouseDown = false
            app.mouseDownControl = undefined
            return unless pass
            if app._menu and app._menu.hasChild e.target.control
                dx = app.mouseX - app.menuOriginX
                dy = app.mouseY - app.menuOriginY
                if dx * dx + dy * dy < 4 and +new Date - app.menuStart <= app.MENU_CLICK_TIME
                    app.menuStart -= 100
                    return

            control.dispatch 'TouchEnd', new TouchEvent().setMouseEvent e
            # e.preventDefault()

        mousewheel = (f) -> (e) ->
            t = e.target
            while not t.control
                t = t.parentNode
                return unless t

            t = t.control
            while t and not t.acceptsScrollWheel
                t = t.parent
                return unless t

            t.dispatch 'ScrollWheel', event = new WheelEvent()[f](e)
            e.preventDefault() unless event.allowDefault


        element.addEventListener 'mousewheel', (mousewheel 'setWebkitEvent'), true
        element.addEventListener 'MozMousePixelScroll', (mousewheel 'setMozEvent'), true
        @

class Menu extends Control
    TYPE_TIMEOUT: 500
    acceptsScrollWheel: true
    acceptsClick: true
    scrollY: 0
    isMenu: true

    @event 'Execute'
    @event 'Close'

    constructor: ->
        super()
        @onScrollWheel @scroll
        @menuItems = []

        @initElements('d-menu', 'd-menu-contents')

        @element.appendChild @search = @newElement 'd-menu-search', 'input'
        @search.addEventListener 'blur', @refocus
        @search.addEventListener 'keydown', @controlKey
        @search.addEventListener 'input', @typeKey

        @element.insertBefore (@upIndicator = @newElement 'd-menu-indicator d-menu-up'), @container
        @element.appendChild @downIndicator = @newElement 'd-menu-indicator d-menu-down'
        @targetElement = @container
        window.addEventListener 'resize', @resize

    @property 'transform',
        value: (item) ->
            if typeof item is 'string'
                action: item
                title: item
            else
                action: item.action
                title: item.title
                state: item.state

    @property 'items', apply: (items) ->
        for item in items
            @addItem item

    @property 'target'

    addItem: (item) ->
        if item is Menu.separator
            return @add new MenuSeparator()

        @menuItems.push item = new MenuItem().load @, @_transform item
        item.index = @menuItems.length - 1
        @add item

    activateItem: (item) ->
        if @activeItem
            removeClass @activeItem.element, 'd-menu-item-active'
        if @activeItem = item
            addClass item.element, 'd-menu-item-active'

    findTarget: (selectedItem) ->
        if typeof selectedItem is 'number'
            target = @menuItems[selectedItem]
        else if typeof selectedItem is 'string' or typeof selectedItem is 'object'
            i = 0
            while target = @menuItems[i++]
                break if target.action is selectedItem or selectedItem.$ and target.action.$ is selectedItem.$
        else
            throw new TypeError
        target.setState 'checked' if target
        target

    popUp: (control, element, selectedItem) ->
        target = @findTarget selectedItem
        elementBB = element.getBoundingClientRect()
        control.app.setMenu @
        target.activate() if target ?= @menuItems[0]
        targetBB = (target ? @).targetElement.getBoundingClientRect()
        @element.style.left = elementBB.left - targetBB.left + 'px'
        @element.style.top = elementBB.top - targetBB.top + 'px'
        @layout()
        @

    popDown: (control, element = control.element, selectedItem) ->
        target = @findTarget selectedItem
        target.activate() if target ?= @menuItems[0]
        @addClass 'd-menu-pop-down'
        elementBB = element.getBoundingClientRect()
        control.app.setMenu @
        @element.style.left = elementBB.left + 'px'
        @element.style.top = elementBB.bottom + 'px'
        @layout()
        @

    show: (control, position) ->
        control.app.setMenu(@)
        @element.style.left = position.x + 'px'
        @element.style.top = position.y + 'px'
        @layout()
        @

    scroll: (e) ->
        top = parseFloat @element.style.top
        @viewHeight = parseFloat (getComputedStyle @element).height
        max = @container.offsetHeight - @viewHeight
        @scrollY = Math.max 0, Math.min max, @scrollY + e.y
        if top > 4 and max > 0
            @scrollY -= top - (top = Math.max 4, top - @scrollY)
            @element.style.top = top + 'px'

        if max > 0 and top + @element.offsetHeight < window.innerHeight - 4
            @element.style.maxHeight = @viewHeight + max - @scrollY + 'px'
            @scrollY = max = @container.offsetHeight - (@viewHeight + max - @scrollY)

        @upIndicator.style.display = if @scrollY > 0 then 'block' else 'none'
        @downIndicator.style.display = if @scrollY < max then 'block' else 'none'
        @container.style.top = '-' + @scrollY + 'px'

    resize: =>
        @scroll new WheelEvent().set x: 0, y: 0
        top = parseFloat @element.style.top
        height = @element.offsetHeight
        if top + height + 4 > window.innerHeight
            @element.style.top = (Math.max 4, window.innerHeight - height - 4) + 'px'

    layout: ->
        maxHeight = parseFloat getComputedStyle(@element).height
        left = parseFloat @element.style.left
        top = parseFloat @element.style.top
        width = @element.offsetWidth
        @element.style.maxHeight = maxHeight + 'px'
        if top < 4
            @container.style.top = '-' + (@scrollY = 4 - top) + 'px'
            @element.style.maxHeight = (maxHeight -= 4 - top) + 'px'
            @element.style.top = (top = 4) + 'px'

        if left < 4
            @element.style.left = (left = 4) + 'px'
        if left + width + 4 > window.innerWidth
            @element.style.left = (left = Math.max(4, window.innerWidth - width - 4)) + 'px'

        @element.style.bottom = '4px'
        @viewHeight = parseFloat getComputedStyle(@element).height
        height = @element.offsetHeight
        if top + height + 4 > window.innerHeight
            @element.style.top = (top = Math.max 4, window.innerHeight - height - 4) + 'px'

        if @viewHeight < maxHeight
            @downIndicator.style.display = 'block'

        if @scrollY > 0
            @upIndicator.style.display = 'block'

        setTimeout =>
            @search.focus()

    execute: (model) ->
        if @_target
            if model.action instanceof Array
                @_target[model.action[0]].apply @_target, model.action.slice 1
            else
                @_target[model.action] model
            return @
        else if model.action instanceof Array
            model.action[0].apply null, model.action.slice 1
        else if typeof model.action is 'function'
            model.action()

        @dispatch 'Execute', (new ControlEvent @).set item: model
        @

    close: ->
        if @parent
            window.removeEventListener 'resize', @resize
            @parent.remove @
            @dispatch 'Close', new ControlEvent @

    clearSearch: =>
        @search.value = ''
        @typeTimeout = undefined

    controlKey: (e) =>
        switch e.keyCode
            when 27
                e.preventDefault()
                @close()
            when 32, 13
                return if e.keyCode is 32 and @typeTimeout
                e.preventDefault()
                if @activeItem
                    @activeItem.accept()
                else
                    @close()
            when 38
                e.preventDefault()
                if @activeItem
                    @activateItem item if item = @menuItems[@activeItem.index - 1]
                else
                    @activateItem @menuItems[@menuItems.length - 1]
                @clearSearch()
            when 40
                e.preventDefault()
                if @activeItem
                    @activateItem item if item = @menuItems[@activeItem.index + 1]
                else
                    @activateItem @menuItems[0]
                @clearSearch()

    typeKey: =>
        find = @search.value.toLowerCase()
        length = find.length
        if @typeTimeout
            clearTimeout @typeTimeout
            @typeTimeout = undefined

        return if find.length is 0
        @typeTimeout = setTimeout @clearSearch, @TYPE_TIMEOUT
        for item in @menuItems
            if (item.title.substr 0, length).toLowerCase() is find
                item.activate()
                return

    refocus: =>
        @search.focus()

    @separator: {}

class MenuItem extends Control
    acceptsClick: true

    constructor: ->
        super()
        @initElements 'd-menu-item'
        @element.appendChild @stateEl = @newElement 'd-menu-item-state'
        @element.appendChild @targetElement = @label = @newElement 'd-menu-item-title'
        @onTouchEnd @touchEnd
        @element.addEventListener 'mouseover', @activate
        @element.addEventListener 'mouseout', @deactivate

    @property 'title',
        get: -> @label.textContent
        set: (title) -> @label.textContent = title

    @property 'action'

    @property 'state', apply: (state) ->
        addClass @stateEl, 'd-menu-item-checked' if state is 'checked'
        addClass @stateEl, 'd-menu-item-radio' if state is 'radio'
        addClass @stateEl, 'd-menu-item-minimized' if state is 'minimized'

    load: (menu, item) ->
        @menu = menu
        @model = item
        @title = item.title if item.title
        @action = item.action if item.action
        @state = item.state if item.state
        @

    touchEnd: (e) ->
        @accept() if bbTouch @element, e

    activate: =>
        if app = @app
            app.mouseDownControl = @
            @parent.activateItem @

    deactivate: =>
        if app = @app
            app.mouseDownControl = undefined
            @parent.activateItem null

    accept: ->
        @menu.execute @model
        @menu.close()

class MenuSeparator extends Control
    constructor: ->
        super()
        @initElements 'd-menu-separator'

class FormControl extends Control
    @event 'Focus'
    @event 'Blur'

    focus: ->
        @element.focus()
        @

    blur: ->
        @element.blur()
        @

    fireFocus: =>
        @dispatch 'Focus', new ControlEvent @

    fireBlur: =>
        @dispatch 'Blur', new ControlEvent @

    @property 'enabled',
        get: -> not @element.disabled
        set: (enabled) -> @element.disabled = not enabled


class TextField extends FormControl
    @event 'Input'
    @event 'InputDone'
    @event 'KeyDown'

    INPUT_DONE_THRESHOLD: 300
    TAG_NAME: 'input'

    constructor: (className = 'd-textfield') ->
        super()
        @element = @newElement className, @TAG_NAME
        @element.addEventListener 'input', @_input
        @element.addEventListener 'keydown', (e) =>
            @dispatch 'KeyDown', (new ControlEvent @).set keyCode: e.keyCode
        @element.addEventListener 'focus', @fireFocus
        @element.addEventListener 'blur', @fireBlur

    _input: (e) =>
        @dispatch 'Input', new ControlEvent @
        clearTimeout @_inputDoneTimer if @_inputDoneTimer
        @_inputDoneTimer = setTimeout @_inputDone, @INPUT_DONE_THRESHOLD

    _inputDone: =>
        @_inputDoneTimer = undefined
        @dispatch 'InputDone', new ControlEvent @

    select: ->
        @element.select()
        @

    clear: -> @setText('')

    autofocus: ->
        @onLive -> @select()

    @property 'text',
        get: -> @element.value
        set: (text) -> @element.value = text

    @property 'placeholder',
        get: -> @element.placeholder
        set: (placeholder) -> @element.placeholder = placeholder

    @property 'readonly',
        get: -> @element.readonly
        set: (readonly) -> @element.readonly = readonly


class TextField.Password extends TextField
    constructor: (className) ->
        super className
        @element.type = 'password'

class TextField.Multiline extends TextField
    constructor: (className) ->
        super className
        @onLive @_autoResize
        @element.addEventListener 'keydown', (e) =>
            if e.keyCode is 13 and not (e.metaKey or e.ctrlKey)
                e.stopPropagation()

    TAG_NAME: 'textarea'
    @property 'autoSize',
        value: false,
        apply: (autoSize) ->
            if autoSize
                @element.style.resize = 'none'

            @_autoResize()

    @property 'text',
        get: ->
            return @element.value
        set: (text) ->
            @element.value = text
            @_autoResize()

    _styleProperties: ['font', 'lineHeight', 'paddingTop', 'paddingRight', 'paddingLeft', 'paddingBottom', 'marginTop', 'marginRight', 'marginBottom', 'marginLeft', 'borderTopWidth', 'borderTopStyle', 'borderTopColor', 'borderRightWidth', 'borderRightStyle', 'borderRightColor', 'borderBottomWidth', 'borderBottomStyle', 'borderBottomColor', 'borderLeftWidth', 'borderLeftStyle', 'borderLeftColor', 'width', 'boxSizing', 'MozBoxSizing'],

    _autoResize: ->
        if @autoSize
            div = TextField.metric
            style = getComputedStyle @element
            properties = @_styleProperties
            for p in properties
                div.style[p] = style[p]

            div.textContent = @element.value + 'M'
            @element.style.height = div.offsetHeight + 'px'

    _input: =>
        super()
        @_autoResize()

do ->
    div = TextField.metric = document.createElement('div')
    style = div.style
    style.position = 'absolute'
    style.top = '-9999px'
    style.left = '-9999px'
    style.whiteSpace = 'pre-wrap'
    document.body.appendChild div

class Button extends FormControl
    @event 'Execute'
    acceptsClick: true

    constructor: (className = 'd-button') ->
        super()
        @element = @container = @newElement className, 'button'
        @onTouchEnd (e) =>
            if inBB e, @element.getBoundingClientRect()
                @dispatch 'Execute', new ControlEvent @
        @element.addEventListener 'keyup', (e) =>
            if e.keyCode is 32 or e.keyCode is 13
                @dispatch 'Execute', new ControlEvent @
        @element.addEventListener 'focus', @fireFocus
        @element.addEventListener 'blur', @fireBlur

    @property 'text',
        get: -> @element.textContent
        set: (text) -> @element.textContent = text


class Checkbox extends Control
    acceptsClick: true
    @event 'Change'

    constructor: (className) ->
        super()
        @initElements('d-checkbox', 'label')
        @element.appendChild (@button = new Button('d-checkbox-button')
            .onExecute(->
                @checked = not @checked
            , @)).element
        @onTouchEnd (e) ->
            if inBB e, @element.getBoundingClientRect()
                @checked = not @checked
        @element.appendChild(@label = @newElement('d-checkbox-label'))
        @element.addEventListener 'focus', @fireFocus
        @element.addEventListener 'blur', @fireBlur

    focus: ->
        @button.focus()
        @

    @property 'checked',
        event: 'Change'
        apply: (checked) ->
            toggleClass @button.element, 'd-checkbox-button-checked', checked

    @property 'text',
        get: -> @label.textContent
        set: (text) -> @label.textContent = text

class ProgressBar extends Control
    constructor: ->
        super()
        @initElements 'd-progress'
        @element.appendChild @bar = @newElement 'd-progress-bar'

    @property 'progress', apply: (progress) ->
        @bar.style.width = progress * 100 + '%'

class Container extends Control
    constructor: (className) ->
        super()
        @element = @container = @newElement className

class Form extends Container
    @event 'Submit'
    @event 'Cancel'

    constructor: (className) ->
        super className
        @element.addEventListener 'keydown', @keydown

    keydown: (e) =>
        if e.keyCode is 13
            @submit()
            e.preventDefault()
            e.stopPropagation()
        if e.keyCode is 27
            @cancel()
            e.preventDefault()
            e.stopPropagation()

    submit: -> @dispatch 'Submit', new ControlEvent @
    cancel: -> @dispatch 'Cancel', new ControlEvent @

class FormGrid extends Form
    constructor: (className = 'd-form-grid') ->
        super className

    addField: (label, field) ->
        @add new Container('d-form-grid-row').setChildren [
            new Label('d-form-grid-label').set text: label
            new Container('d-form-grid-input').setChildren [field]
        ]
        return @

class Dialog extends Control
    constructor: ->
        super()
        @initElements('d-dialog')
        @onLive ->
            window.addEventListener 'resize', @layout
        @onUnlive ->
            window.removeEventListener 'resize', @layout

        @element.addEventListener 'keydown', (e) =>
            return if e.keyCode isnt 9

            first = @firstFocusable()
            last = @lastFocusable()

            if e.target is first and e.shiftKey
                last.focus()
                e.preventDefault()
            else if e.target is last and not e.shiftKey
                first.focus()
                e.preventDefault()

    show: (app) ->
        app.setLightboxEnabled(true).add(@)
        @layout()
        @focus()
        @

    close: ->
        @parent.setLightboxEnabled(false).remove(@)
        @

    firstFocusable: ->
        descend = (child) ->
            if child.tagName is 'INPUT' or child.tagName is 'BUTTON' or child.tagName is 'TEXTAREA' or child.tabIndex >= 0
                return child
            for c in child.childNodes
                f = descend c
                return f if f
        descend @element

    lastFocusable: ->
        descend = (child) ->
            if child.tagName is 'INPUT' or child.tagName is 'BUTTON' or child.tagName is 'TEXTAREA' or child.tabIndex >= 0
                return child
            last = null
            for c in child.childNodes
                f = descend c
                last = f if f
            last
        descend @element

    focus: ->
        f = @firstFocusable()
        setTimeout(-> f.focus()) if f
        @

    layout: =>
        @element.style.left = (window.innerWidth - @element.offsetWidth) / 2 + 'px'
        @element.style.top = (window.innerHeight - @element.offsetHeight) / 2 + 'px'

module 'amber.ui', {
    Control
    Label
    RelativeDateLabel
    Image
    App
    Menu
    MenuItem
    MenuSeparator
    FormControl
    TextField
    Button
    Checkbox
    ProgressBar
    Container
    Form
    FormGrid
    Dialog
}
