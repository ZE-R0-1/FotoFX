//
//  OpenGLRenderer.h
//  FotoFX
//
//  Created by USER on 3/23/25.
//

#define GLES_SILENCE_DEPRECATION 1

#import <UIKit/UIKit.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface OpenGLRenderer : NSObject

// 기존 메서드는 유지 (호환성을 위해)
- (UIImage *)applyFilter:(UIImage *)image filterType:(NSInteger)filterType;

// 새로운 일반화된 메서드 추가 - JSON으로부터 모든 파라미터 지원
- (UIImage *)applyFilter:(UIImage *)image
           redMultiplier:(float)redMultiplier
         greenMultiplier:(float)greenMultiplier
          blueMultiplier:(float)blueMultiplier
               intensity:(float)intensity
               tintColor:(NSArray<NSNumber *> *)tintColor
           tintIntensity:(float)tintIntensity
             grayscaleMix:(float)grayscaleMix
               invertMix:(float)invertMix;

@end
