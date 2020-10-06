# Grand Central Dispatch
## References

[iOS 多线程：『GCD』详尽总结](https://bujige.net/blog/iOS-Complete-learning-GCD.html)

[Grand Central Dispatch Wikipedia](https://en.wikipedia.org/wiki/Grand_Central_Dispatch)

[Concurrency Programming Guide - Apple Doc](https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008091-CH1-SW1)

----
- [General Information](#general-information)
- [GCD Tasks and Dispatch Queue](#gcd-tasks-and-dispatch-queue)
  * [Tasks](#tasks)
  * [Dispatch Queue](#dispatch-queue)
- [How to use GCD](#how-to-use-gcd)
  * [How to create/get Dispatch Queue](#how-to-create-get-dispatch-queue)
  * [How to create tasks](#how-to-create-tasks)
  * [Different task and queue combinations](#different-task-and-queue-combinations)
- [Communicate between Queues inside GCD](#communicate-between-queues-inside-gcd)
- [GCD Other Functions](#gcd-other-functions)
  * [dispatch_barrier_async](#dispatch-barrier-async)
  * [dispatch_after](#dispatch-after)
  * [dispatch_once](#dispatch-once)
  * [dispatch_apply](#dispatch-apply)
  * [dispatch_group](#dispatch-group)
    + [dispatch_group_notify](#dispatch-group-notify)
    + [dispatch_group_wait](#dispatch-group-wait)
    + [dispatch_group_enter、dispatch_group_leave](#dispatch-group-enter-dispatch-group-leave)
  * [dispatch_semaphore](#dispatch-semaphore)

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
    - >Returns a system-defined global concurrent queue with the specified quality-of-service class.
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

## Communicate between Queues inside GCD
For example in iOS development, we will have UI refreshing in main queue. While performing some time consuming tasks, we will put those tasks in other queue, and while those task finished, we could create new task back to main queue. This is how we communicate between queues.
```objectivc-c/**
- (void)communication {
    // Get Global Dispatch Queue
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // Get Main Dispatch Queue
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    dispatch_async(queue, ^{
        // Async task
        // Time consuming tasks in here.
        
        // Back to Main Dispatch Queue
        dispatch_async(mainQueue, ^{
            // Continue to execute in Main Dispatch Queue.
        });
    });
}
```

## GCD Other Functions
### dispatch_barrier_async
- First of all, this function will only make sense to Concurrency Queue.
- If we are inserting a lot of **async tasks** into a **Concurrency Queue**, and we could divide those async tasks into two groups (for simplify). If Group B should execute only if all async tasks inside Group A finished. Then we could add a **dispatch_barrier_async** to create a barrier between those two sets of tasks.
```objective-c
dispatch_async(concurrencyQueueA, ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"A-1 ---%@",[NSThread currentThread]); // Thread number = 3,
});
dispatch_async(concurrencyQueueA, ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"A-2 ---%@",[NSThread currentThread]); // Thread number = 4,
});
dispatch_barrier_async(concurrencyQueueA, ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"barrier ---%@",[NSThread currentThread]); // Thread number = 3,
});
dispatch_async(concurrencyQueueA, ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"B-1 ---%@",[NSThread currentThread]); // Thread number = 3,
});
dispatch_async(concurrencyQueueA, ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"B-2 ---%@",[NSThread currentThread]); // Thread number = 6,
});

/// Print out logs:
// 2020-09-26 21:39:14 A-2 ---<NSThread: 0x6000030b8200>{number = 4, name = (null)}
// 2020-09-26 21:39:14 A-1 ---<NSThread: 0x6000030d5900>{number = 3, name = (null)}
// 2020-09-26 21:39:16 barrier ---<NSThread: 0x6000030d5900>{number = 3, name = (null)}
// 2020-09-26 21:39:18 B-1 ---<NSThread: 0x6000030d5900>{number = 3, name = (null)}
// 2020-09-26 21:39:18 B-2 ---<NSThread: 0x6000030bcec0>{number = 6, name = (null)}
```

### dispatch_after
- This functions is how we could achieve delay in GCD
- Please be aware of that the time is when the task be added into the target queue, not the time when the task be executed. Strictly speaking, the time is not very accurate.
```objective-c
NSLog(@"currentThread---%@",[NSThread currentThread]);
dispatch_time_t delayedTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC));
dispatch_after(delayedTime, dispatch_get_main_queue(), ^{
    NSLog(@"currentThread---%@",[NSThread currentThread]);
});

/// Print out logs:
// 2020-09-26 21:47:46 currentThread---<NSThread: 0x600003ffc040>{number = 1, name = main}
// 2020-09-26 21:47:48 currentThread---<NSThread: 0x600003ffc040>{number = 1, name = main}
```

### dispatch_once
- this task will only be excute once.
- this task is thread-safe under multiple threads.
```objective-c
- (void)once
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"execute once---%@",[NSThread currentThread]);
    });
}

dispatch_queue_t serialQueueB = dispatch_queue_create("serialQueueB", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t concurrencyQueueA = dispatch_queue_create("concurrencyQueueA", DISPATCH_QUEUE_CONCURRENT);
dispatch_queue_t concurrencyQueueB = dispatch_queue_create("concurrencyQueueB", DISPATCH_QUEUE_CONCURRENT);
NSLog(@"1 - %@", [NSThread currentThread]);
dispatch_async(concurrencyQueueA, ^{
    NSLog(@"2 - %@", [NSThread currentThread]);
    dispatch_async(serialQueueB, ^{
        NSLog(@"3 - %@", [NSThread currentThread]);
        [self once];
    });
    NSLog(@"4 - %@", [NSThread currentThread]);
    [self once];
    dispatch_async(concurrencyQueueB, ^{
        NSLog(@"5 - %@", [NSThread currentThread]);
        [self once];
    });
    NSLog(@"6 - %@", [NSThread currentThread]);
    [self once];
    dispatch_async(concurrencyQueueA, ^{
        NSLog(@"7 - %@", [NSThread currentThread]);
        [self once];
    });
    NSLog(@"8 - %@", [NSThread currentThread]);
    [self once];
});
[self once];


/// Print out logs:
// 1 - <NSThread: 0x600001714980>{number = 1, name = main}
// execute once---<NSThread: 0x600001714980>{number = 1, name = main}
// 2 - <NSThread: 0x600001759440>{number = 7, name = (null)}
// 4 - <NSThread: 0x600001759440>{number = 7, name = (null)}
// 3 - <NSThread: 0x60000172ac00>{number = 6, name = (null)}
// 6 - <NSThread: 0x600001759440>{number = 7, name = (null)}
// 5 - <NSThread: 0x600001759380>{number = 4, name = (null)}
// 8 - <NSThread: 0x600001759440>{number = 7, name = (null)}
// 7 - <NSThread: 0x60000172ac00>{number = 6, name = (null)}
```

### dispatch_apply
- You could treat **dispatch_apply** very similar to for-loop.
- If it's to a serial queue, this will be exactly like a for-loop.
- If it's to a concurrency queue, you could think that we added similar tasks into the same queue simutaneously.
- dispatch_apply will wait all tasks finished, and then will continue. similar to **dispatch_group_wait**
```objective-c
dispatch_queue_t serialQueueA = dispatch_queue_create("serialQueueA", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t concurrencyQueueA = dispatch_queue_create("concurrencyQueueA", DISPATCH_QUEUE_CONCURRENT);

NSLog(@"Start - %@", [NSThread currentThread]);
dispatch_apply(5, serialQueueA, ^(size_t index) {
    [NSThread sleepForTimeInterval:1];
    NSLog(@"%zd - %@", index, [NSThread currentThread]);
});

NSLog(@"Middle - %@", [NSThread currentThread]);
dispatch_apply(5, concurrencyQueueA, ^(size_t index) {
    [NSThread sleepForTimeInterval:1];
    NSLog(@"%zd - %@", index, [NSThread currentThread]);
});
NSLog(@"End - %@", [NSThread currentThread]);

/// Print out logs:
// 2020-09-26 22:02:45 Start - <NSThread: 0x600001698240>{number = 1, name = main}
// 2020-09-26 22:02:46 0 - <NSThread: 0x600001698240>{number = 1, name = main}
// 2020-09-26 22:02:47 1 - <NSThread: 0x600001698240>{number = 1, name = main}
// 2020-09-26 22:02:48 2 - <NSThread: 0x600001698240>{number = 1, name = main}
// 2020-09-26 22:02:49 3 - <NSThread: 0x600001698240>{number = 1, name = main}
// 2020-09-26 22:02:50 4 - <NSThread: 0x600001698240>{number = 1, name = main}
// 2020-09-26 22:02:50 Middle - <NSThread: 0x600001698240>{number = 1, name = main}
// 2020-09-26 22:02:51 0 - <NSThread: 0x6000016dcec0>{number = 6, name = (null)}
// 2020-09-26 22:02:51 1 - <NSThread: 0x600001698240>{number = 1, name = main}
// 2020-09-26 22:02:51 3 - <NSThread: 0x6000016d9f40>{number = 4, name = (null)}
// 2020-09-26 22:02:51 4 - <NSThread: 0x6000016d4dc0>{number = 7, name = (null)}
// 2020-09-26 22:02:51 2 - <NSThread: 0x6000016c09c0>{number = 3, name = (null)}
// 2020-09-26 22:02:51 End - <NSThread: 0x600001698240>{number = 1, name = main}
```

### dispatch_group
- This function is for scenarios that we need wait two time costly task finished first and then continue to execute other tasks.
- To achieve it, we have two steps
    - add tasks into dispatch_group
        - we could use **dispatch_group_async** to directly add a certain task into a dispatch_group
        - Or, we could use **dispatch_async, dispatch_group_enter and dispatch_group_leave** to achieve the same thing.
    - while all finished, we will continue.
        - we could use **dispatch_group_notify** callback to a particular queue
        - or we could **dispatch_group_wait** to block current queue until all dispatch_group_async tasks finished.

#### dispatch_group_notify
```objective-c
NSLog(@"currentThread---%@",[NSThread currentThread]);
NSLog(@"group---begin");
dispatch_group_t group =  dispatch_group_create();
dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"1---%@",[NSThread currentThread]);
});
dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"2---%@",[NSThread currentThread]);
});
dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    NSLog(@"3---%@",[NSThread currentThread]);
    NSLog(@"group---end");
});
NSLog(@"group---all code executed");

/// Print out logs:
// 2020-09-26 22:13:03 currentThread---<NSThread: 0x600002c60900>{number = 1, name = main}
// 2020-09-26 22:13:03 group---begin
// 2020-09-26 22:13:03 group---all code executed
// 2020-09-26 22:13:05 2---<NSThread: 0x600002c04b40>{number = 6, name = (null)}
// 2020-09-26 22:13:05 1---<NSThread: 0x600002c2e200>{number = 5, name = (null)}
// 2020-09-26 22:13:05 3---<NSThread: 0x600002c60900>{number = 1, name = main}
// 2020-09-26 22:13:05 group---end
```

#### dispatch_group_wait
```objective-c
NSLog(@"currentThread---%@",[NSThread currentThread]);
NSLog(@"group---begin");
dispatch_group_t group =  dispatch_group_create();
dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"1---%@",[NSThread currentThread]);
});
dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"2---%@",[NSThread currentThread]);
});
dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
NSLog(@"group---end");
NSLog(@"group---all code executed");

/// Print out logs:
// 2020-09-26 22:16:42 currentThread---<NSThread: 0x600003064b40>{number = 1, name = main}
// 2020-09-26 22:16:42 group---begin
// 2020-09-26 22:16:44 2---<NSThread: 0x60000306aac0>{number = 4, name = (null)}
// 2020-09-26 22:16:44 1---<NSThread: 0x6000030045c0>{number = 3, name = (null)}
// 2020-09-26 22:16:44 group---end
// 2020-09-26 22:16:44 group---all code executed
```

#### dispatch_group_enter、dispatch_group_leave
- dispatch_group_enter means we added one task into a group, the unfinished tasks count inside the group +1
- dispatch_group_leave means we removed one task from a group, the unfinished tasks count inside the group -1
- while the unfinished tasks count become 0, then we will continue
```objective-c
NSLog(@"currentThread---%@",[NSThread currentThread]);
NSLog(@"group---begin");
dispatch_group_t group =  dispatch_group_create();
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
dispatch_group_enter(group);
dispatch_async(queue, ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"1---%@",[NSThread currentThread]);
    
    dispatch_group_leave(group);
});
dispatch_group_enter(group);
dispatch_async(queue, ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"2---%@",[NSThread currentThread]);
    
    dispatch_group_leave(group);
});
dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    NSLog(@"3---%@",[NSThread currentThread]);
    NSLog(@"group---end");
});

/// Print out logs:
// 2020-09-26 22:21:25 currentThread---<NSThread: 0x600001974a40>{number = 1, name = main}
// 2020-09-26 22:21:25 group---begin
// 2020-09-26 22:21:27 1---<NSThread: 0x600001934cc0>{number = 6, name = (null)}
// 2020-09-26 22:21:27 2---<NSThread: 0x60000192a340>{number = 4, name = (null)}
// 2020-09-26 22:21:27 3---<NSThread: 0x600001974a40>{number = 1, name = main}
// 2020-09-26 22:21:27 group---end
```

### dispatch_semaphore
- We could treat Dispatch Semaphore as a counting signal.
    - while Dispatch Semaphore is less than 0, currenty task will be blocked
    - while Dispatch Semaphore is no less than 0, current task will continue, but Dispatch Semaphore will deduct 1.
- **dispatch_semaphore_create** : create a Semaphore and initial with a number.
- **dispatch_semaphore_signal** : increase the Semaphore by 1.
- **dispatch_semaphore_wait** : decrease the Semaphore by 1, if total Semaphore become less than 0, it will wait.

There are two main application for Dispatch Semaphore
1. Synchronise Threads
```objective-c
NSLog(@"currentThread---%@",[NSThread currentThread]);
NSLog(@"semaphore---begin");
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
__block int number = 0;
dispatch_async(queue, ^{
    [NSThread sleepForTimeInterval:2];
    NSLog(@"1---%@",[NSThread currentThread]);
    
    number = 100;
    
    dispatch_semaphore_signal(semaphore);
});

dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
NSLog(@"semaphore---end,number = %d",number);

/// Print out logs:
// 2020-09-26 22:31:56 currentThread---<NSThread: 0x600003154900>{number = 1, name = main}
// 2020-09-26 22:31:56 semaphore---begin
// 2020-09-26 22:31:58 1---<NSThread: 0x600003114e80>{number = 4, name = (null)}
// 2020-09-26 22:31:58 semaphore---end,number = 100
```

2. To keep thread-safe
```objective-c
- (void)initTicketStatusSave {
    NSLog(@"currentThread---%@",[NSThread currentThread]); 
    NSLog(@"semaphore---begin");
    
    semaphoreLock = dispatch_semaphore_create(1); // Will only have one action performed each time
    
    self.ticketSurplusCount = 50;
    
    // queue1 
    dispatch_queue_t queue1 = dispatch_queue_create("net.bujige.testQueue1", DISPATCH_QUEUE_SERIAL);
    // queue2 
    dispatch_queue_t queue2 = dispatch_queue_create("net.bujige.testQueue2", DISPATCH_QUEUE_SERIAL);
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue1, ^{
        // [weakSelf saleTicketNotSafe];
        [weakSelf saleTicketSafe];
    });
    
    dispatch_async(queue2, ^{
        // [weakSelf saleTicketNotSafe];
        [weakSelf saleTicketSafe];
    });
}

- (void)saleTicketNotSafe {
    while (1) {
        if (self.ticketSurplusCount > 0) { 
            self.ticketSurplusCount--;
            NSLog(@"%@", [NSString stringWithFormat:@"remaining ticket: %d Thread: %@", self.ticketSurplusCount, [NSThread currentThread]]);
            [NSThread sleepForTimeInterval:0.2];
        } else { 
            NSLog(@"All ticket has been sold out");
            break;
        }
    }
}

- (void)saleTicketSafe {
    while (1) {
        dispatch_semaphore_wait(semaphoreLock, DISPATCH_TIME_FOREVER);
        if (self.ticketSurplusCount > 0) { 
            self.ticketSurplusCount--;
            NSLog(@"%@", [NSString stringWithFormat:@"remaining ticket: %d Thread: %@", self.ticketSurplusCount, [NSThread currentThread]]);
            [NSThread sleepForTimeInterval:0.2];
        } else { 
            NSLog(@"All ticket has been sold out");
            dispatch_semaphore_signal(semaphoreLock);
            break;
        }
        dispatch_semaphore_signal(semaphoreLock);
    }
}
```