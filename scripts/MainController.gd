extends Node
class_name MainController


@export var custom_boot_screen: Control
@export var boot_progress_bar: ProgressBar
@export var main_panel_path: StringName
@export var main_panel_container: Control

@export var main_panel_fade_in_duration: float = 1;
@export var main_panel_fade_in_start_relative_offset = Vector2(0, 1)

var main_panel_load_ended: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    set_process(false)
    ResourceLoader.load_threaded_request(main_panel_path)
    custom_boot_screen.show()
    set_process(true)
    pass


func _process(_delta: float) -> void:
    if !main_panel_load_ended:
        var main_panel_load_progress: Array[float] = []
        var main_panel_load_status: = ResourceLoader.load_threaded_get_status(
            main_panel_path, main_panel_load_progress
        )
        if main_panel_load_status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            if main_panel_load_status == ResourceLoader.THREAD_LOAD_LOADED:
                var main_panel: Control = ResourceLoader.load_threaded_get(
                    main_panel_path
                ).instantiate()
                main_panel_container.add_child(main_panel)

                # Animate the transition.
                main_panel.modulate.a = 0
                main_panel.offset_transform_position_ratio = (
                    main_panel_fade_in_start_relative_offset
                )
                var tween: = create_tween()
                tween.tween_property(
                    main_panel, "modulate:a", 1, main_panel_fade_in_duration
                ).set_ease(Tween.EASE_IN)
                tween.parallel()
                tween.tween_property(
                    main_panel, "offset_transform_position_ratio",
                    Vector2.ZERO, main_panel_fade_in_duration
                ).set_ease(Tween.EASE_IN)
                tween.play()

                # Hide the boot screen.
                if boot_progress_bar:
                    boot_progress_bar.value = 1
                    pass
                tween = create_tween()
                tween.tween_property(
                    custom_boot_screen, "modulate:a", 0, main_panel_fade_in_duration
                ).set_ease(Tween.EASE_IN)
                tween.tween_callback(custom_boot_screen.hide)
                tween.tween_property(custom_boot_screen, "modulate:a", 1, 0)
                tween.play()
                pass
            else:
                push_error(&"Failed to load the portfolio's main panel.")
                if boot_progress_bar:
                    boot_progress_bar.value = 0
                    pass
                pass
            
            main_panel_load_ended = true
            set_process(false)
            pass
        
        elif boot_progress_bar:
            boot_progress_bar.value = main_panel_load_progress[0]
            pass
        pass
    pass
