//
//  ViewController.m
//  CustomQRCodeSample
//
//  Created by king on 2022/3/29.
//

#import "ViewController.h"

#import "QRCodeTool.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.previewImageView.backgroundColor = UIColor.whiteColor;
    self.view.backgroundColor = UIColor.blackColor;
    self.previewImageView.layer.cornerRadius = 12;
    self.previewImageView.layer.masksToBounds = YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSString *str = @"https://apple.com";
    /// 这种方式, 在 kQRCodeCorrectionLevelHight 模式下, 微信识别不是很容易
    /// 低纠错率模式下,识别比较好
    UIImage *image = [QRCodeTool generateCodeForString:str withCorrectionLevel:kQRCodeCorrectionLevelNormal];
    self.previewImageView.image = image;
}

- (UIUserInterfaceStyle)overrideUserInterfaceStyle {
    return UIUserInterfaceStyleDark;
}
@end

