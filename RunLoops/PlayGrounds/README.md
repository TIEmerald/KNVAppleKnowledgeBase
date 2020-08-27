# Play Grounds
## References
[Apple Threading Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html)

----

----
## Getting a Run Loop Object
1. In a Cocoa application, NSRunLoop Class is use
```objective-c
    NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop];
```
2. Or could use CFRunLoop
```objective-c
    NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop];
    CFRunLoopRef myRunLoopRef = [myRunLoop getCFRunLoop];
    /// or
    CFRunLoopRef runLoopRef = CFRunLoopGetCurrent();
```
## Configuring the Run Loop
>Before you run a run loop on a secondary thread, you must add at least one input source or timer to it. If a run loop does not have any sources to monitor, it exits immediately when you try to run it. 

- If there is no source to monitor, run loop will exit immediately.

>When configuring the run loop for a long-lived thread, it is better to add at least one input source to receive messages. Although you can enter the run loop with only a timer attached, once the timer fires, it is typically invalidated, which would then cause the run loop to exit. Attaching a repeating timer could keep the run loop running over a longer period of time, but would involve firing the timer periodically to wake your thread, which is effectively another form of polling. By contrast, an input source waits for an event to happen, keeping your thread asleep until it does.

- A repeated timer could keep wake your thread.

### Create a run loop observer
```objective-c
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
    KNVRunLoopPlayGroundModel *model = (__bridge KNVRunLoopPlayGroundModel *)(info); // info is my self
    NSLog(@"activity = %lu", activity);
    NSLog(@"runLoopOserverCallBack -> model = %@",model);
}
```

### Create and schedule the timer.
```objective-c
- (void)addAndScheduleATimer
{
    NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop];
    
    // Create and schedule the timer.
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self
                                   selector:@selector(doFireTimer:) userInfo:nil repeats:YES];
    
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
```

## Starting the Run Loop
>Starting the run loop is necessary only for the secondary threads in your application. A run loop must have at least one input source or timer to monitor. If one is not attached, the run loop exits immediately.

>There are several ways to start the run loop, including the following:
>- **Unconditionally:** Which is the easilest, but will cause you lost the control of run loop itself. You can add and remove input sources and timers, but the only way to stop the run loop is to kill it. There is also no way to run the run loop in a custom mode.
>- **With a set time limit:** When you use a timeout value, the run loop runs until an event arrives or the allotted time expires. If an event arrives, that event is dispatched to a handler for processing and then the run loop exits. Your code can then restart the run loop to handle the next event. If the allotted time expires instead, you can simply restart the run loop or use the time to do any needed housekeeping.
>- **In a particular mode:** In addition to timeout value, you can also run your run loop using a specific mode.

```objective-c
typedef CF_ENUM(SInt32, CFRunLoopRunResult) {
    kCFRunLoopRunFinished = 1,
    kCFRunLoopRunStopped = 2,
    kCFRunLoopRunTimedOut = 3,
    kCFRunLoopRunHandledSource = 4
};

- (void)skeletonThreadMain
{
    // Set up an autorelease pool here if not using garbage collection.
    BOOL done = NO;
 
    // Add your sources or timers to the run loop and do any other setup.
 
    do
    {
        // Start the run loop but return after each source is handled.
        SInt32    result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10, YES);
 
        // If a source explicitly stopped the run loop, or if there are no
        // sources or timers, go ahead and exit.
        if ((result == kCFRunLoopRunStopped) || (result == kCFRunLoopRunFinished))
            done = YES;
 
        // Check for any other exit conditions here and set the
        // done variable as needed.
    }
    while (!done);
 
    // Clean up code here. Be sure to release any allocated autorelease pools.
}
```
>It is possible to run a run loop recursively. In other words, you can call CFRunLoopRun, CFRunLoopRunInMode, or any of the NSRunLoop methods for starting the run loop from within the handler routine of an input source or timer. When doing so, you can use any mode you want to run the nested run loop, including the mode in use by the outer run loop
- **TODO:** Not very sure about the deatils of this part. From my understanding, CFRunLoopRun or CFRunLoopRunInMode could keep run current run loop (for one full circle of current run loop?). And we could add events to the Run Loop, and then keep call the method to run that Run Loop, until it finished or stopped, the we could release the resources.

## Existing the Run Loop
>There are two ways to make a run loop exit before it has processed an event:
>- Configure the run loop to run with a timeout value.
>- Tell the run loop to stop.

>Using a timeout value is certainly preferred, if you can manage it. Specifying a timeout value lets the run loop finish all of its normal processing, including delivering notifications to run loop observers, before exiting.

>Stopping the run loop explicitly with the CFRunLoopStop function produces a result similar to a timeout. The run loop sends out any remaining run-loop notifications and then exits. The difference is that you can use this technique on run loops you started unconditionally.

>Although removing a run loop’s input sources and timers may also cause the run loop to exit, this is **NOT** a reliable way to stop a run loop. Some system routines add input sources to a run loop to handle needed events. Because your code might not be aware of these input sources, it would be unable to remove them, which would prevent the run loop from exiting.

## Thread Safety and Run Loop Objects
>Thread safety varies depending on which API you are using to manipulate your run loop. The functions in Core Foundation are generally thread-safe and can be called from any thread. **If you are performing operations that alter the configuration of the run loop, however, it is still good practice to do so from the thread that owns the run loop whenever possible**.

>The Cocoa **NSRunLoop** class is **NOT** as inherently thread safe as its Core Foundation counterpart. If you are using the NSRunLoop class to modify your run loop, you should do so only from the same thread that owns that run loop. Adding an input source or timer to a run loop belonging to a different thread could cause your code to crash or behave in an unexpected way.