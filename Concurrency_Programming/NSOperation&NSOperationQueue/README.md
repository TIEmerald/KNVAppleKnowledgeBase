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

### Using NSOperation
#### NSInvocationOperation
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

#### NSBlockOperation
- Please be aware that NSBlockOperation has a method called -(void)addExecutionBlock:, which could add extra tasks into Operation object. Those tasks are executed concurrently, thus those tasks will be executed in different thread. Only all tasks finished, then we will treat this Operation is done.
```objective-c 
NSLog(@"start---%@", [NSThread currentThread]);
NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
    for (int i = 0; i < 2; i++) {
        [NSThread sleepForTimeInterval:2];
        NSLog(@"0-%d---%@", i, [NSThread currentThread]); // If you added a lot of extra tasks, there is no guarantee that this block will be performed in the same thread where [op start] is called.
    }
}];
for (int index = 1; index <= 6; index += 1) {
    [op addExecutionBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"%d-%d---%@", index, i, [NSThread currentThread]);
        }
    }];
}
[op start];
NSLog(@"finished---%@", [NSThread currentThread]);

/// Printed Output
// 2020-09-27 21:53:58 start---<NSThread: 0x6000037641c0>{number = 1, name = main}
// 2020-09-27 21:54:00 6-0---<NSThread: 0x600003763600>{number = 8, name = (null)}
// 2020-09-27 21:54:00 1-0---<NSThread: 0x600003741d80>{number = 4, name = (null)}
// 2020-09-27 21:54:00 4-0---<NSThread: 0x600003763e80>{number = 3, name = (null)}
// 2020-09-27 21:54:00 0-0---<NSThread: 0x6000037641c0>{number = 1, name = main}
// 2020-09-27 21:54:00 3-0---<NSThread: 0x600003749480>{number = 7, name = (null)}
// 2020-09-27 21:54:00 2-0---<NSThread: 0x600003749500>{number = 5, name = (null)}
// 2020-09-27 21:54:00 5-0---<NSThread: 0x600003735700>{number = 9, name = (null)}
// 2020-09-27 21:54:02 0-1---<NSThread: 0x6000037641c0>{number = 1, name = main}
// 2020-09-27 21:54:02 4-1---<NSThread: 0x600003763e80>{number = 3, name = (null)}
// 2020-09-27 21:54:02 2-1---<NSThread: 0x600003749500>{number = 5, name = (null)}
// 2020-09-27 21:54:02 5-1---<NSThread: 0x600003735700>{number = 9, name = (null)}
// 2020-09-27 21:54:02 6-1---<NSThread: 0x600003763600>{number = 8, name = (null)}
// 2020-09-27 21:54:02 1-1---<NSThread: 0x600003741d80>{number = 4, name = (null)}
// 2020-09-27 21:54:02 3-1---<NSThread: 0x600003749480>{number = 7, name = (null)}
// 2020-09-27 21:54:02 finished---<NSThread: 0x6000037641c0>{number = 1, name = main}
```

#### Customised sub-class of NSOperation
- If NSInvocationOperation and NSBlockOperation cannot achieve what we want, we could use customized sub-class of NSOperation. Wahta we need is over-write -(void)main or -(void)start to achieve what we want.
- Normally, over-write -(void)main is easier as we don't need to worry about properties like isExecuting and isFinished.
```objective-c
@interface CustomOperation : NSOperation
@end

@implementation CustomOperation

- (void)main {
    for (int i = 0; i < 2; i++) {
        [NSThread sleepForTimeInterval:2];
        NSLog(@"%d---%@", i, [NSThread currentThread]);
    }
}
@end

CustomOperation *op = [[CustomOperation init] alloc];
[op start];
```

### Using NSOperationQueue
- Only Customsed NSOperationQueue support Concurrency
- [NSOperationQueue mainQueue] will put every tasks assigned into main thread.

### Put NSOperation into NSOperationQueue
1. -(void)addOperation:(NSOperation *)op;
    - Create NSOperation first. While NSOperation is added into NSOperationQueue, a thread is created and that NSOperation will start.
```objective-c
- (void)task1 {
    for (int i = 0; i < 2; i++) {
        [NSThread sleepForTimeInterval:2];
        NSLog(@"task1-%d---%@", i, [NSThread currentThread]);
    }
}

- (void)task2 {
    for (int i = 0; i < 2; i++) {
        [NSThread sleepForTimeInterval:2];
        NSLog(@"task2-%d---%@", i, [NSThread currentThread]);
    }
}

NSInvocationOperation *op1 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task1) object:nil];
NSInvocationOperation *op2 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task2) object:nil];
NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
    for (int i = 0; i < 2; i++) {
        [NSThread sleepForTimeInterval:2];
        NSLog(@"task3-%d---%@", i, [NSThread currentThread]);
    }
}];
[op3 addExecutionBlock:^{
    for (int i = 0; i < 2; i++) {
        [NSThread sleepForTimeInterval:2];
        NSLog(@"task3extra-%d---%@", i, [NSThread currentThread]);
    }
}];

NSOperationQueue *queue = [[NSOperationQueue alloc] init];
NSLog(@"add task 1");
[queue addOperation:op1]; // [op1 start]
NSLog(@"add task 2");
[queue addOperation:op2]; // [op2 start]
NSLog(@"add task 3");
[queue addOperation:op3]; // [op3 start]

/// Printed output
// 2020-09-28 18:21:25 add task 1---<NSThread: 0x6000005c8900>{number = 1, name = main}
// 2020-09-28 18:21:25 add task 2---<NSThread: 0x6000005c8900>{number = 1, name = main}
// 2020-09-28 18:21:25 add task 3---<NSThread: 0x6000005c8900>{number = 1, name = main}
// 2020-09-28 18:21:25 All Added---<NSThread: 0x6000005c8900>{number = 1, name = main}
// 2020-09-28 18:21:27 task3extra-0---<NSThread: 0x6000005d9cc0>{number = 4, name = (null)}
// 2020-09-28 18:21:27 task1-0---<NSThread: 0x600000589140>{number = 3, name = (null)}
// 2020-09-28 18:21:27 task2-0---<NSThread: 0x600000588e40>{number = 6, name = (null)}
// 2020-09-28 18:21:27 task3-0---<NSThread: 0x60000058a280>{number = 8, name = (null)}
// 2020-09-28 18:21:29 task1-1---<NSThread: 0x600000589140>{number = 3, name = (null)}
// 2020-09-28 18:21:29 task2-1---<NSThread: 0x600000588e40>{number = 6, name = (null)}
// 2020-09-28 18:21:29 task3extra-1---<NSThread: 0x6000005d9cc0>{number = 4, name = (null)}
// 2020-09-28 18:21:29 task3-1---<NSThread: 0x60000058a280>{number = 8, name = (null)}
```