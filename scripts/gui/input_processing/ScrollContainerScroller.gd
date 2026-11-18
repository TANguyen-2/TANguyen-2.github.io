## A Controller [Node] to control the scroll of a [ScrollContainer]
## Using scroll and drag inputs from a [ScrollInputProcessor].
extends Node


## The [ScrollInputProcessor] to receive information from.
@export var scroll_processor: ScrollInputProcessor:
    set(value):
        if scroll_processor != value:
            if scroll_processor:
                scroll_processor.scrolled.disconnect(on_scrolled)
                pass
            scroll_processor = value
            if scroll_processor:
                scroll_processor.scrolled.connect(on_scrolled)
                pass
            pass
        pass

## The [ScrollContainer] to perform scrolling on.
@export var scroll_container: ScrollContainer


func on_scrolled(scroll: Vector2) -> void:
    scroll_container.scroll_horizontal += roundi(scroll.x)
    scroll_container.scroll_vertical += roundi(scroll.y)
    pass
