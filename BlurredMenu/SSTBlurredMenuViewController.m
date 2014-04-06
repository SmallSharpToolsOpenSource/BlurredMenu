//
//  SSTBlurredMenuViewController.m
//  BlurredMenu
//
//  Created by Brennan Stehling on 3/4/14.
//  Copyright (c) 2014 SmallSharptools. All rights reserved.
//

#import "SSTBlurredMenuViewController.h"

#import "UIImage+BlurredFrame.h"
#import "UIImage+ImageEffects.h"

#define kSideBarWidth 276

#define kBlurRadius 1.0f

#define kContentChangeDelay 3.0f

@interface SSTBlurredMenuViewController ()

@property (weak, nonatomic) IBOutlet UIView *screenView;

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIView *coloredView;

@property (weak, nonatomic) IBOutlet UIView *sideBarBackgroundView;
@property (weak, nonatomic) IBOutlet UIView *sideBarMenuView;

@property (weak, nonatomic) IBOutlet UIImageView *sideBarBackgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *blurredScreenshotImageView;

@property (weak, nonatomic) IBOutlet UILabel *blurRadiusLabel;
@property (weak, nonatomic) IBOutlet UILabel *saturationLabel;

@property (weak, nonatomic) IBOutlet UISlider *blurRadiusSlider;
@property (weak, nonatomic) IBOutlet UISlider *saturationSlider;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sideBarBackgroundWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sideBarMenuTrailingConstraint;

@property (strong, nonatomic) UIImage *blurredScreenshotImage;

@property (strong, nonatomic) NSArray *texts;
@property (strong, nonatomic) NSArray *colors;

@end

@implementation SSTBlurredMenuViewController {
    NSUInteger contentIndex;
}

#pragma mark - View Lifecycle
#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // assert necessary outlets are defined
    NSCAssert(self.sideBarBackgroundView, @"Outlet is required");
    NSCAssert(self.sideBarBackgroundImageView, @"Outlet is required");
    NSCAssert(self.sideBarMenuView, @"Outlet is required");
    
    self.sideBarBackgroundImageView.image = [self backgroundImageView];
    
    self.texts = @[
                   @"Wayfarers post-ironic Vice Williamsburg sustainable next level. Gluten-free mlkshk salvia semiotics normcore, scenester four loko Vice organic trust fund fingerstache keytar squid umami PBR.",
                   @"Chia Brooklyn hella authentic post-ironic photo booth. Dreamcatcher freegan VHS Thundercats normcore, narwhal PBR&B Vice chia Portland lomo. Brunch Shoreditch street art, meh freegan bicycle.",
                   @"Tote bag freegan hella messenger bag gluten-free, wayfarers Intelligentsia Austin fanny pack. VHS banjo asymmetrical, irony biodiesel chia Wes Anderson cornhole pork belly YOLO distillery fingerstache Marfa."
                  ];
    self.colors = @[[UIColor redColor], [UIColor blueColor], [UIColor greenColor]];
    
    
    NSCAssert(self.texts.count == self.colors.count, @"Counts must match for content arrays.");
    self.label.text = self.texts[contentIndex];
    self.coloredView.backgroundColor = self.colors[contentIndex];
    
    [self updateLabelForSlider:self.blurRadiusSlider];
    [self updateLabelForSlider:self.saturationSlider];
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
    [self performSelector:@selector(updateContent) withObject:self afterDelay:kContentChangeDelay];
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

- (IBAction)sliderValueChanged:(UISlider *)sender {
    [self updateLabelForSlider:sender];
}

#pragma mark - Private Methods
#pragma mark -

- (CGFloat)blurRadiusValue {
    return roundf(self.blurRadiusSlider.value) / 4;
}

- (CGFloat)saturationValue {
    return roundf(self.saturationSlider.value) / 4;
}

- (UIImage *)screenshotOfView:(UIView *)view excludingViews:(NSArray *)excludedViews {
    if (!floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        NSCAssert(FALSE, @"iOS 7 or later is required.");
    }
    
    // hide all exclude views before capturing screen and keep initial value
    NSMutableArray *hiddenValues = [@[] mutableCopy];
    for (NSUInteger index=0;index<excludedViews.count;index++) {
        [hiddenValues addObject:[NSNumber numberWithBool:((UIView *)excludedViews[index]).hidden]];
        ((UIView *)excludedViews[index]).hidden = TRUE;
    }
    
    UIImage *image = nil;
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // reset hidden values
    for (NSUInteger index=0;index<excludedViews.count;index++) {
        ((UIView *)excludedViews[index]).hidden = [[hiddenValues objectAtIndex:index] boolValue];
    }
    
    // clean up
    hiddenValues = nil;
    
    return image;
}

- (UIImage *)blurredScreenshot {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    BOOL wasSideBarHidden = self.sideBarBackgroundImageView.hidden;
    BOOL wasBlurredScreenshotHidden = self.blurredScreenshotImageView.hidden;
        
    UIImage *screenshot = [self screenshotOfView:self.view excludingViews:@[self.screenView, self.sideBarBackgroundImageView, self.blurredScreenshotImageView]];
    UIImage *blurredSnapshotImage = nil;
    
    CGFloat blurRadius = [self blurRadiusValue];
    CGFloat saturation = [self saturationValue];
    
    
    blurredSnapshotImage = [screenshot applyBlurWithRadius:blurRadius tintColor:nil saturationDeltaFactor:saturation maskImage:nil];
//    blurredSnapshotImage = [screenshot applyBlurWithRadius:blurRadius tintColor:nil saturationDeltaFactor:saturation maskImage:nil atFrame:self.view.frame];
    
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    
    CGFloat fps = 1.0f / (stop - start);
    DebugLog(@"Blurring at %.02f fps", fps);
    
    self.sideBarBackgroundImageView.hidden = wasSideBarHidden;
    self.blurredScreenshotImageView.hidden = wasBlurredScreenshotHidden;

    return blurredSnapshotImage;
}

- (void)updateBlurredScreenshot {
    self.blurredScreenshotImage = [self blurredScreenshot];
    self.blurredScreenshotImageView.image = self.blurredScreenshotImage;
}

- (void)updateContent {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateContent) object:nil];
    
    contentIndex++;
    if (contentIndex >= self.colors.count) {
        contentIndex = 0;
    }
    self.label.text = (NSString *)self.texts[contentIndex];
    self.coloredView.backgroundColor = self.colors[contentIndex];
    
    [self updateBlurredScreenshot];
    
    [self performSelector:@selector(updateContent) withObject:self afterDelay:kContentChangeDelay];
}

- (void)updateLabelForSlider:(UISlider *)slider {
    if ([self.blurRadiusSlider isEqual:slider]) {
        self.blurRadiusLabel.text = [NSString stringWithFormat:@"Blur Radius (%.02f)", [self blurRadiusValue]];
    }
    else if ([self.saturationSlider isEqual:slider]) {
        self.saturationLabel.text = [NSString stringWithFormat:@"Saturation (%.02f)", [self saturationValue]];
    }
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
        [self updateBlurredScreenshot];
        self.screenView.hidden = FALSE;
        self.screenView.alpha = 0.0;
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            self.sideBarBackgroundWidthConstraint.constant = kSideBarWidth;
            self.sideBarMenuTrailingConstraint.constant = 0;
            self.screenView.alpha = 1.0;
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self updateBlurredScreenshot];
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
        UIColor* myColor1 = [UIColor colorWithRed: 0.558 green: 0.142 blue: 0.142 alpha: 1];
        UIColor* myColor2 = [UIColor colorWithRed: 0.779 green: 0.232 blue: 0.232 alpha: 1];
        UIColor* myColor3 = [UIColor colorWithRed: 1 green: 0.321 blue: 0.321 alpha: 1];
        
        //// Gradient Declarations
        NSArray* myGradientColors = [NSArray arrayWithObjects:
                                     (id)myColor1.CGColor,
                                     (id)myColor2.CGColor,
                                     (id)myColor3.CGColor, nil];
        CGFloat myGradientLocations[] = {0, 0.9, 1};
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