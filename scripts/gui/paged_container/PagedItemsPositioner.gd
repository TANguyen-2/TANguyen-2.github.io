extends Node
class_name PagedItemsPositioner


var pages: Array[FlowContainer] = []
var page_items: Array[Control] = []


@export var paged_container: BoxContainer:
    set(value):
        if paged_container != value:
            assert(value != null)
            if paged_container:
                for page in pages:
                    paged_container.remove_child(page)
                    pass
                pass
            paged_container = value
            for page in pages:
                paged_container.add_child(page)
                pass
            queue_update_arrangement()
            pass
        pass
    
@export var item_separation: Vector2i = Vector2i(10, 10):
    set(value):
        if item_separation != value:
            item_separation = value
            for page in pages:
                page.add_theme_constant_override(
                    &"h_separation", item_separation.x
                )
                page.add_theme_constant_override(
                    &"v_separation", item_separation.y
                )
                pass
            queue_update_arrangement()
            pass
        pass

@export var align_items_in_columns: bool = false:
    set(value):
        if align_items_in_columns != value:
            align_items_in_columns = value
            for page in pages:
                page.vertical = align_items_in_columns
                pass
            queue_update_arrangement()
            pass
        pass

@export var item_infos: Array[PagedItemInfo] = []:
    set(value):
        item_infos = value
        queue_update_item_list()
        pass

@export var item_template: PackedScene:
    set(value):
        assert(value != null)
        for item in page_items:
            remove_item(item)
            pass
        page_items.resize(0)
        item_pool.clear_pooled_instances()
        item_template = value
        queue_update_item_list()
        pass

@export var page_template: PackedScene:
    set(value):
        assert(value != null)
        for item in page_items:
            item.get_parent().remove_child(item)
            pass
        for page in pages:
            remove_page(page)
            pass
        pages.resize(0)
        page_pool.clear_pooled_instances()
        page_template = value
        queue_update_arrangement()
        pass

@export var item_pool: NodePool = NodePool.new():
    set(value):
        assert(value != null)
        item_pool = value
        item_pool.creation_function = create_item
        pass

@export var page_pool: NodePool = NodePool.new():
    set(value):
        assert(value != null)
        page_pool = value
        page_pool.creation_function = create_page
        pass


## Helper method to check how many items starting from the given index
## can be fit onto a page within the [member paged_container],
## such that no items are smaller than their bound minimum size
## (assuming said size is no greater than
## the maximum size of the [member paged_container]), and
## the page size is no greater than that of the [member paged_container].
## [br]
## Returns the index offset for the first item after
## [code]items[start_index][/code] that cannot be added to the same page.
## [br]
## [br]
## [b]Note:[/b] Each page must contain at least 1 item.
func get_items_range_for_page(items: Array[Control], start_index: int = 0) -> int:
    var max_page_size: Vector2 = paged_container.get_combined_maximum_size()

    # Edge case where the page size has no maximum limit in either dimension.
    if max_page_size.x < 0 or max_page_size.y < 0:
        return items.size()

    ## Either the width or height of the
    ## Bounding Rect size of the content on the page.
    var content_bound_size: float = 0
    ## Current Bounding Rect size of the line the next item will be added to.
    var line_bound_size: Vector2 = Vector2.ZERO

    var current_spacing: Vector2 = Vector2.ZERO
    var default_spacing: Vector2 = item_separation

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
    
    # Swap the x and y components of sizing parameters
    # to change from horizontal to vertical orientation.
    if align_items_in_columns:
        item_size = Vector2(item_size.y, item_size.x)
        max_page_size = Vector2(max_page_size.y, max_page_size.x)
        default_spacing = Vector2(default_spacing.y, default_spacing.x)
        pass

    # Pre-emptively add 1 item so that each page has at least 1 item.
    line_bound_size = item_size
    current_spacing.x = default_spacing.x
    index_offset += 1
    if index_offset >= page_items.size():
        return index_offset
    
    item_size = items[index_offset].get_combined_minimum_size()
    if align_items_in_columns:
        item_size = Vector2(item_size.y, item_size.x)
        pass

    # Add items row by row.
    # Check if adding the item to the current line
    # will exceed the height of the page.
    while (
        content_bound_size + max(line_bound_size.y, item_size.y) + current_spacing.y
    ) <= max_page_size.y:
        # Check if adding another item to the current line
        # will exceed the width of the page.
        if line_bound_size.x + item_size.x + current_spacing.x <= max_page_size.x:
            line_bound_size.x += item_size.x + current_spacing.x
            line_bound_size.y = max(line_bound_size.y, item_size.y)

            index_offset += 1
            if index_offset >= items.size():
                return index_offset
    
            item_size = items[index_offset].get_combined_minimum_size()
            if align_items_in_columns:
                item_size = Vector2(item_size.y, item_size.x)
                pass
            current_spacing.x = default_spacing.x
            pass
        # If the item cannot be added to the current line, move to the next one.
        else:
            content_bound_size += line_bound_size.y + current_spacing.y
            line_bound_size = Vector2.ZERO
            current_spacing.y = default_spacing.y
            current_spacing.x = 0
            pass
        pass
    return index_offset


## Helper method to get the number of pages required to contain all given [param items],
## and the index ranges for the items that should be arranged within each page,
## such that no items are smaller than their bound minimum size
## (assuming said size is no greater than
## the maximum size of the [member paged_container]), and
## the size of each page is no greater than that of the [member paged_container].
## [br]
## Returns an array of [Vector2] [code]page_items_ranges[/code] where
## [code]page_items_ranges[p] = (s, e)[/code] means that
## the items within the subarray [code]items[s:e][/code]
## (not including [code]items[e][/code])
## should be arranged within the page with index [code]p[/code].
func calculate_item_arrangements(items: Array[Control]) -> PackedVector2Array:
    ## Array of index ranges where each range describes
    ## the number of items that should be arranged within the page with the given index.
    var page_items_ranges: PackedVector2Array = []
    
    ## Index of the first item on the current page.
    var page_item_start_index: int = 0

    while page_item_start_index < items.size():
        var page_item_end_index: int = get_items_range_for_page(
            page_items, page_item_start_index
        )
        page_items_ranges.append(Vector2(page_item_start_index, page_item_end_index))
        page_item_start_index = page_item_end_index
        pass
    
    return page_items_ranges


func create_item() -> Control:
    return item_template.instantiate()

func new_item() -> Control:
    var item: Control = item_pool.get_instance()
    item.minimum_size_changed.connect(queue_update_arrangement)
    item.maximum_size_changed.connect(queue_update_arrangement)
    return item

func remove_item(item: Control) -> void:
    # Clear the parent of the page item (remove it from the scene),
    # disconnect it from all relevant listeners,
    # and return it back to the pool.
    var item_parent: = item.get_parent()
    if item_parent:
        item_parent.remove_child(item)
        pass
    item.minimum_size_changed.disconnect(queue_update_arrangement)
    item.maximum_size_changed.disconnect(queue_update_arrangement)
    item_pool.pool_instance(item)
    pass


func create_page() -> FlowContainer:
    var page: FlowContainer = page_template.instantiate()
    page.vertical = align_items_in_columns
    page.add_theme_constant_override(&"h_separation", item_separation.x)
    page.add_theme_constant_override(&"v_separation", item_separation.y)
    page.custom_minimum_size = Vector2.ZERO
    page.custom_maximum_size = Vector2(-1, -1)
    return page

func new_page() -> Control:
    var page: FlowContainer = page_pool.get_instance()
    paged_container.add_child(page)
    return page

func remove_page(page: FlowContainer) -> void:
    # Clear the parent of the page (remove it from the scene),
    # and return it back to the pool.
    paged_container.remove_child(page)
    page_pool.pool_instance(page)
    pass



## Generate items based on the [member item_infos] array.
## [br]
## [br]
## This method should be called when any of the following occurs:[br]
## 1. The [member item_infos] array is changed.[br]
func configure_items_from_info() -> void:
    if page_items.size() > item_infos.size():
        for i in range(item_infos.size(), page_items.size()):
            remove_item(page_items[i])
            pass
        page_items.resize(item_infos.size())
        pass
    else:
        for i in range(page_items.size(), item_infos.size()):
            page_items.append(new_item())
            pass
        pass
    
    # Bind the item infos to their respective items.
    for i in range(item_infos.size()):
        page_items[i].bind(item_infos[i])
        pass
    pass


var item_list_update_queued: bool = false
var arrangement_update_queued: bool = false

func queue_update_item_list() -> void:
    if !(item_list_update_queued or arrangement_update_queued):
        update_content.call_deferred()
        pass
    item_list_update_queued = true
    arrangement_update_queued = true
    pass

func queue_update_arrangement() -> void:
    if !(item_list_update_queued or arrangement_update_queued):
        update_content.call_deferred()
        pass
    arrangement_update_queued = true
    pass


func update_content() -> void:
    if item_list_update_queued:
        configure_items_from_info()
        pass
    if arrangement_update_queued:
        arrange_items()
        pass
    item_list_update_queued = false
    arrangement_update_queued = false
    pass


## Generate pages and arrange items into them.
## [br]
## [br]
## This method should be called when any of the following occurs:[br]
## 1. The maximum size for the paged container is changed.[br]
## 2. The minimum size for any item is changed.[br]
## 3. The  [member item_infos] array is changed.[br]
## 4. The [member item_separation] is changed.[br]
## 5. The flow direction of items in a page
## ([member align_items_in_column]) is changed.[br]
func arrange_items() -> void:
    var page_items_ranges: = calculate_item_arrangements(page_items)
    
    if pages.size() > page_items_ranges.size():
        for i in range(page_items_ranges.size(), pages.size()):
            remove_page(pages[i])
            pass
        pages.resize(page_items_ranges.size())
        pass
    else:
        for i in range(pages.size(), page_items_ranges.size()):
            # Get a page from the pool to have enough items.
            pages.append(new_page())
            pass
        pass
    
    # Arrange items into their respective pages.
    for i in range(page_items_ranges.size()):
        var page: FlowContainer = pages[i]
        # For each page, add all items within the specified index range.
        for j in range(page_items_ranges[i].x, page_items_ranges[i].y):
            # For each item, if it already has a parent, use reparent.
            var page_item_parent: = page_items[j].get_parent()
            if page_item_parent:
                page_items[j].reparent(page)
                pass
            # Otherwise, use add_child method of the given page.
            else:
                page.add_child(page_items[j])
                pass
            pass
        pass
    
    var max_page_size: = paged_container.get_combined_maximum_size()
    if pages.size() == 1:
        # Make the page large enough to hold all items on 1 line,
        # overflowing only when the maximum size prevents
        # all of them from fitting within the same line.
        # No clamping is required for the minimum size,
        # since the engine will limit it to the maximum_size automatically.
        var min_line_length: float = 0
        
        var page: FlowContainer = pages[0]
        page.custom_maximum_size = max_page_size
        
        if align_items_in_columns:
            for item in page_items:
                min_line_length += item.get_bound_minimum_size().y
                pass
            min_line_length += max((page_items.size() - 1), 0) * item_separation.y
            page.custom_minimum_size = Vector2(0, min_line_length)
            pass
        else:
            for item in page_items:
                min_line_length += item.get_bound_minimum_size().x
                pass
            min_line_length += max((page_items.size() - 1), 0) * item_separation.x
            page.custom_minimum_size = Vector2(min_line_length, 0)
            pass    
        pass
    elif pages.size() > 1:
        for page in pages:
            page.custom_minimum_size = max_page_size
            page.custom_maximum_size = max_page_size
            pass
        pass
    pass
