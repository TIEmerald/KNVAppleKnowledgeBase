# Objective-C Runtime Programming
## References
[Apple Objective-C Runtime Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008048-CH1-SW1)

[Objective-C Runtime References](https://developer.apple.com/documentation/objectivec/objective-c_runtime)

[doesNotRecognizeSelector(_:) Document](https://developer.apple.com/documentation/objectivec/nsobject/1418637-doesnotrecognizeselector)

[forwardInvocation: Document](https://developer.apple.com/documentation/objectivec/nsobject/1571955-forwardinvocation)

[resolveInstanceMethod(_:) Document](https://developer.apple.com/documentation/objectivec/nsobject/1418500-resolveinstancemethod)

[forwardingTarget(for:)](https://developer.apple.com/documentation/objectivec/nsobject/1418855-forwardingtarget)

----

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

----

## Messaging
```objective-c
objc_msgSend(receiver, selector, arg1, arg2, ...)
```
> The key to messaging lies in the structures that the compiler builds for each class and object. Every class structure includes **these two essential elements**:
> 1. A pointer to the superclass.
> 2. A class dispatch table. This table has entries that associate method selectors with the class-specific addresses of the methods they identify.

> When a new object is created, memory for it is allocated, and its instance variables are initialized. First among the object's variables is a pointer to its class structure. This pointer, called **isa**, gives the object access to its class and, through the class, to all the classes it inherits from.

> Whe a message is sent to an object, the messaging function follows the object's isa pointer to the class structure where it looks up the method selector in the dispatch table. If it can't find the selector there, objec_msgSend follows the pointer to the superclass and tries to find the selector in its dispatch table. Successive failures cause objc_msgSend to climb the class hierarchy until it reaches the NSObject class. Once it locates the selector, the function calls the method entered in the table and passes it the receiving object's data structure.

## Messaging Forwarding
>Sending a message to an object that does not handle that message is an error, However, before announcing the error, the runtime system gives the receiving object a second chance to handle the message.
```objective-c
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([someOtherObject respondsToSelector:
            [anInvocation selector]])
        [anInvocation invokeWithTarget:someOtherObject];
    else
        [super forwardInvocation:anInvocation];
}
```

> **Note:** The message that’s forwarded must have a fixed number of arguments; variable numbers of arguments (in the style of printf()) are not supported.

> **Note:** The forwardInvocation: method gets to handle messages only if they don't invoke an existing method in the nominal receiver. If, for example, you want your object to forward negotiate messages to another object, it can't have a negotiate method of its own. If it does, the message will never reach forwardInvocation:

> **Note:** Also Pls note, Although forwarding mimics inheritance, the NSObject class never confuses the two. Methods like __respondsToSelector:__ and __isKindOfClass:__ look only at the inheritance hierarchy, never at the forwarding chain. Thus if you don't re-implement those methods, the answers from those methods will always be NO.

> In addition to __respondsToSelector:__ and __isKindOfClass:__, the __instancesRespondToSelector:__ method should also mirror the forwarding algorithm. If protocols are used, the __conformsToProtocol:__ method should likewise be added to the list.

> Similarly, if an object forwards any remote messages it receives, it should have a version of __methodSignatureForSelector:__ that can return accurate descriptions of the methods that ultimately respond to the forwarded messages; for example, if an object is able to forward a message to its surrogate (I guess something like [NSProxy performSelector:...]), you would implement __methodSignatureForSelector:__ as follows:
```objective-c
- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature* signature = [super methodSignatureForSelector:selector];
    if (!signature) {
       signature = [surrogate methodSignatureForSelector:selector];
    }
    return signature;
}
```

> **Note:**  This is an advanced technique, suitable only for situations where no other solution is possible. It is not intended as a replacement for inheritance. If you must make use of this technique, make sure you fully understand the behavior of the class doing the forwarding and the class you’re forwarding to.

## doesNotRecognizeSelector(_:)
> The runtime system invoikes this method whenever an object receives an aSelector message it can't respond to or forward. This method, in turn, raises an NSInvalidArgument Exception, and generates an error message.

> It could also be used in prgram code to prevent a method from being inherited. For example, an NSObject subclass might renounce the copy() or init() method by re-implementing it to include a doesNotRecognizeSelector(_:) message as follows:
```objective-c
- (id)copy {
    [self doesNotrecognizeSelector:_cmd];
}
```

## resolveInstanceMethod(_:)
> Dynamically provides an implementation for a given selector for an instance method.

> This method and __resolveClassMethod(_:)__ allow you to dynamically provide an implementation for a given selector. An Objective-C method is simply a C function that take at least two arguments - self and _cmd. Using the __class_addMethod(_:_:_:_:)__ function, you can add a function to a class as a method.
```objective-c
void dynamicMethodIMP(id self, SEL _cmd)
{
    // implementation ....
}
+ (BOOL) resolveInstanceMethod:(SEL)aSEL
{
    if (aSEL == @selector(resolveThisMethodDynamically))
    {
          class_addMethod([self class], aSEL, (IMP) dynamicMethodIMP, "v@:");
          return YES;
    }
    return [super resolveInstanceMethod:aSel];
}
```

> **Special Considerations** This method is called before the Objective-C forwarding mechanism is invoked. If __responds(to:)__ or __instancesRespond(to:)__ is invoked, the dynamic method resolver is given the opportunity to provide an IMP for the given selector first.

## forwardingTarget(for:)
> Returns the object to which unrecognized messages should first be directed.

> This method gives an object a chance to redirect an unknown message sent to it before the much more expensive __forwardInvocation:__ machinery takes over. This is useful when you simply want to redirect messages to another object and can be an order of magnitude faster than regular forwarding. It is not useful where the goal of the forwarding is to capture the NSInvocation, or manipulate the arguments or return value during the forwarding.

## General diagram about what will happen, if we cannot find message implementaiton in class structures.

![The workflow of the message sending](messaging_diagram.jpg "The workflow of the message sending")