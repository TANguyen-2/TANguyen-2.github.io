extends Resource
class_name PagedItemInfo


@export var item_name: StringName = &"":
    set(value):
        item_name = value
        emit_changed()
        pass
@export var item_onclick_signal_id: StringName = &"":
    set(value):
        item_onclick_signal_id = value
        emit_changed()
        pass
