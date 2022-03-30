//
//  QRCodeTool.m
//  CustomQRCodeSample
//
//  Created by king on 2022/3/29.
//

#import "QRCodeTool.h"

#import "qrencode/QRCode.h"

#import <CoreImage/CoreImage.h>

#define RGB(r, g, b) [UIColor colorWithRed:(r / 255.0) green:(g / 255.0) blue:(b / 255.0) alpha:1.0]
//#define RGB(r, g, b) UIColor.blackColor

@implementation QRCodeTool
+ (UIImage *)generateCodeForString:(nonnull NSString *)str withCorrectionLevel:(kQRCodeCorrectionLevel)corLevel drawType:(kQRCodeDrawType)drawType useBuiltin:(BOOL)useBuiltin {
    if (str.length == 0) {
        return nil;
    }

    @autoreleasepool {

        NSArray<NSArray<NSNumber *> *> *codePoints = nil;
        if (useBuiltin) {
            CIImage *originalImg = [self createOriginalCIImageWithString:str withCorrectionLevel:corLevel];
            //            return [self scaleImage:originalImg toSize:CGSizeMake(200, 200)];
            // 这行代码主要是为了,在断点时,可以通过quicklook 查看
            __unused UIImage *_image = [UIImage imageWithCIImage:originalImg];
            codePoints = [self getPixelsWithCIImage:originalImg];
        } else {
            QRCode *code = [QRCode codeWithString:str version:0 level:(QRCodeLevel)corLevel mode:QRCodeMode8BitData];
            codePoints = [code.map.datas mutableCopy];
        }

        if (codePoints == nil) {
            return nil;
        }

        NSUInteger codeWidth = codePoints.firstObject.count;
        NSUInteger codeHeight = codePoints.count;

        NSUInteger borderWidth = 0;
        NSUInteger bigOrientationAngleWidth = 0;
        NSUInteger tinyOrientationAngleMinX = 0;
        NSUInteger tinyOrientationAngleMaxY = 0;
        NSUInteger gridWidth = 0;
        BOOL findOrientationAngle = NO;
        char *temp_map = alloca(sizeof(char) * codeWidth);

        // 找大的定位角
        NSUInteger lastY = 0;
        for (NSUInteger y = 0; y < codeHeight; y++) {
            lastY = y;
            memset(temp_map, 0, codeWidth);
            borderWidth = 0;
            bigOrientationAngleWidth = 0;
            NSArray<NSNumber *> *rows = codePoints[y];
            for (NSUInteger x = 0; x < codeWidth; x++) {
                BOOL value = [rows[x] boolValue];
                temp_map[x] = value;
                if (x == 0) {
                    if (value) {
                        // 不存在边框
                        bigOrientationAngleWidth += 1;
                    } else {
                        borderWidth += 1;
                    }
                } else {
                    if (temp_map[x - 1] == NO && value) {
                        bigOrientationAngleWidth += 1;
                    } else if (temp_map[x - 1] && !value) {
                        findOrientationAngle = YES;
                        break;
                    } else if (bigOrientationAngleWidth > 0 && value) {
                        bigOrientationAngleWidth += 1;
                    } else {
                        borderWidth += 1;
                    }
                }
            }
            if (findOrientationAngle) {
                break;
            }
        }

        // 找定位角内部小矩形
        for (NSUInteger y = lastY; y < codeHeight; y++) {
            memset(temp_map, 0, bigOrientationAngleWidth);
            tinyOrientationAngleMinX = borderWidth;
            tinyOrientationAngleMaxY = borderWidth;
            findOrientationAngle = NO;
            gridWidth = 0;
            NSArray<NSNumber *> *rows = codePoints[y];
            for (NSUInteger x = borderWidth; x < bigOrientationAngleWidth; x++) {
                BOOL value = [rows[x] boolValue];
                temp_map[x] = value;
                if (x > borderWidth) {
                    if (gridWidth == 0 && !value) {
                        gridWidth = x - borderWidth;
                    }
                    if (temp_map[x - 1] == NO && value) {
                        tinyOrientationAngleMinX = x;
                    } else if (temp_map[x - 1] && !value && tinyOrientationAngleMinX > borderWidth) {
                        tinyOrientationAngleMaxY = x;
                        findOrientationAngle = YES;
                        break;
                    }
                }
            }
            if (findOrientationAngle) {
                break;
            }
        }

        NSMutableArray<NSArray<NSNumber *> *> *fixCodePoints = [codePoints mutableCopy];
        if (borderWidth > 0) {
            fixCodePoints = [NSMutableArray<NSArray<NSNumber *> *> arrayWithCapacity:codeWidth - 2 * borderWidth];
            for (NSArray<NSNumber *> *rows in codePoints) {
                NSArray<NSNumber *> *fixRows = [rows subarrayWithRange:NSMakeRange(borderWidth, rows.count - 2 * borderWidth)];
                [fixCodePoints addObject:fixRows];
            }

            [fixCodePoints removeLastObject];
            [fixCodePoints removeObjectAtIndex:0];

            codeWidth = fixCodePoints.firstObject.count;
            codeHeight = fixCodePoints.count;
        }

        UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
        format.scale = 1;

        CGFloat scale = 10;
        CGFloat drawBorderWidth = 2;
        CGFloat canvasWidth = (codeWidth + (2 * drawBorderWidth)) * scale;
        CGSize canvasSize = CGSizeMake(canvasWidth, canvasWidth);
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:canvasSize format:format];
        UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext) {
            do {
                UIBezierPath *path = [UIBezierPath bezierPathWithRect:rendererContext.format.bounds];
                [UIColor.whiteColor setFill];
                [path fill];
            } while (0);

            [self drawBigOrientationAngle:canvasWidth / scale drawBorderWidth:drawBorderWidth gridWidth:gridWidth width:bigOrientationAngleWidth scale:scale drawType:drawType];

            [self drawTinyOrientationAngle:canvasWidth / scale drawBorderWidth:drawBorderWidth minX:tinyOrientationAngleMinX - borderWidth maxY:tinyOrientationAngleMaxY - borderWidth scale:scale drawType:drawType];

            CGRect topLeftAngle = CGRectMake(0, 0, bigOrientationAngleWidth, bigOrientationAngleWidth);
            CGRect topRightAngle = CGRectMake(codeWidth - bigOrientationAngleWidth, 0, bigOrientationAngleWidth, bigOrientationAngleWidth);
            CGRect bottomLeftAngle = CGRectMake(0, codeHeight - bigOrientationAngleWidth, bigOrientationAngleWidth, bigOrientationAngleWidth);

            for (NSUInteger yy = 0; yy < codeHeight; yy++) {
                NSArray<NSNumber *> *rows = fixCodePoints[yy];
                for (NSUInteger xx = 0; xx < codeWidth; xx++) {
                    BOOL value = [rows[xx] boolValue];
                    if (!value) {
                        continue;
                    }
                    CGPoint point = CGPointMake(xx, yy);
                    if (CGRectContainsPoint(topLeftAngle, point) || CGRectContainsPoint(topRightAngle, point) || CGRectContainsPoint(bottomLeftAngle, point)) {
                        continue;
                    }

                    UIBezierPath *path = nil;
                    if (drawType == kQRCodeDrawTypeCircle) {
                        CGFloat centerX = point.x * scale + 0.5 * scale + drawBorderWidth * scale;
                        CGFloat centerY = point.y * scale + 0.5 * scale + drawBorderWidth * scale;
                        CGFloat radius = 0.5 * scale;  // - 2;
                        CGFloat startAngle = 0;
                        CGFloat endAngle = 2 * M_PI;
                        path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(centerX, centerY) radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
                    } else {
                        CGFloat x = point.x * scale + drawBorderWidth * scale;
                        CGFloat y = point.y * scale + drawBorderWidth * scale;
                        CGFloat w = gridWidth * scale;
                        CGFloat h = w;
                        path = [UIBezierPath bezierPathWithRect:CGRectMake(x, y, w, h)];
                    }
                    if (useBuiltin) {
                        [RGB(0x61, 0x46, 0xfc) setFill];
                    } else {
                        [RGB(0xa1, 0x31, 0xcc) setFill];
                    }

                    [path fill];
                }
            }
        }];

        return image;
    }

    return nil;
}

+ (void)drawBigOrientationAngle:(CGFloat)canvasWidth drawBorderWidth:(CGFloat)drawBorderWidth gridWidth:(CGFloat)gridWidth width:(CGFloat)width scale:(CGFloat)scale drawType:(kQRCodeDrawType)drawType {
    // 左上
    do {

        if (drawType == kQRCodeDrawTypeCircle) {
            //            CGFloat x = drawBorderWidth * scale;
            //            CGFloat y = drawBorderWidth * scale;
            //            CGFloat w = width * scale;
            //            CGFloat h = width * scale;
            //            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:w * 0.5];

            CGFloat centerX = (drawBorderWidth + width * 0.5) * scale;
            CGFloat centerY = (drawBorderWidth + width * 0.5) * scale;
            CGFloat radius = ((width - gridWidth) * 0.5) * scale;
            CGFloat startAngle = 0;
            CGFloat endAngle = 2 * M_PI;
            UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(centerX, centerY) radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];

            path.lineWidth = gridWidth * scale;
            [RGB(0xac, 0x07, 0xf5) setStroke];
            [path stroke];
        } else {
            UIBezierPath *path = [UIBezierPath bezierPath];
            // 上
            for (NSInteger i = 0; i < width; i++) {
                CGFloat x = i * scale + drawBorderWidth * scale;
                CGFloat y = drawBorderWidth * scale;
                [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(x, y, scale, scale)]];
            }

            // 左
            for (NSInteger i = 1; i < width - 1; i++) {
                CGFloat x = drawBorderWidth * scale;
                CGFloat y = i * scale + drawBorderWidth * scale;
                [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(x, y, scale, scale)]];
            }

            // 下
            for (NSInteger i = 0; i < width; i++) {
                CGFloat x = i * scale + drawBorderWidth * scale;
                CGFloat y = (width - 1) * scale + drawBorderWidth * scale;
                [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(x, y, scale, scale)]];
            }

            // 右
            for (NSInteger i = 1; i < width - 1; i++) {
                CGFloat x = (width - 1) * scale + drawBorderWidth * scale;
                CGFloat y = i * scale + drawBorderWidth * scale;
                [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(x, y, scale, scale)]];
            }

            [RGB(0xac, 0x07, 0xf5) setFill];
            [path fill];
        }

    } while (0);

    // 右上
    do {

        if (drawType == kQRCodeDrawTypeCircle) {
            //            CGFloat x = (canvasWidth - width - drawBorderWidth) * scale;
            //            CGFloat y = drawBorderWidth * scale;
            //            CGFloat w = width * scale;
            //            CGFloat h = width * scale;
            //            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:w * 0.5];

            CGFloat x = (canvasWidth - width - drawBorderWidth);
            CGFloat y = drawBorderWidth;
            CGFloat centerX = (x + width * 0.5) * scale;
            CGFloat centerY = (y + width * 0.5) * scale;
            CGFloat radius = ((width - gridWidth) * 0.5) * scale;
            CGFloat startAngle = 0;
            CGFloat endAngle = 2 * M_PI;
            UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(centerX, centerY) radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];

            path.lineWidth = gridWidth * scale;
            [RGB(0xac, 0x07, 0xf5) setStroke];
            [path stroke];
        } else {
            UIBezierPath *path = [UIBezierPath bezierPath];
            CGFloat sx = (canvasWidth - width - drawBorderWidth);
            CGFloat sy = drawBorderWidth;
            // 上
            for (NSInteger i = 0; i < width; i++) {
                CGFloat x = (i + sx) * scale;
                CGFloat y = drawBorderWidth * scale;
                [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(x, y, scale, scale)]];
            }

            // 左边
            for (NSInteger i = 1; i < width - 1; i++) {
                CGFloat x = sx * scale;
                CGFloat y = (i + sy) * scale;
                [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(x, y, scale, scale)]];
            }

            // 下
            for (NSInteger i = 0; i < width; i++) {
                CGFloat x = (i + sx) * scale;
                CGFloat y = (sy + width - 1) * scale;
                [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(x, y, scale, scale)]];
            }

            // 右
            for (NSInteger i = 1; i < width - 1; i++) {
                CGFloat x = (sx + width - 1) * scale;
                CGFloat y = (i + sy) * scale;
                [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(x, y, scale, scale)]];
            }

            [RGB(0xac, 0x07, 0xf5) setFill];
            [path fill];
        }
    } while (0);

    // 左下
    do {

        if (drawType == kQRCodeDrawTypeCircle) {
            //            CGFloat x = drawBorderWidth * scale;
            //            CGFloat y = (canvasWidth - width - drawBorderWidth) * scale;
            //            CGFloat w = width * scale;
            //            CGFloat h = width * scale;
            //            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:w * 0.5];

            CGFloat x = drawBorderWidth;
            CGFloat y = (canvasWidth - width - drawBorderWidth);
            CGFloat centerX = (x + width * 0.5) * scale;
            CGFloat centerY = (y + width * 0.5) * scale;
            CGFloat radius = ((width - gridWidth) * 0.5) * scale;
            CGFloat startAngle = 0;
            CGFloat endAngle = 2 * M_PI;
            UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(centerX, centerY) radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
            path.lineWidth = gridWidth * scale;
            [RGB(0xac, 0x07, 0xf5) setStroke];
            [path stroke];
        } else {
            UIBezierPath *path = [UIBezierPath bezierPath];

            CGFloat sy = canvasWidth - width - drawBorderWidth;
            // 上
            for (NSInteger i = 0; i < width; i++) {
                CGFloat x = i * scale + drawBorderWidth * scale;
                CGFloat y = sy * scale;
                [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(x, y, scale, scale)]];
            }

            // 左
            for (NSInteger i = 1; i < width - 1; i++) {
                CGFloat x = drawBorderWidth * scale;
                CGFloat y = (i + sy) * scale;
                [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(x, y, scale, scale)]];
            }

            // 下
            for (NSInteger i = 0; i < width; i++) {
                CGFloat x = i * scale + drawBorderWidth * scale;
                CGFloat y = (sy + width - 1) * scale;
                [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(x, y, scale, scale)]];
            }

            // 右
            for (NSInteger i = 1; i < width - 1; i++) {
                CGFloat x = (width - 1) * scale + drawBorderWidth * scale;
                CGFloat y = (i + sy) * scale;
                [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(x, y, scale, scale)]];
            }

            [RGB(0xac, 0x07, 0xf5) setFill];
            [path fill];
        }

    } while (0);
}

+ (void)drawTinyOrientationAngle:(CGFloat)canvasWidth drawBorderWidth:(CGFloat)drawBorderWidth minX:(CGFloat)minX maxY:(CGFloat)maxY scale:(CGFloat)scale drawType:(kQRCodeDrawType)drawType {

    CGFloat width = (maxY - minX);
    CGFloat paading = (minX + drawBorderWidth);
    // 左上
    do {
        CGFloat x = paading * scale;
        CGFloat y = paading * scale;
        CGFloat w = width * scale;
        CGFloat h = width * scale;
        UIBezierPath *path = nil;
        if (drawType == kQRCodeDrawTypeCircle) {
            path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:w * 0.5];
        } else {
            path = [UIBezierPath bezierPathWithRect:CGRectMake(x, y, w, h)];
        }
        [RGB(0x3f, 0x52, 0xe0) setFill];
        [path fill];
    } while (0);

    // 右上
    do {
        CGFloat x = (canvasWidth - paading - width) * scale;
        CGFloat y = paading * scale;
        CGFloat w = width * scale;
        CGFloat h = width * scale;
        UIBezierPath *path = nil;
        if (drawType == kQRCodeDrawTypeCircle) {
            path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:w * 0.5];
        } else {
            path = [UIBezierPath bezierPathWithRect:CGRectMake(x, y, w, h)];
        }
        [RGB(0x3f, 0x52, 0xe0) setFill];
        [path fill];
    } while (0);

    // 左下
    do {
        CGFloat x = paading * scale;
        CGFloat y = (canvasWidth - paading - width) * scale;
        CGFloat w = width * scale;
        CGFloat h = width * scale;
        UIBezierPath *path = nil;
        if (drawType == kQRCodeDrawTypeCircle) {
            path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:w * 0.5];
        } else {
            path = [UIBezierPath bezierPathWithRect:CGRectMake(x, y, w, h)];
        }
        [RGB(0x3f, 0x52, 0xe0) setFill];
        [path fill];
    } while (0);
}

// 创建原始二维码
+ (CIImage *)createOriginalCIImageWithString:(NSString *)str withCorrectionLevel:(kQRCodeCorrectionLevel)corLevel {
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKeyPath:@"inputMessage"];

    NSString *corLevelStr = nil;
    switch (corLevel) {
        case kQRCodeCorrectionLevelLow:
            corLevelStr = @"L";
            break;
        case kQRCodeCorrectionLevelNormal:
            corLevelStr = @"M";
            break;
        case kQRCodeCorrectionLevelSuperior:
            corLevelStr = @"Q";
            break;
        case kQRCodeCorrectionLevelHight:
            corLevelStr = @"H";
            break;
    }
    [filter setValue:corLevelStr forKey:@"inputCorrectionLevel"];

    CIImage *outputImage = [filter outputImage];
    return outputImage;
}

// 缩放图片(生成高质量图片）
+ (UIImage *)scaleImage:(CIImage *)image toSize:(CGSize)size {
    if (!image) {
        return nil;
    }
    //! 将CIImage转成CGImageRef
    CGRect integralRect = image.extent;  // CGRectIntegral(image.extent);// 将rect取整后返回，origin取舍，size取入
    CGImageRef imageRef = [[CIContext context] createCGImage:image fromRect:integralRect];

    //! 创建上下文
    CGFloat sideScale = fminf(size.width / integralRect.size.width, size.width / integralRect.size.height) * [UIScreen mainScreen].scale;  // 计算需要缩放的比例
    size_t contextRefWidth = ceilf(integralRect.size.width * sideScale);
    size_t contextRefHeight = ceilf(integralRect.size.height * sideScale);
    CGContextRef contextRef = CGBitmapContextCreate(nil, contextRefWidth, contextRefHeight, 8, 0, CGColorSpaceCreateDeviceGray(), (CGBitmapInfo)kCGImageAlphaNone);  // 灰度、不透明
    CGContextSetInterpolationQuality(contextRef, kCGInterpolationNone);                                                                                              // 设置上下文无插值
    CGContextScaleCTM(contextRef, sideScale, sideScale);                                                                                                             // 设置上下文缩放
    CGContextDrawImage(contextRef, integralRect, imageRef);                                                                                                          // 在上下文中的integralRect中绘制imageRef

    //! 从上下文中获取CGImageRef
    CGImageRef scaledImageRef = CGBitmapContextCreateImage(contextRef);

    CGContextRelease(contextRef);
    CGImageRelease(imageRef);

    //! 将CGImageRefc转成UIImage
    UIImage *scaledImage = [UIImage imageWithCGImage:scaledImageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];

    return scaledImage;
}

// 将 `CIImage` 转成 `CGImage`
+ (CGImageRef)convertCIImage2CGImageForCIImage:(CIImage *)image {
    CGRect extent = CGRectIntegral(image.extent);

    size_t width = CGRectGetWidth(extent);
    size_t height = CGRectGetHeight(extent);
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, 1, 1);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);

    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);

    return scaledImage;
}

// 将原始图片的所有点的色值保存到二维数组.
+ (NSArray<NSArray<NSNumber *> *> *)getPixelsWithCIImage:(CIImage *)ciimg {
    NSMutableArray<NSArray<NSNumber *> *> *pixels = [NSMutableArray<NSArray<NSNumber *> *> array];

    // 将系统生成的二维码从 `CIImage` 转成 `CGImageRef`.
    CGImageRef imageRef = [self convertCIImage2CGImageForCIImage:ciimg];

    __unused UIImage *_image = [UIImage imageWithCGImage:imageRef];
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);

    // 创建一个颜色空间.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // 开辟一段 unsigned char 的存储空间，用 rawData 指向这段内存.
    // 每个 RGBA 色值的范围是 0-255，所以刚好是一个 unsigned char 的存储大小.
    // 每张图片有 height * width 个点，每个点有 RGBA 4个色值，所以刚好是 height * width * 4.
    // 这段代码的意思是开辟了 height * width * 4 个 unsigned char 的存储大小.
    unsigned char *rawData = (unsigned char *)calloc(height * width * 4, sizeof(unsigned char));

    // 每个像素的大小是 4 字节.
    NSUInteger bytesPerPixel = 4;
    // 每行字节数.
    NSUInteger bytesPerRow = width * bytesPerPixel;
    // 一个字节8比特
    NSUInteger bitsPerComponent = 8;

    // 将系统的二维码图片和我们创建的 rawData 关联起来，这样我们就可以通过 rawData 拿到指定 pixel 的内存地址.
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    for (int indexY = 0; indexY < height; indexY++) {
        NSMutableArray<NSNumber *> *tepArrM = [NSMutableArray<NSNumber *> array];
        for (int indexX = 0; indexX < width; indexX++) {
            // 取出每个 pixel 的 RGBA 值，保存到矩阵中.
            @autoreleasepool {
                NSUInteger byteIndex = bytesPerRow * indexY + indexX * bytesPerPixel;
                CGFloat red = (CGFloat)rawData[byteIndex];
                CGFloat green = (CGFloat)rawData[byteIndex + 1];
                CGFloat blue = (CGFloat)rawData[byteIndex + 2];

                BOOL shouldDisplay = red == 0 && green == 0 && blue == 0;
                [tepArrM addObject:@(shouldDisplay)];
                byteIndex += bytesPerPixel;
            }
        }
        [pixels addObject:[tepArrM copy]];
    }
    free(rawData);
    return [pixels copy];
}
@end

