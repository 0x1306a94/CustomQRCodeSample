//
//  QRCodeTool.h
//  CustomQRCodeSample
//
//  Created by king on 2022/3/29.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, kQRCodeCorrectionLevel) {
    kQRCodeCorrectionLevelLow,       // 低纠正率.
    kQRCodeCorrectionLevelNormal,    // 一般纠正率.
    kQRCodeCorrectionLevelSuperior,  // 较高纠正率.
    kQRCodeCorrectionLevelHight,     // 高纠正率.
};

typedef NS_ENUM(NSInteger, kQRCodeDrawType) {
    kQRCodeDrawTypeSquare,  // 正方形.
    kQRCodeDrawTypeCircle,  // 圆.
};

NS_ASSUME_NONNULL_BEGIN

@interface QRCodeTool : NSObject
+ (UIImage *_Nullable)generateCodeForString:(nonnull NSString *)str withCorrectionLevel:(kQRCodeCorrectionLevel)corLevel drawType:(kQRCodeDrawType)drawType useBuiltin:(BOOL)useBuiltin;
@end

NS_ASSUME_NONNULL_END

