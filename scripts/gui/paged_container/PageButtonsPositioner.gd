extends Node
class_name PageItemsPositioner


@export var paged_container: BoxContainer
@export var item_separation: Vector2 = Vector2(10, 10)
@export var align_items_in_columns: bool = false


var pages: Array[FlowContainer] = []
var items: Array[Control] = []


func fill_page_with_items(
    page: FlowContainer, index_offset: int = 0
) -> int:
    var original_offset: int = index_offset
    var max_page_size: Vector2 = paged_container.get_combined_maximum_size()

    if max_page_size == Vector2.ZERO:
        for i in range(index_offset, items.size()):
            items[i].reparent(page)
            pass
        return items.size() - index_offset

    ## Either the width or height of the
    ## Bounding Rect size of the content on the page.
    var content_bound_size: float = 0
    ## Current Bounding Rect size of the line the next item will be added to.
    var line_bound_size: Vector2 = Vector2.ZERO

    var spacing: Vector2 = Vector2.ZERO
    var item_separation: Vector2 = item_separation

    ## The minimum required size of the Control to add.
    var item_size: Vector2 = items[index_offset].get_combined_minimum_size()
    
    # Assert that the Control can actually be stored on a page.
    # Otherwise, this will either loop indefinitely,
    # or the outer method will infinitely create new pages
    # in an attempt to arrange a Control that is too big to be arranged.
    assert(
        line_bound_size.x <= max_page_size.x and
        line_bound_size.y <= max_page_size.y
    )
    
    # Swap the x and y components of sizing parameters
    # to change from horizontal to vertical orientation.
    if align_items_in_columns:
        item_size = Vector2(item_size.y, item_size.x)
        max_page_size = Vector2(max_page_size.y, max_page_size.x)
        item_separation = Vector2(item_separation.y, item_separation.x)
        pass

    # Add items row by row.
    # Check if adding the item to the current line
    # will exceed the height of the page.
    while (
        content_bound_size + max(line_bound_size.y, item_size.y) + spacing.y
    ) <= max_page_size.y:
        # Check if adding another item to the current line
        # will exceed the width of the page.
        if line_bound_size.x + item_size.x + spacing.x <= max_page_size.x:
            items[index_offset].reparent(page)
            line_bound_size.x += item_size.x + spacing.x
            line_bound_size.y = max(line_bound_size.y, item_size.y)

            index_offset += 1
            if index_offset > items.size():
                break
            
            item_size = items[index_offset].get_combined_minimum_size()
            if page.vertical:
                item_size = Vector2(item_size.y, item_size.x)
                pass
            spacing.x = item_separation.x
            pass
        # If the item cannot be added to the current line, move to the next one.
        else:
            content_bound_size += line_bound_size.y + spacing.y
            line_bound_size = Vector2.ZERO
            spacing.y = item_separation.y
            spacing.x = 0
            pass
        pass
    return index_offset - original_offset


# Rearrange items among pages.
# This should be called when any of the following occurs:
# 1. The maximum size for the paged container is changed.
# 2. The minimum size for any item is changed.
# 3. The number of items is changed.
# 4. The item separation is changed.
func arrange_items() -> void:
    var filled_page_count: int = 0
    var arranged_item_count: int = 0

    # Try to fill up all pages
    while filled_page_count < pages.size():
        arranged_item_count += fill_page_with_items(
            pages[filled_page_count], arranged_item_count
        )
        filled_page_count += 1
        # Quit when all items have been arranged.
        if arranged_item_count >= items.size():
            break
        pass

    # If there are some unfilled pages
    # (only occurs when the above loop was exited by the break statement),
    # delete the unfilled pages.
    for i in range(filled_page_count, pages.size()):
        pages[filled_page_count].queue_free()
        pass
    
    # If there are some unarranged items,
    # (only occurs when the above loop was not exited by the break statement),
    # add more pages to arrange those items into.
    while arranged_item_count < items.size():
        var page: FlowContainer = FlowContainer.new()
        add_child(page)
        arranged_item_count += fill_page_with_items(
            page, arranged_item_count
        )
        pass
    pass
