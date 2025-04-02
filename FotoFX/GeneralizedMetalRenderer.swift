//
//  GeneralizedMetalRenderer.swift
//  FotoFX
//
//  Created by USER on 4/2/25.
//

import UIKit
import Metal
import MetalKit

class GeneralizedMetalRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLComputePipelineState?
    
    init() {
        // Metal 장치 및 명령 큐 설정
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("Metal을 지원하지 않는 기기입니다.")
        }
        
        self.device = device
        self.commandQueue = commandQueue
        
        setupPipeline()
    }
    
    private func setupPipeline() {
        // 완전히 일반화된 셰이더 코드 - 모든 기본 이미지 처리 기능을 지원
        let source = """
        #include <metal_stdlib>
        using namespace metal;
        
        kernel void applyGeneralFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                                      texture2d<float, access::write> outTexture [[texture(1)]],
                                      constant float4 &colorMatrix1 [[buffer(0)]],
                                      constant float4 &colorMatrix2 [[buffer(1)]],
                                      constant float4 &colorMatrix3 [[buffer(2)]],
                                      constant float4 &colorMatrix4 [[buffer(3)]],
                                      constant float4 &colorAdjust [[buffer(4)]],
                                      constant float4 &mixValues [[buffer(5)]],
                                      uint2 gid [[thread_position_in_grid]]) {
            // 범위 체크
            if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
                return;
            }
            
            // 원본 색상 읽기
            float4 originalColor = inTexture.read(gid);
            float4 resultColor = originalColor;
            
            // 1. RGB 채널별 곱셈 (색상 조정)
            float3 adjustedColor = originalColor.rgb * colorAdjust.rgb;
            
            // 2. 그레이스케일 변환 (필요한 경우)
            float grayscale = dot(originalColor.rgb, colorMatrix1.rgb);
            
            // 3. 색상 매트릭스 변환 적용 (선택적)
            // colorMatrix1, colorMatrix2, colorMatrix3: 선형 변환에 사용되는 행렬 값
            if (mixValues.x > 0.0) {
                float3 matrixColor;
                matrixColor.r = dot(originalColor.rgb, colorMatrix1.rgb) + colorMatrix1.a;
                matrixColor.g = dot(originalColor.rgb, colorMatrix2.rgb) + colorMatrix2.a;
                matrixColor.b = dot(originalColor.rgb, colorMatrix3.rgb) + colorMatrix3.a;
                adjustedColor = mix(adjustedColor, matrixColor, mixValues.x);
            }
            
            // 4. 흑백 효과 적용 (필요한 경우)
            if (mixValues.y > 0.0) {
                adjustedColor = mix(adjustedColor, float3(grayscale), mixValues.y);
            }
            
            // 5. 색상 반전 (필요한 경우)
            if (mixValues.z > 0.0) {
                float3 invertedColor = float3(1.0) - originalColor.rgb;
                adjustedColor = mix(adjustedColor, invertedColor, mixValues.z);
            }
            
            // 6. 색상 고정값과 혼합 (특정 색조 추가용)
            float3 tintColor = colorMatrix4.rgb;
            float tintIntensity = colorMatrix4.a;
            if (tintIntensity > 0.0) {
                adjustedColor = mix(adjustedColor, adjustedColor * tintColor, tintIntensity);
            }
            
            // 7. 전체 필터 강도 적용
            resultColor = float4(mix(originalColor.rgb, adjustedColor, colorAdjust.a), originalColor.a);
            
            // 결과 저장
            outTexture.write(resultColor, gid);
        }
        """
        
        // 셰이더 컴파일 및 에러 처리
        do {
            let library = try device.makeLibrary(source: source, options: nil)
            guard let function = library.makeFunction(name: "applyGeneralFilter") else {
                print("⚠️ 셰이더 함수 생성 실패")
                return
            }
            
            pipelineState = try device.makeComputePipelineState(function: function)
            print("✅ Metal 파이프라인 생성 성공")
        } catch {
            print("⚠️ Metal 파이프라인 생성 실패: \(error.localizedDescription)")
        }
    }
    
    // FilterData 구조체 - JSON에서 불러온 필터 데이터를 Metal 셰이더 파라미터로 변환
    struct FilterData {
        var colorMatrix1: SIMD4<Float> = SIMD4<Float>(0.299, 0.587, 0.114, 0.0)  // 기본 luminance 값
        var colorMatrix2: SIMD4<Float> = SIMD4<Float>(0.0, 0.0, 0.0, 0.0)
        var colorMatrix3: SIMD4<Float> = SIMD4<Float>(0.0, 0.0, 0.0, 0.0)
        var colorMatrix4: SIMD4<Float> = SIMD4<Float>(1.0, 1.0, 1.0, 0.0)  // tint color + intensity
        var colorAdjust: SIMD4<Float> = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)   // RGB 조정 + 전체 강도
        var mixValues: SIMD4<Float> = SIMD4<Float>(0.0, 0.0, 0.0, 0.0)     // 매트릭스/흑백/반전/예비
        
        // Filter 객체에서 FilterData 객체 생성
        static func from(filter: Filter) -> FilterData {
            var data = FilterData()
            
            // JSON에서 필터 파라미터 가져오기
            let constants = filter.shaderConstants ?? [:]
            
            // 1. luminance 벡터 (그레이스케일 변환용)
            if let luminance = constants["luminance"] as? [Double], luminance.count >= 3 {
                data.colorMatrix1.x = Float(luminance[0])
                data.colorMatrix1.y = Float(luminance[1])
                data.colorMatrix1.z = Float(luminance[2])
            }
            
            // 2. 색상 매트릭스 (선형 변환용)
            if let matrix = constants["colorMatrix"] as? [[Double]], matrix.count >= 3 {
                if matrix[0].count >= 4 {
                    data.colorMatrix1 = SIMD4<Float>(
                        Float(matrix[0][0]), Float(matrix[0][1]), Float(matrix[0][2]), Float(matrix[0][3])
                    )
                }
                if matrix[1].count >= 4 {
                    data.colorMatrix2 = SIMD4<Float>(
                        Float(matrix[1][0]), Float(matrix[1][1]), Float(matrix[1][2]), Float(matrix[1][3])
                    )
                }
                if matrix[2].count >= 4 {
                    data.colorMatrix3 = SIMD4<Float>(
                        Float(matrix[2][0]), Float(matrix[2][1]), Float(matrix[2][2]), Float(matrix[2][3])
                    )
                }
            }
            
            // 3. RGB 채널별 조정값
            if let redMultiplier = constants["redMultiplier"] as? Double {
                data.colorAdjust.x = Float(redMultiplier)
            }
            if let greenMultiplier = constants["greenMultiplier"] as? Double {
                data.colorAdjust.y = Float(greenMultiplier)
            }
            if let blueMultiplier = constants["blueMultiplier"] as? Double {
                data.colorAdjust.z = Float(blueMultiplier)
            }
            
            // 4. 특정 색조 추가
            if let tintColor = constants["tintColor"] as? [Double], tintColor.count >= 3 {
                data.colorMatrix4.x = Float(tintColor[0])
                data.colorMatrix4.y = Float(tintColor[1])
                data.colorMatrix4.z = Float(tintColor[2])
            }
            if let tintIntensity = constants["tintIntensity"] as? Double {
                data.colorMatrix4.w = Float(tintIntensity)
            }
            
            // 5. 혼합 값들
            if let matrixMix = constants["matrixMix"] as? Double {
                data.mixValues.x = Float(matrixMix)
            }
            if let grayscaleMix = constants["grayscaleMix"] as? Double {
                data.mixValues.y = Float(grayscaleMix)
            }
            if let invertMix = constants["invertMix"] as? Double {
                data.mixValues.z = Float(invertMix)
            }
            
            // 6. 필터 강도
            if let intensity = constants["intensity"] as? Double {
                data.colorAdjust.w = Float(intensity)
            }
            
            return data
        }
    }
    
    // 필터 객체를 사용하여 필터 적용
    func applyFilter(to image: UIImage, filter: Filter) -> UIImage? {
        guard let pipelineState = pipelineState,
              let cgImage = image.cgImage else { return nil }
        
        // 필터 데이터 준비
        let filterData = FilterData.from(filter: filter)
        
        // 텍스처 생성
        let textureLoader = MTKTextureLoader(device: device)
        guard let inTexture = try? textureLoader.newTexture(cgImage: cgImage, options: nil) else {
            print("입력 텍스처 생성 실패")
            return nil
        }
        
        // 출력 텍스처 생성
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: inTexture.pixelFormat,
            width: inTexture.width,
            height: inTexture.height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        guard let outTexture = device.makeTexture(descriptor: textureDescriptor) else {
            print("출력 텍스처 생성 실패")
            return nil
        }
        
        // 커맨드 버퍼 생성
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            print("커맨드 버퍼/인코더 생성 실패")
            return nil
        }
        
        // 명령 인코더 설정
        commandEncoder.setComputePipelineState(pipelineState)
        commandEncoder.setTexture(inTexture, index: 0)
        commandEncoder.setTexture(outTexture, index: 1)
        
        // 필터 파라미터 설정
        var matrix1 = filterData.colorMatrix1
        var matrix2 = filterData.colorMatrix2
        var matrix3 = filterData.colorMatrix3
        var matrix4 = filterData.colorMatrix4
        var colorAdjust = filterData.colorAdjust
        var mixValues = filterData.mixValues
        
        commandEncoder.setBytes(&matrix1, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
        commandEncoder.setBytes(&matrix2, length: MemoryLayout<SIMD4<Float>>.size, index: 1)
        commandEncoder.setBytes(&matrix3, length: MemoryLayout<SIMD4<Float>>.size, index: 2)
        commandEncoder.setBytes(&matrix4, length: MemoryLayout<SIMD4<Float>>.size, index: 3)
        commandEncoder.setBytes(&colorAdjust, length: MemoryLayout<SIMD4<Float>>.size, index: 4)
        commandEncoder.setBytes(&mixValues, length: MemoryLayout<SIMD4<Float>>.size, index: 5)
        
        // 스레드 그룹 설정
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (inTexture.width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (inTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        commandEncoder.endEncoding()
        
        // 명령 실행
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // 이미지로 변환
        return textureToUIImage(texture: outTexture)
    }
    
    // 원래 메서드와 호환성 유지를 위한 인터페이스
    func applyFilter(to image: UIImage, filterType: Int) -> UIImage? {
        // FilterManager에서 해당 filterType을 가진 필터 찾기
        if let filter = FilterManager.shared.filters.first(where: { $0.filterType == filterType }) {
            return applyFilter(to: image, filter: filter)
        }
        
        // 필터를 찾지 못한 경우 원본 반환
        print("필터 타입 \(filterType)에 해당하는 필터를 찾을 수 없습니다.")
        return image
    }
    
    private func textureToUIImage(texture: MTLTexture) -> UIImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4
        
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * 4)
        let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                              size: MTLSize(width: width, height: height, depth: 1))
        
        texture.getBytes(data, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        // RGB 채널 수동 스왑 (문제 해결을 위한 대안)
        for i in stride(from: 0, to: width * height * 4, by: 4) {
            let temp = data[i]      // R
            data[i] = data[i + 2]   // B -> R
            data[i + 2] = temp      // R -> B
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: data,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: 8,
                                     bytesPerRow: bytesPerRow,
                                     space: colorSpace,
                                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            data.deallocate()
            return nil
        }
        
        guard let cgImage = context.makeImage() else {
            data.deallocate()
            return nil
        }
        
        data.deallocate()
        
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
}
