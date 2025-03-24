//
//  ImageModel.swift
//  FotoFX
//
//  Created by USER on 3/23/25.
//

import UIKit
import Photos

class ImageModel {
    // 편집할 이미지 정보를 담는 모델
    struct EditableImage {
        let originalImage: UIImage
        var currentImage: UIImage
        let assetID: String?
        let creationDate: Date
        var appliedFilters: [String]
        var filterIntensity: Float
        
        init(originalImage: UIImage, assetID: String? = nil) {
            self.originalImage = originalImage
            self.currentImage = originalImage
            self.assetID = assetID
            self.creationDate = Date()
            self.appliedFilters = []
            self.filterIntensity = 0.5
        }
        
        mutating func applyFilter(name: String, filteredImage: UIImage, intensity: Float) {
            self.currentImage = filteredImage
            self.appliedFilters.append(name)
            self.filterIntensity = intensity
        }
        
        mutating func resetToOriginal() {
            self.currentImage = originalImage
            self.appliedFilters = []
            self.filterIntensity = 0.5
        }
    }
    
    private var editableImages: [EditableImage] = []
    private(set) var currentEditingImage: EditableImage?
    
    // 컬렉션뷰에서 필요한 메서드들
    
    // editableImages 배열의 개수 반환
    func getEditableImagesCount() -> Int {
        return editableImages.count
    }
    
    // 특정 인덱스의 이미지 반환
    func getImage(at index: Int) -> UIImage? {
        guard index < editableImages.count else { return nil }
        return editableImages[index].currentImage
    }
    
    // 수정된 메서드: 동기화 개선 및 기존 데이터 초기화 추가
    func fetchImagesFromGallery(completion: @escaping ([UIImage]) -> Void) {
        print("ImageModel - fetchImagesFromGallery 시작")
        var images: [UIImage] = []
        
        // 기존 데이터 초기화
        editableImages.removeAll()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        print("가져온 PHAsset 수: \(fetchResult.count)")
        
        if fetchResult.count == 0 {
            print("사진이 없거나 권한이 없습니다")
            completion([])
            return
        }
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        
        let group = DispatchGroup()
        
        fetchResult.enumerateObjects { (asset, index, stop) in
            if index < 20 { // 최대 20개 이미지만 가져오기
                print("Asset \(index) 처리 중: \(asset)")
                group.enter()
                imageManager.requestImage(for: asset,
                                         targetSize: CGSize(width: 500, height: 500),
                                         contentMode: .aspectFill,
                                         options: requestOptions) { (image, info) in
                    if let image = image {
                        print("이미지 \(index) 가져오기 성공")
                        // EditableImage 객체 생성 및 저장
                        let editableImage = EditableImage(originalImage: image, assetID: asset.localIdentifier)
                        
                        // 동기화 문제 방지를 위해 메인 큐에서 배열 업데이트
                        DispatchQueue.main.async {
                            self.editableImages.append(editableImage)
                            images.append(image)
                        }
                    } else {
                        print("이미지 \(index) 가져오기 실패: \(String(describing: info))")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            print("모든 이미지 처리 완료: 최종 \(images.count)개")
            completion(images)
        }
    }
    
    func createNewImage(image: UIImage) -> EditableImage {
        let editableImage = EditableImage(originalImage: image)
        editableImages.append(editableImage)
        return editableImage
    }
    
    func selectImageForEditing(at index: Int) -> EditableImage? {
        guard index < editableImages.count else { return nil }
        currentEditingImage = editableImages[index]
        return currentEditingImage
    }
    
    func updateCurrentImage(with filteredImage: UIImage, filterName: String, intensity: Float) {
        if currentEditingImage == nil {
            print("⚠️ currentEditingImage가 nil입니다")
            return
        }
        
        print("이미지 업데이트: \(filterName), 강도: \(intensity)")
        
        var image = currentEditingImage!
        image.applyFilter(name: filterName, filteredImage: filteredImage, intensity: intensity)
        
        // 현재 편집 중인 이미지 업데이트
        if let index = editableImages.firstIndex(where: { $0.assetID == image.assetID }) {
            editableImages[index] = image
            print("✅ editableImages[\(index)] 업데이트됨")
        }
        
        currentEditingImage = image
        print("✅ currentEditingImage 업데이트됨")
    }
    
    func setCurrentEditingImage(_ image: EditableImage) {
        currentEditingImage = image
        print("✅ 현재 편집 중인 이미지 직접 설정됨")
    }
    
    func saveCurrentImage(completion: @escaping (Bool, Error?) -> Void) {
        print("저장 시도: currentEditingImage = \(currentEditingImage != nil ? "있음" : "없음")")
        
        guard let image = currentEditingImage?.currentImage else {
            let error = NSError(domain: "ImageModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "저장할 이미지가 없습니다."])
            print("⚠️ 저장 실패: 이미지 없음")
            completion(false, error)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: completion)
    }
    
    // 이미지 삭제 메서드 추가
    func deleteImage(at index: Int, completion: @escaping (Bool, Error?) -> Void) {
        guard index < editableImages.count else {
            completion(false, NSError(domain: "ImageModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "유효하지 않은 인덱스"]))
            return
        }
        
        let editableImage = editableImages[index]
        
        // 현재 편집 중인 이미지인 경우 참조 제거
        if currentEditingImage?.assetID == editableImage.assetID {
            currentEditingImage = nil
        }
        
        // 앱 내부 배열에서 제거
        editableImages.remove(at: index)
        
        // assetID가 있으면 (갤러리에서 가져온 이미지) 실제 사진 라이브러리에서도 삭제
        if let assetID = editableImage.assetID {
            // 에셋 ID로 PHAsset 가져오기
            let fetchOptions = PHFetchOptions()
            fetchOptions.includeHiddenAssets = true
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: fetchOptions)
            
            // 사진이 존재하면 삭제 시도
            if fetchResult.count > 0 {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.deleteAssets(fetchResult as NSFastEnumeration)
                }, completionHandler: completion)
            } else {
                // 사진이 이미 사진 라이브러리에서 삭제된 경우
                completion(true, nil)
            }
        } else {
            // 앱에서 생성된 이미지는 assetID가 없으므로 삭제 성공으로 처리
            completion(true, nil)
        }
    }
}
