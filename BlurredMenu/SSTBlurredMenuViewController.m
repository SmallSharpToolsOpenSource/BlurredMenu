//
//  SSTBlurredMenuViewController.m
//  BlurredMenu
//
//  Created by Brennan Stehling on 3/4/14.
//  Copyright (c) 2014 SmallSharptools. All rights reserved.
//

#import "SSTBlurredMenuViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <GPUImage/GPUImage.h>

#define kSideBarWidth 276

#define kBlurRadius 1.0f

@interface SSTBlurredMenuViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *screenView;

@property (weak, nonatomic) IBOutlet UIView *sideBarBackgroundView;
@property (weak, nonatomic) IBOutlet UIView *sideBarMenuView;

@property (weak, nonatomic) IBOutlet UIImageView *sideBarBackgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *blurredScreenshotImageView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sideBarBackgroundWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sideBarMenuTrailingConstraint;

@property (strong, nonatomic) GPUImageiOSBlurFilter *blurFilter;

@property (strong, nonatomic) UIImage *blurredScreenshotImage;

@end

@implementation SSTBlurredMenuViewController

#pragma mark - View Lifecycle
#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // assert necessary outlets are defined
    NSCAssert(self.sideBarBackgroundView, @"Outlet is required");
    NSCAssert(self.sideBarBackgroundImageView, @"Outlet is required");
    NSCAssert(self.sideBarMenuView, @"Outlet is required");
    
    self.blurFilter = [[GPUImageiOSBlurFilter alloc] init];
    self.blurFilter.blurRadiusInPixels = kBlurRadius;
    
    self.sideBarBackgroundImageView.image = [self backgroundImageView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.sideBarBackgroundView.backgroundColor = [UIColor clearColor];
    self.sideBarMenuView.backgroundColor = [UIColor clearColor];
    
    // hide sidebar if not hidden already
    if (![self isSideBarHidden]) {
        [self showHideSideBar:FALSE];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.blurredScreenshotImage = [self blurredScreenshot];
}

#pragma mark - User Actions
#pragma mark -

- (IBAction)showHideButtonTapped:(id)sender {
    [self showHideSideBar:TRUE];
}

- (IBAction)screenViewTapped:(id)sender {
    BOOL isHidden = [self isSideBarHidden];
    if (!isHidden) {
        [self showHideSideBar:TRUE];
    }
}

#pragma mark - Private Methods
#pragma mark -

- (UIImage *)blurredScreenshot
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    UIImage *screenshot = nil;
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
    if (isiOS7OrLater) {
        [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
        screenshot = UIGraphicsGetImageFromCurrentImageContext();
    }
    else {
        [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        screenshot = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    UIImage *blurredSnapshotImage = [self.blurFilter imageByFilteringImage:screenshot];
    
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    DebugLog(@"Thing took %f sec", stop - start);

    return blurredSnapshotImage;
}

- (BOOL)isSideBarHidden {
    return CGRectGetWidth(self.sideBarBackgroundView.frame) == 0;
}

- (void)showHideSideBar:(BOOL)animated {
    BOOL isHidden = [self isSideBarHidden];
    
    CGFloat duration = animated ? 0.25 : 0.0;
    
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState |
        UIViewAnimationOptionCurveEaseOut;
    
    if (isHidden) {
        // Shown: background width is kSideBarWidth and trailing constraint is 0
        self.blurredScreenshotImageView.image = self.blurredScreenshotImage;
        self.screenView.hidden = FALSE;
        self.screenView.alpha = 0.0;
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            self.sideBarBackgroundWidthConstraint.constant = kSideBarWidth;
            self.sideBarMenuTrailingConstraint.constant = 0;
            self.screenView.alpha = 1.0;
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.screenView.hidden = FALSE;
        }];
    }
    else {
        // Hidden: background width is 0 and trailing constraint is -kSideBarWidth
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            self.sideBarBackgroundWidthConstraint.constant = 0;
            self.sideBarMenuTrailingConstraint.constant = -1 * kSideBarWidth;
            self.screenView.alpha = 1.0;
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.screenView.hidden = TRUE;
        }];
    }
}

- (UIImage *)backgroundImageView {
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(276, 568), NO, 0.0f);
        
        
        //// General Declarations
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        //// Color Declarations
        UIColor* myColor1 = [UIColor colorWithRed: 0.945 green: 0.631 blue: 0.506 alpha: 1];
        UIColor* myColor2 = [UIColor colorWithRed: 0.699 green: 0.445 blue: 0.344 alpha: 1];
        
        //// Gradient Declarations
        NSArray* myGradientColors = [NSArray arrayWithObjects:
                                     (id)myColor1.CGColor,
                                     (id)[UIColor colorWithRed: 0.822 green: 0.538 blue: 0.425 alpha: 1].CGColor,
                                     (id)myColor2.CGColor, nil];
        CGFloat myGradientLocations[] = {0, 0.61, 1};
        CGGradientRef myGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)myGradientColors, myGradientLocations);
        
        //// Rectangle Drawing
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 276, 568)];
        CGContextSaveGState(context);
        [rectanglePath addClip];
        CGContextDrawLinearGradient(context, myGradient, CGPointMake(0, 284), CGPointMake(276, 284), 0);
        CGContextRestoreGState(context);
        
        
        //// Cleanup
        CGGradientRelease(myGradient);
        CGColorSpaceRelease(colorSpace);
        
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
    });
    return image;
}

@end