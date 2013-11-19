{ Base, extend, addClass, removeClass, toggleClass, hasClass, format, htmle, htmlu, bbTouch, inBB } = amber.util
{ Event, PropertyEvent, ControlEvent, TouchEvent, WheelEvent } = amber.event
{ getText: tr } = amber.locale

transUnion = (arrays...) ->
    if arrays.length
        result = transUnion arrays.slice(1)...
        for x in arrays[0]
            found = false
            for y in result
                if y is x or y.$ and y.$ is x.$
                    found = true
                    break
            continue if found
            result.push x
        result
    else []

class Project extends Base
    @property 'name', event: 'NameChange'

    constructor: ->
        @name = tr 'Untitled'

class Scriptable extends Base
    @id: 0

    isStage: false
    isSprite: false

    @event 'Change'

    constructor: (@name) ->
        @id = ++Scriptable.id

        @variables = []
        @allVariables = {}

        for name, config of @properties
            @variables.push new Variable @, $:name, config
        @rebuildVariables()

        @children = []
        @costumes = []

        @filters =
            color: 0
            fisheye: 0
            whirl: 0
            pixelate: 0
            mosaic: 0
            brightness: 0
            ghost: 0

        @onCostumeChange @change
        @onFilterChange @change

    change: =>
        @dispatch 'Change', new ControlEvent(@)

    @event 'FilterChange'
    setFilter: (name, value) ->
        @filters[name] = value
        @dispatch 'FilterChange', new ControlEvent(@)

    applyFilter: (cx) ->
        cx.globalAlpha = 1 - @filters.ghost / 100

    @property 'costume', event: 'CostumeChange'
    @property 'costumeIndex',
        get: -> @costumes.indexOf @costume
        set: (i) -> @costume = @costumes[i]

    @property 'stage', -> @parent?.stage

    @property 'allObjects', ->
        if @children
            [].concat.apply [@], (x.allObjects for x in @children)
        else
            [@]

    @property 'allSprites', ->
        x for x in @allObjects when x.isSprite

    addCostume: (info) ->
        image = new Image
        image.onload = =>
            costume = new Costume().set({
                name: info.name
                image: image
                rotationCenterX: info.rotationCenterX
                rotationCenterY: info.rotationCenterY
            })
            if not @costumes.length
                @costume = costume
            @costumes.push costume
        image.src = info.base64
        @

    addVariable: (name) ->
        return if @findVariable name
        @variables.push new Variable @, name
        @rebuildVariables()

    removeVariable: (name) ->
        for x, i in @variables
            if x.name is name or name.$ and x.name.$ is name.$
                @variables.splice i, 1
                @rebuildVariables()
                break

    findVariable: (name) ->
        if name.$ then @allProperties[name.$] else @allVariables[name]

    hasVariable: (name) ->
        !!@findVariable name

    @property 'parent',
        get: -> @_parent
        set: (p) ->
            @_parent = p
            @rebuildVariables()

    rebuildVariables: ->
        @allVariables = {}
        @allProperties = {}
        if @parent
            for name, v of @parent.allVariables
                @allVariables[name] = v
            for name, v of @parent.allProperties
                @allProperties[name] = v
        for v in @variables
            if v.name.$
                @allProperties[v.name.$] = v
            else
                @allVariables[v.name] = v
        if @children
            c.rebuildVariables() for c in @children
        return

    properties: extend Object.create(null),
        'costume #': category: 'looks', isWritable: false
        'costume name': category: 'looks', isWritable: false
        'color effect': 'looks'
        'fisheye effect': 'looks'
        'whirl effect': 'looks'
        'pixelate effect': 'looks'
        'mosaic effect': 'looks'
        'brightness effect': 'looks'
        'ghost effect': 'looks'
        'instrument': 'sound'
        'volume': 'sound'

    @property 'variableNames', ->
        (v.name for v in @variables)

    @property 'writableVariableNames', ->
        (v.name for v in @variables when v.isWritable)

    @property 'allVariableNames', ->
        transUnion (v.name for v in @variables), (@parent?.allVariableNames ? [])

    @property 'allWritableVariableNames', ->
        transUnion (v.name for v in @variables when v.isWritable), (@parent?.allWritableVariableNames ? [])

class Stage extends Scriptable
    @WIDTH: 480
    @HEIGHT: 360

    isStage: true

    @property 'stage', -> @

    properties: extend Object.create(Scriptable::properties),
        'backdrop #': category: 'looks', isWritable: false
        'backdrop name': category: 'looks', isWritable: false
        'tempo': 'sound'
        'answer': category: 'sensing', isWritable: false
        'mouse x': category: 'sensing', isWritable: false
        'mouse y': category: 'sensing', isWritable: false
        'mouse down?': category: 'sensing', isWritable: false
        'loudness': category: 'sensing', isWritable: false
        'loud?': category: 'sensing', isWritable: false
        'video transparency': 'sensing'
        'timer': 'sensing'

    @property 'children',
        event: 'ChildrenChange'
        apply: (children, old) ->
            if old
                for c in old
                    c.parent = null
            for c in children
                c.parent = @

    constructor: ->
        super $:'Stage'

    draw: (cx) ->
        if costume = @costumes[@costumeIndex]
            cx.save()

            @applyFilter cx
            cx.drawImage costume.image, 0, 0

            cx.restore()

        for c in @children
            c.draw cx

class Sprite extends Scriptable
    isSprite: true

    properties: extend Object.create(Scriptable::properties),
        'x position': 'motion'
        'y position': 'motion'
        'direction': 'motion'
        'rotation style': 'motion'
        'size': 'looks'
        'layer': 'looks'
        'pen down?': 'pen'
        'pen color': 'pen'
        'pen hue': 'pen'
        'pen lightness': 'pen'
        'pen size': 'pen'

    constructor: (name) ->
        super name

        @onPositionChange @change
        @onDirectionChange @change
        @onVisibleChange @change
        @onScaleChange @change

    x: 0
    y: 0
    @event 'PositionChange'
    moveTo: (x, y) ->
        @x = x
        @y = y
        @dispatch 'PositionChange', new ControlEvent(@)

    @property 'direction',
        value: 90
        event: 'DirectionChange'

    @property 'visible',
        value: true
        event: 'VisibleChange'

    @property 'scale',
        value: 1
        event: 'ScaleChange'

    draw: (cx) ->
        if @visible and @costume
            cx.save()

            cx.translate Stage.WIDTH / 2 + @x, Stage.HEIGHT / 2 - @y
            cx.rotate (@direction - 90) * Math.PI / 180
            cx.scale @scale, @scale
            cx.translate -@costume.rotationCenterX, -@costume.rotationCenterY

            @applyFilter cx

            cx.drawImage @costume.image, 0, 0

            cx.restore()

    @default: ->
        new Sprite tr 'Scratch Cat'

Scriptable.categoryIndex = {}
for k, v of Stage::properties
    Scriptable.categoryIndex[k] = v.category ? v
for k, v of Sprite::properties
    Scriptable.categoryIndex[k] = v.category ? v

class Costume extends Base
    @property 'image', event: 'ImageChange'

    constructor: (@name) ->

class Variable extends Base
    isPersistent: false
    isWritable: true
    category: 'data'

    constructor: (@target, @name, config = 'data') ->
        config = category: config if typeof config is 'string'
        extend @, config

module 'amber.editor.models', {
    Project
    Scriptable
    Stage
    Sprite
    Costume
    Variable
}
