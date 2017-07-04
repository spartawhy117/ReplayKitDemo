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
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface ViewController ()<RPScreenRecorderDelegate,RPPreviewViewControllerDelegate,RPBroadcastActivityViewControllerDelegate,RPBroadcastControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnStart;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;
@property (weak, nonatomic) IBOutlet UIButton *btnLivePause;
@property (weak, nonatomic) IBOutlet UILabel *lbTime;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;



@property(nonatomic, weak)RPBroadcastController * broadcastController;
@property (nonatomic, weak)   UIView   *cameraPreview;
@property (nonatomic, assign) BOOL allowLive;

@property (nonatomic,strong) NSTimer *progressTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
     self.allowLive = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0");
    
    if(self.allowLive)
    {
        [self setUpCameraAndMic];
        
    }
    
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
        [self startRecording];
    }
    else if([name isEqualToString:@"stop"])
    {
        [self stopRecording];
    }
}

- (IBAction)liveStartPressed:(UIButton *)sender {
    
    __weak ViewController* weakSelf=self;
    
    if(![RPScreenRecorder sharedRecorder].isRecording)
    {
        [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"%@",error);
                return;
            }
            broadcastActivityViewController.delegate=weakSelf;
            broadcastActivityViewController.modalPresentationStyle=UIModalPresentationPopover;
            
            //ipad适配
            if([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad)
            {
                broadcastActivityViewController.popoverPresentationController.sourceRect = weakSelf.btnStop.frame;
                broadcastActivityViewController.popoverPresentationController.sourceView=weakSelf.btnStop;
                
            }
            
                [weakSelf presentViewController:broadcastActivityViewController animated:true completion:^{
                    
                }];
            
        }];

    }
    else{
        //断开当前链接
        [self.broadcastController finishBroadcastWithHandler:^(NSError * _Nullable error) {
        
            //TODO 移除摄像机 改变录制按钮形态
        }];
    }
    
    
   }

- (IBAction)livePause:(UIButton *)sender {
    NSString *name=self.btnLivePause.titleLabel.text;
    
    if([name isEqualToString:@"live pause"])
    {
        [self.broadcastController pauseBroadcast];
        [self.btnLivePause setTitle:@"live resume" forState:UIControlStateNormal];
        NSLog(@"pause");
    }
    else
    {
        [self.broadcastController resumeBroadcast];
        [self.btnLivePause setTitle:@"live pause" forState:UIControlStateNormal];
        NSLog(@"resume");
       
    }
    
    
}
- (IBAction)liveFinish:(UIButton *)sender {
    
    __weak ViewController *weakSelf=self;
    [self.broadcastController finishBroadcastWithHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"finishBroadcastWithHandler %@",error);
        }
        
        //移除摄像头
        
        [weakSelf.cameraPreview removeFromSuperview];
       
    }];
}

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
-(void)setUpCameraAndMic
{
    //使用相机
    [RPScreenRecorder sharedRecorder].cameraEnabled = true;
    //使用麦克风
    [RPScreenRecorder sharedRecorder].microphoneEnabled = true;
}

#pragma mark -replaykit delegate
-(void)startRecording
{
    if(![self checkSupportRecording])
        
    {
        [self showAlertWithString:@"can't support record!"];
        return;
    }
    
//    __weak ViewController *weakSelf=self;
    
    [[RPScreenRecorder sharedRecorder]startRecordingWithHandler:^(NSError *error){
         NSLog(@"start log");
         if(error)
         {
             NSLog(@"wrong meassage %@",error);
             [self showAlertWithString:error.description];
         }
         else
         {
             
             self.progressTimer=[NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(changeProgressValue) userInfo:nil repeats:YES];
             
             NSLog(@"start recording");
             
             
         }
         
         
     }];
    
    
    
}
-(void)stopRecording
{
//    __weak ViewController *weakSelf=self;
    [[RPScreenRecorder sharedRecorder]stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        
        if(error)
        {
            NSLog(@"wrong meassage %@",error);
            [self showAlertWithString:error.description];
            
        }
        else{
            
            NSLog(@"show preview");
            previewViewController.previewControllerDelegate=self;
            
            [self.progressTimer invalidate];
            self.progressTimer=nil;
            
            [self showVideoPreviewController:previewViewController withAnimation:YES];
        }
        
    
    }];
}

-(void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(RPBroadcastController *)broadcastController error:(NSError *)error{
   
    
    if (error) {
        NSLog(@"didFinishWithBroadcastController with error %@",error);
    }
    [broadcastActivityViewController dismissViewControllerAnimated:true completion:nil];
    
    self.broadcastController = broadcastController;
    
    
    __weak ViewController* weakSelf=self;
    if(!error)
    {
        [broadcastController startBroadcastWithHandler:^(NSError * _Nullable error) {
            
            NSLog(@"broadcastControllerHandler");
            if(!error)
            {
                
                weakSelf.broadcastController.delegate=self;
                UIView* cameraView = [[RPScreenRecorder sharedRecorder] cameraPreviewView];
                weakSelf.cameraPreview=cameraView;
                if(cameraView)
                {
                    cameraView.frame=CGRectMake(0, 0, 200, 200);
                    [weakSelf.view addSubview:cameraView];
                    
                    
                    
                }
                
                
            }
            else{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                         message:error.localizedDescription
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:@"Ok"
                                                                    style:UIAlertActionStyleCancel
                                                                  handler:nil]];
                
                [self presentViewController:alertController
                                   animated:YES
                                 completion:nil];
            }
        }];
        
        
    }
    else{
        NSLog(@"Error returning from Broadcast Activity: %@", error);
    }
    
    
    
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
