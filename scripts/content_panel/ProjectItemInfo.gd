@tool
extends Resource
class_name ProjectItemInfo


@export_multiline(&"monospace") var item_name: String = &"":
    set(value):
        item_name = value
        emit_changed()
        pass

@export var icon_path: StringName = &"":
    set(value):
        icon_path = value
        emit_changed()
        pass