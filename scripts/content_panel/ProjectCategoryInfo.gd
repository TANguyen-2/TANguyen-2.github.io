@tool
extends Resource
class_name ProjectCategoryInfo


@export var category_name: StringName = &"":
    set(value):
        if category_name != value:
            category_name = value
            emit_changed()
            pass
        pass

@export var projects: Array[ProjectItemInfo] = []:
    set(value):
        if projects != value:
            projects = value
            emit_changed()
            pass
        pass

@export_multiline(&"monospace") var tooltip: String = &"":
    set(value):
        if tooltip != value:
            tooltip = value
            emit_changed()
            pass