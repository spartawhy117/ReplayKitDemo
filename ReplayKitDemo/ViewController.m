//
//  ViewController.m
//  ReplayKitDemo
//
//  Created by spartawhy on 2017/6/9.
//  Copyright © 2017年 spartawhy. All rights reserved.
//

#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>

#define AnimationDuration (0.3)

@interface ViewController ()<RPPreviewViewControllerDelegate,RPBroadcastActivityViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnStart;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;
@property (weak, nonatomic) IBOutlet UIButton *btnLivePause;
@property (weak, nonatomic) IBOutlet UILabel *lbTime;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property(nonatomic, strong)RPBroadcastController * broadcastViewController;
@property (nonatomic,strong) NSTimer *progressTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


-(void)viewDidAppear:(BOOL)animated
{
    //todo some check
    if(![self isSystemVersionOK])
    {
        NSLog(@"ios version lower");
        return;
    }
    
    
    //init time
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"HH:MM:SS"];
    NSString *dateString=[dateFormatter stringFromDate:[NSDate date]];
    _lbTime.text=dateString;
    
    _progressView.progress=0.0;
    
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimeString) userInfo:nil repeats:YES];
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -UI setting
-(void)updateTimeString
{
    NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init] ;
    [dateFormat setDateFormat: @"HH:mm:ss"];
    NSString *dateString = [dateFormat stringFromDate:[NSDate date]];
    self.lbTime.text =  dateString;
}
- (void)showAlert:(NSString *)title andMessage:(NSString *)message {
      if (!title) {
                 title = @"";
             }
        if (!message) {
                 message = @"";
            }
         UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil];
         UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
         [alert addAction:actionCancel];
         [self presentViewController:alert animated:NO completion:nil];
}
-(void)showVideoPreviewController:(RPPreviewViewController *)previewController withAnimation:(BOOL)animation
{
    __weak ViewController *weakSelf=self;
    
    //ui change to main thread
    dispatch_async(dispatch_get_main_queue(), ^{
       
        CGRect rect=[UIScreen mainScreen].bounds;
        if(animation)
        {
            rect.origin.x+=rect.size.width;
            previewController.view.frame=rect;
            rect.origin.x-=rect.size.width;
            
            [UIView animateWithDuration:AnimationDuration animations:^(void){
                previewController.view.frame=rect;
             }completion:^(BOOL finished)
             {
                 
             }];
            
            
        }
        else
        {
            previewController.view.frame=rect;
        }
        
        [weakSelf.view addSubview:previewController.view];
        [weakSelf addChildViewController:previewController];
        
        
    });
}
//关闭视频预览页面，animation=是否要动画显示
 - (void)hideVideoPreviewController:(RPPreviewViewController *)previewController withAnimation:(BOOL)animation {
    
         //UI需要放到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        
    CGRect rect = previewController.view.frame;
        
    if (animation) {
            
        rect.origin.x += rect.size.width;
        [UIView animateWithDuration:AnimationDuration animations:^(){
                 previewController.view.frame = rect;
         } completion:^(BOOL finished){
        //移除页面
        [previewController.view removeFromSuperview];
        [previewController removeFromParentViewController];
         }];
            
    } else {
       //移除页面
       [previewController.view removeFromSuperview];
       [previewController removeFromParentViewController];
            }
    });
     
}
-(void)showAlertWithString:(NSString *)message
{
    UIAlertController *alertController=[UIAlertController alertControllerWithTitle:@"warning" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}
#pragma mark - progress value change
-(void)changeProgressValue
{
    float value=self.progressView.progress+0.01;
    [self.progressView setProgress:value animated:YES];
    if(value>=1.0)
    {
        self.progressView.progress=0.0;
    }
}



#pragma mark -btn press
- (IBAction)btnPressed:(UIButton *)sender {
    
    NSString *name=sender.titleLabel.text;
    
    if([name isEqualToString:@"start"])
    {
        
    }
    else if([name isEqualToString:@"stop"])
    {
        
    }
}

- (IBAction)liveStartPressed:(UIButton *)sender {
    [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"%@",error);
            return;
        }
        broadcastActivityViewController.delegate = self;
        [self presentViewController:broadcastActivityViewController animated:true completion:^{
        }];
    }];
}

- (IBAction)livePause:(UIButton *)sender {
    NSString *name=self.btnLivePause.titleLabel.text;
    
    if([name isEqualToString:@"livepause"])
    {
        [self.broadcastViewController pauseBroadcast];
        self.btnLivePause.titleLabel.text=@"liveresume";
        NSLog(@"pause");
    }
    else
    {
        [self.broadcastViewController resumeBroadcast];
        NSLog(@"resume");
        self.btnLivePause.titleLabel.text=@"livepause";
    }
    
    
}
- (IBAction)liveFinish:(UIButton *)sender {
    [self.broadcastViewController finishBroadcastWithHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@",error);
        }
        NSLog(@"finish");
    }];}

#pragma mark - check method
-(BOOL)checkSupportRecording
{
    if([[RPScreenRecorder sharedRecorder]isAvailable])
    {
        return YES;
    }
    else{
        return NO;
    }
}

-(BOOL)isSystemVersionOK
{
    if([[UIDevice currentDevice].systemVersion floatValue]<9.0)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

#pragma mark -replaykit delegate
-(void)startRecording
{
    if(![self checkSupportRecording])
        
    {
        [self showAlertWithString:@"can't support record!"];
        return;
    }
    
    __weak ViewController *weakSelf=self;
    
    [[RPScreenRecorder sharedRecorder]startRecordingWithHandler:^(NSError *error)
     {
         NSLog(@"start log");
         if(error)
         {
             NSLog(@"wrong meassage %@",error);
             [weakSelf showAlertWithString:error.description];
         }
         else
         {
             weakSelf.progressTimer=[NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(changeProgressValue) userInfo:nil repeats:YES];
             
             
         }
         
         
     }];
    
    
    
}
-(void)stopRecording
{
    __weak ViewController *weakSelf=self;
    [[RPScreenRecorder sharedRecorder]stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        
        if(error)
        {
            NSLog(@"wrong meassage %@",error);
            [weakSelf showAlertWithString:error.description];
            
        }
        else{
            
            NSLog(@"show preview");
            previewViewController.previewControllerDelegate=weakSelf;
            
            [weakSelf.progressTimer invalidate];
            weakSelf.progressTimer=nil;
            
            [self showVideoPreviewController:previewViewController withAnimation:YES];
        }
        
    
    }];
}

-(void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(RPBroadcastController *)broadcastController error:(NSError *)error{
    NSLog(@"%s",__func__);
    if (error) {
        NSLog(@"%@",error);
    }
    [self dismissViewControllerAnimated:true completion:nil];
    //使用相机
    [RPScreenRecorder sharedRecorder].cameraEnabled = true;
    //使用麦克风
    [RPScreenRecorder sharedRecorder].microphoneEnabled = true;
    self.broadcastViewController = broadcastController;
    //开始录制
    [broadcastController startBroadcastWithHandler:^(NSError * _Nullable error) {
        NSLog(@"开始录");
        if (error) {
            NSLog(@"%@",error);
        }
     
        [self.view addSubview:[RPScreenRecorder sharedRecorder].cameraPreviewView];
    }];
}


#pragma mark - preview vedio callback
-(void)previewControllerDidFinish:(RPPreviewViewController *)previewController
{
    [self hideVideoPreviewController:previewController withAnimation:YES];
}

-(void)previewController:(RPPreviewViewController *)previewController didFinishWithActivityTypes:(NSSet<NSString *> *)activityTypes
{
    __weak ViewController *weakSelf=self;
    if ([activityTypes containsObject:@"com.apple.UIKit.activity.SaveToCameraRoll"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showAlert:@"保存成功" andMessage:@"已经保存到系统相册"];
        });
    }
    if ([activityTypes containsObject:@"com.apple.UIKit.activity.CopyToPasteboard"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showAlert:@"复制成功" andMessage:@"已经复制到粘贴板"];
        });
    }}


@end
