extends Node
class_name ProjectContentDisplayer


@export var content_panel: Control
@export var content_panel_controller: ContentPanelController:
    set(value):
        if content_panel_controller != value:
            if content_panel_controller:
                content_panel_controller.project_selected.disconnect(on_project_selected)
                content_panel_controller.category_selected.disconnect(on_category_selected)
                pass
            content_panel_controller = value
            if content_panel_controller:
                content_panel_controller.project_selected.connect(on_project_selected)
                content_panel_controller.category_selected.connect(on_category_selected)
                pass
            pass
        pass

@export var project_content_panel: Control
@export var project_content_panel_close_button: Button:
    set(value):
        if project_content_panel_close_button != value:
            if project_content_panel_close_button:
                project_content_panel_close_button.pressed.disconnect(
                    hide_project_content
                )
            project_content_panel_close_button = value
            if project_content_panel_close_button:
                project_content_panel_close_button.pressed.connect(
                    hide_project_content
                )
                pass
            pass
        pass
@export var project_content_container: Control


@export var tooltip_display: Label
@export_multiline(&"monospace") var default_tooltip: String = &""


@export var transition_duration: float = 1


var transition_tween: Tween = null

var current_content: Node = null

var current_project_info: ProjectItemInfo = null

var current_category_info: ProjectCategoryInfo = null


func update_displayed_tooltip() -> void:
    if current_project_info:
        tooltip_display.text = current_project_info.tooltip
        pass
    elif current_category_info:
        tooltip_display.text = current_category_info.tooltip
        pass
    else:
        tooltip_display.text = default_tooltip
        pass
    pass


func on_category_selected(selected_category: ProjectCategoryInfo) -> void:
    current_category_info = selected_category
    update_displayed_tooltip()
    pass


func on_project_selected(selected_project: ProjectItemInfo) -> void:
    current_project_info = selected_project
    if current_project_info:
        var scene_path: = current_project_info.content_scene_path
        current_content = null
        match ResourceLoader.load_threaded_get_status(scene_path):
            ResourceLoader.THREAD_LOAD_LOADED:
                current_content = ResourceLoader.load_threaded_get(
                    scene_path
                ).instantiate()
                project_content_container.add_child(current_content)
                display_project_content()
                pass
            ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
                ResourceLoader.load_threaded_request(scene_path)
                pass
        pass
    update_displayed_tooltip()
    pass


func _process(_delta: float) -> void:
    if current_project_info and not current_content:
        var scene_path: = current_project_info.content_scene_path
        if (
            ResourceLoader.load_threaded_get_status(scene_path) ==
            ResourceLoader.THREAD_LOAD_LOADED
        ):
            current_content = ResourceLoader.load_threaded_get(
                scene_path
            ).instantiate()
            project_content_container.add_child(current_content)
            display_project_content()
            pass
        pass
    pass


func on_display_animation_started() -> void:
    project_content_panel_close_button.disabled = true
    project_content_panel.show()
    project_content_panel.offset_transform_scale = Vector2.ZERO
    content_panel.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
    content_panel.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
    pass

func on_display_animation_finished() -> void:
    project_content_panel_close_button.disabled = false
    content_panel.hide()
    pass

func on_hide_animation_started() -> void:
    project_content_panel_close_button.disabled = true
    content_panel.show()
    pass

func on_hide_animation_finished() -> void:
    project_content_panel_close_button.disabled = true
    project_content_panel.hide()
    project_content_panel.offset_transform_scale = Vector2(1, 1)
    current_project_info = null
    if current_content:
        current_content.queue_free()
        pass
    current_content = null
    update_displayed_tooltip()
    content_panel.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
    content_panel.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
    pass



func display_project_content() -> void:
    if transition_tween and transition_tween.is_valid():
        transition_tween.kill()
        pass
    
    transition_tween = create_tween()

    on_display_animation_started()

    transition_tween.tween_property(
        content_panel, "modulate:a", 0,
        transition_duration
    )
    transition_tween.parallel()
    transition_tween.tween_property(
        project_content_panel, "offset_transform_scale", Vector2(1, 1),
        transition_duration
    )
    transition_tween.chain()
    transition_tween.tween_callback(on_display_animation_finished)
    pass


func hide_project_content() -> void:
    if transition_tween and transition_tween.is_valid():
        transition_tween.kill()
        pass
    
    transition_tween = create_tween()

    on_hide_animation_started()

    transition_tween.tween_property(
        content_panel, "modulate:a", 1.0,
        transition_duration
    )
    transition_tween.parallel()
    transition_tween.tween_property(
        project_content_panel, "offset_transform_scale", Vector2.ZERO,
        transition_duration
    )
    transition_tween.chain()
    transition_tween.tween_callback(on_hide_animation_finished)
    pass
