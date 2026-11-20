extends Node
class_name ContentPanelController
signal project_selected(project: ProjectItemInfo)
signal category_selected(category: ProjectCategoryInfo)


## This variable should only be set once,
## when the main panel is first added to the scene.
@export var projects_paged_container: PagedContainer:
    set(value):
        if projects_paged_container != value:
            if projects_paged_container:
                projects_paged_container.sort_children.disconnect(
                    on_projects_container_resorted
                )
                pass
            projects_paged_container = value
            if projects_paged_container:
                projects_paged_container.sort_children.connect(
                    on_projects_container_resorted
                )
                pass
            pass
        pass

## This variable should only be set once,
## when the main panel is first added to the scene.
@export var projects_paged_scroller: PagedContainerScroller:
    set(value):
        if projects_paged_scroller != value:
            if projects_paged_scroller:
                projects_paged_scroller.tracked_item_changed.disconnect(
                    on_tracked_project_changed
                )
                pass
            projects_paged_scroller = value
            if projects_paged_scroller:
                projects_paged_scroller.tracked_item_changed.connect(
                    on_tracked_project_changed
                )
                pass
            pass
        pass

## This variable should only be set once,
## when the main panel is first added to the scene.
@export var pages_paged_container: PagedContainer

## This variable should only be set once,
## when the main panel is first added to the scene.
@export var pages_paged_scroller: PagedContainerScroller


## This variable should only be set once,
## when the main panel is first added to the scene.
@export var project_button_instance: PackedScene
@export var project_button_pool: NodePool = NodePool.new():
    set(value):
        project_button_pool = value
        project_button_pool.creation_function = create_project_button
        pass

## This variable should only be set once,
## when the main panel is first added to the scene.
@export var page_button_instance: PackedScene
## This variable should only be set once,
## when the main panel is first added to the scene.
@export var page_button_group: ButtonGroup = ButtonGroup.new()
@export var page_button_pool: NodePool = NodePool.new():
    set(value):
        page_button_pool = value
        page_button_pool.creation_function = create_page_button
        pass


@export var selected_category: ProjectCategoryInfo = null:
    set(value):
        selected_category = value
        load_category_projects()
        category_selected.emit(selected_category)
        pass

@export var selected_project: ProjectItemInfo = null:
    set(value):
        selected_project = value
        project_selected.emit(selected_project)
        pass


func create_project_button() -> ProjectItemButton:
    return project_button_instance.instantiate()

func new_project_button() -> ProjectItemButton:
    return project_button_pool.get_instance()

func remove_project_button(project_button: ProjectItemButton) -> void:
    project_button.get_parent().remove_child(project_button)
    project_button_pool.pool_instance(project_button)
    pass


func create_page_button() -> Button:
    return page_button_instance.instantiate()

func new_page_button() -> Button:
    return page_button_pool.get_instance()

func remove_page_button(page_button: Button) -> void:
    page_button.get_parent().remove_child(page_button)
    page_button_pool.pool_instance(page_button)
    pass



func on_tracked_project_changed() -> void:
    # Set the tracked page in the pages container
    # to the currently tracked page in the projects container.
    # Additionally press the corresponding button.
    var tracked_page: int = projects_paged_scroller.get_tracked_page()
    pages_paged_scroller.tracked_visible_item = (tracked_page)
    (
        pages_paged_container.get_child(tracked_page) as Button
    ).button_pressed = true
    pass



var page_selected_callback_map: Dictionary[Button, Callable] = {}
func set_project_page(page_index: int) -> void:
    projects_paged_scroller.tracked_visible_item = (
        projects_paged_container.get_page_visible_item_index_range(
            page_index
        )[0]
    )
    pass

func on_projects_container_resorted() -> void:
    var page_count: = projects_paged_container.get_page_count()
    var page_buttons: Array[Control] = (
        pages_paged_container.get_visible_child_controls()
    )

    # Reset the tab focus functionality.
    if page_buttons.size() > 0:
        page_buttons[0].focus_previous = NodePath()
        page_buttons.back().focus_next = NodePath()
        pass

    if page_count < page_buttons.size():
        for i in range(page_buttons.size() - 1, page_count - 1, -1):
            var button: Button = page_buttons.pop_back()
            button.pressed.disconnect(page_selected_callback_map[button])
            page_selected_callback_map.erase(button)
            button.button_group = null
            remove_page_button(button)
            pass
        pass
    elif page_count > pages_paged_container.get_child_count():
        for i in range(page_buttons.size(), page_count):
            var button: Button = new_page_button()
            var page_selected_callback: Callable = set_project_page.bind(i)
            page_selected_callback_map[button] = page_selected_callback
            button.pressed.connect(page_selected_callback)
            button.text = str(i + 1)
            button.button_group = page_button_group
            pages_paged_container.add_child(button)
            page_buttons.append(button)
            pass
        pass

    # Make it so that the tab focus functionality loops back.
    if page_buttons.size() > 0:
        page_buttons[0].focus_previous = NodePath(
            &"../" + page_buttons.back().name
        )
        page_buttons.back().focus_next = NodePath(
            &"../" + page_buttons[0].name
        )
        pass

    # Track and press the page button
    # corresponding to the currently tracked project page.
    var tracked_page: int = projects_paged_scroller.get_tracked_page()
    pages_paged_scroller.tracked_visible_item = tracked_page
    if tracked_page < page_buttons.size():
        page_buttons[tracked_page].button_pressed = true
        pass
    pass


var project_selected_callback_map: Dictionary[ProjectItemButton, Callable] = {}
func set_selected_project(project_button: ProjectItemButton) -> void:
    selected_project = project_button.info_res
    projects_paged_scroller.tracked_visible_item = project_button.get_index()
    pass

func load_category_projects() -> void:
    var project_count: = 0
    if selected_category:
        project_count = selected_category.projects.size()
        pass
    var project_buttons: Array[Control] = (
        projects_paged_container.get_visible_child_controls()
    )

    # Reset the tab focus functionality.
    if project_buttons.size() > 0:
        project_buttons[0].focus_previous = NodePath()
        project_buttons.back().focus_next = NodePath()
        pass

    # Number of project buttons to update with
    # the new ProjectItemInfos from the selected category.
    var unupdated_button_count: int
    if project_count < project_buttons.size():
        unupdated_button_count = project_count
        for i in range(project_buttons.size() - 1, project_count - 1, -1):
            var button: ProjectItemButton = project_buttons.pop_back()
            button.bind(null)
            button.pressed.disconnect(project_selected_callback_map[button])
            project_selected_callback_map.erase(button)
            remove_project_button(button)
            pass
        pass
    elif project_count > pages_paged_container.get_child_count():
        unupdated_button_count = project_buttons.size()
        for i in range(project_buttons.size(), project_count):
            var button: ProjectItemButton = new_project_button()
            var project_selected_callback: Callable = (
                set_selected_project.bind(button)
            )
            project_selected_callback_map[button] = (
                project_selected_callback
            )
            button.pressed.connect(project_selected_callback)
            button.bind(selected_category.projects[i])
            projects_paged_container.add_child(button)
            project_buttons.append(button)
            pass
        pass
    else:
        unupdated_button_count = project_count
        pass
    
    # Make it so that the tab focus functionality loops back.
    if project_buttons.size() > 0:
        project_buttons[0].focus_previous = NodePath(
            &"../" + project_buttons.back().name
        )
        project_buttons.back().focus_next = NodePath(
            &"../" + project_buttons[0].name
        )
        pass

    # Rebind remaining old buttons.
    for i in range(unupdated_button_count):
        var button: ProjectItemButton = project_buttons[i]
        button.bind(selected_category.projects[i])
        pass

    selected_project = null
    projects_paged_scroller.tracked_visible_item = 0
    pass
