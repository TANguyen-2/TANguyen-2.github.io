## A [Container] that arranges its items into [FlowContainer] pages.
##
## A [Container] that arranges its items into [FlowContainer] pages
## based on the specified [member page_ref] [FlowContainer].
## [br]
## If adding an item to a page will cause the bounds of the items to
## exceed the maximum size of the page,
## the item will be overflowed to the next page instead.
## [br]
## The pages are further arranged as if they are children of a [BoxContainer]
## based on the specified [member page_container_ref] [BoxContainer].
## [br]
## [br]
## [b]Note:[/b]
## [br]
## Due to how this class is set up, the items are arranged based on
## the size-related properties of the
## [member page_ref] and [member page_container_ref] containers,
## and are unaffected by the size-related properties
## of the [PagedContainer] itself.
## [br]
## [br]
## It is recommended that each [PagedContainer] at bare minimum has the same
## size in the secondary axis as its [member page_container_ref], and that
## the maximum sizes of all 3 containers follow the order:
## [code]self[/code] >= [member page_container_ref] >= [member page_ref].
## [br]
## [br]
## This container cannot automatically react to changes in the
## layout properties, theme properties, and custom minimum/maximum sizes
## of the [member page_ref] and [member page_container_ref] containers.
## [br]
## [br]
## This container additionally assumes that
## the [member Control.custom_minimum_size] of the [member page_ref]
## is exclusively controlled by this container itself, and that
## the the [member page_ref] and [member page_container_ref] containers
## have no child [Control]s other than the ones
## added by this container itself.
@tool
extends Container
class_name PagedContainer


@export var page_container_ref: BoxContainer

@export var page_ref: FlowContainer


@export var dummy_pool: NodePool = NodePool.new():
    set(value):
        assert(value != null)
        dummy_pool = value
        dummy_pool.creation_function = create_dummy_container_child
        pass


## The array of local rects in which each page is fitted,
## not accounting for any offset transforms.
var page_rects: Array[Rect2] = []

## The array of page indices
## each visible child [Control]s is fitted into.
var visible_item_pages: PackedInt32Array = []


## Get the array of local rects in which each page is fitted,
## not accounting for any offset transforms.
func get_page_rects() -> Array[Rect2]:
    return page_rects

## Get the index of the page which the item with the given index
## in the array of visible child [Control]s is conceptually fitted into.
## [br]
## If no item with the given index has been arranged,
## return [code]-1[/code] instead.
func get_visible_item_page_index(visible_child_index: int) -> int:
    if visible_child_index > visible_item_pages.size():
        return -1
    return visible_item_pages[visible_child_index]


func _notification(what: int) -> void:
    if what == NOTIFICATION_SORT_CHILDREN:
        fake_sort_children()
        pass
    pass


func get_visible_child_controls() -> Array[Control]:
    var child_controls: Array[Control] = []
    for child in get_children():
        if child is Control and child.visible:
            child_controls.append(child)
            pass
        pass
    return child_controls


func fake_sort_children() -> void:
    var item_ranges: PackedVector2Array = []
    var child_controls: Array[Control] = get_visible_child_controls()
    
    var check_start_index: int = 0
    var single_page_item_bound_size: Vector2 = Vector2.ZERO
    while check_start_index < child_controls.size():
        var page_bound_info: = get_items_bound_for_page(
            page_ref, child_controls, check_start_index, true
        )
        item_ranges.append(
            Vector2(check_start_index, page_bound_info[0])
        )
        check_start_index = int(page_bound_info[0])
        single_page_item_bound_size.x = page_bound_info[1]
        single_page_item_bound_size.y = page_bound_info[2]
        pass
    
    # If there needs to be more than 1 page,
    # set the minimum size of each page to its maximum size
    if item_ranges.size() > 1:
        var page_max_size: Vector2 = page_ref.get_combined_maximum_size()
        if page_max_size.x >= 0:
            page_ref.custom_minimum_size.x = page_max_size.x
            page_ref.size.x = page_max_size.x
            pass
        if page_max_size.y >= 0:
            page_ref.custom_minimum_size.y = page_max_size.y
            page_ref.size.y = page_max_size.y
            pass
        pass
    # Otherwise, if there is only 1 page,
    # set the minimum size of the page so that
    # as many items can be contained on a single line as possible.
    elif item_ranges.size() == 1:
        page_ref.custom_minimum_size = single_page_item_bound_size
        page_ref.size = single_page_item_bound_size
        pass
    
    # Get the rect that each item is fitted in relative to its page.
    var dummy_pages: Array[DummyContainerChild] = []
    var child_page_local_rects: Array[Rect2] = []
    
    dummy_pages.resize(item_ranges.size())
    
    for i in range(item_ranges.size()):
        var dummy_page: = new_dummy_container_child()
        child_page_local_rects += get_page_local_child_rects(
            page_ref, child_controls,
            floori(item_ranges[i].x), floori(item_ranges[i].y), dummy_page
        )
        dummy_pages[i] = dummy_page
        page_container_ref.add_child(dummy_page)
        pass
    
    # Ensure that the page container is of the correct size,
    # and then calculate the positions of its children within it.
    page_container_ref.size = page_container_ref.size.max(
        page_container_ref.get_bound_minimum_size()
    )
    page_container_ref.notification(NOTIFICATION_SORT_CHILDREN)
    page_rects.resize(item_ranges.size())
    
    for i in range(dummy_pages.size()):
        page_rects[i] = Rect2(dummy_pages[i].position, dummy_pages[i].size)
        remove_dummy_container_child(dummy_pages[i])
        pass
    
    # Use the position of each page to calculate
    # the position of each item relative to this container.
    visible_item_pages.resize(child_controls.size())
    for p in range(dummy_pages.size()):
        for i in range(floori(item_ranges[p][0]), floori(item_ranges[p][1])):
            var child_rect: Rect2 = child_page_local_rects[i]
            child_rect.position += dummy_pages[p].position
            fit_child_in_rect(
                child_controls[i], child_rect
            )
            visible_item_pages[i] = p
            pass
        pass
    pass


func _get_minimum_size() -> Vector2:
    if page_ref:
        var child_controls: Array[Control] = get_visible_child_controls()
        var items_bound_info: = get_items_bound_for_page(
            page_ref, child_controls, 0, true
        )
        if items_bound_info[0] < child_controls.size():
            return page_container_ref.get_combined_maximum_size()
        else:
            return page_container_ref.get_combined_maximum_size().min(
                Vector2(items_bound_info[1], items_bound_info[2])
            )
    else:
        return Vector2.ZERO


## Helper method to check how many items starting from the given index
## can be fit onto a given [param page],
## such that no items are smaller than their bound minimum size
## (assuming said size is no greater than
## the maximum size of the [param page]), and
## no items overlap with each other or exceed the page's maximum size.
## [br]
## Returns an array containing (in the following order):
## [br]
## 0. The first index offset after [code]items[start_index][/code]
## that cannot be added to the page.
## [br]
## 1. The width of the rect in which all of said items are fitted on the page.
## [br]
## 2. The height of the rect in which all of said items are fitted on the page.
## [br]
## [br]
## [b]Note:[/b]
## [br]
## Each page must contain at least 1 item.
## [br]
## The width and height of the bounding rect is only returned if
## [param get_bound_size] is [code]true[/code].
func get_items_bound_for_page(
    page: FlowContainer, items: Array[Control], start_index: int = 0,
    get_bound_size: bool = false
) -> PackedFloat32Array:
    if start_index >= items.size():
        return [0, 0, 0]
    
    var max_page_size: Vector2 = page.get_combined_maximum_size()

    # Edge case where the page size has no maximum limit in either dimension.
    if max_page_size.x < 0 or max_page_size.y < 0:
        if !get_bound_size:
            return [items.size()]
        else:
            max_page_size = Vector2(INF, INF)
            pass
        pass

    ## Either the width or height of the
    ## Bounding Rect size of the content on the page.
    var content_bound_size: Vector2 = Vector2.ZERO
    ## Current Bounding Rect size of the line the next item will be added to.
    var line_bound_size: Vector2 = Vector2.ZERO

    var current_spacing: Vector2 = Vector2.ZERO
    var item_separation: Vector2 = Vector2(
        page.get_theme_constant(&"h_separation"),
        page.get_theme_constant(&"v_separation")
    )

    var index_offset: int = start_index

    ## The minimum required size of the Control to add.
    var item_size: Vector2 = items[index_offset].get_combined_minimum_size()
    
    """
    # Assert that the Control can actually be stored on a page.
    # Otherwise, this will either loop indefinitely,
    # or the outer method will infinitely create new pages
    # in an attempt to arrange a Control that is too big to be arranged.
    assert(
        (max_page_size.x < 0 or line_bound_size.x <= max_page_size.x) and
        (max_page_size.y < 0 or line_bound_size.y <= max_page_size.y)
    )
    """

    # Pre-emptively add 1 item so that each page has at least 1 item.
    line_bound_size = item_size
    current_spacing.x = item_separation.x
    index_offset += 1
    
    ## Track if the latest line is empty.
    var empty_line: bool = false
    
    if index_offset >= items.size():
        if get_bound_size:
            return [index_offset, line_bound_size.x, line_bound_size.y]
        else:
            return [index_offset]
    
    # Swap the x and y components of sizing parameters
    # to change from horizontal to vertical orientation.
    if page.vertical:
        line_bound_size = Vector2(line_bound_size.y, line_bound_size.x)
        max_page_size = Vector2(max_page_size.y, max_page_size.x)
        item_separation = Vector2(item_separation.y, item_separation.x)
        pass
    
    item_size = items[index_offset].get_combined_minimum_size()
    if page.vertical:
        item_size = Vector2(item_size.y, item_size.x)
        pass

    # Add items row by row.
    # Check if adding the item to the current line
    # will exceed the height of the page.
    while (
        content_bound_size.y + max(line_bound_size.y, item_size.y) + current_spacing.y
    ) <= max_page_size.y:
        # Check if adding another item to the current line
        # will exceed the width of the page.
        if line_bound_size.x + item_size.x + current_spacing.x <= max_page_size.x:
            empty_line = false
            
            line_bound_size.x += item_size.x + current_spacing.x
            line_bound_size.y = max(line_bound_size.y, item_size.y)

            index_offset += 1
            if index_offset >= items.size():
                break
    
            item_size = items[index_offset].get_combined_minimum_size()
            if page.vertical:
                item_size = Vector2(item_size.y, item_size.x)
                pass
            current_spacing.x = item_separation.x
            pass
        # If the item cannot be added to the current line, move to the next one.
        else:
            empty_line = true
            
            content_bound_size.x = max(content_bound_size.x, line_bound_size.x)
            content_bound_size.y += line_bound_size.y + current_spacing.y
            line_bound_size = Vector2.ZERO
            current_spacing.y = item_separation.y
            current_spacing.x = 0
            pass
        pass
    
    if get_bound_size:
        # Add everything together to get the content bound size.
        content_bound_size.x = max(content_bound_size.x, line_bound_size.x)
        # Only add spacing if the next line is not empty.
        if !empty_line:
            content_bound_size.y += line_bound_size.y + current_spacing.y
            pass
        
        # If the page is in vertical orientation, then
        # the x and y components had been swapped during calculation.
        # Thus, they must be swapped again to be the correct value.
        if page.vertical:
            content_bound_size = Vector2(
                content_bound_size.y, content_bound_size.x
            )
            pass
        return [index_offset, content_bound_size.x, content_bound_size.y]
    else:
        return [index_offset]


static func create_dummy_container_child() -> DummyContainerChild:
    return DummyContainerChild.new()

func new_dummy_container_child() -> DummyContainerChild:
    return dummy_pool.get_instance()

func remove_dummy_container_child(dummy: DummyContainerChild) -> void:
    dummy.get_parent().remove_child(dummy)
    dummy_pool.pool_instance(dummy)
    pass


## Helper method to get the rects to fit
## a subarray of [Control]s [code]items[start_index:end_index][/code]
## into a [FlowContainer] [param page], and optionally
## copy the container sizing parameters of the [param page] after sorting
## into a given [DummyContainerChild] [param page_container_sizing_info].
func get_page_local_child_rects(
    page: FlowContainer, items: Array[Control],
    start_index: int, end_index: int,
    page_container_sizing_info: DummyContainerChild = null
) -> Array[Rect2]:
    var dummies: Array[DummyContainerChild] = []
    for i in range(start_index, end_index):
        var dummy: = new_dummy_container_child()
        dummy.set_sizing_properties(items[i])
        dummies.append(dummy)
        page.add_child(dummy)
        pass
    page.notification(NOTIFICATION_SORT_CHILDREN)
    if page_container_sizing_info:
        page_container_sizing_info.set_sizing_properties(page)
        pass
    
    var local_child_rects: Array[Rect2] = []
    for dummy in dummies:
        local_child_rects.append(Rect2(
            dummy.position, dummy.size
        ))
        remove_dummy_container_child(dummy)
        pass
    return local_child_rects
