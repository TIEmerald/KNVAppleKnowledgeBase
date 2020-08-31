//
//  KNVRunLoopPlayGroundModel.m
//  Temp Objective C Playground Project
//
//  Created by UNDaniel on 27/8/20.
//  Copyright © 2020 UNDaniel. All rights reserved.
//

#import "UNDRunLoopPlayGroundModel.h"

@implementation UNDRunLoopPlayGroundModel

#pragma mark - General Methods
- (void)playWithRunLoop
{
    // The application uses garbage collection, so no autorelease pool is needed.
    NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop];
    NSLog(@"myRunLoop: %@", myRunLoop);
    
    CFRunLoopRef runLoopRef = CFRunLoopGetCurrent();
    NSLog(@"runLoopRef: %@", runLoopRef);
}

- (void)addAndScheduleATimer
{
    NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop];
    
    // Create and schedule the timer.
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self
                                   selector:@selector(doFireTimer:) userInfo:nil repeats:YES];
    //scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:
    //scheduledTimerWithTimeInterval:invocation:repeats:
    //    These methods create the timer and add it to the current thread’s run loop in the default mode (NSDefaultRunLoopMode).
    
    // You can also schedule a timer manually if you want by creating your NSTimer object and then adding it to the run loop using the addTimer:forMode: method of NSRunLoop. Both techniques do basically the same thing but give you different levels of control over the timer’s configuration.
//    NSDate *firstFireDate = [NSDate dateWithTimeIntervalSinceNow:1.0];
//    NSTimer *myTimer = [[NSTimer alloc] initWithFireDate:firstFireDate interval:0.1 target:self selector:@selector(doFireTimer:) userInfo:nil repeats:YES];
//    [myRunLoop addTimer:myTimer forMode:NSDefaultRunLoopMode];
    
    // You could also use the Core Foundation functions
//    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
//    CFRunLoopTimerContext context = {0, NULL, NULL, NULL, NULL};
//    CFRunLoopTimerRef timer = CFRunLoopTimerCreate(kCFAllocatorDefault, 0.1, 0.3, 0, 0,
//                                                   &myCFTimerCallback, &context);
//    
//    CFRunLoopAddTimer(runLoop, timer, kCFRunLoopCommonModes);
    
    NSInteger    loopCount = 10;
    do
    {
        // Run the run loop 10 times to let the timer fire.
        [myRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        loopCount--;
    }
    while (loopCount);
}

- (void)doFireTimer:(NSTimer *)timer
{
    NSLog(@"Fireing Timer");
}

- (void)addAnObserver
{
    CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
    
    // Create a run loop observer and attach it to the run loop.
    CFRunLoopObserverContext  context = {0, (__bridge void *)self, NULL, NULL, NULL};
    CFRunLoopObserverRef    observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                                               kCFRunLoopAllActivities, YES, 0, &myRunLoopObserver, &context);
    
    if (observer) {
        CFRunLoopAddObserver(currentRunLoop, observer, kCFRunLoopDefaultMode);
    }
}

static void myRunLoopObserver(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    UNDRunLoopPlayGroundModel *model = (__bridge UNDRunLoopPlayGroundModel *)(info); // info is my self
    NSLog(@"activity = %lu", activity);
    NSLog(@"runLoopOserverCallBack -> model = %@",model);
}

#define kCheckinMessage 100

// Handle responses from the worker thread.
// Only exist in Mac OS.
//- (void)handlePortMessage:(NSPortMessage *)portMessage
//{
//    unsigned int message = [portMessage msgid];
//    NSPort* distantPort = nil;
//
//    if (message == kCheckinMessage)
//    {
//        // Get the worker thread’s communications port.
//        distantPort = [portMessage sendPort];
//
//        // Retain and save the worker port for later use.
//        [self storeDistantPort:distantPort];
//    }
//    else
//    {
//        // Handle other messages.
//    }
//}


@end

// The Reference to how to configure RunLoop with Port-Based Source we could checking this Doc: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html#//apple_ref/doc/uid/10000057i-CH16-131281
@implementation UNDRunLoopWorkerModel

@end

