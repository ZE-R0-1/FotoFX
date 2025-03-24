//
//  Effects.glsl
//  FotoFX
//
//  Created by USER on 3/23/25.
//

precision mediump float;

varying vec2 v_texCoord;
uniform sampler2D u_texture;
uniform float u_intensity;

// 빈티지 필터
vec4 applyVintageFilter(vec4 color) {
    vec3 sepia = vec3(
        color.r * 0.393 + color.g * 0.769 + color.b * 0.189,
        color.r * 0.349 + color.g * 0.686 + color.b * 0.168,
        color.r * 0.272 + color.g * 0.534 + color.b * 0.131
    );
    
    // 약간의 색조를 추가
    vec3 tint = vec3(1.2, 1.0, 0.8);
    vec3 result = sepia * tint;
    
    // 약간의 비네팅 효과 추가
    float d = length(v_texCoord - vec2(0.5, 0.5));
    float vignette = 1.0 - d * 0.6;
    
    return vec4(result * vignette, color.a);
}

// 메인 함수
void main() {
    vec4 color = texture2D(u_texture, v_texCoord);
    vec4 effectColor = applyVintageFilter(color);
    
    gl_FragColor = mix(color, effectColor, u_intensity);
}
