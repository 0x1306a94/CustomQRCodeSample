//
//  QRCode.m
//  qrencode
//
//  Created by 冷秋 on 2019/6/3.
//  Copyright © 2019 Magic-Unique All rights reserved.
//

#import "QRCode.h"
#import "libqrencode/qrencode.h"

@implementation QRCodeMap

- (BOOL)dataInRow:(NSUInteger)row col:(NSUInteger)col {
    return (self.datas[row][col]).boolValue;
}

- (instancetype)initWithQRCode:(QRcode *)code {
    self = [super init];
    if (self) {
        _size = code->width;
        NSMutableArray<NSArray<NSNumber *> *> *datas = [NSMutableArray<NSArray<NSNumber *> *> arrayWithCapacity:_size];
        for (NSUInteger row = 0; row < _size; row++) {
            NSMutableArray<NSNumber *> *currentRow = [NSMutableArray<NSNumber *> arrayWithCapacity:_size];
            for (NSUInteger col = 0; col < _size; col++) {
                NSUInteger index = row * _size + col;
                unsigned char data = code->data[index];
                if (data & 1) {
                    [currentRow addObject:@YES];
                } else {
                    [currentRow addObject:@NO];
                }
            }
            [datas addObject:currentRow];
        }
        _datas = [datas copy];

        NSUInteger borderWidth = 0;
        NSUInteger bigOrientationAngleWidth = 0;
        NSUInteger tinyOrientationAngleMinX = 0;
        NSUInteger tinyOrientationAngleMaxY = 0;
        NSUInteger gridWidth = 0;
        BOOL findOrientationAngle = NO;
        char *temp_map = alloca(sizeof(char) * _size);

        // 找大的定位角
        NSUInteger lastY = 0;
        for (NSUInteger y = 0; y < _size; y++) {
            lastY = y;
            memset(temp_map, 0, _size);
            borderWidth = 0;
            bigOrientationAngleWidth = 0;
            NSArray<NSNumber *> *rows = datas[y];
            for (NSUInteger x = 0; x < _size; x++) {
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
        for (NSUInteger y = lastY; y < _size; y++) {
            memset(temp_map, 0, bigOrientationAngleWidth);
            tinyOrientationAngleMinX = borderWidth;
            tinyOrientationAngleMaxY = borderWidth;
            findOrientationAngle = NO;
            gridWidth = 0;
            NSArray<NSNumber *> *rows = datas[y];
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

        _borderWidth = borderWidth;
        _largePostitionAngleWidth = bigOrientationAngleWidth;
        _smallPostitionAngleMinX = tinyOrientationAngleMinX;
        _smallPostitionAngleMaxX = tinyOrientationAngleMaxY;
        _gridWidth = gridWidth;
    }
    return self;
}

@end

@implementation QRCode

+ (instancetype)codeWithString:(NSString *)string version:(int)version level:(QRCodeLevel)level mode:(QRCodeMode)mode {
    QRcode *_qrcode = QRcode_encodeString(string.UTF8String, version, (QRecLevel)level, (QRencodeMode)mode, 1);
    if (!_qrcode) {
        return nil;
    }
    QRCodeMap *map = [[QRCodeMap alloc] initWithQRCode:_qrcode];
    QRCode *code = [[self alloc] init];
    code->_version = _qrcode->version;
    code->_map = map;
    code->_string = [string copy];
    
//    QRcode_free(_qrcode);
    return code;
}

@end

