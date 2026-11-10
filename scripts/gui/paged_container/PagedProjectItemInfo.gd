extends PagedItemInfo
class_name PagedProjectItemInfo


@export var icon_path: StringName = &"":
    set(value):
        icon_path = value
        emit_changed()
        pass
