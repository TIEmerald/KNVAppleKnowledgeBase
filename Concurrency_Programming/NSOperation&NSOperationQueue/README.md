# NSOperation and NSOperationQueue
## References

[iOS多线程：『NSOperation、NSOperationQueue』详尽总结](https://bujige.net/blog/iOS-Complete-learning-NSOperation.html)

[Concurrency Programming Guide - Apple Doc](https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008091-CH1-SW1)

----


<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

----

## General Information
NSOperation and NSOperationQueue is a higher level framework provided by Apple to help us resolve multi-thread issues. And they are based on GCD framework.

## NSOperation, NSOperationQueue
- **Operation** :
    - Operation is the part of code will be executed in the thread.
    - We are using NSOperation's sub-class - NSInvocationOperation, NSBlockOperation or customized sub-classes - to encapsulate codes.
- **Operation Queues** :
    - Similar to dispatch_queue in GCD, Operation Queue is an object stored all Operations passed in. Different from dispatch_queue in GCD, Operation Queue is not following FIFO as 
        - Every Operations added into an Operation Queue will become a status of Ready for exection
        - The start execution time of these Operations are based on Operations' priority.
    - We are using **maxConcurrentOperationCount** control to execute it Serially or Concurrently.
    - [NSOperationQueue mainQueue] is working inside mainthread. others could work on different threads.

## How to use NSOperation and NSOperationQueue
Normally we could simply follow the following steps to achieve multi-threading
1. Create a NSOperation object which encapulate the actions you want to execute.
2. Create a NSOperationQueue object.
3. Add NSOperation object you created into NSOperationQueue object.

If we use NSOperation only, we will find out that system will execute those operation synchronized.

### NSInvocationOperation
- If we use NSInvocationOperation only, we could find out that the operation is executed in current thread. **NO NEW** thread created.
```objective-c
- (void)task1 {
    for (int i = 0; i < 2; i++) {
        [NSThread sleepForTimeInterval:2];
        NSLog(@"%d---%@", i, [NSThread currentThread]);
    }
}

- (void)useInvocationOperation {
    NSLog(@"start---%@", [NSThread currentThread]);
    NSInvocationOperation *io = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task1) object:nil];
    [io start];
}

[self useInvocationOperation];
[NSThread detachNewThreadSelector:@selector(useInvocationOperation) toTarget:self withObject:nil];

/// Printed Output
// 2020-09-27 10:11:12 start---<NSThread: 0x600001a14900>{number = 1, name = main}
// 2020-09-27 10:11:14 0---<NSThread: 0x600001a14900>{number = 1, name = main}
// 2020-09-27 10:11:16 1---<NSThread: 0x600001a14900>{number = 1, name = main}
// 2020-09-27 10:11:16 start---<NSThread: 0x600001a70600>{number = 6, name = (null)}
// 2020-09-27 10:11:18 0---<NSThread: 0x600001a70600>{number = 6, name = (null)}
// 2020-09-27 10:11:20 1---<NSThread: 0x600001a70600>{number = 6, name = (null)}
```