## Helper [Node] to process [InputEventScreenDrag]s
## into scrolling for [ScrollContainer]s.
##
## This [Node] receives [signal Control.gui_input] signals
## from a given [Control] and correspondingly
## scrolls a given [ScrollContainer].
extends Node
class_name ScrollDragProcessor


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

## The [ScrollContainer] to perform scrolling on.
@export var scroll_container: ScrollContainer

## The additional scale factor to
## apply to the screen drag (in pixels)
## to get the amount of scrolling that will be performed.
@export var screen_drag_scroll_scale: float = -1

## The amount of scrolling (in pixels) that will be performed
## for each second a mouse wheel button is pressed.
@export var mouse_wheel_scroll_scale: float = 1000

## The key to hold down in order to swap the scroll direciton
## between horizontal and vertical.
## [br]
## This is useful for devices that can only
## scroll vertically or horizontally, but not both.
@export var alt_scroll_key: Key = Key.KEY_SHIFT


func _gui_input(event: InputEvent) -> void:
    ## Process screen drag events into scroll.
    if event is InputEventScreenDrag:
        var scroll: Vector2i = event.relative * screen_drag_scroll_scale
        scroll_container.scroll_horizontal += scroll.x
        scroll_container.scroll_vertical += scroll.y
        pass
    elif event is InputEventMouseButton and event.is_pressed():
        var scroll_scale: int = roundi(
            mouse_wheel_scroll_scale * get_process_delta_time()
        )
        var scroll: Vector2i = Vector2i.ZERO
        match event.button_index:
            MOUSE_BUTTON_WHEEL_UP:
                scroll.y = -scroll_scale
                pass
            MOUSE_BUTTON_WHEEL_DOWN:
                scroll.y = scroll_scale
                pass
            MOUSE_BUTTON_WHEEL_LEFT:
                scroll.x = scroll_scale
                pass
            MOUSE_BUTTON_WHEEL_RIGHT:
                scroll.x = -scroll_scale
                pass
            pass
        if Input.is_key_pressed(alt_scroll_key):
            scroll = Vector2i(scroll.y, scroll.x)
            pass
        scroll_container.scroll_horizontal += scroll.x
        scroll_container.scroll_vertical += scroll.y
        pass
    pass
