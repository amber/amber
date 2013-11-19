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
    selectedCategory: 'motion'

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
            @stageView.model = @project.stage
        @

    createVariable: ->
        dialog = new Dialog()
            .add((form = new Form()
                .onSubmit =>
                    sprite = @selectedSprite
                    variable = name.text.trim()

                    sprite = sprite.stage unless checkbox?.checked

                    dialog.close()
                    if not variable or sprite.hasVariable variable
                        return

                    sprite.addVariable variable

                    if @tab instanceof BlockEditor and @tab.palette.selectedCategory is 'data'
                        @tab.palette.reload()
                .onCancel =>
                    dialog.close())
                .add(name = new TextField()
                    .setPlaceholder(tr 'Variable Name')))

        unless @selectedSprite.isStage
            dialog.add(checkbox = new Checkbox()
                .setText(tr 'For this sprite only'))

        dialog.add(new Button()
                .setText(tr 'OK')
                .onExecute(form.submit, form))
            .add(new Button()
                .setText(tr 'Cancel')
                .onExecute(form.cancel, form))
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
        @scripts = object.scripts
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

            if editMode
                @originalParent = @parent
                app.add @
            else if @originalParent
                @originalParent.add @

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
        label.textContent = tr.maybe user.name
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
        @element = @container = @newElement 'd-stage', 'canvas'
        @resize()
        @context = @element.getContext '2d'
        @redraw = true
        @onLive @start
        @onUnlive @stop

    @property 'model', apply: (model, old) ->
        if old
            old.unChange @dirty
            old.unChildrenChange @listenChildren
            c.unChange @dirty for c in old.children

        model.onChange @dirty
        c.onChange @dirty for c in model.children

        @dirty()

    @property 'framerate',
        value: 60
        apply: -> @restart()

    resize: ->
        @element.width = Stage.WIDTH
        @element.height = Stage.HEIGHT

    restart: ->
        @stop()
        @start()

    start: ->
        return if @interval
        @interval = setInterval @step, 1000 / @framerate
        @step()

    stop: ->
        return unless @interval
        clearInterval @interval
        delete @interval

    dirty: =>
        @redraw = true

    step: =>
        if @redraw
            @draw()
            @redraw = false

    draw: ->
        @element.width = @element.width
        @amber.project.stage.draw @context

    createBackdrop: ->
        image = @model.filteredImage
        image.control = @
        @element.appendChild @image = image, @element.firstChild

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
        @add @palette = new BlockPalette(sprite, amber)
        @add @scripts = new ScriptEditor(sprite, amber)

class ScriptEditor extends Control
    padding: 10
    acceptsScrollWheel: true

    constructor: (sprite, amber) ->
        super()
        @initElements 'd-script-editor d-scrollable'

        @element.appendChild @fill = @newElement 'd-block-editor-fill'
        @element.addEventListener 'scroll', @fit
        @onLive @fit
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
            for c in @children
                c.setPosition c.x - x, c.y - y

            x = 0
            y = 0

        @fillWidth = Math.max w + p * 2, @element.scrollLeft + @element.offsetWidth
        @fillHeight = Math.max h + p * 2, @element.scrollTop + @element.offsetHeight

        @fill.style.width = @fillWidth + 'px'
        @fill.style.height = @fillHeight + 'px'
        @fill.style.left = x + 'px'
        @fill.style.top = y + 'px'

        @element.style.overflowX = if x + @fillWidth <= @element.offsetWidth then 'hidden' else 'auto'
        @element.style.overflowY = if y + @fillHeight <= @element.offsetHeight then 'hidden' else 'auto'

class BlockPalette extends Control
    isPalette: true

    constructor: (@sprite, @amber) ->
        super()
        @initElements 'd-block-palette'
        @add @categorySelector = new CategorySelector().onCategorySelect @selectCategory, @

        for name of specs when name isnt 'undefined'
            @categorySelector.addCategory name

        @categorySelector.selectCategory @amber.selectedCategory

    @property 'selectedCategory', apply: (category) ->
        @amber.selectedCategory = category
        @reload()

    reload: ->
        @remove @list if @list

        @list = new BlockList
        blocks = specs[@selectedCategory]

        if blocks.stage
            blocks = blocks[if @sprite.isStage then 'stage' else 'sprite']

        target = @amber.selectedSprite
        for spec in blocks
            if spec.stage
                spec = spec.stage
                continue unless @sprite.isStage
            if spec.sprite
                spec = spec.sprite
                continue unless @sprite.isSprite
            do (spec) =>
                if spec is '-'
                    @list.addSpace()
                else if spec[0] is '&'
                    @list.add new Button().setText(tr.maybe spec[2]).onExecute =>
                        @amber[spec[1]]()
                else if spec[0] is '!'
                    @list.add new Label().setText(tr.maybe spec[1])
                else if spec is 'v' or spec is 'gv'
                    sprite = target
                    sprite = sprite.stage if spec is 'gv'
                    for n in sprite.variableNames
                        if sprite.findVariable(n).category is 'data'
                            block = Block.fromSpec ['v', n], target
                            @list.add block if block
                else
                    block = Block.fromSpec spec, target
                    block.setDefaults()
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

HTOLERANCE = 15
VTOLERANCE = 8

class BlockStack extends Control
    isStack: true

    constructor: ->
        super()
        @initElements 'd-block-stack'
        @onTouchMove @drag
        @onTouchEnd @stopDrag

    toJSON: (script = false) ->
        result = (b.toJSON() for b in @children)
        if script then result = [@x, @y, result]
        result

    @fromJSON: (json, target) ->
        stack = new BlockStack()
        if typeof json[0] is 'number'
            stack.setPosition json[0], json[1]
            json = json[2]

        for b in json
            stack.add Block.fromJSON b, target, false

        stack

    @property 'top', -> @children[0]
    @property 'bottom', -> @children[@children.length - 1]

    changed: ->
        @parent?.changed?()

    splitAt: (top) ->
        if top is @top
            if @parent.isCommandSlot
                @parent.stack = null
            return @

        stack = new BlockStack

        i = @children.indexOf top
        if -1 isnt i
            for c in @children[i..@children.length - 1]
                stack.add c

        @changed()

        stack

    copyAt: (b) ->
        copy = new BlockStack
        i = @children.indexOf b
        if i isnt -1
            for c in @children[i..@children.length - 1]
                copy.add c.copy()
        copy

    copy: ->
        copy = new BlockStack
        for c in @children
            copy.add c.copy()
        copy

    startDrag: (e, editor, tbb) ->
        return if @dragging

        editor ?= @editor
        ebb = editor.element.getBoundingClientRect()
        tbb ?= @element.getBoundingClientRect()

        @dragging = true
        @dragOffsetX = tbb.left - ebb.left - e.x
        @dragOffsetY = tbb.top - ebb.top - e.y

        if not (editor.tab instanceof BlockEditor)
            editor.tabBar.select 0
        editor.add @

        app = @app
        app.mouseDown = true
        app.mouseDownControl = @

        @feedback = new Container('d-block-feedback')
        @feedback.hide()
        editor.add @feedback

        @addClass 'dragging'
        @drag e

    drag: (e) ->
        @element.style.left = (@dragOffsetX + e.x) + 'px'
        @element.style.top = (@dragOffsetY + e.y) + 'px'

        @showFeedback e

    showFeedback: (e) ->
        targets = []

        top = @top
        bottom = @bottom

        tbb = @element.getBoundingClientRect()
        tp = x: tbb.left, y: tbb.top

        add = (pt, target, bb) ->
            pt.radiusX ?= 0
            pt.radiusY ?= 0
            if inBB pt, bb
                targets.push target

        showStackFeedback = (stack, each) ->
            for c in stack.children
                each c

        showCommandFeedback = (block) ->
            unless block.isReporter
                bb = block.element.getBoundingClientRect()

                if not block.isTerminal and (not bottom.isTerminal or block is block.parent.bottom) and not top.isHat
                    add tp, {
                        block
                        type: 'insertAfter'
                    }, {
                        left: bb.left - HTOLERANCE
                        right: bb.left + HTOLERANCE
                        top: bb.bottom - VTOLERANCE
                        bottom: bb.bottom + VTOLERANCE
                    }

                if block.parent.top is block and not (bottom.isTerminal or block.isHat)
                    add tp, {
                        block, type: 'insertBefore'
                    }, {
                        left: bb.left - HTOLERANCE
                        right: bb.right + HTOLERANCE
                        top: bb.top - VTOLERANCE
                        bottom: bb.top + VTOLERANCE
                    }

            for a in block.arguments
                if a.isCommandSlot
                    if a.stack
                        showStackFeedback a.stack, showCommandFeedback
                    else
                        abb = a.element.getBoundingClientRect()
                        add tp, {
                            block: a
                            type: 'insertIn'
                        }, {
                            left: abb.left - HTOLERANCE
                            right: abb.right + HTOLERANCE
                            top: abb.top - VTOLERANCE
                            bottom: abb.top + VTOLERANCE
                        }
                else if a.isBlock
                    showCommandFeedback a

        showSlotFeedback = (block) ->
            for a in block.arguments
                if a.isCommandSlot
                    if a.stack
                        showStackFeedback a.stack, showSlotFeedback
                else
                    bb = a.element.getBoundingClientRect()
                    add tp, {
                        block: a
                        type: 'replace'
                    }, {
                        left: bb.left - HTOLERANCE
                        right: bb.right + HTOLERANCE
                        top: bb.top - VTOLERANCE
                        bottom: bb.bottom + VTOLERANCE
                    }
                if a.isBlock
                    showSlotFeedback a

        if @top.isReporter
            for c in @editor.tab?.scripts.children
                showStackFeedback c, showSlotFeedback
        else
            for c in @editor.tab?.scripts.children
                showStackFeedback c, showCommandFeedback

        if @dropTarget = targets.pop()
            @resizeFeedback @dropTarget
            @feedback.show()
        else
            @feedback.hide()

    resizeFeedback: (target) ->
        bb = target.block.element.getBoundingClientRect()
        ebb = @feedback.parent.element.getBoundingClientRect()
        switch target.type
            when 'insertAfter'
                @feedback.element.style.left = bb.left - 10 - ebb.left + 'px'
                @feedback.element.style.top = bb.bottom - 2 - ebb.top + 'px'
                @feedback.element.style.width = bb.width + 20 + 'px'
                @feedback.element.style.height = '4px'
            when 'insertBefore', 'insertIn'
                @feedback.element.style.left = bb.left - 10 - ebb.left + 'px'
                @feedback.element.style.top = bb.top - 2 - ebb.top + 'px'
                @feedback.element.style.width = bb.width + 20 + 'px'
                @feedback.element.style.height = '4px'
            when 'replace'
                @feedback.element.style.left = bb.left - 4 - ebb.left + 'px'
                @feedback.element.style.top = bb.top - 4 - ebb.top + 'px'
                @feedback.element.style.width = bb.width + 8 + 'px'
                @feedback.element.style.height = bb.height + 8 + 'px'

    stopDrag: (e) ->
        @dragging = false
        @removeClass 'dragging'

        @feedback?.parent?.remove @feedback
        @feedback = null

        editor = @editor
        if editor.tab.scripts
            if bbTouch editor.tab.palette.element, e
                @delete()
            else if t = @dropTarget
                switch t.type
                    when 'insertBefore'
                        i = t.block.parent.children.indexOf t.block
                        t.block.parent.insertStack @, i
                    when 'insertAfter'
                        i = t.block.parent.children.indexOf t.block
                        t.block.parent.insertStack @, i + 1
                    when 'replace'
                        t.block.parent.replaceArg t.block, @top
                        @parent?.remove @
                    when 'insertIn'
                        @discardPosition()
                        t.block.stack = @
            else if bbTouch editor.tab.scripts.element, e
                editor.tab.scripts.add @
                @moveInParent @dragOffsetX + e.x, @dragOffsetY + e.y

    delete: (e) ->
        editor = @editor
        @parent.remove @
        editor.tab.scripts.fit()

    insertStack: (s, i) ->
        j = s.children.length
        while j--
            @insert s.children[j], @children[i]
        s.parent?.remove s
        @changed()

    discardPosition: ->
        @element.style.left =
        @element.style.top = ''

    setPosition: (@x, @y) ->
        @element.style.left = x + 'px'
        @element.style.top = y + 'px'

    setScreenPosition: (x, y) ->
        bb = @parent.container.getBoundingClientRect()
        ebb = @editor.container.getBoundingClientRect()
        @setPosition x - bb.left + ebb.left + @parent.container.scrollLeft,
                     y - bb.top + ebb.top + @parent.container.scrollTop

    moveInParent: (x, y) ->
        @setScreenPosition x, y
        @editor.tab.scripts.fit()

class Block extends Control

    isBlock: true

    acceptsClick: true
    acceptsContextMenu: true

    shape: 'puzzle'

    argStart: 0

    constructor: (@target) ->
        super()
        @initElements 'd-block', 'd-block-label'
        @element.insertBefore (@canvas = @newElement 'd-block-canvas', 'canvas'), @container
        @context = @canvas.getContext '2d'
        @shapeChanged()
        @onLive -> @changed()

        @onTouchStart @pickUp
        @onContextMenu @contextMenu

    toJSON: -> [@selector].concat (a.toJSON() for a in @arguments)

    @fromJSON: (json, target, reporter) ->
        selector = json[0]
        spec = specsBySelector[selector]
        if spec
            b = Block.fromSpec spec, target
        else
            b = Block.fromSpec [(if reporter then 'r' else 'c'), undefined, 'nop', 'obsolete' + Array(json.length).join(' %s')], target
        for a, i in json[1..]
            if a instanceof Array
                if typeof a[0] is 'string'
                    b.replaceArg b.arguments[i], Block.fromJSON a, target, true
                else
                    b.arguments[i].stack = BlockStack.fromJSON a, target
            else if a?
                b.arguments[i].value = a
        b

    contextMenu: (e) ->
        items = [
            (action: 'help', title: tr 'Help')
        ]
        unless @anyParentSatisfies((p) -> p.isPalette)
            items = items.concat [
                Menu.separator
                (action: 'duplicate', title: tr 'Duplicate')
            ]
        new Menu()
            .onExecute (s) =>
                switch s.item?.action
                    when 'duplicate'
                        editor = @editor
                        bb = @element.getBoundingClientRect()
                        if @parent.isStack
                            stack = @parent.copyAt @
                        else
                            stack = new BlockStack()
                            stack.add @copy()
                        editor.add stack
                        stack.startDrag(e, editor, bb)
            .setItems(items)
            .show(@, e)

    pickUp: (e) ->
        editor = @editor
        bb = @element.getBoundingClientRect()
        if @parent?.parent?.isPalette
            stack = new BlockStack
            stack.add @copy()
        else if @parent.isStack
            stack = @split()
        else
            stack = new BlockStack
            @parent.revertArg @
            stack.add @
        stack.startDrag e, editor, bb

    split: -> @parent.splitAt @

    revertArg: (a) ->
        if -1 isnt i = @arguments.indexOf a
            @replace a, @defaultArguments[i]
            @arguments[i] = @defaultArguments[i]
            @changed()

    replaceArg: (a, b) ->
        if -1 isnt i = @arguments.indexOf a
            if a.isBlock
                bb = a.element.getBoundingClientRect()
            @replace a, b
            @arguments[i] = b
            @changed()
            if a.isBlock
                stack = new BlockStack
                @editor.tab.scripts.add stack
                stack.add a
                stack.moveInParent bb.left + 20, bb.top + 20

    copy: ->
        copy = new @constructor(@target)
        copy.spec = @spec
        copy.selector = @selector
        copy.category = @category
        copy.isTerminal = @isTerminal
        for a, i in @arguments
            b = copy.arguments[i]
            if a.isBlock
                copy.replaceArg b, a.copy()
            else if a.isCommandSlot
                b.stack = a.stack?.copy()
            else
                b.value = a.value
        copy

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

        if args[args.length - 1]?.isCSlot
            @add(new Label('d-block-c-end'))

        @defaultArguments = args.slice 0

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

        @parent?.changed?()

    draw: (w, h) ->

        color = categoryColors[@category]
        highlight = 'rgba(255,255,255,.2)'
        shadow = 'rgba(0,0,0,.3)'
        shape = @shape

        cx = @context

        puzzleInset = 8
        puzzleWidth = 12
        puzzleHeight = 3

        switch shape
            when 'puzzle', 'puzzle-terminal', 'hat'
                r = 3
                hh = @paddingTop - @paddingBottom
                hw = 80
                y = if shape is 'hat' then hh else 0

                cx.fillStyle = color

                cx.beginPath()

                if shape is 'hat'
                    cx.moveTo 0, hh
                    cx.quadraticCurveTo hw / 2, -hh / 2, hw, hh
                else
                    cx.arc r, r, r, Math.PI, Math.PI * 3 / 2, false

                    cx.lineTo puzzleInset, 0
                    cx.arc puzzleInset + r, puzzleHeight - r, r, Math.PI, Math.PI / 2, true
                    cx.arc puzzleInset + puzzleWidth - r, puzzleHeight - r, r, Math.PI / 2, 0, true
                    cx.lineTo puzzleInset + puzzleWidth, 0

                cx.arc w - r, y + r, r, Math.PI * 3 / 2, 0, false
                cx.arc w - r, h - r, r, 0, Math.PI / 2, false

                if shape isnt 'puzzle-terminal'
                    cx.lineTo puzzleInset + puzzleWidth, h
                    cx.arc puzzleInset + puzzleWidth - r, h + puzzleHeight - r, r, 0, Math.PI / 2, false
                    cx.arc puzzleInset + r, h + puzzleHeight - r, r, Math.PI / 2, Math.PI, false
                    cx.lineTo puzzleInset, h

                cx.arc r, h - r, r, Math.PI / 2, Math.PI, false
                cx.fill()

                cx.strokeStyle = highlight
                cx.beginPath()
                cx.moveTo .5, h - r

                if shape is 'hat'
                    cx.lineTo .5, hh + .5
                    cx.quadraticCurveTo hw / 2, -hh / 2, hw, hh + .5
                else
                    cx.arc r, y + r, r - .5, Math.PI, Math.PI * 3 / 2, false

                    cx.lineTo puzzleInset, y + .5
                    cx.arc puzzleInset + r, y + puzzleHeight - r, r + .5, Math.PI, Math.PI / 2, true
                    cx.arc puzzleInset + puzzleWidth - r, y + puzzleHeight - r, r + .5, Math.PI / 2, 0, true
                    cx.lineTo puzzleInset + puzzleWidth, y + .5

                cx.arc w - r, y + r, r - .5, Math.PI * 3 / 2, 0, false
                cx.stroke()

                cx.strokeStyle = shadow
                cx.beginPath()

                cx.arc r, h - r, r - .5, Math.PI, Math.PI / 2, true
                cx.lineTo puzzleInset, h - .5

                if shape is 'puzzle-terminal'
                    cx.lineTo puzzleInset + puzzleWidth, h - .5
                else
                    cx.moveTo puzzleInset, h - .5
                    cx.arc puzzleInset + r, h + puzzleHeight - r, r - .5, Math.PI, Math.PI / 2, true
                    cx.arc puzzleInset + puzzleWidth - r, h + puzzleHeight - r, r - .5, Math.PI / 2, 0, true
                    cx.lineTo puzzleInset + puzzleWidth, h - .5

                    cx.moveTo puzzleInset + puzzleWidth, h - .5

                cx.arc w - r, h - r, r - .5, Math.PI / 2, 0, true
                cx.lineTo w - .5, y + r

                cx.stroke()

            when 'rounded'

                r = Math.min h / 2, 12

                cx.fillStyle = color

                cx.beginPath()
                cx.arc r, r, r, Math.PI, Math.PI * 3 / 2, false
                cx.arc w - r, r, r, Math.PI * 3 / 2, 0, false
                cx.arc w - r, h - r, r, 0, Math.PI / 2, false
                cx.arc r, h - r, r, Math.PI / 2, Math.PI, false
                cx.fill()

                cx.strokeStyle = highlight
                cx.beginPath()
                cx.arc w - r, r, r - .5, Math.PI * 15 / 8, Math.PI * 3 / 2, true
                cx.arc r, r, r - .5, Math.PI * 3 / 2, Math.PI * 9 / 8, true
                cx.stroke()

                cx.strokeStyle = shadow
                cx.beginPath()
                cx.arc w - r, h - r, r - .5, Math.PI / 8, Math.PI / 2, false
                cx.arc r, h - r, r - .5, Math.PI / 2, Math.PI * 7 / 8, false
                cx.stroke()

            when 'hexagon'

                cx.fillStyle = color

                r = Math.min h / 2, 12

                cx.beginPath()
                cx.moveTo 0, h / 2
                cx.lineTo r, 0
                cx.lineTo w - r, 0
                cx.lineTo w, h / 2
                cx.lineTo w - r, h
                cx.lineTo r, h
                cx.fill()

                cx.strokeStyle = highlight
                cx.beginPath()
                cx.moveTo .5, Math.floor(h / 2) + .5
                cx.lineTo r, .5
                cx.lineTo w - r, .5
                cx.lineTo w - .5, Math.floor(h / 2) + .5
                cx.stroke()

                cx.strokeStyle = shadow
                cx.beginPath()
                cx.moveTo .5, Math.floor(h / 2) + .5
                cx.lineTo r, h - .5
                cx.lineTo w - r, h - .5
                cx.lineTo w - .5, Math.floor(h / 2) + .5
                cx.stroke()

        bb = null
        for a in @arguments when a.isCSlot
            bb ?= @element.getBoundingClientRect()
            abb = a.element.getBoundingClientRect()

            x = abb.left - bb.left
            y = abb.top - bb.top
            sh = abb.height

            r = 3
            cx.beginPath()
            cx.arc x + r, y + r, r, Math.PI, Math.PI * 3 / 2, false

            cx.lineTo x + puzzleInset, y
            cx.arc x + puzzleInset + r, y + puzzleHeight - r, r, Math.PI, Math.PI / 2, true
            cx.arc x + puzzleInset + puzzleWidth - r, y + puzzleHeight - r, r, Math.PI / 2, 0, true
            cx.lineTo x + puzzleInset + puzzleWidth, y

            cx.arc w - r, y - r, r, Math.PI / 2, 0, true
            cx.arc w - r, y + sh + r, r, 0, Math.PI * 3 / 2, true
            cx.arc x + r, y + sh - r, r, Math.PI / 2, Math.PI, false
            cx.closePath()
            cx.globalCompositeOperation = 'destination-out'
            cx.fill()

            cx.globalCompositeOperation = 'source-atop'
            cx.strokeStyle = shadow
            cx.beginPath()
            cx.moveTo x - .5, y + sh - r
            cx.arc x + r, y + r, r + .5, Math.PI, Math.PI * 3 / 2, false

            cx.lineTo x + puzzleInset, y - .5

            cx.moveTo x + puzzleInset, y + puzzleHeight - r - .5
            cx.arc x + puzzleInset + r, y + puzzleHeight - r, r - .5, Math.PI, Math.PI / 2, true
            cx.arc x + puzzleInset + puzzleWidth - r, y + puzzleHeight - r, r - .5, Math.PI / 2, 0, true
            cx.lineTo x + puzzleInset + puzzleWidth, y + puzzleHeight - r - .5

            cx.arc w - r, y - r, r - .5, Math.PI / 2, 0, true
            cx.stroke()

            cx.strokeStyle = highlight
            cx.beginPath()
            cx.arc w - r, y + sh + r, r - .5, 0, Math.PI * 3 / 2, true
            cx.arc x + r, y + sh - r, r + .5, Math.PI / 2, Math.PI, false
            cx.stroke()

            cx.globalCompositeOperation = 'source-over'

    roundRect: (x, y, w, h, r) ->

    shapeChanged: ->
        switch @shape
            when 'puzzle', 'puzzle-terminal', 'hat'
                @paddingLeft =
                @paddingRight = 5
                @paddingTop =
                @paddingBottom = 3
                @outsetLeft =
                @outsetRight =
                @outsetTop =
                @outsetBottom = 0
                if @shape isnt 'puzzle-terminal'
                    @outsetBottom = 3
                if @shape is 'hat'
                    @paddingTop = 15
            when 'rounded', 'hexagon'
                @paddingLeft =
                @paddingRight = 7
                @paddingTop =
                @paddingBottom = 3
                @outsetLeft =
                @outsetRight =
                @outsetTop =
                @outsetBottom = 0
                if @shape is 'hexagon'
                    @paddingLeft =
                    @paddingRight = 12

        @container.style.top = "#{@paddingTop}px"
        @container.style.left = "#{@paddingLeft}px"
        @canvas.style.top = "#{-@outsetTop}px"
        @canvas.style.left = "#{-@outsetLeft}px"

    setArgs: (args...) ->
        for v, i in args
            @arguments[i].value = v
        @argStart = args.length

    setDefaults: ->
        for a in @arguments
            continue if a.value
            switch a.menu
                when 'var', 'wvar'
                    for n in @target.allVariableNames when @target.findVariable(n).category is 'data'
                        a.value = n
                        break
                when 'costume'
                    a.value = @target.costumes[0]?.name ? ''
                when 'backdrop'
                    a.value = @target.stage.costumes[0]?.name ? ''

    @fromSpec: (spec, target) ->
        switch spec[0]
            when 'c', 't', 'r', 'b', 'e', 'h'
                block = new (
                        h: HatBlock
                        r: ReporterBlock
                        e: ReporterBlock
                        b: BooleanReporterBlock
                        t: CommandBlock
                        c: CommandBlock
                    )[spec[0]](target)
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
                block = new VariableBlock(target).setVar(spec[1])
            when 'vs', 'vc'
                block = new SetterBlock(target)
                    .setIsChange(spec[0] is 'vc')

                block.setVar(spec[1]) if spec[1]
            else
                console.warn "Invalid block type #{spec[0]}"
        block

    argFromSpec: (type, menu, i) ->
        switch type
            when 'i', 'f', 's'
                new TextArg().setMenu(menu).setNumeric(type isnt 's').setIntegral(type is 'i')
            when 'm', 'a'
                new EnumArg().setMenu(menu).setInline(type is 'a')
            when 'c'
                new CArg()
            when 'b'
                new BoolArg()
            when 'color'
                new ColorArg().randomize()
            else
                new TextArg().setText("#E:#{i}:#{type}.#{menu}")

    getMenuItems: (menu) ->
        items = switch menu
            when 'backdrop'
                c.name for c in @target.stage.costumes
            when 'costume'
                c.name for c in @target.costumes
            when 'deletionIndex'
                ['1', ($:'last'), ($:'random'), Menu.separator, ($:'all')]
            when 'direction'
                [(action: '90', title: tr '(90) right'), (action: '-90', title: tr '(-90) left'), (action: '0', title: tr '(0) up'), (action: '180', title: tr '(180) down')]
            when 'index'
                ['1', ($:'last'), ($:'random')]
            when 'key'
                [($:'up arrow'), ($:'down arrow'), ($:'right arrow'), ($:'left arrow'), ($:'space')].concat (String.fromCharCode i for i in [('a'.charCodeAt 0)..('z'.charCodeAt 0)])
            when 'math'
                [($:'abs'), ($:'floor'), ($:'ceiling'), ($:'sqrt'), ($:'sin'), ($:'cos'), ($:'tan'), ($:'asin'), ($:'acos'), ($:'atan'), ($:'ln'), ($:'log'), ($:'e ^'), ($:'10 ^')]
            when 'rotationStyle'
                [($:'left-right'), ($:'don\'t rotate'), ($:'all around')]
            when 'stop'
                [($:'all'), ($:'this script'), ($:'other scripts in @target')]
            when 'spriteOrMouse'
                [$:'mouse-pointer', Menu.separator].concat (s.name for s in @target.stage.allSprites)
            when 'spriteOrSelf'
                [$:'myself', Menu.separator].concat (s.name for s in @target.stage.allSprites)
            when 'spriteOrStage'
                [$:'Stage', Menu.separator].concat (s.name for s in @target.stage.allSprites)
            when 'stageOrThis'
                [($:'Stage'), ($:'this sprite')]
            when 'triggerSensor'
                [($:'loudness'), ($:'timer'), ($:'video motion')]
            when 'var'
                @target.allVariableNames
            when 'videoMotion'
                [($:'motion'), ($:'direction')]
            when 'videoState'
                [($:'off'), ($:'on'), ($:'on-flipped')]
            when 'wvar'
                @target.allWritableVariableNames
            else
                console.warn "Missing menu #{menu}"
                [menu]
        (if x.$ then title: tr(x.$).replace(/@target/g, tr.maybe @target.name), action: x else x) for x in items

    iconFromSpec: (id) ->
        switch id
            when 'target' then new Label('d-block-text').setText(tr.maybe @target.name)
            else new Label('d-block-arg').setText("#{id}")

class HatBlock extends Block

    shape: 'hat'
    isHat: true

class CommandBlock extends Block

    stopChanged: ->
        if @selector is 'stopScripts'
            @isTerminal = @arguments[0].value.$ isnt 'other scripts in @target'

    @property 'isTerminal', apply: (terminal) ->
        @shape = if terminal then 'puzzle-terminal' else 'puzzle'
        @shapeChanged()

class SetterBlock extends CommandBlock
    category: 'data'

    constructor: (target) ->
        super target
        @isChange = false

    @property 'isChange', apply: (isChange) ->
        @spec = if isChange then 'change %m.wvar by %f' else 'set %m.wvar to %s'
        @selector = if isChange then 'changeVar:by:' else 'setVar:to:'
        @add @unitLabel = new Label('d-block-arg')
        @unitLabel.hide()
        @varChanged()

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
                    @argFromSpec('i', 'index').setValue(1)
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
                when 'video transparency'
                    @unit = '%'
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

    isReporter: true

    shape: 'rounded'

    constructor: (target) ->
        super target
        @addClass 'd-reporter-block'

class BooleanReporterBlock extends ReporterBlock

    isBoolean: true

    shape: 'hexagon'

class VariableBlock extends ReporterBlock
    category: 'data'

    constructor: (target) ->
        super target
        @selector = 'readVariable'
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

    changed: ->
        @parent?.changed?()

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
            text = tr.maybe v
            if v.$ and @parent?.target
                text = text.replace /@target/g, tr.maybe @parent.target.name
            @setText text
            @parent?.varChanged?() if @menu is 'var' or @menu is 'wvar'
            @parent?.stopChanged?() if @menu is 'stop'

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
                @changed()
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
        @changed()

    key: (e) =>
        if @numeric
            return if not e.charCode or e.metaKey or e.ctrlKey or
                e.charCode >= 0x30 and e.charCode <= 0x39 or
                e.charCode is 0x2d or e.charCode is 0x2b or
                (not @integral and e.charCode is 0x2e)
            e.preventDefault()

class CArg extends BlockArg
    isCommandSlot: true
    isCSlot: true

    toJSON: -> @stack?.toJSON()

    constructor: ->
        super()
        @initElements 'd-block-c'

    @property 'stack', apply: (stack) ->
        @clear()
        if stack
            @add stack
        @changed()

class BoolArg extends BlockArg

    toJSON: -> false

    constructor: ->
        super()
        @element = @container = @newElement 'd-block-arg d-block-bool', 'canvas'
        @context = @element.getContext '2d'
        @draw()

    draw: ->
        @element.width = w = 30
        @element.height = h = 13

        r = Math.min h / 2, 12

        cx = @context

        cx.fillStyle = 'rgba(0, 0, 0, .1)'
        cx.beginPath()
        cx.moveTo .5, h / 2 - .5
        cx.lineTo r, 0
        cx.lineTo w - r, 0
        cx.lineTo w - .5, h / 2 - .5
        cx.lineTo w - r, h - 1
        cx.lineTo r, h - 1
        cx.fill()

        cx.strokeStyle = 'rgba(0, 0, 0, .4)'
        cx.beginPath()
        cx.moveTo .5, h / 2
        cx.lineTo r, .5
        cx.lineTo w - r, .5
        cx.lineTo w - .5, h / 2
        cx.stroke()

        cx.strokeStyle = 'rgba(255, 255, 255, .3)'
        cx.beginPath()
        cx.moveTo w - .5, h / 2
        cx.lineTo w - r, h - .5
        cx.lineTo r, h - .5
        cx.lineTo .5, h / 2
        cx.stroke()

class ColorArg extends BlockArg

    constructor: ->
        super()
        @initElements 'd-block-arg d-block-color'
        @element.appendChild @picker = @newElement 'd-block-color-input', 'input'
        @picker.type = 'color'
        @value = 0
        @picker.addEventListener 'input', @colorSelected

    colorSelected: =>
        @setValue parseInt @picker.value.substr(1), 16
        @edited()

    randomize: ->
        @setValue Math.floor(Math.random() * 0xffffff)

    copy: -> new @constructor()

    @property 'value',
        apply: (color) ->
            css = color.toString 16
            while css.length < 6
                css = '0' + css
            @element.style.backgroundColor = @picker.value = '#' + css

module 'amber.editor.ui', {
    BlockStack
    Block
    CommandBlock
    SetterBlock
    ReporterBlock
    VariableBlock
    Editor
}
