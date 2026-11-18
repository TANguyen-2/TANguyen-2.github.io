## A Controller [Node] that adjusts
## the offset transform of a [PagedContainer] so that
## the top-left corner of a specific page in the [member paged_container]
## aligns with what would be the top-left corner
## of the [member paged_container] if no offsets were applied.
## [br]
## [br]
## This [Node] assumes that:
## [br]
## - This [Node] has exclusive control over
## the offset transform of the [member paged_container].
## [br]
## - The [member paged_container] has [member Control.clip_contents] disabled.
## [br]
## - The [member paged_container] has
## [member Control.offset_transform_enabled] enabled.
## [br]
## - The [member paged_container] is the child of
## a [Control] with [member Control.clip_contents] enabled.
## - The top-left corner of the [member paged_container]
## aligns with that of said parent [Control].
extends Node


# These values should be set once and never changed.
# The code to account for changing these values will be too bloated,
# and will slow down development or performace.
@export var paged_container: PagedContainer
@export var prev_page_button: Button
@export var next_page_button: Button


@export_range(0, 1, 0.0001)
var scroll_distance_mul_factor: float = 0.0001


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

## The amount of time (in seconds) to wait after
## the last detected scroll input before activating autoscroll.
@export var wait_before_autoscroll: float = 0.25

## The amount of time (in seconds) elapsed
## since the last detected scroll input.
var time_since_scroll_end: float = 0


## The index of the tracked visible [Control] child
## of the [member paged_container].
## [br]
## The [member paged_container] will be offsetted
## such that the top-left corner of the page containing the tracked item
## aligns with what would be the top-left corner
## of the [member paged_container] if no offsets were applied.
var tracked_visible_item: int = 0


## Get the index of the page in the [member paged_container]
## with the top-left corner closest to the [param check_position]
## relative to the top-left corner of the [member paged_container].
## [br]
## This method is used to find the item to track when the page scrolling stops.
func get_nearest_page_index(check_position: Vector2) -> int:
    var page_rects: Array[Rect2] = paged_container.get_page_rects()
    if page_rects.size() > 1:
        # Limit the position to the bounds of the page's top-left corners.
        check_position = check_position.clamp(
            Vector2.ZERO, page_rects.back().position
        )
        var page_stride: Vector2 = (
            page_rects[1].position - page_rects[0].position
        )
        return max(
            roundi(check_position.x / page_stride.x),
            roundi(check_position.y / page_stride.y)
        )
    else:
        return 0


## Get the index of the page in [member paged_container]
## containing the [member tracked_visible_item].
func get_tracked_page() -> int:
    return paged_container.get_visible_item_page_index(tracked_visible_item)


func next_page() -> void:
    var current_page: = get_tracked_page()
    # Get the page of the tracked visible item,
    # then move onto the next page, and
    # set the first visible item of that page
    tracked_visible_item = (
        paged_container.get_page_visible_item_index_range(
            current_page + 1
        )[0]
    )
    update_page_change_button_state()
    pass

func prev_page() -> void:
    var current_page: = get_tracked_page()
    # Get the page of the tracked visible item,
    # then move onto the previous page, and
    # set the first visible item of that page
    tracked_visible_item = (
        paged_container.get_page_visible_item_index_range(
            current_page - 1
        )[0]
    )
    update_page_change_button_state()
    pass


func on_page_item_focused(focused_item_index: int) -> void:
    if tracked_visible_item != focused_item_index:
        var old_page: = get_tracked_page()
        tracked_visible_item = focused_item_index
        var current_page: = get_tracked_page()
        if old_page != current_page:
            update_page_change_button_state()
            pass
        pass
    pass


func update_page_change_button_state() -> void:
    var current_page: = get_tracked_page()
    if current_page <= 0:
        prev_page_button.disabled = true
        pass
    else:
        prev_page_button.disabled = false
        pass
    
    if current_page + 1 >= paged_container.get_page_count():
        next_page_button.disabled = true
        pass
    else:
        next_page_button.disabled = false
        pass
    pass


## Return the [member paged_container] offset transform position that
## aligns the top-left corner of the page containing the tracked item
## with the top-left corner of the [member paged_container].
func get_tracked_page_scroll_position() -> Vector2:
    # This offset transform is simply the negative of
    # the local position of the page in the paged_container.
    return -paged_container.get_page_rects()[get_tracked_page()].position


func snap_to_target_page_scroll() -> void:
    # Get the page of the tracked visible item,
    # and set the offset transform position of the paged container
    # to the negative of the position of said page.
    paged_container.offset_transform_position = (
        get_tracked_page_scroll_position()
    )
    pass


var focus_reaction_map: Dictionary[Control, Callable] = {}
func track_page_item_focus_entered(item: Control) -> void:
    var focus_reaction: Callable = on_page_item_focused.bind(
        item.get_index()
    )
    item.focus_entered.connect(focus_reaction)
    focus_reaction_map[item] = focus_reaction
    pass

func untrack_page_item_focus_entered(item: Control) -> void:
    item.focus_entered.disconnect(focus_reaction_map[item])
    focus_reaction_map.erase(item)
    pass


func clamp_offset_position() -> void:
    paged_container.offset_transform_position = (
        paged_container.offset_transform_position.clamp(
            paged_container.size - paged_container.get_pages_bound_size(),
            Vector2.ZERO
        )
    )
    pass


func on_items_resorted() -> void:
    snap_to_target_page_scroll()
    update_page_change_button_state()
    clamp_offset_position()
    pass


func setup_paged_container() -> void:
    paged_container.sort_children.connect(on_items_resorted)
    for item in paged_container.get_visible_child_controls():
        track_page_item_focus_entered(item)
        pass
    paged_container.child_entered_tree.connect(track_page_item_focus_entered)
    paged_container.child_exiting_tree.connect(untrack_page_item_focus_entered)
    pass


func on_scrolled(scroll: Vector2) -> void:
    time_since_scroll_end = 0
    paged_container.offset_transform_position -= scroll
    clamp_offset_position()
    var current_page: int = get_tracked_page()
    var new_page: int = get_nearest_page_index(
        -paged_container.offset_transform_position
    )
    tracked_visible_item = paged_container.get_page_visible_item_index_range(
        new_page
    )[0]
    if current_page != new_page:
        update_page_change_button_state()
        pass
    pass


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    setup_paged_container()
    next_page_button.pressed.connect(next_page)
    prev_page_button.pressed.connect(prev_page)
    pass # Replace with function body.


func _process(delta: float) -> void:
    if time_since_scroll_end < wait_before_autoscroll:
        time_since_scroll_end += delta
        pass
    else:
        # Slowly scroll towards the target if we are not close enough.
        var target_scroll_position: = get_tracked_page_scroll_position()
        var current_scroll_position: = paged_container.offset_transform_position
        if not current_scroll_position.is_equal_approx(target_scroll_position):
            paged_container.offset_transform_position = (
                (current_scroll_position - target_scroll_position) *
                pow(scroll_distance_mul_factor, delta) +
                target_scroll_position
            )
            pass
        pass
    pass
