{ Base } = amber.util

class Event extends Base
  setEvent: (e) ->
    @alt = e.altKey
    @ctrl = e.ctrlKey
    @meta = e.metaKey
    @shift = e.shiftKey
    @

class PropertyEvent extends Event
  @property 'object'
  @property 'previousObject'

class ControlEvent extends Event
  constructor: (@control) ->

  @property 'control'

class TouchEvent extends Event
  setTouchEvent: (e, touch) ->
    @setEvent e
    @x = touch.clientX
    @y = touch.clientY
    @id = touch.identifier ? 0
    @radiusX = touch.radiusX ? 10
    @radiusY = touch.radiusY ? 10
    @angle = touch.rotationAngle ? 0
    @force = touch.force ? 1
    @

  setMouseEvent: (e) ->
    @setEvent e
    @x = e.clientX
    @y = e.clientY
    @id = -1
    @radiusX = .5
    @radiusY = .5
    @angle = 0
    @force = 1
    @

class WheelEvent extends Event
  @property 'allowDefault'

  setWebkitEvent: (e) ->
    @setEvent e
    @x = -e.wheelDeltaX / 3
    @y = -e.wheelDeltaY / 3
    @

  setMozEvent: (e) ->
    @setEvent e
    @x = 0
    @y = e.detail
    @

module 'amber.event', {
  Event
  PropertyEvent
  ControlEvent
  TouchEvent
  WheelEvent
}
