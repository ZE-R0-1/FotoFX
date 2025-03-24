//
//  MetalRenderer.swift
//  FotoFX
//
//  Created by USER on 3/23/25.
//

import UIKit
import Metal
import MetalKit

class MetalRenderer {
    
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
        let source = """
        #include <metal_stdlib>
        using namespace metal;
        
        kernel void applyFilter(texture2d<float, access::read> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               constant float &intensity [[buffer(0)]],
                               constant int &filterType [[buffer(1)]],
                               uint2 gid [[thread_position_in_grid]]) {
            // 범위 체크
            if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
                return;
            }
            
            // 원본 색상 읽기
            float4 color = inTexture.read(gid);
            float4 result = color;
            
            // 단순 필터 적용
            float luminance = dot(color.rgb, float3(0.299, 0.587, 0.114));
            
            // 필터 타입에 따라 분기
            switch (filterType) {
                case 2: // Noir
                    result = float4(mix(color.rgb, float3(luminance), intensity), color.a);
                    break;
                case 4: // Fade
                    result = float4(mix(color.rgb, float3(0.8, 0.8, 0.8), intensity * 0.5), color.a);
                    break;
                case 6: // Tonal
                    result = float4(mix(color.rgb, float3(luminance * 1.1, luminance, luminance * 0.9), intensity), color.a);
                    break;
                case 8: // Invert
                    result = float4(mix(color.rgb, float3(1.0) - color.rgb, intensity), color.a);
                    break;
                default:
                    // 기본값은 원본
                    break;
            }
            
            // 결과 저장
            outTexture.write(result, gid);
        }
        """
        
        // 셰이더 컴파일 및 에러 처리
        do {
            let library = try device.makeLibrary(source: source, options: nil)
            guard let function = library.makeFunction(name: "applyFilter") else {
                print("⚠️ 셰이더 함수 생성 실패")
                return
            }
            
            pipelineState = try device.makeComputePipelineState(function: function)
            print("✅ Metal 파이프라인 생성 성공")
        } catch {
            print("⚠️ Metal 파이프라인 생성 실패: \(error.localizedDescription)")
        }
    }
    
    func applyFilter(to image: UIImage, filterType: Int, intensity: Float) -> UIImage? {
        guard let pipelineState = pipelineState,
              let cgImage = image.cgImage else { return nil }
        
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
        
        var intensityValue = intensity
        commandEncoder.setBytes(&intensityValue, length: MemoryLayout<Float>.size, index: 0)
        
        var filterTypeValue = filterType
        commandEncoder.setBytes(&filterTypeValue, length: MemoryLayout<Int>.size, index: 1)
        
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
    }}
