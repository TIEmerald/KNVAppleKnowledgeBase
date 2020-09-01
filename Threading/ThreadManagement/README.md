# Thread Management
## References
[Apple Threading Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/CreatingThreads/CreatingThreads.html#//apple_ref/doc/uid/10000057i-CH15-SW2)

----

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

----
## Thread Costs
The cost of maintaining a thread contains threa main parts:
1. **Kernel data structure** - (Aproximately 1 KB) - This memory is used to store the thread data structures and attributes, much of which is allocated as wired memory and therefore cannot be paged to disk.
2. **Stack space** - (512KB - secondary thread, 8MB - OS X main thread, 1MB - iOS main thread) - The minimum allowed stack size for secondary threads is 16 KB and the stack size must be a multiple of 4 KB (**configurable**). The space for this memory is set aside in your process spece at thread creation time.
3. **Creation time** - (Approximately 90 microseconds) - the time might very greatly depneding on processor load, the speed of the computer and the amount of available system and program memory.

## Creating a Thread
### Using NSThread
```objective-c
// Both techniques create a detached thread in your application
[NSThread detachNewThreadSelector:@selector(myThreadMainMethod:) toTarget:self withObject:nil];

// Both techniques create a detached thread in your application
// But this (Supported only in iOS and OS X v10.5 and later.)
NSThread* myThread = [[NSThread alloc] initWithTarget:self
                                    selector:@selector(myThreadMainMethod:)
                                    object:nil];
[myThread start];  // Actually create the thread
```
> **Note:** An alternative to using the initWithTarget:selector:object: method is to subclass NSThread and override its main method. You would use the overridden version of this method to implement your thread's main entry point.

### Using POSIX Threads
```objective-c
#include <assert.h>
#include <pthread.h>
 
void* PosixThreadMainRoutine(void* data)
{
    // Do some work here.
 
    return NULL;
}
 
void LaunchThread()
{
    // Create the thread using POSIX routines.
    pthread_attr_t  attr;
    pthread_t       posixThreadID;
    int             returnVal;
 
    returnVal = pthread_attr_init(&attr);
    assert(!returnVal);
    returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    assert(!returnVal);
 
    int     threadError = pthread_create(&posixThreadID, &attr, &PosixThreadMainRoutine, NULL);
 
    returnVal = pthread_attr_destroy(&attr);
    assert(!returnVal);
    if (threadError != 0)
    {
         // Report an error.
    }
}
```
> If you add the code from the preceding listing to one of your source files and call the LaunchThread function, it would create a new detached thread in your application. Of course, new threads created using this code would not do anything useful. The threads would launch and almost immediately exit. To make things more interesting, you would need to add code to the PosixThreadMainRoutine function to do some actual work. To ensure that a thread knows what work to do, you can pass it a pointer to some data at creation time. You pass this pointer as the last parameter of the pthread_create function.

### Using NSObject to Spawn a Thread
> In iOS and OS X v10.5 and later, all objects have the ability to spawn a new thread and use it to execute one of their methods. The performSelectorInBackground:withObject: method creates a new detached thread and uses the specified method as the entry point for the new thread.

### Using POSIX Threads in a Cocoa Application
1. **Protecting the Cocoa Frameworks** - Locks and other internal synchronization inside Cocoa frameworks might failed to be notified, if you create multithread with POSIX Threads.
> To let Cocoa know that you intend to use multiple threads, all you have to do is spawn a single thread using the NSThread class and let that thread immediately exit. Your thread entry point need not do anything. Just the act of spawning a thread using NSThread is enough to ensure that the locks needed by the Cocoa frameworks are put in place.

> If you are not sure if Cocoa thinks your application is multithreaded or not, you can use the isMultiThreaded method of NSThread to check.