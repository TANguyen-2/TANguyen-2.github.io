## Helper [Node] to process [InputEventScreenDrag]s
## and [InputEventMouseButton]s (with mouse wheel inputs)
## into scrolling information.
##
## This [Node] receives [signal Control.gui_input] signals
## from a given [Control] and emits a [signal scrolled] signal
## containing the amount of scrolling detected.
extends Node
class_name ScrollInputProcessor
signal scrolled(scroll_vector: Vector2)


## The [Control] to receive
## [signal Control.gui_input] signals from.
@export var input_area: Control:
    set(value):
        if input_area != value:
            if input_area:
                input_area.gui_input.disconnect(_gui_input)
                pass
            input_area = value
            if input_area:
                input_area.gui_input.connect(_gui_input)
                pass
            pass


## The additional scale factor to
## apply to the screen drag (in pixels)
## to get the amount of scrolling that will be performed.
@export var screen_drag_scroll_scale: float = 1

## The amount of scrolling (in pixels) that will be performed
## for each second a mouse wheel button is pressed.
@export var mouse_wheel_scroll_scale: float = 1000

enum INVERT_FLAGS {DRAG_H = 1, DRAG_V = 2, WHEEL_H = 4, WHEEL_V = 8}

## Flags to invert the direction of the inputs
## before calculating the scroll vector.
## [br]
## E.g.: If WHEEL_H is enabled, scrolling right using the mouse wheel
## will correspond to scrolling left instead, and vice versa.
@export_flags(&"DRAG_H", &"DRAG_V", &"WHEEL_H", &"WHEEL_V")
var invert_directions: int = (
    INVERT_FLAGS.DRAG_H | INVERT_FLAGS.DRAG_V | INVERT_FLAGS.WHEEL_H
)

## The key to hold down in order to swap the scroll direciton
## between horizontal and vertical.
## [br]
## This is useful for devices that can only
## scroll vertically or horizontally, but not both.
@export var alt_scroll_key: Key = Key.KEY_SHIFT


func _gui_input(event: InputEvent) -> void:
    ## Process screen drag events into scroll.
    if event is InputEventScreenDrag:
        var scroll: Vector2 = event.relative * screen_drag_scroll_scale
        if invert_directions & INVERT_FLAGS.DRAG_H:
            scroll.x = -scroll.x
            pass
        if invert_directions & INVERT_FLAGS.DRAG_V:
            scroll.y = -scroll.y
            pass
        scrolled.emit(scroll)
        pass
    elif event is InputEventMouseButton and event.is_pressed():
        var scroll_scale: int = roundi(
            mouse_wheel_scroll_scale * get_process_delta_time()
        )
        var scroll: Vector2 = Vector2.ZERO
        match event.button_index:
            MOUSE_BUTTON_WHEEL_UP:
                scroll.y = -scroll_scale
                pass
            MOUSE_BUTTON_WHEEL_DOWN:
                scroll.y = scroll_scale
                pass
            MOUSE_BUTTON_WHEEL_LEFT:
                scroll.x = -scroll_scale
                pass
            MOUSE_BUTTON_WHEEL_RIGHT:
                scroll.x = scroll_scale
                pass
            pass
        if invert_directions & INVERT_FLAGS.WHEEL_H:
            scroll.x = -scroll.x
            pass
        if invert_directions & INVERT_FLAGS.WHEEL_V:
            scroll.y = -scroll.y
            pass
        if Input.is_key_pressed(alt_scroll_key):
            scroll = Vector2(scroll.y, scroll.x)
            pass
        scrolled.emit(scroll)
        pass
    pass
