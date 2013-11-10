{ Base, extend, addClass, removeClass, toggleClass, hasClass, format, htmle, htmlu, bbTouch, inBB } = amber.util
{ Event, PropertyEvent, ControlEvent, TouchEvent, WheelEvent } = amber.event
{ getText: tr, maybeGetText: tr.maybe, getList: tr.list, getPlural: tr.plural } = amber.locale
{ Control, Label, Image, Menu, MenuItem, MenuSeparator, FormControl, TextField, TextField, TextField, Button, Checkbox, ProgressBar, Container, Form, FormGrid, Dialog } = amber.ui
{ User } = amber.models
{ specs, specsBySelector, categoryColors } = amber.editor
{ Project, Scriptable, Stage, Sprite, Costume, Variable } = amber.editor.models

Control.property 'editor', ->
    if @isEditor or not @parent then @ else @parent.editor

class Editor extends Control
    isEditor: true

    constructor: ->
        super()
        @blocks = {}
        @objects = {}
        @initElements 'd-amber d-collapse-user-panel'
        @preloader = new Dialog().addClass('d-preloader')
            .add(@_progressLabel = new Label)
            .add(@_progressBar = new ProgressBar)
        @add @spritePanel = new SpritePanel(@)
        @spriteList.hide()
        @spritePanel.toggleVisible = false
        document.addEventListener 'keydown', @keyDown

    amber: ->
        return @

    keyDown: (e) =>
        none = e.target is document.body
        switch e.keyCode
            when 32
                if none
                    @chat.show()
                    e.preventDefault()
            when 27
                if none or e.target is @chat.input
                    @userPanel.collapsed = true
                    e.preventDefault()
            when 'I'.charCodeAt 0
                if (e.metaKey or e.ctrlKey) and not (e.shiftKey or e.altKey)
                    e.preventDefault()
                    @spritePanel.collapsed = not @spritePanel.collapsed

    createSocket: (server, callback) ->
        @socket = new Socket @, server, callback

    newScriptID: 0
    createScript: (x, y, blocks) ->
        id = ++@newScriptID
        tracker = []
        script = new BlockStack().fromJSON [x, y, blocks], tracker
        @socket.newScripts[id] = tracker
        @editor.add script
        @socket.send
            $: 'script.create'
            script: [x, y, blocks]
            request$id: id
            object$id: @selectedSprite.id
        script

    initEditMode: (element) ->
        @editorLoaded = true

        @add @userPanel = new UserPanel(@)
        @add @tabBar = new TabBar(@)

        if @project
            @spriteList.clear()
            @spriteList.addIcon @project.stage
            for sprite in @project.stage.children
                @spriteList.addIcon sprite

            @selectSprite @project.stage.children[0] ? @project.stage
        @

    createVariable: ->
        dialog = new Dialog()
            .add(name = new TextField()
                .setPlaceholder(tr 'Variable Name'))
            .add(new Checkbox()
                .setText(tr 'For this sprite only'))
            .add(new Button()
                .setText(tr 'OK')
                .onExecute =>
                    sprite = @selectedSprite
                    variable = name.text.trim()

                    dialog.close()
                    if not variable or sprite.hasVariable variable
                        return

                    sprite.addVariable variable
                    @socket.send
                        $: 'variable.create'
                        object$id: sprite.id
                        name: variable)
            .add(new Button()
                .setText(tr 'Cancel')
                .onExecute =>
                    dialog.close())
            .show(@app)

    @property 'preloaderEnabled',
        apply: (preloaderEnabled) ->
            @preloader.show @ unless @preloader.parent
            @preloader.visible = preloaderEnabled
            @lightboxEnabled = preloaderEnabled

    @property 'tab',
        apply: (tab, old) ->
            @remove old if old?
            if tab?
                @add tab
                tab.fit() if tab.fit

    @property 'selectedSprite'

    objectWithId: (id) -> @objects[id]

    selectSprite: (object) ->
        @selectedSprite = object
        @editor = object.scripts
        @tabBar.children[1].text = if object.isStage then tr 'Backdrops' else tr 'Costumes'
        @tabBar.select @tabBar.selectedIndex ? 0
        @spriteList.select object

    @property 'project'
    ###
        set: (project) ->
            @preloaderEnabled = true
            @progressText = tr 'Loading resources\u2026'
            @_project = new Project(@).fromJSON project
            @stageView.model = @project.stage
    ###

    @property 'projectId'

    doneLoading: ->
        @preloaderEnabled = false

    isBlockVisible: (block) ->
        scripts = @selectedSprite.scripts
        return block.anyParentSatisfies (parent) -> parent is scripts

    activeRequests: [],

    updateProgress: ->
        p = 0
        p += r.progress for r in @activeRequests

        @progress = p / @activeRequests.length
        if p is @activeRequests.length
            @doneLoading()

    load: (method, url, body, callback) ->
        req = progress: 0
        xhr = new XMLHttpRequest

        @activeRequests.push req
        @updateProgress()

        xhr.open method, API_URL + url, true

        xhr.onprogress = (e) =>
            if e.lengthComputable
                req.progress = e.loaded / e.total
                @updateProgress()

        xhr.onload = =>
            req.progress = 1
            @updateProgress()
            callback.call @, req.responseText if callback

        xhr.onerror = =>
            @activeRequests = []
            @progress = 0
            @progressText = tr 'Error.'

        xhr.send body
        @

    loadImage: (url, callback) ->
        req = progress: 0
        img = new Image

        @activeRequests.push req
        @updateProgress()

        img.onload = =>
            req.progress = 1
            @updateProgress()
            callback.call @, img if callback

        img.onerror = (e) =>
            @activeRequests = []
            @progress = 0
            @progressText = tr 'Error.'

        img.src = API_URL + url
        @

    @property 'progress',
        apply: (progress) ->
            @_progressBar.progress = progress

    @property 'progressText',
        apply: (progressText) ->
            @_progressLabel.text = progressText

    @property 'editMode',
        apply: (editMode) ->
            app = @app
            if editMode
                @originalParent = @parent
                app.add @
            else if @originalParent
                @originalParent.add @

            app.redirect app.reverse('project', @projectId, editMode)

            toggleClass @element, 'd-app-edit', editMode
            document.body.style.overflow = if editMode then 'hidden' else ''

            if @editorLoaded
                @tab.visible = editMode if @tab
                @userPanel.visible = editMode
                @tabBar.visible = editMode
                @lightboxEnabled = @lightboxEnabled and editMode or @preloaderEnabled
            else if editMode
                @initEditMode()

            if editMode
                @userList.clear()
                @userList.addUser @app.user ? User.guest()
                app.onUnload @unload
            else
                @spritePanel.collapsed = false
                app.unUnload @unload

            @spriteList.visible = editMode
            @spritePanel.toggleVisible = editMode

    unload: =>
        if @editMode and @parent
            @parent.remove @

class UserPanel extends Control

    constructor: (amber) ->
        @amber = amber
        super()
        @initElements 'd-user-panel'
        @add amber.userList = new UserList(amber)
        @add amber.chat = new Chat(amber)
        @element.appendChild @toggleButton = @newElement 'd-user-panel-toggle'
        @toggleButton.addEventListener 'click', @toggle

    @property 'collapsed',
        value: true
        apply: (collapsed) ->
            toggleClass @amber.element, 'd-collapse-user-panel', collapsed

            if collapsed
                @amber.chat.blur()
            else
                @amber.chat.focus()

    toggle: =>
        @collapsed = not @collapsed

class UserList extends Control
    constructor: (amber) ->
        @amber = amber
        super()
        @initElements 'd-user-list'
        @element.appendChild @title = @newElement 'd-panel-title'
        @element.appendChild @contents = @newElement 'd-panel-contents d-scrollable'
        @title.appendChild @titleLabel = @newElement 'd-panel-title-label'
        @titleLabel.textContent = tr 'Users'
        @users = {}

    addUser: (user) ->
        unless @users[user.id]
            @contents.appendChild @users[user.id] = @createUserItem user

    removeUser: (user) ->
        if @users[user.id]
            @contents.removeChild @users[user.id]
            delete @users[user.id]

    clear: ->
        @users = {}
        @contents.innerHTML = ''

    createUserItem: (user) ->
        item = @newElement 'd-user-list-item', 'a'
        icon = @newElement 'd-user-list-icon', 'img'
        label = @newElement 'd-user-list-label'
        item.href = user.profileURL
        target = '_blank'
        icon.src = user.avatarURL
        label.textContent = user.name
        item.appendChild icon
        item.appendChild label
        item

class Chat extends Control
    notificationCount: 0

    constructor: (amber) ->
        @amber = amber
        super()
        @initElements 'd-chat'
        @element.appendChild @title = @newElement 'd-panel-title'
        @contentLabel = new Label('d-panel-contents d-scrollable')
        @contentLabel.selectable = true
        @element.appendChild @contents = @contentLabel.element
        @title.appendChild @input = @newElement 'd-chat-input d-textfield', 'input'
        @input.addEventListener 'keydown', @keyDown

    keyDown: (e) =>
        if e.keyCode is 13 and @input.value isnt ''
            # @amber.socket.send
            #     $: 'chat.message'
            #     message: @input.value
            @showMessage @app.user, @input.value
            @input.value = ''

        if e.keyCode is 32 and @input.value is ''
            e.preventDefault()

    focus: ->
        @removeNotification()
        @input.focus()
        @autoscroll()

    blur: ->
        @input.blur()

    show: ->
        if @amber.userPanel.collapsed
            @amber.userPanel.toggle()
        else
            @focus()

    autoscroll: ->
        @contents.scrollTop = @contents.scrollHeight

    notify: ->
        if not @notification
            @notification = @newElement 'd-chat-notification'
            @amber.userPanel.element.appendChild @notification

        @notification.textContent = ++@notificationCount

    removeNotification: ->
        if @notification
            @amber.userPanel.element.removeChild @notification
            @notification = undefined
            @notificationCount = 0

    addItems: (history) ->
        i = 0
        do next = =>
            if item = history[i++]
                @app.server.getUser item[0], (user) =>
                    line = @createLine user, item[1]
                    @contents.appendChild line
                    next()
            else
                t.autoscroll()

    createLine: (user, chat) ->
        line = @newElement 'd-chat-line'
        username = @newElement 'd-chat-username'
        hidden = @newElement 'd-chat-line-hidden'
        message = @newElement 'd-chat-message'
        username.textContent = user.name
        hidden.textContent = ': '
        message.textContent = chat
        line.appendChild username
        line.appendChild hidden
        line.appendChild message
        line

    showMessage: (user, chat) ->
        line = @createLine user, chat
        @contents.appendChild line
        @autoscroll()
        if @amber.userPanel.collapsed
            @notify()


class SpritePanel extends Control
    constructor: (@amber) ->
        super()
        @initElements 'd-sprite-panel'
        @add amber.stagePanel = new StagePanel(amber)
        @add amber.spriteList = new SpriteList(amber)
        @element.appendChild @toggleButton = @newElement 'd-sprite-panel-toggle'
        @toggleButton.addEventListener 'click', @toggle

    @property 'toggleVisible',
        get: ->
            @toggleButton.style.display isnt 'none'
        set: (toggleVisible) ->
            @toggleButton.style.display = if toggleVisible then '' else 'none'

    @property 'collapsed',
        apply: (collapsed) ->
            toggleClass @amber.element, 'd-collapse-sprite-panel', collapsed

    toggle: =>
        @collapsed = not @collapsed

class StagePanel extends Control
    constructor: (@amber) ->
        super()
        @initElements 'd-stage-panel'
        @add amber.stageControls = new StageControls(amber)
        @add amber.stageView = new StageView(amber)

class StageControls extends Control
    constructor: (@amber) ->
        super()
        @initElements 'd-stage-controls'
        @add new Button('d-stage-control d-stage-control-go')
        @add new Button('d-stage-control d-stage-control-stop')
        @add new Button('d-stage-control d-stage-control-edit').onExecute =>
            @amber.editMode = not @amber.editMode

class StageView extends Control
    constructor: (@amber) ->
        super()
        @initElements 'd-stage'

    createBackdrop: ->
        image = @model.filteredImage
        image.control = @
        @element.appendChild @image = image, @element.firstChild

    @property 'model',
        apply: (model) ->
            @element.innerHTML = ''
            @createBackdrop()
            for sprite in model.children
                @add new SpriteView(@amber).setModel(sprite)


class SpriteView extends Control
    constructor: (@amber) ->
        super()
        @initElements 'd-sprite'

    createCostume: ->
        image = @model.filteredImage
        image.control = @
        @element.appendChild @image = image, @element.firstChild

    updateCostume: =>
        costume = @model.costume
        @image.style.WebkitTransform = 'translate(' + -costume.centerX + 'px,' + -costume.centerY + 'px)'

    updatePosition: =>
        x = @model.x + 240
        y = 180 - @model.y
        @element.style.WebkitTransform = 'translate(' + x + 'px,' + y + 'px) rotate(' + (@model.direction - 90) + 'deg)'

    @property 'model',
        apply: (model) ->
            @createCostume()
            @updatePosition()
            model.onCostumeChange @updateCostume
            model.onPositionChange @updatePosition


class SpriteList extends Control
    constructor: (@amber) ->
        super()
        @initElements 'd-sprite-list'
        @element.appendChild @container = @newElement 'd-panel-contents d-scrollable'
        @element.appendChild @title = @newElement 'd-panel-title'
        @title.appendChild @titleLabel = @newElement 'd-panel-title-label'
        @titleLabel.textContent = tr 'Sprites'
        @icons = {}

    clear: ->
        super()
        @icons = {}

    addIcon: (object) ->
        @add @icons[object.id] = new SpriteIcon(@amber, object)

    select: (object) ->
        @selectedIcon.deselect() if @selectedIcon
        (@selectedIcon = @icons[object.id]).select()

class SpriteIcon extends Control
    acceptsClick: true,

    constructor: (@amber, @object) ->
        super()
        @initElements 'd-sprite-icon'
        @element.appendChild @image = @newElement 'd-sprite-icon-image', 'canvas'
        @element.appendChild @label = @newElement 'd-sprite-icon-label'
        @onTouchStart ->
            amber.selectSprite object
        @updateLabel()
        object.onCostumeChange @updateImage

    updateImage: =>
        image = @image
        size = 120
        x = image.getContext '2d'
        costume = @object.costume.image
        ow = costume.width
        oh = costume.height
        ratio = Math.min size / ow, size / oh
        tw = Math.min ow, ow * ratio
        th = Math.min oh, oh * ratio
        image.width = size
        image.height = size
        x.drawImage costume, (size - tw) / 2, (size - th) / 2, tw, th

    updateLabel: ->
        @label.textContent = tr.maybe @object.name

    select: ->
        addClass @element, 'd-sprite-icon-selected'

    deselect: ->
        removeClass @element, 'd-sprite-icon-selected'

class TabBar extends Control
    constructor: (@amber) ->
        super()
        @initElements 'd-tab-bar', 'd-tab-bar-tabs'
        @order = []
        @addTab tr 'Scripts'
        @addTab tr 'Costumes'
        @addTab tr 'Sounds'

    addTab: (label) ->
        i = @children.length
        @order.push i
        tab = new Label('d-tab')
        tab.acceptsClick = true
        @add tab.setText(label).onTouchStart =>
            @select i

    select: (i) ->
        if @selectedIndex?
            @amber.removeClass 'tab-' + @selectedIndex
            removeClass @children[@selectedIndex].element, 'd-tab-selected'

        unless @amber.selectedSprite
            @amber.tab = null
            return

        addClass @children[@selectedIndex = i].element, 'd-tab-selected'
        @order.splice @order.indexOf(i), 1
        @order.unshift i

        l = @order.length
        for j in @order
            @children[@order[j]].element.style.zIndex = l - j

        @amber.addClass 'tab-' + i
        switch i
            when 0
                # TODO: fixme
                @amber.tab = new BlockEditor @amber.selectedSprite, @amber
            when 1
                @amber.tab = new CostumeEditor @amber.selectedSprite
            when 2
                @amber.tab = new SoundEditor @amber.selectedSprite


class CostumeEditor extends Control
    constructor: (@object) ->
        super()
        @initElements 'd-costume-editor d-editor', 'd-editor-list d-scrollable'
        @element.appendChild @contents = @newElement 'd-editor-list-contents'

        for costume, i in object.costumes
            @add icon = new CostumeEditor.Icon(@, costume)
            if i is object.costumeIndex
                @selectedCostume = costume
                @selectedIcon = icon
                icon.select()

    select: (icon, costume) ->
        @selectedIcon.deselect() if @selectedIcon

        @selectedIcon = icon
        icon.select()
        @object.costumeIndex = @object.costumes.indexOf costume

class CostumeEditor.Icon extends Control
    acceptsClick: true

    constructor: (editor, costume) ->
        @costume = costume
        super()
        @initElements 'd-costume-icon'
        @element.appendChild @image = @newElement 'd-costume-icon-image', 'canvas'
        @element.appendChild @label = @newElement 'd-costume-icon-label'
        @onTouchStart ->
            editor.select @, costume
        @updateLabel()
        costume.onImageChange @updateImage
        @updateImage()

    updateImage: =>
        image = @image
        size = 120
        x = image.getContext '2d'
        costume = @costume.image
        ow = costume.width
        oh = costume.height
        ratio = Math.min size / ow, size / oh
        tw = Math.min ow, ow * ratio
        th = Math.min oh, oh * ratio
        image.width = size
        image.height = size
        x.drawImage costume, (size - tw) / 2, (size - th) / 2, tw, th

    updateLabel: ->
        @label.textContent = @costume.name

    select: ->
        addClass @element, 'd-costume-icon-selected'

    deselect: ->
        removeClass @element, 'd-costume-icon-selected'

class SoundEditor extends Control
    constructor: ->
        super()
        @initElements 'd-sound-editor d-editor', 'd-editor-list d-scrollable'
        @element.appendChild @contents = @newElement 'd-editor-list-contents'

class BlockEditor extends Control
    constructor: (sprite, amber) ->
        super()
        @initElements 'd-block-editor d-editor'
        @add new BlockPalette(sprite, amber)
        @add new ScriptEditor(sprite, amber)

class ScriptEditor extends Control
    padding: 10
    acceptsScrollWheel: true

    constructor: (sprite, amber) ->
        super()
        @initElements 'd-script-editor'

        @element.appendChild @fill = @newElement 'd-block-editor-fill'
        @element.addEventListener 'scroll', @fit
        @onScrollWheel @scrollWheel

    scrollWheel: (e) =>
        newTop = @element.scrollTop + e.y
        newLeft = @element.scrollLeft + e.x

        if (delta = newLeft - @element.scrollWidth + @element.offsetWidth) > 0
            @fill.style.width = (@fillWidth += delta) + 'px'

        if (delta = newTop - @element.scrollHeight + @element.offsetHeight) > 0
            @fill.style.height = (@fillHeight += delta) + 'px'

        @element.scrollLeft = newLeft
        @element.scrollTop = newTop

    fit: =>
        bb = @fill.getBoundingClientRect()
        p = @padding
        c = @children
        i = c.length
        w = 0
        h = 0
        x = 0
        y = 0

        for c in @children
            b = c.element.getBoundingClientRect()
            if (v = b.left - bb.left - p) < x
                w += x - v
                x = v

            # TODO could be b.width?
            w = Math.max w, v + c.element.offsetWidth - x
            if (v = b.top - bb.top - p) < y
                h += y - v
                y = v

            h = Math.max h, v + c.element.offsetHeight - y

        if x < 0 or y < 0
            for c in children
                b = c.getPosition()
                c.initPosition b.x - x, b.y - y

            x = 0
            y = 0

        @fillWidth = Math.max w + p * 2, @element.scrollLeft + @element.offsetWidth
        @fillHeight = Math.max h + p * 2, @element.scrollTop + @element.offsetHeight

        @fill.style.width = @fillWidth + 'px'
        @fill.style.height = @fillHeight + 'px'
        @fill.style.left = x + 'px'
        @fill.style.top = y + 'px'

class BlockPalette extends Control
    @palettes: []

    isPalette: true

    constructor: (@sprite, @amber) ->
        super()
        @initElements 'd-block-palette'
        @add @categorySelector = new CategorySelector().onCategorySelect @selectCategory, @
        BlockPalette.palettes.push @

        for name of specs when name isnt 'obsolete'
            @categorySelector.addCategory name

        @selectedCategory = 'motion'

    @property 'selectedCategory', apply: -> @reload()

    reload: ->
        @remove @list if @list

        @list = new BlockList
        blocks = specs[@selectedCategory]

        if blocks.stage
            blocks = blocks[if @sprite.isStage then 'stage' else 'sprite']

        for spec in blocks
            do (spec) =>
                if spec is '-'
                    @list.addSpace()
                else if spec[0] is '&'
                    @list.add new Button().setText(tr.maybe spec[2]).onExecute =>
                        @amber[spec[1]]()
                else if spec[0] is '!'
                    @list.add new Label().setText(tr.maybe spec[1])
                else
                    block = Block.fromSpec spec
                    @list.add block if block

        @add @list

    selectCategory: (e) ->
        @selectedCategory = e.category

class CategorySelector extends Control
    acceptsClick: true

    constructor: ->
        super()
        @initElements 'd-panel-title'
        @onTouchStart @touchStart
        @clear()

    @event 'CategorySelect'

    clear: ->
        super()
        @buttons = []
        @categories = []
        @byCategory = {}

    addCategory: (category) ->
        button = @newElement 'd-category-button'
        color = @newElement 'd-category-button-color'

        color.style.backgroundColor = amber.editor.categoryColors[category]
        button.appendChild color
        @element.appendChild button
        @buttons.push button
        @categories.push category
        @byCategory[category] = button

        if 1 is @buttons.length
            @selectCategory 'motion'

        width = 100 / @buttons.length + '%'
        for b in @buttons
            b.style.width = width

        return @

    selectCategory: (category) ->
        if @selectedCategory
            removeClass @byCategory[@selectedCategory], 'active'

        if @selectedCategory = category
            addClass @byCategory[category], 'active'

        @dispatch 'CategorySelect', new ControlEvent(@).set { category }

    touchStart: (e) ->
        for b, i in @buttons
            if bbTouch b, e
                @selectCategory @categories[i]

class BlockList extends Control
    constructor: ->
        super()
        @initElements 'd-panel-contents d-scrollable', 'd-block-list-contents'
        @list = @container

    add: (child) ->
        @list.appendChild @container = @newElement 'd-block-list-item'
        super child

    addSpace: ->
        @list.appendChild @newElement 'd-block-list-space'
        @

class Block extends Control

    shape: 'puzzle'

    paddingTop: 3
    paddingRight: 5
    paddingBottom: 3
    paddingLeft: 5

    outsetTop: 0
    outsetRight: 0
    outsetBottom: 3
    outsetLeft: 0

    constructor: ->
        super()
        @initElements 'd-block', 'd-block-label'
        @element.insertBefore (@canvas = @newElement 'd-block-canvas', 'canvas'), @container
        @context = @canvas.getContext '2d'
        @shapeChanged()
        @onLive -> @changed()

    @property 'category', value: 'undefined', apply: -> @changed()

    @property 'selector'

    @property 'spec', apply: (spec) ->
        @clear()

        start = 0
        args = @arguments = []
        n = 0

        while -1 isnt i = spec.substr(start).search(/[%@]/)
            i += start
            if not /^\s*$/.test label = spec.substring start, i
                @add(new Label('d-block-text').setText(label))

            if ex = /^%(?:(\d+)\$)?(\w+)(?:\.(\w+))?/.exec(spec.substr(i))
                @add(arg = @argFromSpec(ex[2], ex[3], ex[1] ? n))
                if ex[1]
                    args[ex[1]] = arg
                else
                    args.push arg
                ++n
                start = i + ex[0].length

            else if ex = /^@(\w+)/.exec(spec.substr(i))
                @add(label = @iconFromSpec(ex[1]))
                start = i + ex[0].length

            else
                @add(new Label('d-block-text').setText(spec[i]))
                start = i + 1

        if start < spec.length
            @add(new Label('d-block-text').setText(spec.substr(start)))

        @defaultArguments = args

    changed: ->
        zoom = 1 # TODO: for debugging, remove

        if @isLive
            bb = @container.getBoundingClientRect()
            width = bb.right - bb.left + @paddingLeft + @paddingRight
            height = bb.bottom - bb.top + @paddingTop + @paddingBottom
            @element.style.width = zoom * width + 'px'
            @element.style.height = zoom * height + 'px'
            @canvas.width = zoom * (width + @outsetLeft + @outsetRight)
            @canvas.height = zoom * (height + @outsetTop + @outsetBottom)

            @context.save()
            @context.scale(zoom, zoom)

            @draw width, height

            @context.restore()

    draw: (w, h) ->

        color = categoryColors[@category]
        shadow = 'rgba(0,0,0,.3)'
        shape = @shape

        (->
            switch shape
                when 'puzzle', 'puzzle-terminal'
                    r = 3
                    puzzleInset = 8
                    puzzleWidth = 12
                    puzzleHeight = 3

                    @fillStyle = color

                    @beginPath()
                    @arc r, r, r, Math.PI, Math.PI * 3 / 2, false

                    @lineTo puzzleInset, 0
                    @arc puzzleInset + r, puzzleHeight - r, r, Math.PI, Math.PI / 2, true
                    @arc puzzleInset + puzzleWidth - r, puzzleHeight - r, r, Math.PI / 2, 0, true
                    @lineTo puzzleInset + puzzleWidth, 0

                    @arc w - r, r, r, Math.PI * 3 / 2, 0, false
                    @arc w - r, h - r, r, 0, Math.PI / 2, false

                    if shape is 'puzzle'
                        @lineTo puzzleInset + puzzleWidth, h
                        @arc puzzleInset + puzzleWidth - r, h + puzzleHeight - r, r, 0, Math.PI / 2, false
                        @arc puzzleInset + r, h + puzzleHeight - r, r, Math.PI / 2, Math.PI, false
                        @lineTo puzzleInset, h

                    @arc r, h - r, r, Math.PI / 2, Math.PI, false
                    @fill()

                    @strokeStyle = shadow
                    @beginPath()

                    @arc r, h - r, r - .5, Math.PI, Math.PI / 2, true
                    @lineTo puzzleInset, h - .5

                    if shape is 'puzzle'
                        @moveTo puzzleInset, h - .5
                        @arc puzzleInset + r, h + puzzleHeight - r, r - .5, Math.PI, Math.PI / 2, true
                        @arc puzzleInset + puzzleWidth - r, h + puzzleHeight - r, r - .5, Math.PI / 2, 0, true
                        @lineTo puzzleInset + puzzleWidth, h - .5

                        @moveTo puzzleInset + puzzleWidth, h - .5
                    else
                        @lineTo puzzleInset + puzzleWidth, h - .5

                    @arc w - r, h - r, r - .5, Math.PI / 2, 0, true

                    @stroke()

                when 'rounded'

                    r = Math.min h / 2, 12

                    @fillStyle = color

                    @beginPath()
                    @arc r, r, r, Math.PI, Math.PI * 3 / 2, false
                    @arc w - r, r, r, Math.PI * 3 / 2, 0, false
                    @arc w - r, h - r, r, 0, Math.PI / 2, false
                    @arc r, h - r, r, Math.PI / 2, Math.PI, false
                    @fill()

                    @strokeStyle = shadow
                    @beginPath()
                    @arc w - r, h - r, r - .5, Math.PI / 8, Math.PI / 2, false
                    @arc r, h - r, r - .5, Math.PI / 2, Math.PI * 7 / 8, false
                    @stroke()

                when 'hexagon'

                    @fillStyle = color

                    r = Math.min h / 2, 12

                    @beginPath()
                    @moveTo 0, h / 2
                    @lineTo r, 0
                    @lineTo w - r, 0
                    @lineTo w, h / 2
                    @lineTo w - r, h
                    @lineTo r, h
                    @fill()

                    @strokeStyle = shadow
                    @beginPath()
                    @moveTo .5, Math.floor(h / 2) + .5
                    @lineTo r, h - .5
                    @lineTo w - r, h - .5
                    @lineTo w - .5, Math.floor(h / 2) + .5
                    @stroke()

        ).call @context


    roundRect: (x, y, w, h, r) ->

    shapeChanged: ->
        @container.style.top = "#{@paddingTop}px"
        @container.style.left = "#{@paddingLeft}px"
        @canvas.style.top = "#{-@outsetTop}px"
        @canvas.style.left = "#{-@outsetLeft}px"

    setArgs: (args...) ->
        for v, i in args
            @arguments[i].value = v

    @fromSpec: (spec) ->
        switch spec[0]
            when 'c', 't', 'r', 'b', 'e', 'h'
                block = new (
                        h: HatBlock
                        r: ReporterBlock
                        e: ReporterBlock
                        b: BooleanReporterBlock
                        t: CommandBlock
                        c: CommandBlock
                    )[spec[0]]()
                    .setCategory(spec[1])
                    .setSelector(spec[2])
                    .setSpec(spec[3])

                switch spec[0]
                    when 't'
                        block.setIsTerminal(true)
                    when 'e'
                        block.setEmbedded(true).setFillsLine(true)
                    # when 'b'
                    #     block.setIsBoolean(true)

                block.setArgs spec.slice(4)...
                block
            when 'v'
                new VariableBlock().setVar(spec[1])
            when 'vs', 'vc'
                block = new SetterBlock()
                    .setIsChange(spec[0] is 'vc')
                    .setVar(spec[1])

                block
            else
                console.warn "Invalid block type #{spec[0]}"

    argFromSpec: (type, menu, i) ->
        switch type
            when 'i', 'f', 's'
                new TextArg().setMenu(menu).setNumeric(type isnt 's').setIntegral(type is 'i')
            when 'm', 'a'
                new EnumArg().setMenu(menu).setInline(type is 'a')
            else
                new TextArg().setText("#E:#{i}:#{type}.#{menu}")

    getMenuItems: (menu) ->
        items = switch menu
            when 'backdrop'
                c.name for c in @editor.selectedSprite.stage.costumes
            when 'costume'
                c.name for c in @editor.selectedSprite.costumes
            when 'deletionIndex'
                ['1', ($:'last'), ($:'random'), Menu.separator, ($:'all')]
            when 'direction'
                [(action: '90', title: tr '(90) right'), (action: '-90', title: tr '(-90) left'), (action: '0', title: tr '(0) up'), (action: '180', title: tr '(180) down')]
            when 'index'
                ['1', ($:'last'), ($:'random')]
            when 'math'
                [($:'abs'), ($:'floor'), ($:'ceiling'), ($:'sqrt'), ($:'sin'), ($:'cos'), ($:'tan'), ($:'asin'), ($:'acos'), ($:'atan'), ($:'ln'), ($:'log'), ($:'e ^'), ($:'10 ^')]
            when 'stop'
                [($:'all'), ($:'this script'), ($:'other scripts in sprite')]
            when 'spriteOrMouse'
                [$:'mouse-pointer', Menu.separator].concat (s.name for s in @editor.selectedSprite.stage.allSprites)
            when 'spriteOrSelf'
                [$:'myself', Menu.separator].concat (s.name for s in @editor.selectedSprite.stage.allSprites)
            when 'rotationStyle'
                [($:'left-right'), ($:'don\'t rotate'), ($:'all around')]
            when 'var'
                @editor.selectedSprite?.allVariableNames
            when 'wvar'
                @editor.selectedSprite?.allWritableVariableNames
            else
                console.warn "Missing menu #{menu}"
                [menu]
        (if x.$ then title: tr(x.$), action: x else x) for x in items

    iconFromSpec: (id) ->
        # TODO
        new Label('d-block-arg').setText("#{id}")

class HatBlock extends Block

class CommandBlock extends Block

    @property 'isTerminal', apply: (terminal) ->
        @shape = if terminal then 'puzzle-terminal' else 'puzzle'
        @shapeChanged()

class SetterBlock extends CommandBlock
    category: 'data'

    constructor: ->
        super()
        @isChange = false

    @property 'isChange', apply: (isChange) ->
        @spec = if isChange then 'change %m.wvar by %f' else 'set %m.wvar to %s'
        @selector = if isChange then 'changeVar:by:' else 'setVar:to:'
        @add @unitLabel = new Label('d-block-arg')
        @unitLabel.hide()

    varChanged: ->
        @unit = ''
        if @arguments[1] is @defaultArguments[1]
            arg = @getDefaultArg(@var)
            @replace @arguments[1], arg
            @arguments[1] = @defaultArguments[1] = arg
        if @unit
            @unitLabel.show()
            @unitLabel.text = @unit
        else
            @unitLabel.hide()
        @category = @var.$ and Scriptable.categoryIndex[@var.$] or 'data'

    getDefaultArg: (name) ->
        if @isChange
            switch name.$
                when 'costume #', 'layer', 'instrument'
                    @argFromSpec('i').setValue(1)
                when 'direction'
                    @argFromSpec('f').setValue(15)
                when 'tempo'
                    @argFromSpec('f').setValue(20)
                when 'volume'
                    @argFromSpec('f').setValue(-10)
                when 'pen size', 'answer', 'timer'
                    @argFromSpec('f').setValue(1)
                else
                    @argFromSpec('f').setValue(if name.$ then 10 else 1)
        else
            switch name.$
                when 'x position', 'y position', 'pen hue', 'timer'
                    @argFromSpec('f').setValue(0)
                when 'direction'
                    @argFromSpec('f', 'direction').setValue(90)
                when 'costume #'
                    @argFromSpec('i').setValue(1)
                when 'layer'
                    @argFromSpec('i', 'index').setValue('top')
                when 'instrument'
                    @argFromSpec('i', 'instrument').setValue(1)
                when 'size', 'volume'
                    @unit = '%'
                    @argFromSpec('f').setValue(100)
                when 'tempo'
                    @unit = 'bpm'
                    @argFromSpec('f').setValue(60)
                when 'pen down?'
                    @argFromSpec('b')
                when 'pen color'
                    @argFromSpec('color')
                when 'pen lightness'
                    @argFromSpec('f').setValue(50)
                when 'pen size'
                    @argFromSpec('f').setValue(1)
                when 'rotation style'
                    @argFromSpec('m', 'rotationStyle').setValue($:'left-right')
                else
                    if name.$ and /[ ]effect$/.test name.$
                        @argFromSpec('f').setValue(0)
                    else
                        @argFromSpec('s').setValue(0)

    @property 'var',
        get: -> @arguments[0].value
        set: (name) ->
            @arguments[0].value = name

    @property 'value',
        get: -> @arguments[1].value
        set: (value) -> @arguments[1].value = value

class ReporterBlock extends Block

    shape: 'rounded'

    paddingTop: 3
    paddingRight: 7
    paddingBottom: 3
    paddingLeft: 7

    outsetTop: 0
    outsetRight: 0
    outsetBottom: 0
    outsetLeft: 0

class BooleanReporterBlock extends ReporterBlock

    shape: 'hexagon'

    paddingRight: 12
    paddingLeft: 12

class VariableBlock extends ReporterBlock
    category: 'data'

    constructor: ->
        super()
        @spec = '%a.var'

    varChanged: ->
        @category = @var.$ and Scriptable.categoryIndex[@var.$] or 'data'

    @property 'var',
        get: -> @arguments[0].value
        set: (name) -> @arguments[0].value = name

class BlockArg extends Control
    isArg: true

    acceptsReporter: (reporter) -> false

    toJSON: -> @value

    claimEdits: ->

    unclaimEdits: ->

    claim: ->
        id = @block.id
        return if id is -1
        @app.socket.send 'slot.claim',
            block$id: id
            slot$index: @slotIndex

    unclaim: ->
        return if @block.id is -1
        @app.socket.send 'slot.claim',
            block$id: -1

    sendEdit: (value) ->
        @app.socket.send 'slot.set',
            block$id: @block.id
            slot$index: @slotIndex
            value: value

    edited: =>
        #@sendEdit @value

    claimedBy: (user) ->
        addClass @element, 'd-arg-claimed'
        @claimEdits()
        @claimedUser = user
        @_isClaimed = true

    unclaimed: ->
        removeClass @element, 'd-arg-claimed'
        @unclaimEdits()
        @_isClaimed = false

    @property 'isClaimed', -> @_isClaimed

    getPosition: ->
        e = @app.editor.element
        bb = @element.getBoundingClientRect()
        bbe = e.getBoundingClientRect()
        return {
            x: bb.left + e.scrollLeft - bbe.left,
            y: bb.top + e.scrollTop - bbe.top
        }

    @property 'block', ->
        if @parent.isArg then @parent.block else @parent

    @property 'slotIndex', -> @parent.indexOfSlot @

class EnumArg extends BlockArg
    acceptsClick: true

    acceptsReporter: -> true

    constructor: ->
        super()
        @initElements 'd-block-arg d-block-enum'
        @element.appendChild @label = @newElement '', 'span'
        @element.appendChild @menuButton = @newElement 'd-block-enum-menu-button'
        @onTouchStart @touchStart

    copy: ->
        copy = new @constructor().setMenu(@_menu).setValue(@value)
        copy.inline = @_inline
        copy

    @property 'menu'

    @property 'text',
        set: (v) -> @label.textContent = v
        get: -> @label.textContent

    @property 'value',
        value: '',
        set: (v) ->
            @_value = if typeof v is 'number' then '' + v else v
            @setText (if v.$ then tr v.$ else v)
            @parent?.varChanged?() if @menu is 'var' or @menu is 'wvar'

        get: -> @_value

    @property 'inline',
        value: false
        apply: (inline) ->
            toggleClass @element, 'd-block-enum-inline', inline

    touchStart: (e) ->
        if @_inline and not bbTouch @menuButton, e
            @hoistTouchStart e
            return

        new Menu()
            .addClass('d-enum-menu')
            .onExecute (e) =>
                item = e.item
                @value = if typeof item is 'string'
                    item
                else if Object::hasOwnProperty.call item, 'value'
                    item.value
                else
                    item.action
                @parent.changed()
                @edited()
            .setItems(@block.getMenuItems @menu)
            .popUp(@, @label, @value)

class TextArg extends BlockArg

    @measure = document.createElement 'div'
    @measure.className = 'd-block-field-measure'
    @cache = {}
    document.body.appendChild @measure

    acceptsClick: true
    acceptsReporter: (reporter) -> !@_numeric or !reporter.isBoolean

    constructor: ->
        super()
        @initElements 'd-block-arg d-block-string'
        @element.appendChild @input = @newElement '', 'input'
        @element.appendChild @menuButton = @newElement 'd-block-field-menu'
        @menuButton.style.display = 'none'
        @onTouchStart @touchStart
        @input.addEventListener 'input', @autosize
        @input.addEventListener 'input', @edited
        @input.addEventListener 'keypress', @key
        @input.addEventListener 'focus', @focus
        @input.addEventListener 'blur', @blur
        @input.style.width = '1px'

    copy: ->
        copy = new @constructor()
        copy.text = @text
        copy.numeric = @numeric
        copy.integral = @integral
        copy.inline = @inline
        copy.menu = @menu
        copy

    @property 'text',
        set: (v) ->
            @input.value = v
            @autosize()

        get: -> @input.value

    @property 'value',
        set: (v) ->
            @_value = if typeof v is 'number' then '' + v else v
            @setText tr.maybe @_value
        get: -> @_value

    evaluate: ->
        value = @value
        if @numeric
            if @integral
                value = parseInt value
            else
                value = parseFloat value
            return 0 if value isnt value
        return value

    @property 'numeric', apply: (numeric) ->
        @element.className = "d-block-arg #{if numeric then 'd-block-number' else 'd-block-string'}"

    @property 'integral'

    @property 'inline', apply: (inline) ->
        toggleClass @element, 'd-block-field-inline', inline

    @property 'menu', apply: (menu) ->
        @menuButton.style.display = if menu then '' else 'none'

    claimEdits: -> @input.disabled = true

    unclaimEdits: -> @input.disabled = false

    focus: =>
        @setText '' if @numeric and /[^0-9\.+-]/.test @input.value
        @claim()

    blur: =>
        @unclaim()

    edited: =>
        super()
        v = +@text
        if @numeric and v isnt v
            @_value = '' + @evaluate()
        else
            @_value = @text

    touchStart: (e) ->
        if @menu and bbTouch @menuButton, e
            new Menu()
                .addClass('d-enum-menu')
                .onExecute (e) =>
                    item = e.item
                    @value = if typeof e.item is 'string'
                        e.item
                    else if Object::hasOwnProperty.call item, 'value'
                        item.value
                    else
                        item.action
                .setItems(@block.getMenuItems @menu)
                .popDown(@, @element, @value)

    autosize: (e) =>
        cache = TextArg.cache
        measure = TextArg.measure
        # (document.activeElement is @input ? /[^0-9\.+-]/.test(@input.value) :

        if not width = cache[@input.value]
            measure.style.display = 'inline-block'
            measure.textContent = @input.value
            width = cache[@input.value] = measure.offsetWidth + 1 # Math.max(1, measure.offsetWidth)
            measure.style.display = 'none'

        @input.style.width = width + 'px'
        @parent?.changed()

    key: (e) =>
        if @numeric
            return if not e.charCode or e.metaKey or e.ctrlKey or
                e.charCode >= 0x30 and e.charCode <= 0x39 or
                e.charCode is 0x2d or e.charCode is 0x2b or
                (not @integral and e.charCode is 0x2e)
            e.preventDefault()

module 'amber.editor.ui', {
    Block
    CommandBlock
    SetterBlock
    ReporterBlock
    VariableBlock
    Editor
}
