extends ScrollContainer


func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenDrag:
        scroll_horizontal -= event.relative.x
        scroll_vertical -= event.relative.y
        pass
    pass
