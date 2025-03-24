//
//  FilterCollectionViewCell.swift
//  FotoFX
//
//  Created by USER on 3/23/25.
//

import UIKit

class FilterCollectionViewCell: UICollectionViewCell {
    private let filterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true
        imageView.backgroundColor = .lightGray  // 이미지 로드 전 배경색
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()
    
    var filterName: String? {
        didSet {
            nameLabel.text = filterName
        }
    }
    
    // 미리보기 이미지 설정 메서드 추가
    func setPreviewImage(_ image: UIImage?) {
        filterImageView.image = image
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(filterImageView)
        addSubview(nameLabel)
        
        filterImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            filterImageView.topAnchor.constraint(equalTo: topAnchor),
            filterImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            filterImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            filterImageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: filterImageView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    override var isSelected: Bool {
        didSet {
            layer.borderWidth = isSelected ? 2 : 0
            layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : nil
        }
    }
}
