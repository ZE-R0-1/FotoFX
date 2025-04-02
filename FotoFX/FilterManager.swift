//
//  FilterManager.swift
//  FotoFX
//
//  Created by USER on 4/2/25.
//

import UIKit

// 필터 모델 정의
struct Filter: Codable {
    let id: String
    let name: String
    let type: String
    let renderer: String
    let order: Int
    let parameters: [String: Any]
    var shaderConstants: [String: Any]?
    
    // Codable을 위한 CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, name, type, renderer, order, parameters, shaderConstants
    }
    
    // parameters와 shaderConstants는 [String: Any] 타입이므로 직접 인코딩/디코딩 구현
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        renderer = try container.decode(String.self, forKey: .renderer)
        order = try container.decode(Int.self, forKey: .order)
        
        // parameters와 shaderConstants는 JSON 객체를 [String: Any]로 변환
        if let parametersData = try? container.decode([String: AnyCodable].self, forKey: .parameters) {
            parameters = parametersData.mapValues { $0.value }
        } else {
            parameters = [:]
        }
        
        if let constantsData = try? container.decode([String: AnyCodable].self, forKey: .shaderConstants) {
            shaderConstants = constantsData.mapValues { $0.value }
        } else {
            shaderConstants = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(renderer, forKey: .renderer)
        try container.encode(order, forKey: .order)
        
        // parameters와 shaderConstants를 AnyCodable로 변환하여 인코딩
        let parametersAnyCodable = parameters.mapValues { AnyCodable($0) }
        try container.encode(parametersAnyCodable, forKey: .parameters)
        
        if let constants = shaderConstants {
            let constantsAnyCodable = constants.mapValues { AnyCodable($0) }
            try container.encode(constantsAnyCodable, forKey: .shaderConstants)
        }
    }
    
    // 편의를 위한 이니셜라이저
    init(id: String, name: String, type: String, renderer: String, order: Int, parameters: [String: Any], shaderConstants: [String: Any]? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.renderer = renderer
        self.order = order
        self.parameters = parameters
        self.shaderConstants = shaderConstants
    }
    
    // filterType 값을 쉽게 가져오기 위한 computed property
    var filterType: Int {
        return parameters["filterType"] as? Int ?? 0
    }
}

// JSON에서 [String: Any] 타입을 인코딩/디코딩하기 위한 유틸리티 클래스
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            value = dictionaryValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictionaryValue as [String: Any]:
            try container.encode(dictionaryValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// 필터 관리 클래스
class FilterManager {
    // 싱글톤 인스턴스
    static let shared = FilterManager()
    
    // 필터 목록
    private(set) var filters: [Filter] = []
    
    // 필터 이름 목록 (UI에 표시할 용도)
    var filterNames: [String] {
        return filters.sorted(by: { $0.order < $1.order }).map { $0.name }
    }
    
    private init() {
        loadFilters()
    }
    
    // JSON 파일에서 필터 정보 로드
    func loadFilters() {
        guard let url = Bundle.main.url(forResource: "filters", withExtension: "json") else {
            print("filters.json 파일을 찾을 수 없습니다.")
            loadDefaultFilters()
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let filtersResponse = try decoder.decode(FiltersResponse.self, from: data)
            self.filters = filtersResponse.filters.sorted(by: { $0.order < $1.order })
            print("필터 \(self.filters.count)개 로드 성공")
        } catch {
            print("필터 로드 실패: \(error)")
            loadDefaultFilters()
        }
    }
    
    // 필터 파일이 없거나 오류 발생 시 기본 필터 설정
    private func loadDefaultFilters() {
        let defaultFilters: [Filter] = [
            Filter(id: "original", name: "원본", type: "none", renderer: "none", order: 0, parameters: [:]),
            Filter(id: "sepia", name: "세피아", type: "opengl", renderer: "opengl", order: 1, parameters: ["filterType": 1]),
            Filter(id: "noir", name: "느와르", type: "metal", renderer: "metal", order: 2, parameters: ["filterType": 2]),
            Filter(id: "chrome", name: "크롬", type: "opengl", renderer: "opengl", order: 3, parameters: ["filterType": 3]),
            Filter(id: "fade", name: "페이드", type: "metal", renderer: "metal", order: 4, parameters: ["filterType": 4]),
            Filter(id: "mono", name: "모노", type: "opengl", renderer: "opengl", order: 5, parameters: ["filterType": 5]),
            Filter(id: "tonal", name: "토널", type: "metal", renderer: "metal", order: 6, parameters: ["filterType": 6]),
            Filter(id: "transfer", name: "컬러 반전", type: "opengl", renderer: "opengl", order: 7, parameters: ["filterType": 7]),
            Filter(id: "invert", name: "반전", type: "metal", renderer: "metal", order: 8, parameters: ["filterType": 8])
        ]
        
        self.filters = defaultFilters
        print("기본 필터 \(self.filters.count)개 로드됨")
    }
    
    // 인덱스로 필터 가져오기
    func getFilter(at index: Int) -> Filter? {
        guard index >= 0 && index < filters.count else { return nil }
        
        // order 속성에 따라 정렬된 필터 목록에서 인덱스에 해당하는 필터 반환
        let sortedFilters = filters.sorted(by: { $0.order < $1.order })
        return index < sortedFilters.count ? sortedFilters[index] : nil
    }
    
    // order 속성으로 필터 정렬하기
    func getSortedFilters() -> [Filter] {
        return filters.sorted(by: { $0.order < $1.order })
    }
}

// JSON 파일 최상위 구조
struct FiltersResponse: Codable {
    let version: String
    let filters: [Filter]
}
