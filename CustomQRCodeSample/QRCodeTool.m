//
//  QRCodeTool.m
//  CustomQRCodeSample
//
//  Created by king on 2022/3/29.
//

#import "QRCodeTool.h"

#import <CoreImage/CoreImage.h>

#define RGB(r, g, b) [UIColor colorWithRed:(r / 255.0) green:(g / 255.0) blue:(b / 255.0) alpha:1.0]
@implementation QRCodeTool
+ (UIImage *)generateCodeForString:(nonnull NSString *)str withCorrectionLevel:(kQRCodeCorrectionLevel)corLevel {
    if (str.length == 0) {
        return nil;
    }

    @autoreleasepool {
        CIImage *originalImg = [self createOriginalCIImageWithString:str withCorrectionLevel:corLevel];
        // 这行代码主要是为了,在断点时,可以通过quicklook 查看
        UIImage *_image = [UIImage imageWithCIImage:originalImg];
        NSArray<NSArray<NSNumber *> *> *codePoints = [self getPixelsWithCIImage:originalImg];
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

        UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
        format.scale = 20;

        CGFloat drawBorderWidth = 2;
        CGFloat canvasWidth = codeWidth - (2.0 * borderWidth) + (2 * drawBorderWidth);
        CGSize canvasSize = CGSizeMake(canvasWidth, canvasWidth);
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:canvasSize format:format];
        UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext) {
            //            do {
            //                UIBezierPath *path = [UIBezierPath bezierPathWithRect:rendererContext.format.bounds];
            //                [UIColor.orangeColor setFill];
            //                [path fill];
            //            } while (0);

            [self drawBigOrientationAngle:canvasWidth drawBorderWidth:drawBorderWidth gridWidth:gridWidth width:bigOrientationAngleWidth];
            [self drawTinyOrientationAngle:canvasWidth drawBorderWidth:drawBorderWidth minX:tinyOrientationAngleMinX - borderWidth maxY:tinyOrientationAngleMaxY - borderWidth];

            NSMutableArray<NSArray<NSNumber *> *> *fixCodePoints = [NSMutableArray<NSArray<NSNumber *> *> arrayWithCapacity:codeWidth - 2 * borderWidth];
            for (NSArray<NSNumber *> *rows in codePoints) {
                NSArray<NSNumber *> *fixRows = [rows subarrayWithRange:NSMakeRange(borderWidth, rows.count - 2 * borderWidth)];
                [fixCodePoints addObject:fixRows];
            }

            [fixCodePoints removeLastObject];
            [fixCodePoints removeObjectAtIndex:0];

            NSUInteger _h = fixCodePoints.count;
            NSUInteger _w = fixCodePoints.firstObject.count;

            CGRect topLeftAngle = CGRectMake(0, 0, bigOrientationAngleWidth, bigOrientationAngleWidth);
            CGRect topRightAngle = CGRectMake(_w - bigOrientationAngleWidth, 0, bigOrientationAngleWidth, bigOrientationAngleWidth);
            CGRect bottomLeftAngle = CGRectMake(0, _h - bigOrientationAngleWidth, bigOrientationAngleWidth, bigOrientationAngleWidth);

            for (NSUInteger yy = 0; yy < _h; yy++) {
                NSArray<NSNumber *> *rows = fixCodePoints[yy];
                for (NSUInteger xx = 0; xx < _w; xx++) {
                    BOOL value = [rows[xx] boolValue];
                    if (!value) {
                        continue;
                    }
                    CGPoint point = CGPointMake(xx, yy);
                    if (CGRectContainsPoint(topLeftAngle, point) || CGRectContainsPoint(topRightAngle, point) || CGRectContainsPoint(bottomLeftAngle, point)) {
                        continue;
                    }

//                    NSLog(@"%1f, %1f", point.x, point.y);
                    CGFloat x = point.x + drawBorderWidth;
                    CGFloat y = point.y + drawBorderWidth;

                    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, 1, 1) cornerRadius:0.5];
                    [RGB(0x61, 0x46, 0xfc) setFill];
                    [path fill];
                }
            }
        }];

        return image;
    }

    return nil;
}

+ (void)drawBigOrientationAngle:(CGFloat)canvasWidth drawBorderWidth:(CGFloat)drawBorderWidth gridWidth:(CGFloat)gridWidth width:(CGFloat)width {
    // 左上
    do {
        CGFloat x = drawBorderWidth;
        CGFloat y = drawBorderWidth;
        CGFloat w = width;
        CGFloat h = width;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:w * 0.5];
        path.lineWidth = gridWidth;
        [RGB(0xac, 0x07, 0xf5) setStroke];
        [path stroke];
    } while (0);

    // 右上
    do {
        CGFloat x = canvasWidth - width - drawBorderWidth;
        CGFloat y = drawBorderWidth;
        CGFloat w = width;
        CGFloat h = width;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:w * 0.5];
        path.lineWidth = gridWidth;
        [RGB(0xac, 0x07, 0xf5) setStroke];
        [path stroke];
    } while (0);

    // 左下
    do {
        CGFloat x = drawBorderWidth;
        CGFloat y = canvasWidth - width - drawBorderWidth;
        CGFloat w = width;
        CGFloat h = width;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:w * 0.5];
        path.lineWidth = gridWidth;
        [RGB(0xac, 0x07, 0xf5) setStroke];
        [path stroke];
    } while (0);
}

+ (void)drawTinyOrientationAngle:(CGFloat)canvasWidth drawBorderWidth:(CGFloat)drawBorderWidth minX:(CGFloat)minX maxY:(CGFloat)maxY {

    CGFloat width = maxY - minX;
    CGFloat paading = minX + drawBorderWidth;
    // 左上
    do {
        CGFloat x = paading;
        CGFloat y = paading;
        CGFloat w = width;
        CGFloat h = width;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:w * 0.5];
        [RGB(0x3f, 0x52, 0xe0) setFill];
        [path fill];
    } while (0);

    // 右上
    do {
        CGFloat x = canvasWidth - paading - width;
        CGFloat y = paading;
        CGFloat w = width;
        CGFloat h = width;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:w * 0.5];
        [RGB(0x3f, 0x52, 0xe0) setFill];
        [path fill];
    } while (0);

    // 左下
    do {
        CGFloat x = paading;
        CGFloat y = canvasWidth - paading - width;
        CGFloat w = width;
        CGFloat h = width;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y, w, h) cornerRadius:w * 0.5];
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

    UIImage *_image = [UIImage imageWithCGImage:imageRef];
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

