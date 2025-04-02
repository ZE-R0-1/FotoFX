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
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.backgroundColor = .darkGray // 이미지 로드 전 배경색
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .white
        return label
    }()
    
    var filterName: String? {
        didSet {
            nameLabel.text = filterName
        }
    }
    
    // 미리보기 이미지 설정 메서드
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
            filterImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            filterImageView.widthAnchor.constraint(equalToConstant: 50),
            filterImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: filterImageView.bottomAnchor, constant: 5),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                filterImageView.layer.borderWidth = 3
                filterImageView.layer.borderColor = UIColor.white.cgColor
                nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            } else {
                filterImageView.layer.borderWidth = 0
                filterImageView.layer.borderColor = nil
                nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            }
        }
    }
}
