//
//  FilterModel.swift
//  FotoFX
//
//  Created by USER on 4/2/25.
//

import UIKit

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
    
    // parameters와 shaderConstants는 [String: Any] 타입이므로 인코딩/디코딩 구현
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

// JSON에서 [String: Any] 타입을 인코딩/디코딩하기 위한 유틸리티
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
