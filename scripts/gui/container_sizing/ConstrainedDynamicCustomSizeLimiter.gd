## A [DynamicCustomSizeLimiter] that limits the setted
## custom minimum/maximum size to be no greater/smaller
## than the size of a constraint [Control].
@tool
extends DynamicCustomSizeLimiter
class_name ConstrainedDynamicCustomSizeLimiter

## The [Control] to limit the set value for
## the [member target]'s custom minimum/maximum size.
## [br]
## If given, the custom maximum size cannot be set
## smaller than the size of this [Control], and
## the custom minimum size cannot be set
## greater than the size of this [Control].
## [br]
## If not given, no constraints will be applied.
@export var constraint: Control:
    set(value):
        if constraint != value:
            if constraint:
                constraint.resized.disconnect(update_limit)
                pass
            constraint = value
            if constraint:
                constraint.resized.connect(update_limit)
                pass
            update_limit()
            pass


func _get_set_minimum_size() -> Vector2:
    if reference:
        if constraint:
            return reference.size.min(constraint.size)
        else:
            return reference.size
    else:
        return Vector2.ZERO

func _get_set_maximum_size() -> Vector2:
    if reference:
        if constraint:
            return reference.size.max(constraint.size)
        else:
            return reference.size
    else:
        return Vector2(-1, -1)
