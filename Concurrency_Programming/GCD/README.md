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