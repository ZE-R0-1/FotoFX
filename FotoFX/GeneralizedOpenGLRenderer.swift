//
//  GeneralizedOpenGLRenderer.swift
//  FotoFX
//
//  Created by USER on 4/2/25.
//

import UIKit

class GeneralizedOpenGLRenderer {
    // 네이티브 OpenGL 렌더러 인스턴스
    private let openGLRenderer = OpenGLRenderer()
    
    // FilterData 구조체 - JSON에서 불러온 필터 데이터를 OpenGL 파라미터로 변환
    struct FilterData {
        var filterType: Int = 0                    // 기본 필터 타입
        var luminance: [Float] = [0.299, 0.587, 0.114] // 기본 luminance 값
        var redMultiplier: Float = 1.0             // R 채널 곱셈
        var greenMultiplier: Float = 1.0           // G 채널 곱셈
        var blueMultiplier: Float = 1.0            // B 채널 곱셈
        var tintColor: [Float] = [1.0, 1.0, 1.0]   // 색조
        var tintIntensity: Float = 0.0             // 색조 강도
        var intensity: Float = 1.0                 // 전체 필터 강도
        var grayscaleMix: Float = 0.0              // 흑백 혼합
        var invertMix: Float = 0.0                 // 반전 혼합
        
        // Filter 객체에서 FilterData 객체 생성
        static func from(filter: Filter) -> FilterData {
            var data = FilterData()
            
            // JSON에서 필터 파라미터 가져오기
            data.filterType = filter.filterType
            
            let constants = filter.shaderConstants ?? [:]
            
            // 1. luminance 벡터 (그레이스케일 변환용)
            if let luminance = constants["luminance"] as? [Double], luminance.count >= 3 {
                data.luminance = luminance.map { Float($0) }
            }
            
            // 2. RGB 채널별 조정값
            if let redMultiplier = constants["redMultiplier"] as? Double {
                data.redMultiplier = Float(redMultiplier)
            }
            if let greenMultiplier = constants["greenMultiplier"] as? Double {
                data.greenMultiplier = Float(greenMultiplier)
            }
            if let blueMultiplier = constants["blueMultiplier"] as? Double {
                data.blueMultiplier = Float(blueMultiplier)
            }
            
            // 3. 색조 추가
            if let tintColor = constants["tintColor"] as? [Double], tintColor.count >= 3 {
                data.tintColor = tintColor.map { Float($0) }
            }
            if let tintIntensity = constants["tintIntensity"] as? Double {
                data.tintIntensity = Float(tintIntensity)
            }
            
            // 4. 특수 효과
            if let grayscaleMix = constants["grayscaleMix"] as? Double {
                data.grayscaleMix = Float(grayscaleMix)
            }
            if let invertMix = constants["invertMix"] as? Double {
                data.invertMix = Float(invertMix)
            }
            
            // 5. 필터 강도
            if let intensity = constants["intensity"] as? Double {
                data.intensity = Float(intensity)
            }
            
            return data
        }
    }
    
    // 필터 객체를 사용하여 필터 적용
    func applyFilter(to image: UIImage, filter: Filter) -> UIImage? {
        // 원본 필터인 경우 이미지 그대로 반환
        if filter.type == "none" {
            return image
        }
        
        // 필터 데이터 준비
        let filterData = FilterData.from(filter: filter)
        
        // 필터 적용
        print("\(filter.name) OpenGL 필터 적용 중...")
        
        // Swift의 [Float]를 Objective-C의 [NSNumber] 형태로 변환
        let tintColorNSNumbers = filterData.tintColor.map { NSNumber(value: $0) }
        
        // OpenGLRenderer에서 제공하는 기본 필터 타입 사용
        // 기존의 Objective-C OpenGLRenderer와 호환성 유지
        let result = openGLRenderer.applyFilter(image,
                                               redMultiplier: filterData.redMultiplier,
                                               greenMultiplier: filterData.greenMultiplier,
                                               blueMultiplier: filterData.blueMultiplier,
                                               intensity: filterData.intensity,
                                               tintColor: tintColorNSNumbers,
                                               tintIntensity: filterData.tintIntensity,
                                               grayscaleMix: filterData.grayscaleMix,
                                               invertMix: filterData.invertMix)
        
        return result
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
}
