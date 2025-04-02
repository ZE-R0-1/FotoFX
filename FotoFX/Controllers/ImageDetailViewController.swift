//
//  ImageDetailViewController.swift
//  FotoFX
//
//  Created by USER on 4/2/25.
//

import UIKit
import Photos

class ImageDetailViewController: UIViewController {
    
    // 이미지 모델과 현재 이미지 인덱스
    var imageModel: ImageModel!
    var currentIndex: Int = 0
    var totalCount: Int = 0
    var editableImage: ImageModel.EditableImage!
    
    // 페이지 뷰 컨트롤러
    private var pageViewController: UIPageViewController!
    
    // 하단 툴바 컨테이너
    private let bottomToolbarContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    // 구분선
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray.withAlphaComponent(0.3)
        return view
    }()
    
    // VideoLab 버튼
    private let videoLabButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("VIDEOLAB", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.tintColor = .darkGray
        return button
    }()
    
    // VideoLab 아이콘
    private let videoLabIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "video.circle.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGreen
        return imageView
    }()
    
    // 편집 버튼
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("편집", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.tintColor = .darkGray
        return button
    }()
    
    // 편집 아이콘
    private let editIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "wand.and.stars")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .darkGray
        return imageView
    }()
    
    // 하단 홈 인디케이터 영역 (iOS의 홈 바)
    private let homeIndicatorArea: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        
        // 홈 인디케이터 바 추가
        let bar = UIView()
        bar.backgroundColor = .darkGray
        bar.layer.cornerRadius = 2.5
        view.addSubview(bar)
        
        bar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bar.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            bar.widthAnchor.constraint(equalToConstant: 130),
            bar.heightAnchor.constraint(equalToConstant: 5)
        ])
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupPageViewController()
        updateTitle()
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        
        // 네비게이션 바 설정
        setupNavigationBar()
        
        // 하단 툴바 추가
        view.addSubview(bottomToolbarContainer)
        
        // 구분선 추가
        bottomToolbarContainer.addSubview(separatorLine)
        
        // VideoLab 버튼 컨테이너
        let videoLabContainer = UIView()
        videoLabContainer.backgroundColor = .clear
        bottomToolbarContainer.addSubview(videoLabContainer)
        
        videoLabContainer.addSubview(videoLabIconView)
        videoLabContainer.addSubview(videoLabButton)
        
        // 편집 버튼 컨테이너
        let editContainer = UIView()
        editContainer.backgroundColor = .clear
        bottomToolbarContainer.addSubview(editContainer)
        
        editContainer.addSubview(editIconView)
        editContainer.addSubview(editButton)
        
        // 홈 인디케이터 영역 추가
        view.addSubview(homeIndicatorArea)
        
        // Auto Layout 설정
        bottomToolbarContainer.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        videoLabContainer.translatesAutoresizingMaskIntoConstraints = false
        videoLabIconView.translatesAutoresizingMaskIntoConstraints = false
        videoLabButton.translatesAutoresizingMaskIntoConstraints = false
        editContainer.translatesAutoresizingMaskIntoConstraints = false
        editIconView.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        homeIndicatorArea.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 하단 툴바 레이아웃
            bottomToolbarContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbarContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbarContainer.bottomAnchor.constraint(equalTo: homeIndicatorArea.topAnchor),
            bottomToolbarContainer.heightAnchor.constraint(equalToConstant: 90),
            
            // 구분선 레이아웃
            separatorLine.topAnchor.constraint(equalTo: bottomToolbarContainer.topAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: bottomToolbarContainer.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: bottomToolbarContainer.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            
            // VideoLab 컨테이너 레이아웃
            videoLabContainer.leadingAnchor.constraint(equalTo: bottomToolbarContainer.leadingAnchor),
            videoLabContainer.topAnchor.constraint(equalTo: bottomToolbarContainer.topAnchor),
            videoLabContainer.bottomAnchor.constraint(equalTo: bottomToolbarContainer.bottomAnchor),
            videoLabContainer.widthAnchor.constraint(equalTo: bottomToolbarContainer.widthAnchor, multiplier: 0.5),
            
            // VideoLab 아이콘 및 버튼 레이아웃
            videoLabIconView.centerXAnchor.constraint(equalTo: videoLabContainer.centerXAnchor),
            videoLabIconView.topAnchor.constraint(equalTo: videoLabContainer.topAnchor, constant: 15),
            videoLabIconView.widthAnchor.constraint(equalToConstant: 28),
            videoLabIconView.heightAnchor.constraint(equalToConstant: 28),
            
            videoLabButton.centerXAnchor.constraint(equalTo: videoLabContainer.centerXAnchor),
            videoLabButton.topAnchor.constraint(equalTo: videoLabIconView.bottomAnchor, constant: 5),
            
            // 편집 컨테이너 레이아웃
            editContainer.trailingAnchor.constraint(equalTo: bottomToolbarContainer.trailingAnchor),
            editContainer.topAnchor.constraint(equalTo: bottomToolbarContainer.topAnchor),
            editContainer.bottomAnchor.constraint(equalTo: bottomToolbarContainer.bottomAnchor),
            editContainer.widthAnchor.constraint(equalTo: bottomToolbarContainer.widthAnchor, multiplier: 0.5),
            
            // 편집 아이콘 및 버튼 레이아웃
            editIconView.centerXAnchor.constraint(equalTo: editContainer.centerXAnchor),
            editIconView.topAnchor.constraint(equalTo: editContainer.topAnchor, constant: 15),
            editIconView.widthAnchor.constraint(equalToConstant: 28),
            editIconView.heightAnchor.constraint(equalToConstant: 28),
            
            editButton.centerXAnchor.constraint(equalTo: editContainer.centerXAnchor),
            editButton.topAnchor.constraint(equalTo: editIconView.bottomAnchor, constant: 5),
            
            // 홈 인디케이터 영역 레이아웃
            homeIndicatorArea.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            homeIndicatorArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            homeIndicatorArea.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            homeIndicatorArea.heightAnchor.constraint(equalToConstant: 34)
        ])
        
        // 버튼 액션 추가
        videoLabButton.addTarget(self, action: #selector(videoLabButtonTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        
        // 탭 제스처 추가 (VideoLab 컨테이너)
        let videoLabTapGesture = UITapGestureRecognizer(target: self, action: #selector(videoLabButtonTapped))
        videoLabContainer.addGestureRecognizer(videoLabTapGesture)
        videoLabContainer.isUserInteractionEnabled = true
        
        // 탭 제스처 추가 (편집 컨테이너)
        let editTapGesture = UITapGestureRecognizer(target: self, action: #selector(editButtonTapped))
        editContainer.addGestureRecognizer(editTapGesture)
        editContainer.isUserInteractionEnabled = true
    }
    
    private func setupPageViewController() {
        // 페이지 뷰 컨트롤러 초기화
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        // 페이지 뷰 컨트롤러를 자식 뷰 컨트롤러로 추가
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        // 페이지 뷰 컨트롤러 레이아웃 설정
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: bottomToolbarContainer.topAnchor)
        ])
        
        // 첫 번째 페이지 설정
        totalCount = imageModel.getEditableImagesCount()
        if totalCount > 0 {
            if let initialVC = createImagePageViewController(for: currentIndex) {
                pageViewController.setViewControllers([initialVC], direction: .forward, animated: false)
                editableImage = imageModel.selectImageForEditing(at: currentIndex)
            }
        }
    }
    
    private func createImagePageViewController(for index: Int) -> UIViewController? {
        guard index >= 0, index < totalCount else { return nil }
        
        let pageContentVC = UIViewController()
        pageContentVC.view.backgroundColor = .white
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        
        if let image = imageModel.getImage(at: index) {
            imageView.image = image
        }
        
        pageContentVC.view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: pageContentVC.view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: pageContentVC.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: pageContentVC.view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: pageContentVC.view.bottomAnchor)
        ])
        
        // 페이지 인덱스 저장
        pageContentVC.view.tag = index
        
        return pageContentVC
    }
    
    private func setupNavigationBar() {
        // 네비게이션 바 표시
        navigationController?.navigationBar.isHidden = false
        
        // 네비게이션 바 색상 - 검은 배경에 흰색 텍스트
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .regular)
        ]
        
        // 페이지 인디케이터 (2 / 2) 스타일의 제목 설정
        updateTitle()
        
        // 뒤로가기 버튼
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
        
        // 오른쪽 버튼들 (휴지통, 공유 버튼)
        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )
        
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareButtonTapped)
        )
        
        navigationItem.rightBarButtonItems = [shareButton, deleteButton]
    }
    
    private func updateTitle() {
        // "현재 위치 / 전체 수" 형식의 제목 설정
        title = "\(currentIndex + 1) / \(totalCount)"
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func deleteButtonTapped() {
        // 삭제 확인 다이얼로그
        let alert = UIAlertController(
            title: "이미지 삭제",
            message: "이 이미지를 갤러리에서 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            let indexToDelete = self.currentIndex
            
            // 이미지 모델에서 이미지 삭제 요청
            self.imageModel.deleteImage(at: indexToDelete) { (success, error) in
                DispatchQueue.main.async {
                    if success {
                        // 전체 이미지 개수 갱신
                        self.totalCount = self.imageModel.getEditableImagesCount()
                        
                        if self.totalCount == 0 {
                            // 이미지가 없으면 이전 화면으로 돌아가기
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            // 현재 인덱스 조정
                            if self.currentIndex >= self.totalCount {
                                self.currentIndex = self.totalCount - 1
                            }
                            
                            // 페이지 뷰 컨트롤러 업데이트
                            if let newVC = self.createImagePageViewController(for: self.currentIndex) {
                                self.pageViewController.setViewControllers(
                                    [newVC],
                                    direction: .forward,
                                    animated: true
                                )
                                self.editableImage = self.imageModel.selectImageForEditing(at: self.currentIndex)
                                self.updateTitle()
                            }
                        }
                    } else {
                        // 삭제 실패 처리
                        let errorAlert = UIAlertController(
                            title: "삭제 실패",
                            message: error?.localizedDescription ?? "이미지를 삭제하는 중 오류가 발생했습니다.",
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "확인", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    @objc private func shareButtonTapped() {
        // 현재 페이지의 이미지 가져오기
        guard let currentVC = pageViewController.viewControllers?.first,
              let imageView = currentVC.view.subviews.first as? UIImageView,
              let image = imageView.image else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // iPad에서 팝오버 설정
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?[0]
        }
        
        present(activityViewController, animated: true)
    }
    
    @objc private func videoLabButtonTapped() {
        print("VideoLab 버튼 탭됨")
        // VideoLab 기능 구현 (현재는 로그만 출력)
    }
    
    @objc private func editButtonTapped() {
        print("편집 버튼 탭됨")
        
        // EditViewController로 이동
        if let editableImage = editableImage {
            let editVC = EditViewController()
            editVC.source = .gallery
            editVC.imageModel = imageModel
            editVC.editableImage = editableImage
            navigationController?.pushViewController(editVC, animated: true)
        }
    }
}

// MARK: - UIPageViewControllerDataSource
extension ImageDetailViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentIndex = viewController.view.tag
        
        // 이전 페이지는 현재 인덱스 - 1
        guard currentIndex > 0 else { return nil }
        return createImagePageViewController(for: currentIndex - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let currentIndex = viewController.view.tag
        
        // 다음 페이지는 현재 인덱스 + 1
        guard currentIndex < totalCount - 1 else { return nil }
        return createImagePageViewController(for: currentIndex + 1)
    }
}

// MARK: - UIPageViewControllerDelegate
extension ImageDetailViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let visibleViewController = pageViewController.viewControllers?.first {
            let newIndex = visibleViewController.view.tag
            currentIndex = newIndex
            editableImage = imageModel.selectImageForEditing(at: currentIndex)
            updateTitle()
        }
    }
}
