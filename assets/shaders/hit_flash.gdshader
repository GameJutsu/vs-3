shader_type canvas_item;
// Hit Flash Shader — Canvas Item
// When flash_intensity is 1.0, the entire sprite turns pure white.
// When 0.0, the sprite renders normally. We tween between these values
// to create the classic "damage flash" seen in almost every 2D action game.

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    // Mix between the original pixel color and pure white, preserving alpha
    COLOR = mix(tex_color, vec4(1.0, 1.0, 1.0, tex_color.a), flash_intensity);
}
