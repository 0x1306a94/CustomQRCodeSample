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
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSString *str = @"https://apple.com";
    UIImage *image = [QRCodeTool generateCodeForString:str withCorrectionLevel:kQRCodeCorrectionLevelHight];
    self.previewImageView.image = image;
}

@end

