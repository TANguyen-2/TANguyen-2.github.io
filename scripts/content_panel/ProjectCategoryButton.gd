extends Button
class_name ProjectCategoryButton


@export var info_res: ProjectCategoryInfo

@export var content_panel_controller: ContentPanelController


func _pressed() -> void:
    content_panel_controller.selected_category = info_res
    pass
