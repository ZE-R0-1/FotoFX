# FotoFX
 이미지편집 및 카메라 서비스

## 주요 기능

### 홈 화면
- 직관적인 홈 인터페이스로 다양한 기능에 쉽게 접근
- 편집, 콜라주, 매거진, 템플릿, 뷰티카메라, VideoLab UI 표시
- 추천 기능 및 빠른 액세스 옵션 UI 표시

### 갤러리 및 이미지 관리
- 기기의 사진 라이브러리에서 이미지 불러오기
- 3열/4열 그리드 레이아웃 전환 기능
- 이미지 선택, 삭제 및 상세 보기

### 이미지 상세 보기
- 페이지 형식의 이미지 탐색
- 이미지 공유 및 삭제 기능
- 편집 모드로 빠른 전환

### 이미지 편집 기능
- 다양한 필터 적용
  - 빈티지, 선셋, 네온, 트와일라잇 등 실시간 필터
- 필터 미리보기로 적용 전 효과 확인
- 실시간 이미지 처리 및 렌더링

### 카메라 기능
- 내장 카메라로 사진 촬영
- 촬영 후 바로 편집 가능
- 카메라 권한 관리 및 에러 처리

### 이미지 저장 및 공유
- 갤러리에 이미지 저장
- 소셜 미디어, 메시지 앱 등으로 이미지 공유
- 권한 관리 및 저장 기능

## 기술 스택

- **언어**: Swift, Objective-C (일부 렌더링 코드)
- **프레임워크**:
  - UIKit: UI 구성 및 관리
  - AVFoundation: 카메라 기능
  - Photos: 갤러리 접근 및 이미지 관리
  - Metal: 고성능 GPU 기반 이미지 처리
  - OpenGL ES: 레거시 이미지 필터링
- **아키텍처**: MVC 패턴
- **렌더링 기술**:
  - Metal 셰이더 기반 필터
  - OpenGL ES 기반 필터

## 프로젝트 구조

```
FotoFX/
├── AppDelegate.swift                 # 앱 진입점
├── SceneDelegate.swift               # 씬 관리
├── Models/
│   ├── ImageModel.swift              # 이미지 데이터 및 관리
│   ├── FilterModel.swift             # 필터 정의 및 구조
│   └── FilterManager.swift           # 필터 관리
├── ViewControllers/
│   ├── HomeViewController.swift      # 메인 화면
│   ├── RecentItemsViewController.swift # 갤러리 화면
│   ├── ImageDetailViewController.swift # 이미지 상세 화면
│   ├── EditViewController.swift      # 편집 화면
│   └── CameraViewController.swift    # 카메라 화면
├── Views/
│   └── FilterCollectionViewCell.swift # 필터 셀 정의
├── Renderers/
│   ├── MetalRenderer.swift           # Metal 기반 렌더링
│   ├── GeneralizedOpenGLRenderer.swift # OpenGL 래퍼
│   └── OpenGLRenderer.m              # Objective-C OpenGL 렌더링
└── Resources/
    └── filters.json                  # 필터 정의 데이터
```

## 권한 요청

앱은 다음의 권한을 요청합니다:
- 카메라 접근 (사진 촬영용)
- 사진 라이브러리 접근 (이미지 불러오기 및 저장)
