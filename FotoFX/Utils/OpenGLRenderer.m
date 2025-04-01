//
//  OpenGLRenderer.m
//  FotoFX
//
//  Created by USER on 3/23/25.
//


#import "OpenGLRenderer.h"
#import <GLKit/GLKit.h>

static void releaseDataCallback(void *info, const void *data, size_t size) {
    free((void *)data);
}

@implementation OpenGLRenderer {
    EAGLContext *_context;
    GLuint _framebuffer;
    GLuint _renderbuffer;
    GLuint _program;
    GLuint _texture;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // OpenGL ES 컨텍스트 설정
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        
        if (!_context) {
            NSLog(@"OpenGL ES 3.0을 사용할 수 없습니다.");
            return nil;
        }
        
        [EAGLContext setCurrentContext:_context];
        
        // 셰이더 설정
        [self setupShaders];
    }
    return self;
}

- (void)dealloc {
    [EAGLContext setCurrentContext:_context];
    
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    
    if (_texture) {
        glDeleteTextures(1, &_texture);
        _texture = 0;
    }
    
    [EAGLContext setCurrentContext:nil];
}

- (void)setupShaders {
    // 버텍스 셰이더
    NSString *vertexShaderSource = @"attribute vec4 position;\
    attribute vec2 texCoord;\
    varying vec2 v_texCoord;\
    \
    void main() {\
        gl_Position = position;\
        v_texCoord = texCoord;\
    }";
    
    // 프래그먼트 셰이더
    NSString *fragmentShaderSource = @"precision mediump float;\
    varying vec2 v_texCoord;\
    uniform sampler2D u_texture;\
    uniform int u_filterType;\
    \
    void main() {\
        vec4 color = texture2D(u_texture, v_texCoord);\
        vec4 result;\
        \
        if (u_filterType == 1) { /* Sepia */\
            float r = color.r * 0.393 + color.g * 0.769 + color.b * 0.189;\
            float g = color.r * 0.349 + color.g * 0.686 + color.b * 0.168;\
            float b = color.r * 0.272 + color.g * 0.534 + color.b * 0.131;\
            result = vec4(vec3(r, g, b), color.a);\
        } else if (u_filterType == 3) { /* Chrome */\
            vec3 chrome = vec3(color.r * 0.8 + 0.2, color.g * 0.8 + 0.2, color.b * 0.8 + 0.2);\
            result = vec4(chrome, color.a);\
        } else if (u_filterType == 5) { /* Mono */\
            float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));\
            result = vec4(vec3(gray), color.a);\
        } else if (u_filterType == 7) { /* Transfer */\
            vec3 transfer = vec3(1.0 - color.r, 1.0 - color.g, color.b);\
            result = vec4(transfer, color.a);\
        } else { /* Fallback */\
            result = color;\
        }\
        \
        gl_FragColor = result;\
    }";
    
    // 셰이더 컴파일 및 프로그램 생성
    _program = [self createProgramWithVertexShader:vertexShaderSource fragmentShader:fragmentShaderSource];
}

- (GLuint)createProgramWithVertexShader:(NSString *)vertexShaderSource fragmentShader:(NSString *)fragmentShaderSource {
    GLuint vertexShader = [self compileShader:vertexShaderSource withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:fragmentShaderSource withType:GL_FRAGMENT_SHADER];
    
    if (vertexShader == 0 || fragmentShader == 0) {
        NSLog(@"셰이더 컴파일 실패");
        return 0;
    }
    
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    GLint linkStatus;
    glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLint logLength;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
        
        if (logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetProgramInfoLog(program, logLength, &logLength, log);
            NSLog(@"프로그램 링크 실패: %s", log);
            free(log);
        }
        
        glDeleteProgram(program);
        return 0;
    }
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return program;
}

- (GLuint)compileShader:(NSString *)shaderString withType:(GLenum)type {
    GLuint shader = glCreateShader(type);
    const char *shaderStringUTF8 = [shaderString UTF8String];
    GLint length = (GLint)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, &length);
    glCompileShader(shader);
    
    GLint compileStatus;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileStatus);
    
    if (compileStatus == GL_FALSE) {
        GLint logLength;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
        
        if (logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(shader, logLength, &logLength, log);
            NSLog(@"셰이더 컴파일 실패: %s", log);
            free(log);
        }
        
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}

- (UIImage *)applyFilter:(UIImage *)image filterType:(NSInteger)filterType {
    [EAGLContext setCurrentContext:_context];
    
    if (_program == 0) {
        NSLog(@"유효한 셰이더 프로그램이 없습니다.");
        return image; // 원본 이미지 반환
    }
    
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    // 텍스처 생성
    if (_texture) {
        glDeleteTextures(1, &_texture);
    }
    
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    
    // 이미지 데이터 로드
    GLubyte *imageData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4,
                                               CGImageGetColorSpace(cgImage),
                                               kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(context);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    free(imageData);
    
    // 텍스처 파라미터 설정
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 프레임버퍼 설정
    if (!_framebuffer) {
        glGenFramebuffers(1, &_framebuffer);
    }
    
    if (!_renderbuffer) {
        glGenRenderbuffers(1, &_renderbuffer);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, (GLsizei)width, (GLsizei)height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"프레임버퍼가 완전하지 않습니다: %d", status);
        return image; // 오류 시 원본 이미지 반환
    }
    
    // 뷰포트 설정
    glViewport(0, 0, (GLsizei)width, (GLsizei)height);
    
    // 프로그램 사용
    glUseProgram(_program);
    
    // 쿼드 그리기 위한 정점과 텍스처 좌표
    const GLfloat vertices[] = {
        -1.0f, -1.0f, 0.0f, 0.0f,  // 왼쪽 아래 (위치 xy, 텍스처 좌표 st)
         1.0f, -1.0f, 1.0f, 0.0f,  // 오른쪽 아래
        -1.0f,  1.0f, 0.0f, 1.0f,  // 왼쪽 위
         1.0f,  1.0f, 1.0f, 1.0f,  // 오른쪽 위
    };
    
    // 유니폼 설정
    GLint textureUniform = glGetUniformLocation(_program, "u_texture");
    GLint filterTypeUniform = glGetUniformLocation(_program, "u_filterType");
    
    glUniform1i(textureUniform, 0);
    glUniform1i(filterTypeUniform, (GLint)filterType);
    
    // 어트리뷰트 설정
    GLint positionAttribute = glGetAttribLocation(_program, "position");
    GLint texCoordAttribute = glGetAttribLocation(_program, "texCoord");
    
    glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), vertices);
    glEnableVertexAttribArray(positionAttribute);
    
    glVertexAttribPointer(texCoordAttribute, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), vertices + 2);
    glEnableVertexAttribArray(texCoordAttribute);
    
    // 클리어 및 그리기
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // 결과 읽기
    GLubyte *resultData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    glReadPixels(0, 0, (GLsizei)width, (GLsizei)height, GL_RGBA, GL_UNSIGNED_BYTE, resultData);
    
    // 메모리 해제를 위한 릴리즈 콜백 함수 추가
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                             resultData,
                                                             width * height * 4,
                                                             releaseDataCallback);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // RGBA 형식에 맞는 비트맵 정보 설정
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
    
    CGImageRef filteredImageRef = CGImageCreate(width, height, 8, 32, width * 4,
                                              colorSpace,
                                              bitmapInfo,
                                              provider, NULL, true, kCGRenderingIntentDefault);
    
    UIImage *filteredImage = [UIImage imageWithCGImage:filteredImageRef];
    
    // 메모리 해제 - resultData는 이제 릴리즈 콜백에서 해제됨
    CGImageRelease(filteredImageRef);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    
    // 버텍스 어트리뷰트 비활성화
    glDisableVertexAttribArray(positionAttribute);
    glDisableVertexAttribArray(texCoordAttribute);
    
    return filteredImage;
}

@end
