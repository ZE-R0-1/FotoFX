//
//  FilterManager.swift
//  FotoFX
//
//  Created by USER on 4/2/25.
//

import UIKit

// 필터 관리 클래스
class FilterManager {
    // MARK: - Properties
    // 싱글톤 인스턴스
    static let shared = FilterManager()
    
    // 필터 목록
    private(set) var filters: [Filter] = []
    
    // 필터 이름 목록 (UI에 표시할 용도)
    var filterNames: [String] {
        return filters.sorted(by: { $0.order < $1.order }).map { $0.name }
    }
    
    // MARK: - Initialization
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
    
    // MARK: - Private Methods
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
    
    // MARK: - Public Methods
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
