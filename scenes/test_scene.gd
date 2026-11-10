extends Control


func _input(event):
    if (
        event is InputEventKey and
        not event.is_echo() and
        event.is_pressed()
    ):
        match event.keycode:
            KEY_UP:
                var temp: Array[PagedItemInfo] = $HBoxContainer/PanelContainer/MarginContainer/BoxContainer/PagedItemsPositioner.item_infos
                temp.append(preload("res://projects/thumbnails/P1Thumbnail.tres"))
                $HBoxContainer/PanelContainer/MarginContainer/BoxContainer/PagedItemsPositioner.item_infos = temp
                pass
            KEY_DOWN:
                var temp: Array[PagedItemInfo] = $HBoxContainer/PanelContainer/MarginContainer/BoxContainer/PagedItemsPositioner.item_infos
                if temp.size() > 0:
                    temp.pop_back()
                    pass
                $HBoxContainer/PanelContainer/MarginContainer/BoxContainer/PagedItemsPositioner.item_infos = temp
                pass
            KEY_SPACE:
                $HBoxContainer/PanelContainer/MarginContainer.clip_contents = not (
                    $HBoxContainer/PanelContainer/MarginContainer.clip_contents
                )
                pass
        pass
