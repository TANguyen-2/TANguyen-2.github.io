## Helper class to check how a reference [Control]
## will be positioned in a [Container]
##
## A [Control] that copies the container sizing properties
## and minimum + maximum sizes of another [Control]
@tool
extends Control
class_name DummyContainerChild


func set_sizing_properties(reference: Control) -> void:
    assert(reference != null)
    size_flags_horizontal = reference.size_flags_horizontal
    size_flags_vertical = reference.size_flags_vertical
    size_flags_stretch_ratio = reference.size_flags_stretch_ratio
    custom_minimum_size = reference.get_combined_minimum_size()
    custom_maximum_size = reference.get_combined_maximum_size()
    pass


func _init() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
    focus_mode = Control.FOCUS_NONE
    focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
    pass
