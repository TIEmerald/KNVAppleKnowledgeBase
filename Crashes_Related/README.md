# Crashes Related
## References
[(Apple Doc.) Understanding the Exception Types in a Crash Report](https://developer.apple.com/documentation/xcode/diagnosing_issues_using_crash_reports_and_device_logs/understanding_the_exception_types_in_a_crash_report#3582420)

----
## Crash Reports
### SIGABRT
#### Definition
```c
#define SIGABRT 6 /* abort() */
``` 

#### The Reason Cuased the SIGABRT
1. **Free pointer which is not alloc, yet**
```c
plain void *ptr = (void*)0x00000100; free(ptr); // SIGABRT() 
```
2. **Free same pointer twice**
```c
plain void *ptr =malloc(256); free(ptr); free(ptr); // SIGABRT() 
```
3. **Over Boundary**
```c
plain char str2[10]; char *str1 = "dasfadvzxfwersdfasf"; strcpy(str2, str1); // SIGABRT() 
```
4. **Called abort()**
5. **Called assert()**

### SIGSEGV
#### Definition
```c
#define SIGSEGV 11 /* segmentation violation */
``` 
From [Wiki](https://en.wikipedia.org/wiki/Segmentation_fault)
> A segmentation fault occurs when a program attempts to access a memory location that it is not allowed to access, or attempts to access a memory location in a way that is not allowed (for example, attempting to write to a read-only location, or to overwrite part of the operating system).

#### The Reason Cuased the SIGSEGV
1. **Trying to access the memory address which is not exist (NULL)**
```c
plain int *ptr = NULL; *ptr = 1; // SIGSEGV() 
```
2. **Trying to access the memory address which is not allowed to (the address is not inited, yet.)**
```c
plain int *ptr; *ptr = 1; // SIGSEGV() 
```
3. **Trying to write into read only memory address**
```c
plain int *s = "hello world"; *s = "new hellow world"; // SIGSEGV() 
```
4. **Trying to access memory address which has already been released**
```c
plain char *ptr = malloc(10); free(ptr); strcpy(ptr, "new"); -- SIGSEGV() 
```
5. **Stack Overflow**
```c
plain int main(void) { main(); return 0; }; // SIGSEGV() 
```

### EXC_BREAKPOINT (SIGTRAP) and EXC_BAD_INSTRUCTION (SIGILL)
#### Definition
In apple document, it said:
> The breakpoint exception type indicates a trace trap interrupted the process. On ARM processors, this appears as EXC_BREAKPOINT (SIGTRAP). On x86_64 processors, this appears as EXC_BAD_INSTRUCTION (SIGILL).

But in [GNU C Library - 24.2.1 Program Error Signals](http://www.gnu.org/software/libc/manual/html_node/Program-Error-Signals.html?spm=ata.13261165.0.0.6eb73b1985ysXa), it has further explanation about **SIGILL**.

```c
#define SIGTRAP 5 /* trace trap (not reset when caught) */
#define SIGILL 4 /* illegal instruction (not reset when caught) */
``` 

#### The Reason Cuased the SIGTRAP
- Swift runtime uses trace traps for specific types of unrecoverable errors - [Addressing Crashes from Swift Runtime Errors](https://developer.apple.com/documentation/xcode/diagnosing_issues_using_crash_reports_and_device_logs/identifying_the_cause_of_common_crashes/addressing_crashes_from_swift_runtime_errors)
- Some lower-level libraries, such as [Dispatch](https://developer.apple.com/documentation/dispatch), trap the process with this exception upon encountering an unrecoverable error and log additional information about the error in the Additional Diagnostic Information section of the crash report. ([Diagnostic Messages](https://developer.apple.com/documentation/xcode/diagnosing_issues_using_crash_reports_and_device_logs/examining_the_fields_in_a_crash_report#3582416)) 
- Cause by __builtin_trap(). In DEBUG mode, it will trigger break point, otherwise it will crash and cause SIGTRAP()

### SIGBUS
#### Definition
```c
#define SIGBUS 10 /* bus error */
``` 
From The [GNU C Library - 24.2.1 Program Error Signals](http://www.gnu.org/software/libc/manual/html_node/Program-Error-Signals.html?spm=ata.13261165.0.0.6eb73b1985ysXa), it said:
> This signal is generated when an invalid pointer is dereferenced. Like SIGSEGV, this signal is typically the result of dereferencing an uninitialized pointer. The difference between the two is that SIGSEGV indicates an invalid access to valid memory, while SIGBUS indicates an access to an invalid address. In particular, SIGBUS signals often result from dereferencing a misaligned pointer, such as referring to a four-word integer at an address not divisible by four. (Each kind of computer has its own requirements for address alignment.)

Which means this similar to **SIGSEGV**, instead of be "an invalid access to valid memory", it is accessing an invalid address.

#### The Reason Cuased the SIGBUS
- Like assign a value over the allocated size? 
```c
plain int *pi = (int*)(0x00001111); *pi = 17; 
```

### SIGKILL (UnCatched)
#### The Reason Cuased the SIGKILL
1. **If the App take Main Thread too Long, the App will be Killed by watch dog**
```c
Exception Type: 00000020 Exception Codes: 0x8badf00d // Code 0x8badf00d (also called "ate bad food") means due to watchdoy notice the application take MainThread too long (over 5~6 seconds). Watchdoy killed this app.
```
```c
Exception Type:  EXC_CRASH (SIGKILL)
Exception Codes: 0x0000000000000000, 0x0000000000000000
Exception Note:  EXC_CORPSE_NOTIFY
Termination Reason: Namespace SPRINGBOARD, Code 0x8badf00d
Termination Description: SPRINGBOARD, process-exit watchdog transgression: ********* exhausted real (wall clock) time allowance of 5.00 seconds |  | Elapsed total CPU time (seconds): 10.010 (user 10.010, system 0.000), 100% CPU | Elapsed application CPU time (seconds): 8.442, 84% CPU | 
Triggered by Thread:  0
```

2. **The app take too much system resources**
```c
Event:           cpu usage
CPU:             144s cpu time over 173 seconds (83% cpu average), exceeding limit of 80% cpu over 180 seconds
Action taken:    none
Duration:        173.11s
Steps:           60
Hardware model:  iPhone9,1
Active cpus:     2
Powerstats for:  ******** [7007]
UUID:            20EE63F8-EBBE-38C6-8B2E-56218AFF9371
Start time:      2017-12-08 14:02:49 +0800
End time:        2017-12-08 14:04:48 +0800
Microstackshots: 60 samples (100%)
Primary state:   46 samples Frontmost App, Kernel mode, Effective Thread QoS Background, Requested Thread QoS Default, Override Thread QoS Unspecified
User Activity:   60 samples Idle, 0 samples Active
Power Source:    60 samples on Battery, 0 samples on AC
```
```c
Event:           cpu usage
CPU:             48s cpu time over 48 seconds (99% cpu average), exceeding limit of 80% cpu over 60 seconds
Action taken:    Process killed
Duration:        48.36s
Steps:           14
```

3. **The app switch threds too frequently**
```c
Event:           wakeups
Wakeups:         45014 wakeups over the last 79 seconds (573 wakeups per second average), exceeding limit of 150 wakeups per second over 300 seconds
Action taken:    none
Duration:        78.57s
Steps:           7
```
```c
Exception Type: EXC_RESOURCE
Exception Subtype: WAKEUPS
Exception Message: (Limit 150/sec) Observed 206/sec over 300 secs
Triggered by Thread: 14
```

4. **The app take too much memory, and will killed by jetsam**

Apple Doc: [Identifying High-Memory Use with Jetsame Event Reports](https://developer.apple.com/documentation/xcode/diagnosing_issues_using_crash_reports_and_device_logs/identifying_high-memory_use_with_jetsam_event_reports)
> Under memory pressure, apps free memory after receiving a low-memory notification. If all running apps release enough total memory to alleviate memory pressure, your app will continue to run. But, if memory pressure continues because apps haven’t relinquished enough memory, the system frees memory by terminating applications to reclaim their memory.
- System creates a jetsam event report with information about why it choose to jettison an app.
- If the app is killed by Jetsam it will record Log "Process ********* [6603] killed by jetsam reason per-process-limit"
