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


func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenDrag:
        scroll_container.scroll_horizontal -= event.relative.x
        scroll_container.scroll_vertical -= event.relative.y
        pass
    pass
