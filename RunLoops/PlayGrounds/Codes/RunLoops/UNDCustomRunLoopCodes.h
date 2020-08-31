//
//  UNDCustomRunLoopCodes.h
//  Temp Objective C Playground Project
//
//  Created by UNDaniel on 31/8/20.
//  Copyright © 2020 UNDaniel. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// These are the CFRunLoopSourceRef callback functions.
void RunLoopSourceScheduleRoutine (void *info, CFRunLoopRef rl, CFStringRef mode);
void RunLoopSourcePerformRoutine (void *info);
void RunLoopSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode);

@interface UNDCustomRunLoopSource : NSObject {
    CFRunLoopSourceRef runLoopSource;
    NSMutableArray* commands;
}

- (id)init;
- (void)addToCurrentRunLoop;
- (void)invalidate;

// Handler method
- (void)sourceFired;

// Client interface for registering commands to process
- (void)addCommand:(NSInteger)command withData:(id)data;
- (void)fireAllCommandsOnRunLoop:(CFRunLoopRef)runloop;

@end

@class UNDCustomRunLoopContext;

@protocol UNDCustomRunLoopSourceObserverProtocol <NSObject>
- (void)registerSource:(UNDCustomRunLoopContext*)sourceInfo;
- (void)removeSource:(UNDCustomRunLoopContext*)sourceInfo;
@end

// RunLoopContext is a container object used during registration of the input source.
@interface UNDCustomRunLoopContext : NSObject {
    CFRunLoopRef        runLoop;
    UNDCustomRunLoopSource*        source;
}
@property (readonly) CFRunLoopRef runLoop;
@property (readonly) UNDCustomRunLoopSource* source;

- (id)initWithSource:(UNDCustomRunLoopSource*)src andLoop:(CFRunLoopRef)loop;
@end

NS_ASSUME_NONNULL_END
