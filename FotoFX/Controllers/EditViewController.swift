//
//  EditViewController.swift
//  FotoFX
//
//  Created by USER on 3/23/25.
//

import UIKit
import MetalKit
import Photos

enum EditSource {
    case camera
    case gallery
}

class EditViewController: UIViewController {
    // MARK: - UI Components
    var imageModel: ImageModel!
    var editableImage: ImageModel.EditableImage!
    private var filteredImage: UIImage?
    var source: EditSource = .gallery
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        return imageView
    }()
    
    private let bottomContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let filterLabel: UILabel = {
        let label = UILabel()
        label.text = "필터"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private let filtersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 5
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(FilterCollectionViewCell.self, forCellWithReuseIdentifier: "FilterCell")
        return collectionView
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .clear
        return button
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "checkmark"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .clear
        return button
    }()
    
    // 상단 상태바 스타일 커스텀
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Properties
    private var metalRenderer: MetalRenderer?
    private var openGLRenderer: GeneralizedOpenGLRenderer?
    
    private var filterNames: [String] {
        return FilterManager.shared.filterNames
    }
    
    // 미리보기 이미지 캐시 추가
    private var previewImages: [UIImage?] = []
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupRenderers()
        
        imageView.image = editableImage.currentImage
        filteredImage = editableImage.currentImage
        
        // 미리보기 이미지 생성을 위한 메서드 호출
        generatePreviewImages()
        
        // 현재 편집 중인 이미지 설정 (nil 방지)
        imageModel.setCurrentEditingImage(editableImage)
        
        // 네비게이션 바 숨기기
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 화면을 떠날 때 네비게이션 바를 다시 표시
        navigationController?.navigationBar.isHidden = false
    }
    
    // MARK: - UI Setup
    private func setupViews() {
        view.backgroundColor = .black
        
        // 뷰 추가
        view.addSubview(imageView)
        view.addSubview(bottomContainer)
        
        // 하단 컨테이너에 버튼 및 필터 레이블 추가
        bottomContainer.addSubview(cancelButton)
        bottomContainer.addSubview(filterLabel)
        bottomContainer.addSubview(confirmButton)
        
        // 필터 컬렉션뷰를 위한 별도 컨테이너 생성
        let filtersContainer = UIView()
        filtersContainer.backgroundColor = .gray
        view.addSubview(filtersContainer)
        filtersContainer.addSubview(filtersCollectionView)
        
        // 컬렉션뷰 설정
        filtersCollectionView.delegate = self
        filtersCollectionView.dataSource = self
        
        // 버튼 액션 설정
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        // 오토레이아웃 설정
        imageView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        filterLabel.translatesAutoresizingMaskIntoConstraints = false
        filtersCollectionView.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        filtersContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // 이미지 뷰 레이아웃 - 좌우 여백 10
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6), // 높이 감소
            
            // 필터 컬렉션뷰 컨테이너
            filtersContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filtersContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filtersContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // 하단 컨테이너 레이아웃 (X, 필터, 체크 버튼을 포함)
            bottomContainer.heightAnchor.constraint(equalToConstant: 60),
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // 필터 컨테이너와 하단 컨테이너 연결
            filtersContainer.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor),
            
            // 필터 컬렉션뷰 레이아웃
            filtersCollectionView.topAnchor.constraint(equalTo: filtersContainer.topAnchor, constant: 40),
            filtersCollectionView.leadingAnchor.constraint(equalTo: filtersContainer.leadingAnchor),
            filtersCollectionView.trailingAnchor.constraint(equalTo: filtersContainer.trailingAnchor),
            filtersCollectionView.bottomAnchor.constraint(equalTo: filtersContainer.bottomAnchor),
            
            // 취소 버튼 레이아웃 (하단 왼쪽)
            cancelButton.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 20),
            cancelButton.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 44),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 필터 레이블 레이아웃 (하단 중앙)
            filterLabel.centerXAnchor.constraint(equalTo: bottomContainer.centerXAnchor),
            filterLabel.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor),
            
            // 확인 버튼 레이아웃 (하단 오른쪽)
            confirmButton.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -20),
            confirmButton.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor),
            confirmButton.widthAnchor.constraint(equalToConstant: 44),
            confirmButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Action Handlers
    @objc private func cancelButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func confirmButtonTapped() {
        // 이미지 저장 및 적용
        checkPhotoLibraryPermissionAndSave()
    }
    
    // MARK: - Renderer Setup
    private func setupRenderers() {
        metalRenderer = MetalRenderer()
        openGLRenderer = GeneralizedOpenGLRenderer()
        
        if metalRenderer == nil {
            print("⚠️ Metal 렌더러 초기화 실패")
        } else {
            print("✅ Metal 렌더러 초기화 성공")
        }
        
        if openGLRenderer == nil {
            print("⚠️ OpenGL 렌더러 초기화 실패")
        } else {
            print("✅ OpenGL 렌더러 초기화 성공")
        }
    }
    
    // MARK: - Filter Processing
    // 미리보기 이미지 생성 메서드
    private func generatePreviewImages() {
        // 필터 매니저에서 필터 목록 가져오기
        let filters = FilterManager.shared.getSortedFilters()
        
        // 미리보기 배열 초기화 (필터 개수만큼)
        previewImages = Array(repeating: nil, count: filters.count)
        
        // 원본 이미지는 그대로 사용
        previewImages[0] = editableImage.originalImage
        
        // 백그라운드 스레드에서 미리보기 이미지 생성
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 작은 미리보기 이미지 크기로 원본 이미지 리사이즈
            let originalImage = self.editableImage.originalImage
            let previewSize = CGSize(width: 60, height: 60)
            let previewImage = self.resizeImage(originalImage, targetSize: previewSize)
            
            // 각 필터별 미리보기 이미지 생성
            for i in 1..<filters.count {
                let filter = filters[i]
                var filteredPreview: UIImage?
                
                if filter.renderer == "metal" {
                    // Metal 필터
                    filteredPreview = self.metalRenderer?.applyFilter(to: previewImage, filter: filter)
                } else if filter.renderer == "opengl" {
                    // OpenGL 필터
                    filteredPreview = self.openGLRenderer?.applyFilter(to: previewImage, filter: filter)
                }
                
                // 메인 스레드에서 UI 업데이트
                DispatchQueue.main.async {
                    self.previewImages[i] = filteredPreview
                    
                    // 보이는 셀만 업데이트
                    for indexPath in self.filtersCollectionView.indexPathsForVisibleItems where indexPath.item == i {
                        self.filtersCollectionView.reloadItems(at: [indexPath])
                    }
                }
            }
        }
    }
    
    // MARK: - Image Utilities
    // 이미지 리사이징 메서드
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    // MARK: - Permissions & Saving
    private func checkPhotoLibraryPermissionAndSave() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            // 권한이 이미 있으면 저장 진행
            saveImage()
            
        case .notDetermined:
            // 사용자에게 권한 요청
            PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.saveImage()
                    } else {
                        self?.showAlert(title: "권한 없음", message: "사진을 저장하려면 사진 라이브러리 접근 권한이 필요합니다.")
                    }
                }
            }
            
        case .denied, .restricted:
            // 권한이 거부되었으면 설정으로 안내
            showAlert(title: "권한 없음",
                      message: "사진을 저장하려면 사진 라이브러리 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요."
            )
            
        @unknown default:
            break
        }
    }
    
    private func saveImage() {
        // 현재 표시 중인 이미지가 있는지 확인
        guard let imageToSave = filteredImage ?? editableImage?.currentImage ?? editableImage?.originalImage else {
            showAlert(title: "저장 실패", message: "저장할 이미지가 없습니다.")
            return
        }
        
        // 직접 저장
        UIImageWriteToSavedPhotosAlbum(imageToSave, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("⚠️ 이미지 저장 실패: \(error.localizedDescription)")
            showAlert(title: "저장 실패", message: error.localizedDescription)
        } else {
            print("✅ 이미지 저장 성공")
            
            // 이미지 저장 성공 알림 발송
            NotificationCenter.default.post(name: Notification.Name("ImageSavedNotification"), object: nil)
            
            showAlert(title: "저장 완료", message: "이미지가 갤러리에 저장되었습니다.") { [weak self] in
                guard let self = self else { return }
                
                // 카메라에서 왔을 경우 RecentItemsViewController로 이동
                if self.source == .camera {
                    // 네비게이션 스택에서 RecentItemsViewController 찾기
                    for controller in self.navigationController?.viewControllers ?? [] {
                        if controller is RecentItemsViewController {
                            self.navigationController?.popToViewController(controller, animated: true)
                            return
                        }
                    }
                    
                    // RecentItemsViewController가 스택에 없으면 새로 만들어서 푸시
                    let recentItemsVC = RecentItemsViewController()
                    self.navigationController?.pushViewController(recentItemsVC, animated: true)
                } else {
                    // 갤러리에서 왔을 경우 기존처럼 이전 화면으로
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        
        present(alert, animated: true)
    }
    
    private func applyFilter() {
        let originalImage = editableImage.originalImage
        
        // 현재 선택된 필터 인덱스
        let indexPath = filtersCollectionView.indexPathsForSelectedItems?.first ?? IndexPath(item: 0, section: 0)
        let filterName = filterNames[indexPath.item]
        
        print("필터 적용 시도: \(filterName)")
        
        if indexPath.item == 0 {
            // Original - 원본으로 복원
            filteredImage = originalImage
            imageView.image = originalImage
            editableImage.resetToOriginal()
            return
        }
        
        // FilterManager에서 필터 가져오기
        guard let filter = FilterManager.shared.getFilter(at: indexPath.item) else {
            print("필터를 찾을 수 없음: \(indexPath.item)")
            return
        }
        
        // 필터 적용
        print("\(filter.name) 필터 적용 중 (렌더러: \(filter.renderer))...")
        print("필터 파라미터: \(filter.parameters)")
        if let constants = filter.shaderConstants {
            print("셰이더 상수: \(constants)")
        }
        
        // 렌더러 종류에 따라 필터 적용
        var filteredResult: UIImage? = nil
        
        if filter.renderer == "metal" {
            filteredResult = metalRenderer?.applyFilter(to: originalImage, filter: filter)
        } else if filter.renderer == "opengl" {
            filteredResult = openGLRenderer?.applyFilter(to: originalImage, filter: filter)
        }
        
        // 필터 적용 실패 시 안전하게 처리
        if let filteredResult = filteredResult {
            // 성공적으로 필터 적용
            filteredImage = filteredResult
            imageModel.updateCurrentImage(with: filteredResult, filterName: filterName)
            imageView.image = filteredResult
            print("필터 적용 성공: \(filterName)")
        } else {
            // 필터 적용 실패 시 원본 이미지 사용
            print("⚠️ 필터 적용 실패, 원본 이미지 사용")
            filteredImage = originalImage
            imageView.image = originalImage
            
            // 사용자에게 알림
            let alert = UIAlertController(
                title: "필터 적용 실패",
                message: "선택한 필터를 적용하는 중 오류가 발생했습니다. 다른 필터를 시도해보세요.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - CollectionView DataSource & Delegate
extension EditViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as? FilterCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.filterName = filterNames[indexPath.item]
        
        // 미리보기 이미지 설정
        if indexPath.item < previewImages.count {
            cell.setPreviewImage(previewImages[indexPath.item])
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("필터 선택: \(indexPath.item) - \(filterNames[indexPath.item])")
        applyFilter()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 55, height: 75)
    }
}
