//
//  QRCode.h
//  qrencode
//
//  Created by 冷秋 on 2019/6/3.
//  Copyright © 2019 Magic-Unique All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, QRCodeLevel) {
    QRCodeLevelL,
    QRCodeLevelM,
    QRCodeLevelQ,
    QRCodeLevelH
};

typedef NS_ENUM(NSUInteger, QRCodeMode) {
    QRCodeModeNumeric,
    QRCodeModeAlphabetNumeric,
    QRCodeMode8BitData,
    QRCodeModeKanji,
    QRCodeModeStructure,
    QRCodeModeECI,
    QRCodeModeFNC1First,
    QRCodeModeFNC2Second,
};

@interface QRCodeMap : NSObject

@property (nonatomic, assign, readonly) NSUInteger size;

@property (nonatomic, strong, readonly) NSArray<NSArray<NSNumber *> *> *datas;
@property (nonatomic, assign, readonly) NSUInteger largePostitionAngleWidth;
@property (nonatomic, assign, readonly) NSUInteger smallPostitionAngleMinX;
@property (nonatomic, assign, readonly) NSUInteger smallPostitionAngleMaxX;
@property (nonatomic, assign, readonly) NSUInteger gridWidth;
@property (nonatomic, assign, readonly) NSUInteger borderWidth;

- (BOOL)dataInRow:(NSUInteger)row col:(NSUInteger)col;

@end

@interface QRCode : NSObject

@property (nonatomic, strong, readonly) NSString *string;

@property (nonatomic, strong, readonly) QRCodeMap *map;

@property (nonatomic, assign, readonly) int version;

+ (instancetype)codeWithString:(NSString *)string version:(int)version level:(QRCodeLevel)level mode:(QRCodeMode)mode;

@end

