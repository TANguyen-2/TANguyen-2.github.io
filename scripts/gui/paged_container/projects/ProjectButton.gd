extends Button


@export var info_res: PagedItemInfo:
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


func bind(info: PagedItemInfo) -> void:
    info_res = info
    pass


func update_display() -> void:
    if info_res:
        text = info_res.item_name
        if info_res is PagedProjectItemInfo:
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
        print(info_res.item_onclick_signal_id)
        pass
    pass
