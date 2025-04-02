//
//  CameraViewController.swift
//  FotoFX
//
//  Created by USER on 3/23/25.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    // MARK: - Properties
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // 카메라가 이미 설정되었는지 추적하는 플래그 추가
    private var isCameraSetup = false
    // MARK: - UI Components
    // 로딩 인디케이터 추가
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.tintColor = .black
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.isHidden = true // 초기에는 숨김
        return button
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 카메라가 이미 설정되어 있으면 세션만 다시 시작
        if isCameraSetup {
            restartCameraSession()
        } else {
            // 최초 진입 시에만 권한 확인 및 카메라 설정
            checkCameraPermission()
        }
    }
    
    // 카메라 세션 다시 시작하는 메서드 추가
    private func restartCameraSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self?.captureButton.isHidden = false
                }
            }
        }
    }
    
    // MARK: - Camera Management
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // 백그라운드 큐에서 카메라 설정 시작
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
            }
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.setupCamera()
                
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.captureButton.isHidden = false
                    self?.isCameraSetup = true // 카메라 설정 완료 플래그 설정
                }
            }
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.activityIndicator.startAnimating()
                    }
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        self?.setupCamera()
                        
                        DispatchQueue.main.async {
                            self?.activityIndicator.stopAnimating()
                            self?.captureButton.isHidden = false
                            self?.isCameraSetup = true // 카메라 설정 완료 플래그 설정
                        }
                    }
                } else {
                    self?.showPermissionAlert()
                }
            }
            
        case .denied, .restricted:
            showPermissionAlert()
            
        @unknown default:
            break
        }
    }
    
    // MARK: - UI Setup
    private func setupViews() {
        view.backgroundColor = .black
        
        view.addSubview(captureButton)
        view.addSubview(activityIndicator)
        
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - NavigationBar Setup
    private func setupNavigationBar() {
        // 네비게이션 바 표시
        navigationController?.navigationBar.isHidden = false
        
        // 타이틀 설정
        title = "카메라"
        
        // 뒤로가기 버튼 커스텀
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .white
        navigationItem.leftBarButtonItem = backButton
        
        // 네비게이션 바 스타일 설정 (어두운 배경에 밝은 텍스트)
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupCamera() {
        // 이미 설정된 경우 다시 설정하지 않음
        if isCameraSetup {
            return
        }
        
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("카메라를 사용할 수 없습니다.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer?.videoGravity = .resizeAspectFill
                self.previewLayer?.frame = self.view.layer.bounds
                
                if let previewLayer = self.previewLayer {
                    self.view.layer.insertSublayer(previewLayer, at: 0)
                }
            }
            
            // 카메라 시작
            self.captureSession.startRunning()
            
        } catch {
            print("카메라 설정 오류: \(error)")
        }
    }
    
    // MARK: - Permission Handling
    private func showPermissionAlert() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "카메라 접근 권한이 필요합니다",
                message: "설정 앱에서 카메라 접근 권한을 허용해주세요.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            
            alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
                // 취소 시 이전 화면으로 돌아가기
                self?.navigationController?.popViewController(animated: true)
            })
            
            self?.present(alert, animated: true)
        }
    }
    
    // MARK: - Action Handlers
    @objc private func captureButtonTapped() {
        // 명시적으로 JPEG 포맷 지정
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
    
    // 메모리 해제 시 카메라 세션 중지 및 리소스 정리
    deinit {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        
        // 필요하다면 다른 리소스 정리
        print("CameraViewController 메모리 해제")
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    // iOS 11 이상에서 사용하는 현재 메서드
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("사진 처리 오류: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let capturedImage = UIImage(data: imageData) else {
            print("이미지 데이터 변환 실패")
            return
        }
        
        // 이미지 방향 수정
        let fixedImage = fixImageOrientation(capturedImage)
        
        // 이미지 크기 제한 추가
        let resizedImage = resizeImage(fixedImage, targetSize: CGSize(width: 1500, height: 1500))
        print("이미지 크기 조정 완료: \(resizedImage.size.width) x \(resizedImage.size.height)")
        
        // 편집 화면으로 이동
        DispatchQueue.main.async { [weak self] in
            let editVC = EditViewController()
            editVC.source = .camera
            
            let imageModel = ImageModel()
            let editableImage = imageModel.createNewImage(image: resizedImage)
            imageModel.setCurrentEditingImage(editableImage)  // 이전 문제 해결을 위한 코드도 추가
            editVC.imageModel = imageModel
            editVC.editableImage = editableImage
            self?.navigationController?.pushViewController(editVC, animated: true)
        }
    }
    
    // MARK: - Image Processing
    // 이미지 크기 조정 메서드 추가
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        // 이미 충분히 작으면 그대로 반환
        if size.width <= targetSize.width && size.height <= targetSize.height {
            return image
        }
        
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

    // 이미지 방향 수정 함수 추가
    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        // 디바이스 방향을 확인
        let orientation: UIImage.Orientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = .right  // 세로 모드에서는 오른쪽으로 회전
        case .portraitUpsideDown:
            orientation = .left   // 거꾸로 세로 모드에서는 왼쪽으로 회전
        case .landscapeLeft:
            orientation = .up     // 가로 모드(왼쪽)에서는 회전하지 않음
        case .landscapeRight:
            orientation = .down   // 가로 모드(오른쪽)에서는 180도 회전
        default:
            // 방향을 감지할 수 없는 경우 기본값 (보통 세로 모드)
            orientation = .right
        }
        
        // UIGraphicsImageRenderer를 사용하여 새 이미지 생성
        if image.imageOrientation == orientation {
            return image // 이미 올바른 방향이면 그대로 반환
        }
        
        if let cgImage = image.cgImage {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: orientation)
        }
        
        return image // 실패할 경우 원본 이미지 반환
    }
    
    // iOS 11-12에서 사용하는 메서드 (iOS 18.2에서 호출될 수 있음)
    func captureOutput(_ output: AVCaptureOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("사진 처리 오류 (captureOutput): \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("이미지 데이터 변환 실패 (captureOutput)")
            return
        }
        
        print("사진 촬영 성공 (captureOutput): \(image.size.width) x \(image.size.height)")
        
        // 편집 화면으로 이동
        DispatchQueue.main.async { [weak self] in
            let editVC = EditViewController()
            let imageModel = ImageModel()
            let editableImage = imageModel.createNewImage(image: image)
            editVC.imageModel = imageModel
            editVC.editableImage = editableImage
            self?.navigationController?.pushViewController(editVC, animated: true)
        }
    }
    
    // 구 버전 호환을 위한 메서드 (deprecated이지만 필요할 수 있음)
    @available(iOS, deprecated: 11.0)
    func captureOutput(_ output: AVCaptureOutput,
                     didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,
                     previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?) {
        
        if let error = error {
            print("사진 처리 오류 (Legacy): \(error)")
            return
        }
        
        guard let photoSampleBuffer = photoSampleBuffer,
              let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(
                forJPEGSampleBuffer: photoSampleBuffer,
                previewPhotoSampleBuffer: previewPhotoSampleBuffer),
              let image = UIImage(data: imageData) else {
            print("이미지 데이터 변환 실패 (Legacy)")
            return
        }
        
        print("사진 촬영 성공 (Legacy): \(image.size.width) x \(image.size.height)")
        
        // 편집 화면으로 이동
        DispatchQueue.main.async { [weak self] in
            let editVC = EditViewController()
            let imageModel = ImageModel()
            let editableImage = imageModel.createNewImage(image: image)
            editVC.imageModel = imageModel
            editVC.editableImage = editableImage
            self?.navigationController?.pushViewController(editVC, animated: true)
        }
    }
}
