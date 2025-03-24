//
//  FilterShader.metal
//  FotoFX
//
//  Created by USER on 3/23/25.
//

#include <metal_stdlib>
using namespace metal;

// 커스텀 메탈 셰이더
kernel void customFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         constant float &intensity [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]]) {
    // 텍스처 크기 밖의 스레드는 무시
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float4 color = inTexture.read(gid);
    
    // RGB 채널 분리
    float r = color.r;
    float g = color.g;
    float b = color.b;
    
    // 커스텀 필터 적용
    float3 filteredColor = float3(
        r * (1.0 + intensity * 0.5),
        g * (1.0 - intensity * 0.2),
        b * (1.0 + intensity * 0.1)
    );
    
    // 결과 작성
    outTexture.write(float4(filteredColor, color.a), gid);
}
