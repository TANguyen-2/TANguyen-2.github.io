## Helper [Node] to set the custom minimum/maximum size
## of a target [Control] based on
## the size of a reference [Control].
@tool
extends Node
class_name DynamicCustomSizeLimiter


## The [Control] to set the custom minimum/maximum size of.
@export var target: Control:
    set(value):
        if target != value:
            target = value
            update_limit()
            pass
        pass


## The [Control] to get the custom minimum/maximum size from.
## [br]
## If not given, the custom minimum/maximum size
## of the [member target] is set to its default value.
@export var reference: Control:
    set(value):
        if reference != value:
            if reference:
                reference.resized.disconnect(update_limit)
                pass
            reference = value
            if reference:
                reference.resized.connect(update_limit)
                pass
            update_limit()
            pass


## Flags to indicate whether or not
## the custom minimum/maximum size will be set.
enum LIMIT_SET_FLAGS {
    SET_MIN_X = 1, SET_MIN_Y = 2,
    SET_MAX_X = 4, SET_MAX_Y = 8,
}

## Flags to indicate whether or not
## the custom minimum/maximum size will be set.
@export_flags(
    &"SET_MIN_X:1", &"SET_MIN_Y:2",
    &"SET_MAX_X:4", &"SET_MAX_Y:8"
)
var limit_set_flags: int = 0:
    set(value):
        if limit_set_flags != value:
            limit_set_flags = value
            update_limit()
            pass
        pass


## Helper method to get the custom minimum size to set,
## if this [Node] is made to set the custom minimum size.
##
## This can be overriden to perform
## custom minimum size calculations.
func _get_set_minimum_size() -> Vector2:
    if reference:
        return reference.size
    else:
        return Vector2.ZERO

## Helper method to get the custom minimum size to set,
## if this [Node] is made to set the custom maximum size.
##
## This can be overriden to perform
## custom maximum size calculations.
func _get_set_maximum_size() -> Vector2:
    if reference:
        return reference.size
    else:
        return Vector2(-1, -1)


func update_limit() -> void:
    if target:
        if limit_set_flags & (
            LIMIT_SET_FLAGS.SET_MIN_X |
            LIMIT_SET_FLAGS.SET_MIN_Y
        ) != 0:
            var custom_min_size: = _get_set_minimum_size()
            if limit_set_flags & LIMIT_SET_FLAGS.SET_MIN_X != 0:
                target.custom_minimum_size.x = custom_min_size.x
                pass
            if limit_set_flags & LIMIT_SET_FLAGS.SET_MIN_Y != 0:
                target.custom_minimum_size.y = custom_min_size.y
                pass
            pass
        if limit_set_flags & (
            LIMIT_SET_FLAGS.SET_MAX_X |
            LIMIT_SET_FLAGS.SET_MAX_Y
        ) != 0:
            var custom_max_size: = _get_set_maximum_size()
            if limit_set_flags & LIMIT_SET_FLAGS.SET_MAX_X != 0:
                target.custom_maximum_size.x = custom_max_size.x
                pass
            if limit_set_flags & LIMIT_SET_FLAGS.SET_MAX_Y != 0:
                target.custom_maximum_size.y = custom_max_size.y
                pass
            pass
