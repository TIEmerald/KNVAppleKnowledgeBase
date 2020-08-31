//
//  UNDCustomRunLoopCodes.m
//  Temp Objective C Playground Project
//
//  Created by UNDaniel on 31/8/20.
//  Copyright © 2020 UNDaniel. All rights reserved.
//

#import "UNDCustomRunLoopCodes.h"

// App Delegate
#import "AppDelegate.h"

void RunLoopSourceScheduleRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
{
    UNDCustomRunLoopSource* obj = (__bridge UNDCustomRunLoopSource*)info;
    AppDelegate*   del = (AppDelegate*)[UIApplication sharedApplication].delegate;
    UNDCustomRunLoopContext* theContext = [[UNDCustomRunLoopContext alloc] initWithSource:obj andLoop:rl];
    
    [del performSelectorOnMainThread:@selector(registerSource:)
                          withObject:theContext waitUntilDone:NO];
}

void RunLoopSourcePerformRoutine (void *info)
{
    UNDCustomRunLoopSource* obj = (__bridge UNDCustomRunLoopSource*)info;
    [obj sourceFired];
}

void RunLoopSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
{
    UNDCustomRunLoopSource* obj = (__bridge UNDCustomRunLoopSource*)info;
    AppDelegate*   del = (AppDelegate*)[UIApplication sharedApplication].delegate;
    UNDCustomRunLoopContext* theContext = [[UNDCustomRunLoopContext alloc] initWithSource:obj andLoop:rl];
    
    [del performSelectorOnMainThread:@selector(removeSource:)
                          withObject:theContext waitUntilDone:YES];
}

@implementation UNDCustomRunLoopSource

- (instancetype)init
{
    if (self = [super init]) {
        CFRunLoopSourceContext    context = {0, (__bridge void *)(self), NULL, NULL, NULL, NULL, NULL,
            &RunLoopSourceScheduleRoutine,
            RunLoopSourceCancelRoutine,
            RunLoopSourcePerformRoutine};
        
        runLoopSource = CFRunLoopSourceCreate(NULL, 0, &context);
        commands = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addToCurrentRunLoop
{
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);
}

- (void)fireAllCommandsOnRunLoop:(CFRunLoopRef)runloop
{
    // Signaling the source lets the run loop know that the source is ready to be processed.
    CFRunLoopSourceSignal(runLoopSource);
    // And because the thread might be asleep when the signal occurs, you should always wake up the run loop explicitly. Failing to do so might result in a delay in processing the input source.
    CFRunLoopWakeUp(runloop);
}

@end

@implementation UNDCustomRunLoopContext

@end
