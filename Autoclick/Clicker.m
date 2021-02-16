//
//  Clicker.m
//  Autoclick
//

#import "Clicker.h"
#import "AutoclickAppDelegate.h"

@implementation Clicker

@synthesize isClicking;

- (NSScreen *)currentScreenForMouseLocation:(CGPoint)mouseLocation {
    NSScreen *currentScreen = nil;

    for (NSScreen *screen in NSScreen.screens) {
        if (NSPointInRect(mouseLocation, screen.frame)) {
            currentScreen = screen;
            break;
        }
    }

    if (currentScreen == nil) {
        currentScreen = NSScreen.mainScreen;
    }

    return currentScreen;
}

- (NSScreen *)actualMainScreen {
    for (NSScreen *screen in NSScreen.screens) {
        if (CGPointEqualToPoint(screen.frame.origin, CGPointZero)) {
            return screen;
        }
    }

    return NSScreen.mainScreen;
}

- (BOOL)checkBeforeClicking {
    if ([[NSThread currentThread] isCancelled]) [NSThread exit];
    if ([[NSDate date] timeIntervalSince1970] - lastMoved >= stationarySeconds)
        return !fnPressed;
    
    return NO;
}

- (void)clickWithButton:(CGMouseButton)mouseButton {
    if (![self checkBeforeClicking]) return;

    dispatch_sync(dispatch_get_main_queue(), ^{
        CGPoint point = [NSEvent mouseLocation];

        // Is Autoclick's window front and the cursor is inside it ?
        NSWindow *appWindow = NSApp.appDelegate.window;
        if (appWindow.isKeyWindow && NSPointInRect(point, appWindow.frame)) {
            return;
        }

        if (DEBUG_ENABLED) {
            NSLog(@"Click with button: %@", @(mouseButton));
        }

        NSScreen *mainScreen = [self actualMainScreen];
        NSScreen *currentScreen = [self currentScreenForMouseLocation:point];
        CGFloat screensOverlap = CGRectGetMaxY(currentScreen.frame);
        CGFloat currentScreenTopMargin = mainScreen.frame.size.height - screensOverlap;
        point.y = currentScreenTopMargin + currentScreen.frame.size.height - point.y + currentScreen.frame.origin.y;

        CGEventType mouseDownEvent;
        CGEventType mouseUpEvent;
        switch (mouseButton) {
            case kCGMouseButtonLeft:
                mouseDownEvent = kCGEventLeftMouseDown;
                mouseUpEvent = kCGEventLeftMouseUp;
                break;
            case kCGMouseButtonRight:
                mouseDownEvent = kCGEventRightMouseDown;
                mouseUpEvent = kCGEventRightMouseUp;
                break;
            case kCGMouseButtonCenter:
                mouseDownEvent = kCGEventOtherMouseDown;
                mouseUpEvent = kCGEventOtherMouseUp;
                break;
        }

        CGEventRef click = CGEventCreateMouseEvent(NULL, mouseDownEvent, point, mouseButton);
        CGEventPost(kCGHIDEventTap, click);
        CGEventSetType(click, mouseUpEvent);
        CGEventPost(kCGHIDEventTap, click);
        CFRelease(click);
    });
}

- (void)leftClick {
    [self clickWithButton:kCGMouseButtonLeft];
}

- (void)rightClick {
    [self clickWithButton:kCGMouseButtonRight];
}

- (void)middleClick {
    [self clickWithButton:kCGMouseButtonCenter];
}

- (void)clickThread:(NSDictionary*)parameters {
    if (isClicking)
    {
        NSTimeInterval timeInterval = [[parameters objectForKey:@"rate"] doubleValue] / 1000;
        
        NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
        NSTimer* timer;
        
        SEL selector = nil;
        
        switch ([[parameters objectForKey:@"button"] intValue]) {
            case LEFT: selector = @selector(leftClick); break;
            case RIGHT: selector = @selector(rightClick); break;
            case MIDDLE: selector = @selector(middleClick); break;
            default: selector = @selector(leftClick); break;
        }
        
        timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:selector userInfo:nil repeats:YES];
        
        if ([[parameters objectForKey:@"stop"] integerValue] > 0)
            [NSTimer scheduledTimerWithTimeInterval:[[parameters objectForKey:@"stop"] integerValue]
                                             target:self
                                           selector:@selector(stopClickingByTimer:)
                                           userInfo:[NSDictionary dictionaryWithObject:clickThread forKey:@"clickThread"]
                                            repeats:NO];
        
        stationarySeconds = [[parameters objectForKey:@"stationary"] integerValue];
        
        if ([NSEvent modifierFlags] & NSEventModifierFlagFunction)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->statusLabel setStringValue:@"Paused…"];
                [[NSApp appDelegate] pausedIcon];
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->statusLabel setStringValue:@"Clicking…"];
                [[NSApp appDelegate] clickingIcon];
            });
        }
        
        [runLoop run];
    }
}

- (void)stopClickingByTimer:(NSTimer*)timer {
    if (waitingTimer)
    {
        [waitingTimer invalidate];
        waitingTimer = nil;
    }
    
    NSThread* theThread = [[timer userInfo] objectForKey:@"clickThread"];
    if (theThread)
        [theThread cancel];
    
    isClicking = NO;
    [[NSApp appDelegate] stoppedClicking];
    [statusLabel setStringValue:@"Stopped automatically."];
    [[NSApp appDelegate] defaultIcon];
    
    if (DEBUG_ENABLED) NSLog(@"Stopped Clicking Thread");
}

- (void)stopClicking {
    if (waitingTimer)
    {
        [waitingTimer invalidate];
        waitingTimer = nil;
    }
    
    [clickThread cancel];
    isClicking = NO;
    [[NSApp appDelegate] stoppedClicking];
    [statusLabel setStringValue:@"Stopped."];
    [[NSApp appDelegate] defaultIcon];
    
    if (DEBUG_ENABLED) NSLog(@"Stopped Clicking Thread");
}

- (void)startClickingThread:(NSDictionary*)parameters {
    if (DEBUG_ENABLED) NSLog(@"Starting Clicking Thread…");
    if ([parameters isKindOfClass:[NSTimer class]])
        parameters = [(NSTimer*)parameters userInfo];
    clickThread = [[NSThread alloc] initWithTarget:self selector:@selector(clickThread:) object:parameters];

    isWaiting = NO;
    [clickThread start];
}

- (void)startClickingThread:(NSDictionary*)parameters after:(NSInteger)start {
    isWaiting = YES;
    waitingTimer = [NSTimer scheduledTimerWithTimeInterval:start target:self selector:@selector(startClickingThread:) userInfo:parameters repeats:NO];
    
    [statusLabel setStringValue:@"Waiting…"];
    [[NSApp appDelegate] waitingIcon];
}

- (void)startClicking:(int)button rate:(NSInteger)rate
                startAfter:(NSInteger)start stopAfter:(NSInteger)stop
              ifStationaryFor:(NSInteger)stationary {
    
    if (DEBUG_ENABLED)
    {
        NSLog(@"Button: %d", button);
        NSLog(@"Rate: %ld", rate);
        NSLog(@"Start After: %ld", start);
        NSLog(@"Stop After: %ld", stop);
        NSLog(@"Only if stationary for %ld", stationary);
        NSLog(@"—————————————————————————");
    }
        
    [[[NSApp appDelegate] modeButton] setEnabled:NO];
    isClicking = YES;
    
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:button], @"button", [NSNumber numberWithInteger:rate], @"rate", [NSNumber numberWithInteger:start], @"start", [NSNumber numberWithInteger:stop], @"stop", [NSNumber numberWithInteger:stationary], @"stationary", nil];
    
    if (start == 0)
        [self startClickingThread:parameters];
    else
        [self startClickingThread:parameters after:start];
}

- (id)init
{
    self = [super init];
    if (self) {
        fnPressed = [NSEvent modifierFlags] & NSEventModifierFlagFunction;
        isClicking = NO;
        isWaiting = NO;
        waitingTimer = nil;
        stationarySeconds = 0;
        
        statusLabel = [[NSApp appDelegate] statusLabel];

        __weak typeof(self) weakSelf = self;
        NSEvent* (^moveBlock)(NSEvent*) = ^(NSEvent* event) {
            typeof(self) strongSelf = weakSelf;
            if (!strongSelf) { return (NSEvent *)nil; }

            if (DEBUG_ENABLED && strongSelf->fnPressed) NSLog(@"Mouse Moved");
            
            strongSelf->lastMoved = [[NSDate date] timeIntervalSince1970];
            
            return event;
        };

        [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskMouseMoved handler:(void(^)(NSEvent*))moveBlock];
        [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskMouseMoved handler:moveBlock];
        
        NSEvent* (^fnBlock)(NSEvent*) = ^(NSEvent* event){
            typeof(self) strongSelf = weakSelf;
            if (!strongSelf) { return (NSEvent *)nil; }
//            if (DEBUG_ENABLED) NSLog(@"Flag Changed");
            
            if ([event modifierFlags] & NSEventModifierFlagFunction) {
                strongSelf->fnPressed = YES;
                
                if (strongSelf->isClicking && !strongSelf->isWaiting)
                {
                    [strongSelf->statusLabel setStringValue:@"Paused…"];
                    [[NSApp appDelegate] pausedIcon];
                }
            }
            else
            {
                strongSelf->fnPressed = NO;
                
                if (strongSelf->isClicking && !strongSelf->isWaiting)
                {
                    [strongSelf->statusLabel setStringValue:@"Clicking…"];
                    [[NSApp appDelegate] clickingIcon];
                }
            }
            
            return event;
        };
        
        [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:(void(^)(NSEvent* event))fnBlock];
        [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:fnBlock];
    }
    
    return self;
}

@end
