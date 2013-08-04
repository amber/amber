{ Base, extend, addClass, removeClass, toggleClass, hasClass, format, htmle, htmlu, bbTouch, inBB } = amber.util
{ Event, PropertyEvent, ControlEvent, TouchEvent, WheelEvent } = amber.event
{ getText: tr } = amber.locale

class Project extends Base
    @property 'name', event: 'NameChange'

    constructor: ->
        @name = tr 'Untitled'

class Scriptable extends Base
    @id: 0

    @property 'costume', event: 'CostumeChange'
    @property 'costumeIndex',
        get: -> @costumes.indexOf @costume
        set: (i) -> @costume = @costumes[i]

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

    constructor: (@name) ->
        @id = ++Scriptable.id
        @children = []
        @costumes = []

class Stage extends Scriptable
    constructor: ->
        super tr 'Stage'

class Sprite extends Scriptable
    constructor: (name) ->
        super name

    @default: ->
        new Sprite tr 'Scratch Cat'

class Costume extends Base
    @property 'image', event: 'ImageChange'

    constructor: (@name) ->

module 'amber.editor.models', {
    Project
    Stage
    Sprite
}
