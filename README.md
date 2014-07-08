UIWindow-TouchIndicatorExtension
================================

A UIWindow extension for indicating the user's touches on screen.

Usage
=====

To activate the touch indicators, simply call the following code at the end of your
application delegate's -applicationDidBecomeActive: method.

    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow performSelector:@selector(startIndicatingTouches)];

It is also a good idea to deactivate the touch indicators by calling the following code
at the end of your application delegate's -applicationWillResignActive: method.

    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow performSelector:@selector(stopIndicatingTouches)];


Customizations
==============

The appearence and behavior of the touch indicators can be modified by changing the following defines.

*   `kTouchIndicatorRadius`

    The radius of the touch indicator in points.
  
*   `kTouchIndicatorBorderWidth`

    The width of the border around the touch indicator.
    
*   `kTouchIndicatorColor`

    The UIColor used to draw the touch indicator.
    
*   `kTouchIndicatorBorderColor`

    The UIColor used to draw the border around the touch indicator.
    
*   `kTouchIndicatorOnlyWhenExternalScreenIsConnected`

    When set to `YES` the touch indicators will only be shown when an external screen is connected to the device.

Inspiration
===========

This project was inspired by Rob Terrell's work on iOS device video output.

See original implementation and writeup here:

*    [http://www.theevilboss.com/2009/10/iphone-video-output.html](http://www.theevilboss.com/2009/10/iphone-video-output.html)    
*    [https://www.youtube.com/watch?v=rvGOP87RA7A](https://www.youtube.com/watch?v=rvGOP87RA7A)
