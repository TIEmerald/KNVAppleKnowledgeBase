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
    int *param = (int *)data;
    int first_val = param[0];
    ....

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

    int *param = (int *)malloc(2 * sizeof(int));
    param[0] = 123;
    param[1] = 456;
 
    int     threadError = pthread_create(&posixThreadID, &attr, &PosixThreadMainRoutine, param);
 
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

2. **Mixing POSIX and Cocoa Locks** - Using a mixture of POSIX and Cocoa locks inside the same application is safe. But need to ensure you use the correct interface to create and manipulate that lock.

## Configuring Thread Attributes
### Configure the stack size of a Thread
### Configure THread-Local Storage
> Each thread maintains a dictionary of key-value pairs that can be accessed from anywhere in the thread. You can use this dictionary to storeinformation that you want to persist throughout the execution of your thread.
> **Note:** Cocoa and POSIX store the thread dictionary in different ways, so you cannot mix and match calls to the two technologies. in NSThread it's threadDictionary. in POSIX it's pthread_setspecific and pthread_getspecific
### Setting the Detached State of a Thread
Most high-level thread technologies create detached threads by default.

**TODO:** Join? feeling Joinable threads are opposite to detached threads 
> You can think of joinable threads as akin to child threads. Although they still run as independent threads, a joinable thread must be joined by another thread before its resources can be reclaimed by the system. Joinable threads also provide an explicit way to pass data from an exiting thread to another thread. Just before it exits, a joinable thread can pass a data pointer or other return value to the pthread_exit function. Another thread can then claim this data by calling the pthread_join function.

> **Important** At application exit time, detached threads can be terminated immediately but joinable threads cannot. Each joinable thread must be joined before the process is allowed to exit. Joinable threads may therefore be preferable in cases where the thread is doing critical work that should not be interrupted, such as saving data to disk.

>If you do want to create joinable threads, the only way to do so is using POSIX threads. POSIX creates threads as joinable by default. To mark a thread as detached or joinable, modify the thread attributes using the pthread_attr_setdetachstate function prior to creating the thread. After the thread begins, you can change a joinable thread to a detached thread by calling the pthread_detach function. For more information about these POSIX thread functions, see the pthread man page. For information on how to join with a thread, see the pthread_join man page

```objective-c
#include <assert.h>
#include <pthread.h>

void* PosixThreadMainRoutine(void* data)
{
    int *param = (int *)data;
    NSString *threadMode = param[0] == PTHREAD_CREATE_JOINABLE ? @"Posix Joinable Thread" : @"Posix Detached Thread";
    // Do some work here.
    for (int index = 1; index < 10; index += 1) {
        sleep(1);
        NSLog(@"I am sleeping in %@", threadMode);
    }
    return NULL;
}

void LaunchMainThread()
{
    // Create the thread using POSIX routines.
    pthread_attr_t  attr;
    pthread_t       posixThreadID;
    int             returnVal;
    int             createMode = PTHREAD_CREATE_JOINABLE;
    
    returnVal = pthread_attr_init(&attr);
    assert(!returnVal);
    returnVal = pthread_attr_setdetachstate(&attr, createMode);
    assert(!returnVal);
    int *param = (int *)malloc(1 * sizeof(int));
    param[0] = createMode;
    int     threadError = pthread_create(&posixThreadID, &attr, &PosixThreadMainRoutine, param);
    
    returnVal = pthread_attr_destroy(&attr);
    assert(!returnVal);
    if (threadError != 0)
    {
        // Report an error.
    }
    NSLog(@"Set up new POSIX Thread Successfully.");
    returnVal = pthread_join(posixThreadID, NULL);
    assert(!returnVal);
    NSLog(@"Joined Thread Finished Finished.");
}

```

The log outcome of the codes above will be:
```
2020-09-02 16:49:10.902885+0800 Temp Objective C Playground Project[35169:526667] Set up new POSIX Thread Successfully.
2020-09-02 16:49:11.906845+0800 Temp Objective C Playground Project[35169:527194] I am sleeping in Posix Joinable Thread
2020-09-02 16:49:12.907077+0800 Temp Objective C Playground Project[35169:527194] I am sleeping in Posix Joinable Thread
2020-09-02 16:49:13.907435+0800 Temp Objective C Playground Project[35169:527194] I am sleeping in Posix Joinable Thread
2020-09-02 16:49:14.908512+0800 Temp Objective C Playground Project[35169:527194] I am sleeping in Posix Joinable Thread
2020-09-02 16:49:15.908720+0800 Temp Objective C Playground Project[35169:527194] I am sleeping in Posix Joinable Thread
2020-09-02 16:49:16.908970+0800 Temp Objective C Playground Project[35169:527194] I am sleeping in Posix Joinable Thread
2020-09-02 16:49:17.909344+0800 Temp Objective C Playground Project[35169:527194] I am sleeping in Posix Joinable Thread
2020-09-02 16:49:18.909591+0800 Temp Objective C Playground Project[35169:527194] I am sleeping in Posix Joinable Thread
2020-09-02 16:49:19.909810+0800 Temp Objective C Playground Project[35169:527194] I am sleeping in Posix Joinable Thread
2020-09-02 16:49:19.909939+0800 Temp Objective C Playground Project[35169:526667] Joined Thread Finished Finished.
2020-09-02 16:49:19.947701+0800 Temp Objective C Playground Project[35169:526667] Metal API Validation Enabled
```

But if we set createMode to PTHREAD_CREATE_DETACHED, the method above will failed at returnVal = pthread_join(posixThreadID, NULL);

Actually, if we don't have assert value below, the method will execute as there is not such a line to perfomr join.

Thus, the biggest different between detached threads and joinable threads is only joinable threads could be passed into pthread_join.

**pthread_join:** like a method to block current thread and wait until the target thread finish before continue.

### Setting the Thread Priority
> Any new thread you create has a default priority associated with it. The kernel’s scheduling algorithm takes thread priorities into account when determining which threads to run, with higher priority threads being more likely to run than threads with lower priorities. Higher priorities do not guarantee a specific amount of execution time for your thread, just that it is more likely to be chosen by the scheduler when compared to lower-priority threads.

> **Important:** It is generally a good idea to leave the priorities of your threads at their default values. Increasing the priorities of some threads also increases the likelihood of starvation among lower-priority threads. If your application contains high-priority and low-priority threads that must interact with each other, the starvation of lower-priority threads may block other threads and create performance bottlenecks.