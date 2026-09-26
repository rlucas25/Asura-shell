precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture2D(tex, v_texcoord);
    // Reduce blue and slightly adjust green for warm night light effect
    pixColor.r = min(1.0, pixColor.r * 1.02);
    pixColor.g = pixColor.g * 0.88;
    pixColor.b = pixColor.b * 0.68;
    gl_FragColor = pixColor;
}
