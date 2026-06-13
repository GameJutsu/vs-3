shader_type canvas_item;
// Hit Flash Shader — Canvas Item
// When flash_intensity is 1.0, the entire sprite turns the flash_color.
// When 0.0, the sprite renders normally. We tween between these values
// to create the classic damage or status flashes.

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    vec4 base_color = tex_color * COLOR;
    COLOR = mix(base_color, vec4(flash_color.rgb, base_color.a), flash_intensity * flash_color.a);
}
