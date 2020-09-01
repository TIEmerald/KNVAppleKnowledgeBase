# Run Loops
## References
[Apple Threading Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/AboutThreads/AboutThreads.html#//apple_ref/doc/uid/10000057i-CH6-SW2)

----

----
## What Are Threads 
>Threads are a relatively lightweight way to implement multiple paths of execution inside of an application.

## Threading Terminology
>This document adopts the following terminology:
>- The term thread is used to refer to a separate path of execution for code.
>- The term process is used to refer to a running executable, which can encompass multiple threads.
>- The term task is used to refer to the abstract concept of work that needs to be performed.

## Somethings about Threads
>At the application level, all threads behave in essentially the same way as on other platforms. After starting a thread, the thread runs in one of three main states: running, ready, or blocked. If a thread is not currently running, it is either blocked and waiting for input or it is ready to run but not scheduled to do so yet. The thread continues moving back and forth among these states until it finally exits and moves to the terminated state.

>When you create a new thread, you must specify an entry-point function (or an entry-point method in the case of Cocoa threads) for that thread. This entry-point function constitutes the code you want to run on the thread. When the function returns, or when you terminate the thread explicitly, the thread stops permanently and is reclaimed by the system. Because threads are relatively expensive to create in terms of memory and time, it is therefore recommended that your entry point function do a significant amount of work or set up a run loop to allow for recurring work to be performed.

## Run Loops
>A run loop is a piece of infrastructure used to manage events arriving asynchronously on a thread. A run loop works by monitoring one or more event sources for the thread. As events arrive, the system wakes up the thread and dispatches the events to the run loop, which then dispatches them to the handlers you specify. If no events are present and ready to be handled, the run loop puts the thread to sleep.

> You are not required to use a run loop with any threads you create but doing so can provide a better experience for the user. Run loops make it possible to create long-lived threads that use a minimal amount of resources. Because a run loop puts its thread to sleep when there is nothing to do, it eliminates the need for polling, which wastes CPU cycles and prevents the processor itself from sleeping and saving power.

> To configure a run loop, all you have to do is launch your thread, get a reference to the run loop object, install your event handlers, and tell the run loop to run. The infrastructure provided by OS X handles the configuration of the main thread’s run loop for you automatically. If you plan to create long-lived secondary threads, however, you must configure the run loop for those threads yourself.

## Design Tips
1. **Avoid Creating Threads Explicitly** - Try to use GCD and Operation objects APIs to manage threads instead of manually manage it.
2. **Keep Your Threads Reasonably Busy** - If you decide to create and manage threads manually, remember that threads consume precious system resources. You should not afraid to terminate threads that are spending most of their time idle.
> **Important:** Before you start terminating idle threads, you should always record a set of baseline measurements of your applications current performance. After trying your changes, take additional measurements to verify that the changes are actually improving performance, rather than hurting it.
3. **Avoid Shared Data Structures** - Need try our best to minimize the communication and resources contention among your threads.
4. **Threads and Your User Interface** - Always handle UI-related events in your application's main thread.
5. **Be Aware of Thread Behaviours at Quick Time** - Normally, while an user quits an application, all detached threads (by default all threads which are not main thread) will be terminated immediately. If you want those works done by detached threads to be finished, you need configure those threads to be non-detached.
6. **Handle Exceptions** - All un-catched exception in any thread will cause the application be terminated.
> **Note:** In Cocoa, an NSException object is a self-contained object that can be passed from thread to thread once it has been caught.
7. **Terminal Your Threads Cleanly** - The best way for a thread to exit is naturally, by letting it reach the end of its main entry point routine.
8. **Thread Safety in Libraries** - When developing libraries, you must assume that the calling application is multithreaded or could switch to being multithreaded at any time.