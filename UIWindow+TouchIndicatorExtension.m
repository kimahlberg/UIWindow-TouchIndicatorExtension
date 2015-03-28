//
//  UIWindow+TouchIndicatorExtension.m
//  https://github.com/kimahlberg/UIWindow-TouchIndicatorExtension
//
//  Created by Kim Ahlberg on 2010-11-30.
//
//  The MIT License (MIT)
//
//    Copyright (c) 2010-2015 Kim Ahlberg
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//
//
//  This project was inspired by Rob Terrell's work on iOS device video output.
//	See:
//    http://www.theevilboss.com/2009/10/iphone-video-output.html
//    https://www.youtube.com/watch?v=rvGOP87RA7A
//
//
//  USAGE:
//  To activate the touch indicators, simply call the following code at the end of your
//  application delegate's -applicationDidBecomeActive: method.
//
//    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
//    [keyWindow performSelector:@selector(startIndicatingTouches)];
//
//  It is also a good idea to deactivate the touch indicators by calling the following code
//  at the end of your application delegate's -applicationWillResignActive: method.
//
//    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
//    [keyWindow performSelector:@selector(stopIndicatingTouches)];
//

#import <UIKit/UIKit.h>

// Touch indicator appearence settings.
#define kTouchIndicatorRadius 15.0
#define kTouchIndicatorBorderWidth 4.0
#define kTouchIndicatorColor [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]
#define kTouchIndicatorBorderColor [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.5]

// Should touch indicators only be displayed when external screens are connected?
#define kTouchIndicatorOnlyWhenExternalScreenIsConnected NO

@interface UIWindow (TouchIndicatorExtension)
- (void)startIndicatingTouches;
- (void)stopIndicatingTouches;
@end

@implementation UIWindow (TouchIndicatorExtension)
UIEvent *activeEvent = nil;
UIImage *touchIndicatorImage = nil;
NSMutableArray *touchIndicatorImageViews = nil;
CADisplayLink *displayLink = nil;

#pragma mark - UIWindow overrides

/// Overrides the pointInside:withEvent: method of UIWindow in order to register the touch events.
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(self.bounds, point)) {
        // We only concern ourselves with touch events.
        if (event.type == UIEventTypeTouches)
        {
            @synchronized(activeEvent) {
                if(nil != event && event != activeEvent) {
                    activeEvent = event;
                }
            }
        }
        return YES;
    }
    return NO;
}

#pragma mark - Actions

- (void)startIndicatingTouches
{
    if (kTouchIndicatorOnlyWhenExternalScreenIsConnected)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenDidConnectOrDisconnect:) name:UIScreenDidConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenDidConnectOrDisconnect:) name:UIScreenDidDisconnectNotification object:nil];
        
        // Initialize with the number of screens at startup.
        [self screenDidConnectOrDisconnect:nil];
    }
    else
    {
        [self startDisplayLink];
    }
}

- (void) stopIndicatingTouches
{
    [self stopDisplayLink];
}

#pragma mark - Helpers

- (void) screenDidConnectOrDisconnect:(NSNotification *)notification
{
    if ([[UIScreen screens] count] > 1) {
        [self startDisplayLink];
    }
    else
    {
        [self stopDisplayLink];
    }
}

- (void)startDisplayLink
{
    touchIndicatorImage = [self generateTouchIndicatorImage];
    touchIndicatorImageViews = [NSMutableArray array];
    
    if (displayLink) {
        [displayLink invalidate];
    }
    
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTriggered:)];
    displayLink.frameInterval = 1;
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopDisplayLink
{
    [displayLink invalidate];
    displayLink = nil;
    
    // Cleanup by removing all image views and touch points.
    for (UIImageView *touchIndicatorImageView in touchIndicatorImageViews) {
        [touchIndicatorImageView removeFromSuperview];
    }
    
    [touchIndicatorImageViews removeAllObjects];
    touchIndicatorImageViews = nil;
    touchIndicatorImage = nil;
	activeEvent = nil;
}

- (void)displayLinkTriggered:(CADisplayLink *)sender
{
    [self addTouchIndicatorsToWindow];
}

- (void)addTouchIndicatorsToWindow
{
    CGPoint touchPoint;
    UIImageView *touchIndicatorImageView = nil;
    NSUInteger activeTouchesIndex = 0;
    
    @synchronized(activeEvent)
    {
		for (UITouch *touch in [activeEvent allTouches])
        {
            // Add the additional image views if needed.
            if (activeTouchesIndex >= touchIndicatorImageViews.count)
            {
                touchIndicatorImageView = [[UIImageView alloc]
                                           initWithImage:touchIndicatorImage];
                
                // Handle retina screens by scaling the returned graphic.
                CGFloat scaleFactor = [[UIScreen mainScreen] scale];
                touchIndicatorImageView.transform = CGAffineTransformMakeScale(1.0/scaleFactor,
                                                                               1.0/scaleFactor);
                touchIndicatorImageView.layer.shouldRasterize = YES;
                [touchIndicatorImageViews addObject:touchIndicatorImageView];
                [self addSubview:touchIndicatorImageView];
            }
            else
            {
                touchIndicatorImageView = touchIndicatorImageViews[activeTouchesIndex];
            }

            // Set the touch point.
            if(touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled)
            {
                // Touch is no longer ongoing, move it off screen.
                touchPoint = CGPointMake(-100.0, -100.0);
			}
            else
            {
                touchPoint = [touch locationInView:self];
            }

            touchIndicatorImageView.layer.position = touchPoint;
            
            // Always bring the image view to front, in case something is covering it.
            [self bringSubviewToFront:touchIndicatorImageView];
            
			activeTouchesIndex++;
		}
		
        // Any saved touch indicator views not currently representing a touch should be moved off screen.
        for (NSInteger i = activeTouchesIndex; i < touchIndicatorImageViews.count; i++)
        {
            touchIndicatorImageView = touchIndicatorImageViews[i];
            touchIndicatorImageView.layer.position = CGPointMake(-100.0, -100.0);
        }
        
		if (0 == activeTouchesIndex) {
			// No active touches, so we get rid of the event.
			activeEvent = nil;
		}
	}
}

/// Returns the image used to indicate a touch on screen.
- (UIImage *)generateTouchIndicatorImage
{
    // Use the scale factor for retina screens.
    CGFloat scaleFactor = [[UIScreen mainScreen] scale];
    
    // Prepare the size of the touch indicator.
	static CGFloat radius = kTouchIndicatorRadius;
    static CGFloat borderWidth = kTouchIndicatorBorderWidth;
    NSInteger w = radius * 2.0 + 2 * borderWidth;
    NSInteger h = radius * 2.0 + 2 * borderWidth;
	
    // Create the context to draw into.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 w * scaleFactor,
                                                 h * scaleFactor,
                                                 8,
                                                 4 * w * scaleFactor,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    CGContextScaleCTM(context, scaleFactor, scaleFactor);
    
    // Draw the outer circle.
    CGRect indicatorRect = CGRectMake(0, 0, w, h);
    CGContextSetLineWidth(context, borderWidth);
    CGContextSetStrokeColorWithColor(context, kTouchIndicatorBorderColor.CGColor);
    CGContextStrokeEllipseInRect(context, CGRectInset(indicatorRect, borderWidth/2.0, borderWidth/2.0));

    // Draw the inner circle.
    CGContextSetFillColorWithColor(context, kTouchIndicatorColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectInset(indicatorRect, borderWidth, borderWidth));
    
    // Create the UIImage to return.
    CGImageRef bitmapImage = CGBitmapContextCreateImage(context);
	UIImage *returnImage = [UIImage imageWithCGImage:bitmapImage];
	
    // Cleanup.
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
	CGImageRelease(bitmapImage);

    return returnImage;
}

@end
