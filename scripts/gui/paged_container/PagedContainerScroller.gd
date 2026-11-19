## A Controller [Node] that adjusts the
## offset transform of a [PagedContainer].
##
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
## [br]
## - The [member paged_container] only has visible
## [Control]s as its children.
## [br]
## - Every page of the [member paged_container] is of the same size.
## [br]
## The [member paged_container] can add and remove its children.
## However, in such case, the [member tracked_visible_item] of this Controller
## must be manually updated before the [member paged_container]
## re-sorts its children.
extends Node
class_name PagedContainerScroller
signal tracked_item_changed()


# These values should be set once and never changed.
# The code to account for changing these values will be too bloated,
# and will slow down development or performace.
@export var paged_container: PagedContainer
@export var prev_page_button: Button
@export var next_page_button: Button


@export_range(0, 1, 0.0001)
var autoscroll_distance_shrink_factor: float = 0.0001


## The [Control] to detect the scroll start.
@export var scroll_start_detection_area: Control:
    set(value):
        if scroll_start_detection_area != value:
            if scroll_start_detection_area:
                scroll_start_detection_area.gui_input.disconnect(
                    on_scroll_start_detection_area_input
                )
                pass
            scroll_start_detection_area = value
            if scroll_start_detection_area:
                scroll_start_detection_area.gui_input.connect(
                    on_scroll_start_detection_area_input
                )
                pass
            pass
        pass


@export_flags(&"LEFT:1", &"RIGHT:2", &"MIDDLE:4", &"EXTRA1:128", &"EXTRA2:256")
var manual_scroll_mouse_mask: int = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_MIDDLE

@export var manual_scroll_input_scale_factor: Vector2 = Vector2(-1, -1)


## The amount of time (in seconds) elapsed
## since the last detected scroll input.
var manually_scrolling: bool = false

var previous_mouse_scroll_global_position: Vector2


## The index of the tracked visible [Control] child
## of the [member paged_container].
## [br]
## The [member paged_container] will be offsetted
## such that the top-left corner of the page containing the tracked item
## aligns with what would be the top-left corner
## of the [member paged_container] if no offsets were applied.
var tracked_visible_item: int = 0:
    set(value):
        if tracked_visible_item != value:
            tracked_visible_item = value
            tracked_item_changed.emit()
            pass
        pass


## Get the index of the page in the [member paged_container]
## with the top-left corner closest to the [param check_position]
## relative to the top-left corner of the [member paged_container].
## [br]
## This method is used to find the item to track when the page scrolling stops.
func get_nearest_page_index(check_position: Vector2) -> int:
    if paged_container.get_page_count() > 1:
        var page_rects: Array[Rect2] = paged_container.get_page_rects()
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
    if paged_container.get_page_count() > 0:
        return paged_container.get_visible_item_page_index(tracked_visible_item)
    else:
        return 0


func next_page() -> void:
    var page_count: int = paged_container.get_page_count()
    if page_count > 0:
        # Get the page of the tracked visible item,
        # then move onto the next page, and
        # set the first visible item of that page.
        # If the next page exceeds the range of available pages,
        # loop back to 0.
        var current_page: = (get_tracked_page() + 1) % page_count
        tracked_visible_item = (
            paged_container.get_page_visible_item_index_range(
                current_page
            )[0]
        )
        update_page_change_button_state()
        pass
    pass

func prev_page() -> void:
    var page_count: int = paged_container.get_page_count()
    if page_count > 0:
        # Get the page of the tracked visible item,
        # then move onto the previous page, and
        # set the first visible item of that page.
        # If the next page exceeds the range of available pages,
        # loop back to 0.
        var current_page: = get_tracked_page() - 1
        if current_page < 0:
            current_page = (
                (page_count - 1) +
                ((current_page + 1) % page_count)
            )
            pass
        tracked_visible_item = (
            paged_container.get_page_visible_item_index_range(
                current_page
            )[0]
        )
        update_page_change_button_state()
        pass
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
    # If we have at most 1 page, changing the page is impossible.
    if paged_container.get_page_count() <= 1:
        prev_page_button.disabled = true
        next_page_button.disabled = true
        pass
    else:
        prev_page_button.disabled = false
        next_page_button.disabled = false
        pass
    pass


## Return the [member paged_container] offset transform position that
## aligns the top-left corner of the page containing the tracked item
## with the top-left corner of the [member paged_container].
func get_tracked_page_scroll_position() -> Vector2:
    if paged_container.get_page_count() > 0:
        # This offset transform is simply the negative of
        # the local position of the page in the paged_container.
        return -paged_container.get_page_rects()[get_tracked_page()].position
    else:
        return Vector2.ZERO


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


## Clamp the given [param offset] position such that
## the un-offsetted bounding box
## of the [member paged_contaier] is always contained
## in the bounding box (offsetted by the given position) for all of the pages
## (if the former is no larger than the latter in any dimension).
## [br]
## If the bounding box of the [member paged_container] is larger
## than the bounding box for all of the pages in any dimension,
## then the offset position in that dimension is always set to 0.
## [br]
## Returns the clamped offset position.
func clamp_offset_position(offset: Vector2) -> Vector2:
    if paged_container.get_page_count() > 0:
        var pages_bound_size: Vector2 = paged_container.get_pages_bound_size()
        var container_bound_size: Vector2 = paged_container.size
        
        # If the bounding box for all of the pages is smaller than
        # that of the paged_container in the x-dimension,
        # set the x-offset to 0.
        if pages_bound_size.x <= container_bound_size.x:
            offset.x = 0
            pass
        # Otherwise, clamp it between 0 (max)
        # (so that the bounding box of all the pages covers the left side
        # of the unoffsetted bounding box of the paged_container)
        # and container_bound_size.x - pages_bound_size.x (min)
        # (so that the bounding box of all the pages covers the right side
        # of the unoffsetted bounding box of the paged_container).
        else:
            offset.x = clampf(
                offset.x, container_bound_size.x - pages_bound_size.x, 0
            )
            pass
        
        # If the bounding box for all of the pages is smaller than
        # that of the paged_container in the y-dimension,
        # set the y-offset to 0.
        if pages_bound_size.y <= container_bound_size.y:
            offset.y = 0
            pass
        # Otherwise, clamp it between 0 (max)
        # (so that the bounding box of all the pages covers the top side
        # of the unoffsetted bounding box of the paged_container)
        # and container_bound_size.x - pages_bound_size.x (min)
        # (so that the bounding box of all the pages covers the bottom side
        # of the unoffsetted bounding box of the paged_container).
        else:
            offset.y = clampf(
                offset.y, container_bound_size.y - pages_bound_size.y, 0
            )
            pass
        return offset
    else:
        return Vector2.ZERO


func on_items_resorted() -> void:
    snap_to_target_page_scroll()
    update_page_change_button_state()
    paged_container.offset_transform_position = clamp_offset_position(
        paged_container.offset_transform_position
    )
    pass


func setup_paged_container() -> void:
    paged_container.sort_children.connect(on_items_resorted)
    for item in paged_container.get_visible_child_controls():
        track_page_item_focus_entered(item)
        pass
    paged_container.child_entered_tree.connect(track_page_item_focus_entered)
    paged_container.child_exiting_tree.connect(untrack_page_item_focus_entered)
    pass




func on_scroll_start_detection_area_input(input: InputEvent) -> void:
    if (
        input is InputEventMouse and input.is_pressed() and
        input.button_mask & manual_scroll_mouse_mask != 0
    ):
        manually_scrolling = true
        previous_mouse_scroll_global_position = (
            scroll_start_detection_area.get_global_mouse_position()
        )
        pass
    pass

func process_manual_scrolling(_delta: float) -> void:
    if Input.get_mouse_button_mask() & manual_scroll_mouse_mask == 0:
        manually_scrolling = false
        return
    
    var current_mouse_scroll_global_position: Vector2 = (
        scroll_start_detection_area.get_global_mouse_position()
    )
    var scroll: = (
        current_mouse_scroll_global_position -
        previous_mouse_scroll_global_position
    ) * manual_scroll_input_scale_factor

    previous_mouse_scroll_global_position = current_mouse_scroll_global_position
    
    paged_container.offset_transform_position = clamp_offset_position(
        paged_container.offset_transform_position - scroll
    )
    if paged_container.get_page_count() > 0:
        var current_page: int = get_tracked_page()
        var new_page: int = get_nearest_page_index(
            -paged_container.offset_transform_position
        )
        tracked_visible_item = (
            paged_container.get_page_visible_item_index_range(new_page)[0]
        )
        if current_page != new_page:
            update_page_change_button_state()
            pass
        pass
    pass


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    setup_paged_container()
    next_page_button.pressed.connect(next_page)
    prev_page_button.pressed.connect(prev_page)
    pass # Replace with function body.


func _process(delta: float) -> void:
    if manually_scrolling:
        process_manual_scrolling(delta)
        pass
    if not manually_scrolling:
        # Slowly scroll towards the target if we are not close enough.
        var target_scroll_position: = clamp_offset_position(
            get_tracked_page_scroll_position()
        )
        var current_scroll_position: = paged_container.offset_transform_position
        if not current_scroll_position.is_equal_approx(target_scroll_position):
            paged_container.offset_transform_position = (
                (current_scroll_position - target_scroll_position) *
                pow(autoscroll_distance_shrink_factor, delta) +
                target_scroll_position
            )
            pass
        pass
    pass
