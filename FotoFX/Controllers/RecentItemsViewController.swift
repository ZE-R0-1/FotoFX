//
//  RecentItemsViewController.swift
//  FotoFX
//
//  Created by USER on 4/2/25.
//

import UIKit
import Photos

class RecentItemsViewController: UIViewController {
    // MARK: - Enums
    // 그리드 상태를 추적하는 열거형 추가
    enum GridType {
        case threeColumns // 기본 3열 레이아웃
        case fourColumns // 4열 레이아웃
    }
    
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        return collectionView
    }()
    
    private let cameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.tintColor = .darkGray
        button.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        button.layer.cornerRadius = 30
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        return button
    }()
    
    // MARK: - Properties
    private let imageModel = ImageModel()
    
    // 이미지를 이미 로드했는지 추적하는 플래그 추가
    private var hasLoadedImages = false
    
    // 현재 그리드 타입 상태
    private var currentGridType: GridType = .threeColumns
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        // 이미지 저장 알림 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleImageSaved),
            name: Notification.Name("ImageSavedNotification"),
            object: nil
        )
        
        // 이미지 삭제 알림 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleImageDeleted),
            name: Notification.Name("ImageDeletedNotification"),
            object: nil
        )
        
        // 사진 라이브러리 권한 확인
        checkPhotoLibraryPermissions()
    }
    
    // deinit 추가
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 이미지를 아직 로드하지 않았을 때만 권한 확인 및 사진 가져오기
        if !hasLoadedImages {
            checkPermissions()
        }
    }
    
    // 이미지 저장 알림 처리 메서드
    @objc private func handleImageSaved() {
        print("이미지 저장 알림 수신")
        
        // 편집 화면에서 이미지가 저장되면 이 메서드가 호출됨
        // 저장된 이미지를 컬렉션뷰에 표시하기 위해 갤러리 갱신
        // 약간의 지연을 두고 갱신 (사진 라이브러리에 이미지가 완전히 저장되는데 시간이 걸릴 수 있음)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshGallery()
        }
    }
    
    // 갤러리 갱신 메서드
    func refreshGallery() {
        // hasLoadedImages 플래그를 재설정하지 않음 (로드 상태는 유지)
        fetchPhotos()
    }
    
    // 이미지 삭제 알림 처리 메서드
    @objc private func handleImageDeleted() {
        print("이미지 삭제 알림 수신")
        
        // 약간의 지연을 두고 갱신 (사진 라이브러리에 변경이 완전히 반영되는데 시간이 걸릴 수 있음)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshGallery()
        }
    }
    
    // MARK: - UI Setup
    private func setupViews() {
        // 기본 뷰 설정
        title = "최근 항목"
        view.backgroundColor = .white
        
        // 네비게이션 바 설정
        setupNavigationBar()
        
        view.addSubview(collectionView)
        view.addSubview(cameraButton)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        cameraButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 2),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 카메라 버튼을 우측 하단에 배치
            cameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cameraButton.widthAnchor.constraint(equalToConstant: 60),
            cameraButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupNavigationBar() {
        // 네비게이션 바 표시
        navigationController?.navigationBar.isHidden = false
        
        // 뒤로가기 버튼 커스터마이징
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .black
        navigationItem.leftBarButtonItem = backButton
        
        // 그리드 버튼 추가 - 이미지 변경
        let gridButton = UIBarButtonItem(
            image: UIImage(systemName: "square.grid.2x2"),
            style: .plain,
            target: self,
            action: #selector(gridButtonTapped)
        )
        gridButton.tintColor = .black
        navigationItem.rightBarButtonItem = gridButton
        
        // 네비게이션 바 타이틀 스타일 설정
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .medium)
        ]
    }
    
    @objc private func backButtonTapped() {
        // 홈 화면으로 돌아가기
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func gridButtonTapped() {
        print("그리드 버튼 탭됨")
        
        // 그리드 타입 전환
        switch currentGridType {
        case .threeColumns:
            currentGridType = .fourColumns
            // 버튼 아이콘 변경
            navigationItem.rightBarButtonItem?.image = UIImage(systemName: "square.grid.3x3")
        case .fourColumns:
            currentGridType = .threeColumns
            // 버튼 아이콘 변경
            navigationItem.rightBarButtonItem?.image = UIImage(systemName: "square.grid.2x2")
        }
        
        // 레이아웃 업데이트
        collectionView.reloadData()
    }
    
    // MARK: - Permission Methods
    private func checkPhotoLibraryPermissions() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            switch status {
            case .authorized, .limited:
                // 권한이 있음, 정상 작동
                break
            case .denied, .restricted:
                // 권한이 거부됨
                DispatchQueue.main.async {
                    self?.showPermissionAlert(message: "사진을 삭제하려면 사진 라이브러리 접근 권한이 필요합니다.")
                }
            case .notDetermined:
                // 사용자에게 아직 권한 요청하지 않음
                break
            @unknown default:
                break
            }
        }
    }
    
    private func checkPermissions() {
        print("권한 확인 시작")
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            print("사진 라이브러리 권한 상태: \(status.rawValue)")
            
            switch status {
            case .authorized, .limited:
                DispatchQueue.main.async {
                    self?.fetchPhotos()
                }
            case .denied, .restricted:
                DispatchQueue.main.async {
                    self?.showPermissionAlert(message: "사진을 표시하려면 사진 라이브러리 접근 권한이 필요합니다.")
                }
            case .notDetermined:
                // 이미 requestAuthorization에서 처리됨
                break
            @unknown default:
                break
            }
        }
    }

    private func showPermissionAlert(message: String) {
        let alert = UIAlertController(
            title: "권한 필요",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Image Loading Methods
    private func fetchPhotos() {
        print("사진 가져오기 시작")
        
        // 로딩 인디케이터 추가
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        imageModel.fetchImagesFromGallery { [weak self] _ in
            guard let self = self else { return }
            
            print("이미지 가져오기 완료: \(self.imageModel.getEditableImagesCount())개 이미지")
            
            DispatchQueue.main.async {
                // 이미지 로드 플래그 설정
                self.hasLoadedImages = true
                
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
                
                self.collectionView.reloadData()
                
                // 첫 번째 셀이 있으면 스크롤
                if self.imageModel.getEditableImagesCount() > 0 {
                    self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0),
                                                  at: .top,
                                                  animated: false)
                }
            }
        }
    }
    
    // MARK: - Action Handlers
    @objc private func cameraButtonTapped() {
        print("카메라 버튼 탭됨")
        
        let cameraVC = CameraViewController()
        self.navigationController?.pushViewController(cameraVC, animated: true)
    }
}

// MARK: - CollectionView DataSource & Delegate
extension RecentItemsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageModel.getEditableImagesCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath)
        
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let imageView = UIImageView(frame: cell.contentView.bounds)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        if let image = imageModel.getImage(at: indexPath.item) {
            imageView.image = image
        } else {
            imageView.image = nil
        }
        
        cell.contentView.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 이미지 편집 화면으로 이동
        let detailVC = ImageDetailViewController()
        detailVC.imageModel = imageModel
        detailVC.currentIndex = indexPath.item
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 그리드 타입에 따라 다른 크기 계산
        switch currentGridType {
        case .threeColumns:
            let width = collectionView.frame.width / 3 - 2  // 3열 레이아웃
            return CGSize(width: width, height: width)
        case .fourColumns:
            let width = collectionView.frame.width / 4 - 2  // 4열 레이아웃
            return CGSize(width: width, height: width)
        }
    }
}
