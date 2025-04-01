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

- (UIImage *)applyFilter:(UIImage *)image filterType:(NSInteger)filterType;

@end
