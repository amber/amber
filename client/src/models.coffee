{ Base, extend, addClass, removeClass, toggleClass, hasClass, format, htmle, htmlu, bbTouch, inBB } = amber.util
{ Event, PropertyEvent, ControlEvent, TouchEvent, WheelEvent } = amber.event

RequestError =
    notFound: 0,
    auth$incorrectCredentials: 1

Group =
    DEFAULT: 1 << 0
    MODERATOR: 1 << 1
    ADMINISTRATOR: 1 << 2

class User extends Base
    constructor: (server) ->
        super()
        @setServer server

    @property 'server'

    @property 'name', apply: (name) ->
        @server.usersByName[name] = @

    @property 'id', apply: (id) ->
        @server.usersById[id] = @

    @property 'group',
        value: 'default'

    @property 'avatarURL', ->
        if @isGuest
            'static/img/default-user.svg'
        else
            id = '' + @id
            trim = id.length - 4
            a = id.substr 0, trim
            b = id.substr trim
            "http://scratch.mit.edu/static/site/users/avatars/#{a}/#{b}.png"

    @property 'profileURL', ->
        if @isGuest
            null
        else
            amber.site.App::abs amber.site.App::reverse 'user.profile', @name

    getAvatar: (size) ->
        "http://cdn.scratch.mit.edu/get_image/user/#{@id}_#{size}x#{size}.png"

    toJSON: ->
        group = @group
        result =
            scratchId: @id
            name: @name

        result.group = group if group isnt 'default'
        result

    fromJSON: (o) ->
        @set
            id: o.scratchId
            name: o.name
            group: o.group ? 'default'

    @guest: ->
        u = new User
        u.isGuest = true
        u._name = $:'Guest'
        u._id = -1
        u

class Server extends Base
    INITIAL_REOPEN_DELAY: 100

    constructor: (socketURL, assetStoreURL) ->
        @socketURL = socketURL
        @assetStoreURL = assetStoreURL
        @requestId = 0
        @requests = {}
        @usersByName = {}
        @usersById = {}
        @userIdCallbacks = {}
        @log = []
        @_sessionId = localStorage.getItem 'sessionId'
        @reopenDelay = @INITIAL_REOPEN_DELAY
        @open()

    open: =>
        @socket = new WebSocket @socketURL
        @socket.onopen = @listeners.open.bind @
        @socket.onclose = @listeners.close.bind @
        @socket.onmessage = @listeners.message.bind @
        @socket.onerror = @listeners.error.bind @
        @socketQueue = []

    @property 'app'

    @property 'sessionId', apply: (sessionId) ->
        localStorage.setItem 'sessionId', sessionId

    on:
        connect: (p) ->
            @app.user = if p.user then (new User @).fromJSON p.user else null
            @setSessionId p.sessionId
            if not @app.initialized
                @app.go location.hash.substr 1
                @app.initialized = true

        result: (p) ->
            request = @requests[p.request$id]
            unless request
                console.warn 'Invalid request id:', p
                return

            request.callback p.result
            delete @requests[p.request$id]

        update: (p) ->
            @app.watcher p.data

        requestError: (p) ->
            request = @requests[p.request$id]
            unless request
                console.warn 'Invalid request id:', p
                return

            if request.error
                request.error p.code
            else
                console.error 'RequestError: ' + @requestErrors[p.code] + ' in ' + request.name, request.options

            delete @requests[p.request$id]

        error: (p) ->
            @app.load 'error', p.name, p.message, p.stack

    requestErrors: [
        'Not found',
        'Incorrect credentials'
    ]

    listeners:
        open: ->
            socketQueue = @socketQueue
            packet = sessionId: @sessionId

            @app.connected = true
            @reopenDelay = @INITIAL_REOPEN_DELAY

            raw = JSON.stringify @encodePacket 'Client', 'connect', packet
            @socket.send raw

            packet.$type = 'connect'
            packet.$time = new Date
            packet.$side = 'Client'

            @log.splice @log.length - socketQueue.length, 0, packet
            config = @app.config

            if config.rawPacketLog
                console.log 'Client:', raw
            if config.livePacketLog
                @logPacket packet

            while packet = socketQueue.pop()
                if config.livePacketLog
                    @logPacket @log[@log.length - socketQueue.length - 1]
                if config.rawPacketLog
                    console.log 'Client:', packet

                @socket.send packet

        close: ->
            @app.connected = false
            console.warn 'Socket closed. Reopening.'
            if @signInErrorCallback
                @signInErrorCallback 'Connection lost.'
                @signInErrorCallback = undefined

            setTimeout @open, @reopenDelay
            if @reopenDelay < 5 * 60 * 1000
                @reopenDelay *= 2

        message: (e) ->
            config = @app.config

            if config.rawPacketLog
                console.log 'Server:', e.data

            packet = @decodePacket 'Server', e.data
            return unless packet

            packet.$time = new Date
            packet.$side = 'Server'

            @log.push packet
            if config.livePacketLog
                @logPacket packet

            if hasOwnProperty.call @on, packet.$type
                @on[packet.$type].call @, packet
            else
                console.warn 'Missed packet:', packet

        error: (e) ->
            console.warn 'Socket error:', e

    decodePacket: (side, packet) ->
        try
            packet = JSON.parse packet
        catch
            console.warn 'Packet syntax error:', packet
            return

        if not packet or typeof packet isnt 'object'
            console.warn 'Invalid packet:', e
            return

        return packet unless packet instanceof Array

        type = packet[0]
        info = PACKETS[side + ':' + type]
        if not info
            console.warn 'Invalid packet type:', packet
            return

        result = {}
        result.$type = type
        i = info.length
        while i--
            result[info[i]] = packet[i + 1]

        result

    encodePacket: (side, type, properties) ->
        if @app.config.verbosePackets
            (properties ?= {}).$type = type
            return properties

        info = PACKETS[side + ':' + type]
        if not info
            console.warn 'Invalid packet type:', type, properties
            return

        i = 0
        l = info.length
        result = [type]
        while i < l
            result.push properties[info[i++]]

        result

    send: (type, properties, censorFields) ->
        config = @app.config

        p = @encodePacket 'Client', type, properties
        return unless p

        log = {}
        log.$type = type
        for key, value of properties
            log[key] = if censorFields and censorFields[key] then '********' else value

        log.$time = new Date
        log.$side = 'Client'
        @log.push log

        packet = JSON.stringify p
        if @socket.readyState isnt 1
            @socketQueue.push packet
            return

        if config.rawPacketLog
            console.log 'Client:', packet
        if config.livePacketLog
            @logPacket log

        @socket.send packet

    request: (name, options, callback, error) ->
        id = ++@requestId
        @requests[id] =
            name: name,
            options: options,
            callback: callback,
            error: error

        options.request$id = id
        @send name, options

    getAsset: (hash) -> @assetStoreURL + hash + '/'

    getUser: (name, callback) ->
        @request 'users.user', { user: name }, (data) ->
            callback (new User @).fromJSON data

    logPacket: (packet) ->
        log = (object, dollar) ->
            for key, value of object when not dollar or key[0] isnt '$'
                if value and typeof value is 'object'
                    console.group "#{key}:"
                    log value
                    console.groupEnd()
                else
                    console.log "#{key}:", value

        time = packet.$time.toLocaleTimeString()
        side = packet.$side
        type = packet.$type

        console.groupCollapsed "[#{time}] #{side}:#{type}"
        log packet, true
        console.groupEnd()

    showLog: ->
        for log in @log
            @logPacket log

module 'amber.models', {
    User
    Group
    RequestError
    Server
}
