@tool
extends Button
class_name ProjectItemButton
signal request_show_project(project_info: ProjectItemInfo)


@export var info_res: ProjectItemInfo:
    set(value):
        if info_res != value:
            if info_res:
                info_res.changed.disconnect(update_display)
                pass
            info_res = value
            if info_res:
                info_res.changed.connect(update_display)
                pass
            update_display()
            pass
        pass


func bind(info: ProjectItemInfo) -> void:
    info_res = info
    pass


func update_display() -> void:
    if info_res:
        text = info_res.item_name
        if info_res is ProjectItemInfo:
            icon = load(info_res.icon_path)
            pass
        pass
    else:
        icon = null
        text = &""
        pass
    pass


func _pressed() -> void:
    if info_res:
        request_show_project.emit(info_res)
        pass
    pass
