shader_type canvas_item;

uniform sampler2D star_map;
uniform sampler2D frequency_map;
uniform float frequency_scale = 10;
uniform float frequency_offset = 0.01;
uniform float amplitude_scale = 2;
uniform float amplitude_offset = 0;
uniform float min_star_value: hint_range(0, 1, 0.01) = 0.75;
uniform float max_star_value: hint_range(0, 1, 0.01) = 1;


void fragment()
{
    float star_value = texture(star_map, UV).x;
    if
    (
        star_value >= min_star_value &&
        star_value <= max_star_value
    )
    {
        COLOR.a = clamp(
            sin
            (
                TIME * PI *
                (
                    frequency_scale *
                    texture(frequency_map, UV).x +
                    frequency_offset
                )
            ) * amplitude_scale + amplitude_offset,
            0, 1
        );
    }
    else
    {
        discard;
    }
}
