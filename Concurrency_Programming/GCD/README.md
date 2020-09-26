# Grand Central Dispatch
## References

[iOS 多线程：『GCD』详尽总结](https://bujige.net/blog/iOS-Complete-learning-GCD.html)

[Grand Central Dispatch Wikipedia](https://en.wikipedia.org/wiki/Grand_Central_Dispatch)

[Concurrency Programming Guide - Apple Doc](https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008091-CH1-SW1)

----

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>


----

## General Information
>Grand Central Dispatch (GCD or libdispatch), is a technology developed by Apple Inc. to optimize application support for systems with multi-core processors and other symmetric multiprocessing systems. It is an implementation of task parallelism based on the [thread pool patterm](https://en.wikipedia.org/wiki/Thread_pool). The fundamental idea is to move the management of the thread pool out of the hands of the developer, and closer to the operating system. The developer injects "work packages" into the pool oblivious of the pool's architecture.

## GCD Tasks and Dispatch Queue
### Tasks
>The term task is used to refer to the abstract concept of work that needs to be performed

You could treat tasks as the part of block you are going to execute.

There are two ways to execute tasks
- **sync** 
    - after added a sync task to a queue, and before the sync task is finished in that queue, current task will not continue and will wait.
    - sync tasks will only be executed in current thread, and there will be no new thread created for these tasks.
- **async**
    - after added an async task to a queue, current task won't do anything and will continue executing.
    - async task might create a new thread to ensure task will be executed asynchronized.

### Dispatch Queue
> Disptach queues are a C-based mechanism for executing custom tasks. A dispatch queue executes tasks either serially or concurrently but always in a first-in, first-out order.

- **Serial Dispatch Queue** 
    - Will only open one thread, and will only execute one task each time.
- **Concurrent Dispatch Queue**
    - Might create multiple thread and let multiple takss executing at the same time. (**Please be aware that it will only work under dispatch_async**)

## How to use GCD
- Create a Dispatch Queue
- Then assign tasks into created Dispatch Queue
### How to create/get Dispatch Queue
- We could used dispatch_queue_create method to create a new Dispatch Queue
```objective-c
// How to create a Serial Dispatch Queue
dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", DISPATCH_QUEUE_SERIAL);
// How to create a Concurrent Dispatch Queue
dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", DISPATCH_QUEUE_CONCURRENT);
```
- For UI update you could just use dispatch_get_main_queue() method to get Main Dispatch Queue
    - Please be aware of that Main Dispatch Queue is a Serial Queue
    - If we didn't specify it specially (like assigned current tasks to other queues), the task will be allocate to Main Dispatch Queue by default.
```objective-c
// How to get Main Dispatch Queue
dispatch_queue_t queue = dispatch_get_main_queue();
```
- Or we could use dispatch_get_global_queue() method to get Global Dispatch Queue.
```objective-c
// How to get Global Dispatch Queue
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
```
### How to create tasks
- we could use dispatch_sync to create sync tasks.
- we could use dispatch_async to create async tasks.

### Different task and queue combinations
Here is a table explaining all possible combinations:
|                                |                     to_serial_queue                    |                   to_concurrency_queue                  |                      to_same_queue                      |
|:------------------------------:|:------------------------------------------------------:|:-------------------------------------------------------:|:-------------------------------------------------------:|
|    from_serial_queue (sync)    | **NO NEW**  thread created; Perform tasks **SERIALLY** (*example a.1*) |  **NO NEW**  thread created; Perform tasks **SERIALLY** (*example a.2*) |                        **LOCKED** (*example a.3*)                       |
|    from_serial_queue (async)   |   **NEW** thread created; Perform tasks  **SERIALLY** (*example b.1*)  | **NEW**  thread created; Perform tasks **CONCURRENTLY** (*example b.2*) | **NO NEW**  thread created; Perform tasks  **SERIALLY** (*example b.3*) |
| from_concurrency_queue (sync)  | **NO NEW**  thread created; Perform tasks **SERIALLY** (*example c.1*) | **NO NEW**  thread created; Perform tasks **SERIALLY** (*example c.2*)  | **NO NEW**  thread created; Perform tasks **SERIALLY** (*example c.3*) 
| from_concurrency_queue (async) | **NEW**  thread created; Perform tasks **SERIALLY** (*example d.1*)    | **NEW**  thread created; Perform tasks **CONCURRENTLY** (*example d.2*) | **NEW**  thread created; Perform tasks **CONCURRENTLY** (*example d.3*) |

And here are detailded examples:

**group a**
```objective-c
dispatch_queue_t serialQueueA = dispatch_queue_create("serialQueueA", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t serialQueueB = dispatch_queue_create("serialQueueB", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t concurrencyQueueA = dispatch_queue_create("concurrencyQueueA", DISPATCH_QUEUE_CONCURRENT);
dispatch_queue_t concurrencyQueueB = dispatch_queue_create("concurrencyQueueB", DISPATCH_QUEUE_CONCURRENT);
NSLog(@"1 - %@", [NSThread currentThread]);

dispatch_async(serialQueueA, ^{
    NSLog(@"2 - %@", [NSThread currentThread]); // Thread number = 6,

    // a.1
    dispatch_sync(serialQueueB, ^{
        NSLog(@"3 - %@", [NSThread currentThread]); // Thread number = 6,
    });
    NSLog(@"4 - %@", [NSThread currentThread]); // Thread number = 6,

    // a.2
    dispatch_sync(concurrencyQueueB, ^{
        NSLog(@"5 - %@", [NSThread currentThread]); // Thread number = 6,
    });
    NSLog(@"6 - %@", [NSThread currentThread]); // Thread number = 6,

    // a.3
    dispatch_sync(serialQueueA, ^{
        NSLog(@"7 - %@", [NSThread currentThread]);
    });
    NSLog(@"8 - %@", [NSThread currentThread]);
});

/// Print out logs:
// 1 - <NSThread: 0x600003da81c0>{number = 1, name = main}
// 2 - <NSThread: 0x600003de5a00>{number = 6, name = (null)}
// 3 - <NSThread: 0x600003de5a00>{number = 6, name = (null)}
// 4 - <NSThread: 0x600003de5a00>{number = 6, name = (null)}
// 5 - <NSThread: 0x600003de5a00>{number = 6, name = (null)}
// 6 - <NSThread: 0x600003de5a00>{number = 6, name = (null)}
//(lldb)  EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, subcode=0x0)
```
**group b**
```objective-c
dispatch_queue_t serialQueueA = dispatch_queue_create("serialQueueA", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t serialQueueB = dispatch_queue_create("serialQueueB", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t concurrencyQueueA = dispatch_queue_create("concurrencyQueueA", DISPATCH_QUEUE_CONCURRENT);
dispatch_queue_t concurrencyQueueB = dispatch_queue_create("concurrencyQueueB", DISPATCH_QUEUE_CONCURRENT);
NSLog(@"1 - %@", [NSThread currentThread]);

dispatch_async(serialQueueA, ^{
    NSLog(@"2 - %@", [NSThread currentThread]); // Thread number = 5,

    // b.1
    dispatch_async(serialQueueB, ^{
        NSLog(@"3 - %@", [NSThread currentThread]);  // Thread number = 3,
    });
    NSLog(@"4 - %@", [NSThread currentThread]);  // Thread number = 5,

    // b.2
    dispatch_async(concurrencyQueueB, ^{
        NSLog(@"5 - %@", [NSThread currentThread]);  // Thread number = 7,
    });
    NSLog(@"6 - %@", [NSThread currentThread]);  // Thread number = 5,

    // b.3
    dispatch_async(serialQueueA, ^{
        NSLog(@"7 - %@", [NSThread currentThread]);  // Thread number = 5,
    });
    NSLog(@"8 - %@", [NSThread currentThread]);  // Thread number = 5,
});

/// Print out logs:
// 1 - <NSThread: 0x600003da81c0>{number = 1, name = main}
// 2 - <NSThread: 0x60000121e4c0>{number = 5, name = (null)}
// 4 - <NSThread: 0x60000121e4c0>{number = 5, name = (null)}
// 3 - <NSThread: 0x600001250cc0>{number = 3, name = (null)}
// 6 - <NSThread: 0x60000121e4c0>{number = 5, name = (null)}
// 5 - <NSThread: 0x60000124d440>{number = 7, name = (null)}
// 8 - <NSThread: 0x60000121e4c0>{number = 5, name = (null)}
// 7 - <NSThread: 0x60000121e4c0>{number = 5, name = (null)}
```
**group c**
```objective-c
dispatch_queue_t serialQueueA = dispatch_queue_create("serialQueueA", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t serialQueueB = dispatch_queue_create("serialQueueB", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t concurrencyQueueA = dispatch_queue_create("concurrencyQueueA", DISPATCH_QUEUE_CONCURRENT);
dispatch_queue_t concurrencyQueueB = dispatch_queue_create("concurrencyQueueB", DISPATCH_QUEUE_CONCURRENT);
NSLog(@"1 - %@", [NSThread currentThread]);

dispatch_async(concurrencyQueueA, ^{
    NSLog(@"2 - %@", [NSThread currentThread]); // Thread number = 4,

    // c.1
    dispatch_sync(serialQueueB, ^{
        NSLog(@"3 - %@", [NSThread currentThread]);  // Thread number = 4,
    });
    NSLog(@"4 - %@", [NSThread currentThread]);  // Thread number = 4,

    // c.2
    dispatch_sync(concurrencyQueueB, ^{
        NSLog(@"5 - %@", [NSThread currentThread]);  // Thread number = 4,
    });
    NSLog(@"6 - %@", [NSThread currentThread]);  // Thread number = 4,

    // c.3
    dispatch_sync(concurrencyQueueA, ^{
        NSLog(@"7 - %@", [NSThread currentThread]);  // Thread number = 4,
    });
    NSLog(@"8 - %@", [NSThread currentThread]);  // Thread number = 4,
});

/// Print out logs:
// 1 - <NSThread: 0x600003da81c0>{number = 1, name = main}
// 2 - <NSThread: 0x600000149280>{number = 4, name = (null)}
// 3 - <NSThread: 0x600000149280>{number = 4, name = (null)}
// 4 - <NSThread: 0x600000149280>{number = 4, name = (null)}
// 5 - <NSThread: 0x600000149280>{number = 4, name = (null)}
// 6 - <NSThread: 0x600000149280>{number = 4, name = (null)}
// 7 - <NSThread: 0x600000149280>{number = 4, name = (null)}
// 8 - <NSThread: 0x600000149280>{number = 4, name = (null)}
```
**group d**
```objective-c
dispatch_queue_t serialQueueA = dispatch_queue_create("serialQueueA", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t serialQueueB = dispatch_queue_create("serialQueueB", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t concurrencyQueueA = dispatch_queue_create("concurrencyQueueA", DISPATCH_QUEUE_CONCURRENT);
dispatch_queue_t concurrencyQueueB = dispatch_queue_create("concurrencyQueueB", DISPATCH_QUEUE_CONCURRENT);
NSLog(@"1 - %@", [NSThread currentThread]);

dispatch_async(concurrencyQueueA, ^{
    NSLog(@"2 - %@", [NSThread currentThread]); // Thread number = 6,

    // d.1
    dispatch_async(serialQueueB, ^{
        NSLog(@"3 - %@", [NSThread currentThread]);  // Thread number = 5,
    });
    NSLog(@"4 - %@", [NSThread currentThread]);  // Thread number = 6,

    // d.2
    dispatch_async(concurrencyQueueB, ^{
        NSLog(@"5 - %@", [NSThread currentThread]);  // Thread number = 3,
    });
    NSLog(@"6 - %@", [NSThread currentThread]);  // Thread number = 6,

    // d.3
    dispatch_async(concurrencyQueueA, ^{
        NSLog(@"7 - %@", [NSThread currentThread]);  // Thread number = 5,
    });
    NSLog(@"8 - %@", [NSThread currentThread]);  // Thread number = 6,
});

/// Print out logs:
// 1 - <NSThread: 0x600003da81c0>{number = 1, name = main}
// 2 - <NSThread: 0x600003998b40>{number = 6, name = (null)}
// 4 - <NSThread: 0x600003998b40>{number = 6, name = (null)}
// 3 - <NSThread: 0x600003996140>{number = 5, name = (null)}
// 6 - <NSThread: 0x600003998b40>{number = 6, name = (null)}
// 5 - <NSThread: 0x6000039ce200>{number = 3, name = (null)}
// 8 - <NSThread: 0x600003998b40>{number = 6, name = (null)}
// 7 - <NSThread: 0x600003996140>{number = 5, name = (null)}
```