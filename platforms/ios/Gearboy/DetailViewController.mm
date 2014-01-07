/*
 * Gearboy - Nintendo Game Boy Emulator
 * Copyright (C) 2012  Ignacio Sanchez
 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see http://www.gnu.org/licenses/
 *
 */

#import <GameController/GameController.h>

#import "DetailViewController.h"

@interface DetailViewController ()
@property (readonly, nonatomic) BOOL gameControllerMode;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    _detailItem = newDetailItem;
    [self configureView];
    
    if (self.masterPopoverController != nil)
    {
        [self.theGLViewController.theEmulator resume];
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    if (self.detailItem)
    {
        [self.theGLViewController loadRomWithName:self.detailItem];
    }
    
    if (self.gameControllerMode) {
        self.view.backgroundColor = [UIColor blackColor];
        
        for (UIView* subview in self.view.subviews)
        {
            if ([subview isKindOfClass:[UIImageView class]])
            {
                subview.backgroundColor = [UIColor blackColor];
                ((UIImageView*)subview).image = nil;
            }
        }
    
        CGAffineTransform transform = CGAffineTransformMakeRotation(90 * M_PI / 180);
        transform = CGAffineTransformScale(transform, 1.4, 1.4);
        transform = CGAffineTransformTranslate(transform, 105.0, 0);
        self.theGLViewController.view.transform = transform;
    }
}

- (BOOL)gameControllerMode {
    return [GCController controllers].count > 0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.multipleTouchEnabled = YES;

    [self configureView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.gameControllerMode) {
        [UIApplication sharedApplication].statusBarHidden = YES;
        
        self.navigationController.navigationBarHidden = YES;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (self.gameControllerMode) {
        return NO;
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        return (interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
    }
    else
    {
        return (interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Gearboy";
        
        self.theGLViewController = [[GLViewController alloc] initWithNibName:@"GLViewController" bundle:nil];
        self.theGLViewController.preferredFramesPerSecond = 60;
        self.theGLViewController.resumeOnDidBecomeActive = NO;
        self.theGLViewController.pauseOnWillResignActive = NO;
        
        [self.view addSubview:self.theGLViewController.view];
        
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        if (screenBounds.size.height == 568)
        {
            // 4-inch screen (iPhone 5)
            for (UIView* subview in self.view.subviews)
            {
                if ([subview isKindOfClass:[UIImageView class]])
                {
                    UIImageView* background = (UIImageView*)subview;
                    background.image = [UIImage imageNamed:@"gb-568h.jpg"];
                }
            }
        }
    }
    return self;
}
							
#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = @"Games";
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

-(void) _handleTouch : (UITouch *) touch
{
    InputManager::Instance().HandleTouch(touch, self.view);
}

-(void) touchesBegan : (NSSet *) touches withEvent : (UIEvent *) event
{
    for (UITouch *touch in touches)
    {
        [self _handleTouch : touch];
    }
}

-(void) touchesMoved : (NSSet *) touches withEvent : (UIEvent *) event
{
    for (UITouch *touch in touches)
    {
        [self _handleTouch : touch];
    }
}

-(void) touchesEnded : (NSSet *) touches withEvent : (UIEvent *) event
{
    for (UITouch *touch in touches)
    {
        [self _handleTouch : touch];
    }
}

-(void) touchesCancelled : (NSSet *) touches withEvent : (UIEvent *) event
{
    for (UITouch *touch in touches)
    {
        [self _handleTouch : touch];
    }
}

@end
