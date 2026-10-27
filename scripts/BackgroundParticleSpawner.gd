@tool
extends GPUParticles2D


@export var background_rect: Control:
    set(value):
        if background_rect != value:
            if background_rect:
                background_rect.resized.disconnect(on_background_resized)
                pass
            background_rect = value
            background_rect.resized.connect(on_background_resized)
            update_particle_amount()
            pass

@export_range(0, 1, 0.0001) var area_to_particle_scale: float = 0.0001:
    set(value):
        if area_to_particle_scale != value:
            area_to_particle_scale = value
            update_particle_amount()
            pass
        pass

@export_range(0, 1000, 1, &"or_greater") var max_particle_count: int = 1000:
    set(value):
        if area_to_particle_scale != value:
            area_to_particle_scale = value
            update_particle_amount()
            pass
        pass

func _ready() -> void:
    pass


# When the background control is resized,
# resize the emission box and draw rect to cover all of the control.
func on_background_resized() -> void:
    var rect_extents: Vector2 = background_rect.size / 2
    process_material.emission_box_extents.x = rect_extents.x
    process_material.emission_box_extents.y = rect_extents.y
    process_material.emission_shape_offset.x = rect_extents.x
    process_material.emission_shape_offset.y = rect_extents.y
    visibility_rect.size = background_rect.size
    update_particle_amount()
    pass


# Update the amount of particles that can be spawned,
# based on the area of the background rect.
func update_particle_amount() -> void:
    if background_rect:
        amount = clampi(int(
            process_material.emission_box_extents.x *
            process_material.emission_box_extents.y *
            area_to_particle_scale),
            1, max_particle_count
        )
        pass
    pass
