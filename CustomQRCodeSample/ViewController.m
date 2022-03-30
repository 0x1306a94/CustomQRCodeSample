//
//  ViewController.m
//  CustomQRCodeSample
//
//  Created by king on 2022/3/29.
//

#import "ViewController.h"

#import "QRCodeTool.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
@property (weak, nonatomic) IBOutlet UIImageView *preview2ImageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.blackColor;
    self.previewImageView.backgroundColor = UIColor.whiteColor;
    self.previewImageView.layer.cornerRadius = 12;
    self.previewImageView.layer.masksToBounds = YES;

    self.preview2ImageView.backgroundColor = UIColor.whiteColor;
    self.preview2ImageView.layer.cornerRadius = 12;
    self.preview2ImageView.layer.masksToBounds = YES;

    //    self.textView.text = @"配置属性 --> C/C++ --> 常规 --> 附加包含目录，加入qrencode.h所在路径，\
//    配置属性 --> 链配置属性 --> 链接器 --> 常规 --> 附加库目录，加入libqrencode.lib所在路径\
//    配置属性 --> 链配置属性 --> 链接器 --> 输入 --> 附加依赖项，加入libqrencode.lib";
}

- (IBAction)systemAction:(UIButton *)sender {

    [self.view endEditing:YES];

    NSString *str = self.textView.text;
    kQRCodeCorrectionLevel corLevel = kQRCodeCorrectionLevelHight;
    kQRCodeDrawType drawType = kQRCodeDrawTypeCircle;
    UIImage *image = [QRCodeTool generateCodeForString:str withCorrectionLevel:corLevel drawType:drawType useBuiltin:YES];
    self.previewImageView.image = image;
}

- (IBAction)qrencodeAction:(UIButton *)sender {
    [self.view endEditing:YES];

    NSString *str = self.textView.text;
    kQRCodeCorrectionLevel corLevel = kQRCodeCorrectionLevelHight;

    kQRCodeDrawType drawType = kQRCodeDrawTypeCircle;
    UIImage *image = [QRCodeTool generateCodeForString:str withCorrectionLevel:corLevel drawType:drawType useBuiltin:NO];
    self.preview2ImageView.image = image;
}

- (IBAction)systemSaveAction:(UIButton *)sender {
    [self.view endEditing:YES];
    if (self.previewImageView.image == nil) {
        NSLog(@"请先生成....");
        return;
    }
    NSArray *items = @[
        self.previewImageView.image
    ];
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)qrencodeSaveAction:(UIButton *)sender {
    [self.view endEditing:YES];
    if (self.preview2ImageView.image == nil) {
        NSLog(@"请先生成....");
        return;
    }
    NSArray *items = @[
        self.preview2ImageView.image
    ];
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

- (UIUserInterfaceStyle)overrideUserInterfaceStyle {
    return UIUserInterfaceStyleDark;
}
@end

