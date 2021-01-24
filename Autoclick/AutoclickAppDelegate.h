//
//  AutoclickAppDelegate.h
//  Autoclick
//
//  Created by Mahdi Bchetnia on 05/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBNumberField.h"
#import "Clicker.h"
#import <ShortcutRecorder/ShortcutRecorder.h>

@interface AutoclickAppDelegate : NSObject <NSApplicationDelegate> {
    __unsafe_unretained NSWindow *window;
    
    BOOL mode;
    __unsafe_unretained IBOutlet NSButton* modeButton;
    IBOutlet NSButton* startStopButton;
    
    IBOutlet NSBox* topBorder;
    IBOutlet NSBox* bottomBorder;
    IBOutlet NSBox* advancedBox;
    
    IBOutlet NSTextField* statusLabel;
    
    NSUserDefaults* userDefaults;
    
    Clicker* clicker;
    
    EventHotKeyRef hotkeyRef;
    
    // Values
    IBOutlet NSPopUpButton* buttonSelector;
    IBOutlet MBNumberField* rateSelector;
    IBOutlet NSPopUpButton* rateUnitSelector;
    
    IBOutlet MBNumberField* startAfterSelector;
    IBOutlet NSPopUpButton* startAfterUnitSelector;
    IBOutlet NSButton* startAfterCheckbox;
    
    IBOutlet MBNumberField* stopAfterSelector;
    IBOutlet NSPopUpButton* stopAfterUnitSelector;
    IBOutlet NSButton* stopAfterCheckbox;
    
    IBOutlet NSButton* ifStationaryCheckbox;
    IBOutlet NSButton* ifStationaryForCheckbox;
    IBOutlet MBNumberField* ifStationaryForSelector;
    IBOutlet NSTextField* ifStationaryForText;
    
    IBOutlet SRRecorderControl* shortcutRecorder;
    
    NSArray* iconArray;
    NSInteger iconIndex;
    NSTimer* iconTimer;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton* modeButton;
@property (readonly) IBOutlet NSTextField* statusLabel;
@property (readonly) IBOutlet NSButton* startStopButton;

- (void)startedClicking;
- (void)stoppedClicking;

- (IBAction)changedState:(id)sender;
- (IBAction)startStop:(id)sender;

#pragma mark - Icon Handling

- (void)defaultIcon;
- (void)pausedIcon;
- (void)waitingIcon;
- (void)clickingIcon;

@end
