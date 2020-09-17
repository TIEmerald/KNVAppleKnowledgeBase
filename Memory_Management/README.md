# Memory Management
## References
[Objective-C中的内存管理](https://www.jianshu.com/p/6c400d2c3a88)

[Advanced Memory Management Programming Guides](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/MemoryMgmt.html#//apple_ref/doc/uid/10000011-SW1)

[Swift - Automatic Reference Counting](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html)

[Transitioning to ARC Release Notes](https://developer.apple.com/library/archive/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html)

----
- [What Are Threads](#what-are-threads)
- [Threading Terminology](#threading-terminology)
- [Somethings about Threads](#somethings-about-threads)
- [Run Loops](#run-loops)
- [Design Tips](#design-tips)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

----
## General Information
- Objective C provides two ways for memory management - MRR (Manual Retain-Release) and ARC (Automatic Reference Counting). Both of them are using "Reference Count" model to achieve memory management. (??? via NSObject-Class inside Foundation framwork, and Runtime Environment ???)
- Swift uses Automatic Reference Counting (ARC) to track and manage your app's memory usage.
    - Please be aware of that Reference counting applies only to instances of classes. Structures and enumerations are value types, not reference types, and are not stored and passed by reference.

## Reference Count
Reference Count is a simple and efficient way to manage object's lifecycle.
- While a new Object is created (**alloc/init**), Reference Count of that object will be inited to 1,
- While create a reference to an existed object (**retain**), the Reference Count of that object will be increased by 1.
- While we don't need the object anymore  (**release**), the Reference Count of that object will be decreased by 1.
- While one object's Reference Count deducted to 0, System will be aware of that this object is not needed anymore, System will distory the object and recollect the momory resource (**dealloc**).

![Object's LifeCycle](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MemoryMgmt/Art/memory_management_2x.png "Object's LifeCycle")

----
## MRR (Manual Retain-Release)
Inside MRR, user have to retain and release objects manually.

### Basic Memory Management Rules
- **You own any object you create** - You create an object using a method whose name begins with "alloc", "new", "copy" or "mutableCopy" (for example, alloc, newObject, or mutableCopy). These method will increase Reference Count by 1, but won't handle the release.
    - methods not start with these keywords, normally handled the ownership by themselves, you shouldn't relinquish their ownership unless you take the ownership (For example, the return value of [NSString stringWithFormat:] has already be assigned to auto release pool)
- **You can take ownership of an object using retain** -  A recieved object is normally guaranteed to remain valid within the method it was received in, and that method may also safely return the object to its invoker. You use retain in two situation:
    - In the implementaiont of an accessor method or an init method, to take ownership of an object you want to store as a property value;
    - To prevent an object from being invalidated as a side-effect of some other opertion.
- **When you no longer need it, you must relinquish ownership of an object you own** - You relinquish ownership of an object by sending it a release message or an autorelease message. In Cocoa terminology, relinquish ownership of an object is therefore typically referred to as "releasing" an object.
    - If you already took ownership of your properties, you need also update your -(void)dealloc method to relinquish the ownership.
- **You must not relinquish ownership of an object you do not own** 
- **If the process of the application terminates, all objects inside the memory will be released**

### Autorelease Pool
- AutoreleasePool is a two-direction linked list of AutoreleasePoolPage, which only contains the references of the objects inserted into AutoreleasePool.
- AutoreleasePool is threa-related (it stored a property point to its pthread)
- While object called -(void)autorelease, the object will be recorded into current AutoreleasePoolPage.
- While objc_autoreleasePoolPop(), be called, AutoreleasePool will call release method from the stack of inserted objects. Normally, at the end of each Runloop, objc_autoreleasePoolPop() will be called to release memory.
- @autorleasepool{} block is using void *context = objc_autoreleasePoolPush(); to insert a soldier pointer into current AutoreleasePool while the block started, and is using objc_autoreleasePoolPop(context); to perform release.
- While AutoreleasePool made the release method call, and the reference count of that object deducted to 0, dealloc will be called to release the memory.

### Use Accessor to improve Memory Management
Simply override Accessor methods, then you won't need to worry about the Memory Manage while using them.
```objective-c
- (void)setTitles:(NSArray *)titles
{
    [titles retain];
    [_titles release];
    _titles = titles;
}
```

### Issues need to be avoided in Memory Management
- Releasing or Re-write the part of Memory where is still being used. It will cause application crash or data damaging.
    - We could use NSZombieEnabled to finde the objects which is over-released.
- Not Releasing Memory which is not used anymore, thus will cause Memory Leaks.
    - We could use Instruments tracking the reference counts and find th ememory leaks issue.

----
## ARC (Automatic Reference Counting)
ARC is a new feature from Xcode 4.2. The compiler will help us insert the memory manage methods properly, thus user do not need to worry about these methods anymore.

ARC is a **compiler feature** that provides automatic memory management of Objective-C objets

![Difference between MRR and ARC](https://developer.apple.com/library/archive/releasenotes/ObjectiveC/RN-TransitioningToARC/Art/ARC_Illustration.jpg "Difference between MRR and ARC")

> Using ARC in Swift is very similar to the approach described in [Transitioning to ARC Release Notes](https://developer.apple.com/library/archive/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html) for using ARC with Objective-C.

> Whenever you assign a class instance to a property, constant, or variable, that property, constant, or variable makes a strong reference to the instance. The reference is called a “strong” reference because it keeps a firm hold on that instance, and does not allow it to be deallocated for as long as that strong reference remains.

### Summary
- ARC works by adding code at compile time to ensure that objects live as long as necessary, but no longer. Conceptually, it follows the same memory management conventions as manual reference counting by adding the appropriate memory management calls for you.
- ARC is supported in Xcode 4.2 for OS X v10.6 and v10.7 and for iOS 4 and iOS 5. Weak references are not supprted in OS X v10.6 and iOS 4.
- “Assigned” instance variables become strong


### Basic Memory Management Rules Under ARC
The ruls under ARC is very simple, we don't need to retain and release object anymore. Instead, we only need to manage the pointers of objects. If there is any pointer to the object, the object will be reserved in Memory, and while there is no pointer pointing to the object, the object will be auto-released.
- Cannot use dealloc, retain, release, retainCount, autorelease nor @selector(retain) and @selector(release)
- Custom dealloc method do not need call [super dealloc] anymore.
- Cannot naming a method or property with prefix "new"
- There is no casual casting between id and void *. You must use special casts that tell the compiler about object lifetime.
- You cannot use NSAutoreleasePool objects, ARC provides @autoreleasepool blocks instead.

----
## Object's Memory Management in Core Foundation 
### Core Foundation
Normally, Objects in Core Foundation are created by methods XXXCreateWithXXXX(). Then we just need to follow the same Rules as MRR, ust CFRetain() and CFRelease() to manage the Reference Counts.

### Toll-free Bridged
Core Foundation framework has a lot of Classes could be replaced with the Classes in Foundation framework. Here is a list of all [Toll-Free Bridged Types](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFDesignConcepts/Articles/tollFreeBridgedTypes.html#//apple_ref/doc/uid/20002401-767858).
While during the process of Toll-free Bridging, there is one memory problem raised - how to handle the ownership of this object. Especially under ARC, while you are convert a Core Foundation object to Foundation object, you are required to epecify the ownership of this object. Thus here comes key words for Toll-free bridged:
1. **__bridge** - Only do the converting, do not transfer the ownership.
```objective-c
   NSString *nsString = @"string";
   CFStringRef cfString = (__bridge CFStringRef)nsString; // Here you don't Release cfString
```
```objective-c   
   CFStringRef cfString = CFStringCreateWithCString(kCFAllocatorDefault, "string", kCFStringEncodingUTF8);
   NSString *nsString = (__bridge NSString*)cfString;
   CFRelease(cfString); // Here you need to release cfString
```
2. **__bridge_retained** - Use __bridge_retained or CFBridgingRetain will convert an Objective-C object to a Core Foundation object, this method will also transfer the ownership to Core Foundation object, thus you need to call CFRelease to release the object.
```objective-c
    NSString *nsString = @"string";
    CFStringRef cfString = (__bridge_retained CFStringRef)nsString;
    CFRelease(cfString); // Then, you need to release CFStringRef in here.
```
3. **__bridge_transfer** - Use __bridge_transafer or CFBridgingRelease will convert a Core Foundation object into an Objective-C object. This method will pass the ownership of that object to ARC, then leave ARC to manage the ownership.
```objective-c   
    CFStringRef cfString = CFStringCreateWithCString(kCFAllocatorDefault, "string", kCFStringEncodingUTF8);
    NSString *nsString = (__bridge_transfer NSString*)cfString;
```