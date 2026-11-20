@tool
extends Resource
class_name ProjectItemInfo


@export_multiline(&"monospace") var item_displayed_name: String = &"":
    set(value):
        if item_displayed_name != value:
            item_displayed_name = value
            emit_changed()
            pass
        pass

@export var icon_path: StringName = &"":
    set(value):
        if icon_path != value:
            icon_path = value
            emit_changed()
            pass
        pass

@export_multiline(&"monospace") var tooltip: String = &"":
    set(value):
        if tooltip != value:
            tooltip = value
            emit_changed()
            pass
        pass

@export var content_scene_path: StringName = &"":
    set(value):
        if content_scene_path != value:
            content_scene_path = value
            emit_changed()
            pass
        pass