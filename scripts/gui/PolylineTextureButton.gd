@tool
extends Button


@export var point_anchors: PackedVector2Array = []:
    set(value):
        point_anchors = value
        point_offsets.resize(point_anchors.size())
        queue_redraw()
        pass

@export var point_offsets: PackedVector2Array = []:
    set(value):
        point_offsets = value
        point_anchors.resize(point_offsets.size())
        queue_redraw()
        pass

@export var antialiased: bool = true:
    set(value):
        if antialiased != value:
            antialiased = value
            queue_redraw()
            pass
        pass

@export_range(0, 10, 0.1) var line_weight: float = 2:
    set(value):
        if line_weight != value:
            line_weight = value
            queue_redraw()
        pass


func get_local_polyline() -> PackedVector2Array:
    assert(point_anchors.size() == point_offsets.size())
    var polyline: PackedVector2Array = []
    for i in range(0, point_offsets.size()):
        polyline.push_back(
            point_anchors[i] * size + point_offsets[i]
        )
        pass
    return polyline


func get_icon_color() -> Color:
    if disabled:
        return get_theme_color(&"icon_disabled_color")
    elif is_hovered():
        if pressed:
            return get_theme_color(&"icon_hover_pressed_color")
        else:
            return get_theme_color(&"icon_hover_color")
    elif pressed:
        return get_theme_color(&"icon_pressed_color")
    elif has_focus():
        return get_theme_color(&"icon_focus_color")
    else:
        return get_theme_color(&"icon_normal_color")
    


func _draw() -> void:
    var polyline: PackedVector2Array = get_local_polyline()
    if polyline.size() >= 2:
        var icon_color: Color = get_icon_color()
        draw_polyline(get_local_polyline(), icon_color, line_weight, antialiased)
        pass
    pass
