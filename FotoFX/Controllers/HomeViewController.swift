//
//  HomeViewController.swift
//  FotoFX
//
//  Created by USER on 4/2/25.
//

import UIKit

class HomeViewController: UIViewController {
    
    // 아이콘 버튼을 담을 컨테이너 뷰
    private let iconsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 15
        return view
    }()
    
    // 상단 검색바 스타일의 뷰
    private let searchBarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.9, alpha: 0.8)
        view.layer.cornerRadius = 20
        return view
    }()
    
    private let searchLabel: UILabel = {
        let label = UILabel()
        label.text = "MOLDIV 프리미엄"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return label
    }()
    
    private let searchArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right.circle.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // 스크롤 뷰
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    // 스크롤 뷰의 내용을 담을 컨테이너 뷰
    private let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    // 각 기능 버튼과 레이블을 포함하는 메서드
    private func createFeatureButton(imageName: String, title: String) -> UIView {
        let containerView = UIView()
        
        let imageView = UIImageView()
        if imageName.starts(with: "system:") {
            // 시스템 이미지 사용
            let systemName = imageName.replacingOccurrences(of: "system:", with: "")
            imageView.image = UIImage(systemName: systemName)
            imageView.tintColor = .black
        } else {
            // 커스텀 이미지나 단순 심볼 사용
            imageView.image = UIImage(named: imageName)
            
            // 이미지가 없는 경우 기본 아이콘 생성
            if imageView.image == nil {
                // 각 기능별로 다른 기본 아이콘 설정
                switch title {
                case "편집":
                    imageView.image = UIImage(systemName: "wand.and.stars")
                case "콜라주":
                    imageView.image = UIImage(systemName: "rectangle.3.group")
                case "매거진":
                    imageView.image = UIImage(systemName: "newspaper")
                case "템플릿":
                    imageView.image = UIImage(systemName: "play.fill")
                case "뷰티카메라":
                    imageView.image = UIImage(systemName: "camera")
                case "VideoLab":
                    imageView.image = UIImage(systemName: "video")
                default:
                    imageView.image = UIImage(systemName: "questionmark.circle")
                }
                imageView.tintColor = .black
            }
        }
        
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        
        containerView.addSubview(imageView)
        containerView.addSubview(label)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 30),
            imageView.heightAnchor.constraint(equalToConstant: 30),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        // 버튼 동작을 위한 제스처 인식기 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(featureButtonTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        containerView.tag = getTagForFeature(title: title)
        
        return containerView
    }
    
    // 기능별 태그 값 반환
    private func getTagForFeature(title: String) -> Int {
        switch title {
        case "편집": return 1
        case "콜라주": return 2
        case "매거진": return 3
        case "템플릿": return 4
        case "뷰티카메라": return 5
        case "VideoLab": return 6
        default: return 0
        }
    }
    
    // 버튼 탭 이벤트 처리
    @objc private func featureButtonTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        switch view.tag {
        case 1: // 편집
            print("편집 버튼 탭됨")
            let mainVC = RecentItemsViewController()
            navigationController?.pushViewController(mainVC, animated: true)
            
        case 2: // 콜라주
            print("콜라주 버튼 탭됨")
            
        case 3: // 매거진
            print("매거진 버튼 탭됨")
            
        case 4: // 템플릿
            print("템플릿 버튼 탭됨")
            
        case 5: // 뷰티카메라
            print("뷰티카메라 버튼 탭됨")
            
        case 6: // VideoLab
            print("VideoLab 버튼 탭됨")
            
        default:
            print("알 수 없는 버튼 탭됨")
        }
    }
    
    // 추천 기능 섹션 제목
    private let recommendedLabel: UILabel = {
        let label = UILabel()
        label.text = "추천 기능"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        return label
    }()
    
    // 추천 기능 이미지 컬렉션 뷰
    private lazy var recommendedCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 200)
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "RecommendedCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        // 스크롤 뷰 추가
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 상단 검색바 설정
        contentView.addSubview(searchBarView)
        searchBarView.addSubview(searchLabel)
        searchBarView.addSubview(searchArrowImageView)
        
        // 아이콘 컨테이너 뷰 설정
        contentView.addSubview(iconsContainerView)
        
        // 추천 기능 섹션 설정
        contentView.addSubview(recommendedLabel)
        contentView.addSubview(recommendedCollectionView)
        
        // 오토레이아웃 설정
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        searchBarView.translatesAutoresizingMaskIntoConstraints = false
        searchLabel.translatesAutoresizingMaskIntoConstraints = false
        searchArrowImageView.translatesAutoresizingMaskIntoConstraints = false
        iconsContainerView.translatesAutoresizingMaskIntoConstraints = false
        recommendedLabel.translatesAutoresizingMaskIntoConstraints = false
        recommendedCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 스크롤 뷰 레이아웃
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 컨텐트 뷰 레이아웃 - 스크롤 뷰의 내용 크기 정의
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            // 높이 제약은 없지만 내부 콘텐츠의 제약을 통해 자동으로 계산됨
            
            // 검색바 레이아웃
            searchBarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            searchBarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            searchBarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            searchBarView.heightAnchor.constraint(equalToConstant: 50),
            
            searchLabel.leadingAnchor.constraint(equalTo: searchBarView.leadingAnchor, constant: 15),
            searchLabel.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor),
            
            searchArrowImageView.trailingAnchor.constraint(equalTo: searchBarView.trailingAnchor, constant: -15),
            searchArrowImageView.centerYAnchor.constraint(equalTo: searchBarView.centerYAnchor),
            searchArrowImageView.widthAnchor.constraint(equalToConstant: 25),
            searchArrowImageView.heightAnchor.constraint(equalToConstant: 25),
            
            // 아이콘 컨테이너 레이아웃
            iconsContainerView.topAnchor.constraint(equalTo: searchBarView.bottomAnchor, constant: 240),
            iconsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            iconsContainerView.heightAnchor.constraint(equalToConstant: 220),
            
            // 추천 기능 레이블 레이아웃
            recommendedLabel.topAnchor.constraint(equalTo: iconsContainerView.bottomAnchor, constant: 30),
            recommendedLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // 추천 기능 컬렉션뷰 레이아웃
            recommendedCollectionView.topAnchor.constraint(equalTo: recommendedLabel.bottomAnchor),
            recommendedCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            recommendedCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            recommendedCollectionView.heightAnchor.constraint(equalToConstant: 250),
            // 중요: contentView의 bottom 제약을 recommendedCollectionView의 bottom에 연결
            contentView.bottomAnchor.constraint(equalTo: recommendedCollectionView.bottomAnchor, constant: 20)
        ])
        
        // 기능 아이콘 그리드 설정
        setupFeatureIcons()
    }
    
    private func setupFeatureIcons() {
        // 2x3 그리드로 기능 아이콘 배치
        let featureTitles = ["편집", "콜라주", "매거진", "템플릿", "뷰티카메라", "VideoLab"]
        let iconNames = ["system:wand.and.stars", "system:rectangle.3.group", "system:newspaper", "system:play.fill", "system:camera", "custom:videolab"]
        
        // 그리드 레이아웃 계산
        let containerWidth = UIScreen.main.bounds.width - 40 // 양쪽 여백 20씩
        let itemWidth = containerWidth / 3
        let itemHeight: CGFloat = 90
        
        // 아이콘 뷰들을 담을 컨테이너
        let gridContainer = UIView()
        iconsContainerView.addSubview(gridContainer)
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 2행 3열 그리드의 전체 크기 계산
        let gridWidth = itemWidth * 3
        let gridHeight = itemHeight * 2
        
        // 그리드 컨테이너를 iconsContainerView 중앙에 배치
        NSLayoutConstraint.activate([
            gridContainer.centerXAnchor.constraint(equalTo: iconsContainerView.centerXAnchor),
            gridContainer.centerYAnchor.constraint(equalTo: iconsContainerView.centerYAnchor),
            gridContainer.widthAnchor.constraint(equalToConstant: gridWidth),
            gridContainer.heightAnchor.constraint(equalToConstant: gridHeight)
        ])
        
        for i in 0..<featureTitles.count {
            let row = i / 3
            let col = i % 3
            
            let featureView = createFeatureButton(imageName: iconNames[i], title: featureTitles[i])
            gridContainer.addSubview(featureView)
            
            featureView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                featureView.topAnchor.constraint(equalTo: gridContainer.topAnchor, constant: CGFloat(row) * itemHeight),
                featureView.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor, constant: CGFloat(col) * itemWidth),
                featureView.widthAnchor.constraint(equalToConstant: itemWidth),
                featureView.heightAnchor.constraint(equalToConstant: itemHeight)
            ])
        }
    }
}

// MARK: - UICollectionView 데이터 소스 및 델리게이트 구현
extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4 // 샘플 추천 항목 4개
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecommendedCell", for: indexPath)
        
        // 셀 스타일 설정
        cell.backgroundColor = UIColor.systemGray5
        cell.layer.cornerRadius = 10
        cell.clipsToBounds = true
        
        // 기존 콘텐츠 제거
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // 이미지 추가 (예시)
        let imageView = UIImageView(frame: cell.contentView.bounds)
        // 인덱스에 따라 다른 시스템 아이콘 사용
        let systemImages = ["photo", "camera.viewfinder", "video", "square.and.pencil"]
        imageView.image = UIImage(systemName: systemImages[indexPath.item])
        imageView.contentMode = .center
        imageView.tintColor = .darkGray
        cell.contentView.addSubview(imageView)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("추천 기능 \(indexPath.item + 1) 선택됨")
    }
}
