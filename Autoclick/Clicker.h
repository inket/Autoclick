//
//  Clicker.h
//  Autoclick
//
//  Created by Mahdi Bchetnia on 09/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Clicker : NSObject {
    BOOL isClicking;
    BOOL isWaiting;
    BOOL fnPressed;
    
    NSTimer* waitingTimer;
    NSInteger stationarySeconds;
    NSTimeInterval lastMoved; // Mouse
    NSTextField* statusLabel;
    
    NSDictionary* params; // for keeping the parameters between threads and timers
    NSThread* clickThread;
}

@property (assign) BOOL isClicking;

- (void)stopClicking;
- (void)startClicking:(int)button rate:(NSInteger)rate
                startAfter:(NSInteger)start stopAfter:(NSInteger)stop
              ifStationaryFor:(NSInteger)stationary;

@end
