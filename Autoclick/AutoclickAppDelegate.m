//
//  AutoclickAppDelegate.m
//  Autoclick
//
//  Created by Mahdi Bchetnia on 05/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AutoclickAppDelegate.h"

@interface AutoclickAppDelegate(Private)

- (IBAction)changeMode:(id)sender;
- (void)setMode:(BOOL)val;
- (void)resizeModeButtonToFit;

OSStatus hotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData);
- (void)registerGlobalHotKey:(NSString*)name withFlags:(unsigned int)flags code:(short)code recorder:(SRRecorderControl*)aRecorder;

@end

@implementation AutoclickAppDelegate

@synthesize window;
@synthesize modeButton;
@synthesize statusLabel;
@synthesize startStopButton;

- (void)window:(NSWindow*)wndw willEncodeRestorableState:(NSCoder *)state {
    [state encodeInteger:[buttonSelector indexOfSelectedItem] forKey:@"buttonSelector"];
    [state encodeInteger:[rateSelector integerValue] forKey:@"rateSelector"];
    [state encodeInteger:[rateUnitSelector indexOfSelectedItem] forKey:@"rateUnitSelector"];
    
    [state encodeInteger:[startAfterSelector integerValue] forKey:@"startAfterSelector"];
    [state encodeInteger:[startAfterUnitSelector indexOfSelectedItem] forKey:@"startAfterUnitSelector"];
    [state encodeBool:[startAfterCheckbox state] forKey:@"startAfterCheckbox"];
    
    [state encodeInteger:[stopAfterSelector integerValue] forKey:@"stopAfterSelector"];
    [state encodeInteger:[stopAfterUnitSelector indexOfSelectedItem] forKey:@"stopAfterUnitSelector"];
    [state encodeBool:[stopAfterCheckbox state] forKey:@"stopAfterCheckbox"];
    
    [state encodeBool:[ifStationaryCheckbox state] forKey:@"ifStationaryCheckbox"];
    [state encodeBool:[ifStationaryForCheckbox state] forKey:@"ifStationaryForCheckbox"];
    [state encodeInteger:[ifStationaryForSelector integerValue] forKey:@"ifStationaryForSelector"];
}

- (void)window:(NSWindow*)wndw didDecodeRestorableState:(NSCoder *)state {
    [buttonSelector selectItemAtIndex:[state decodeIntegerForKey:@"buttonSelector"]];
    [rateSelector setIntegerValue:[state decodeIntegerForKey:@"rateSelector"]];
    [rateUnitSelector selectItemAtIndex:[state decodeIntegerForKey:@"rateUnitSelector"]];
    
    [startAfterSelector setIntegerValue:[state decodeIntegerForKey:@"startAfterSelector"]];
    [startAfterUnitSelector selectItemAtIndex:[state decodeIntegerForKey:@"startAfterUnitSelector"]];
    [startAfterCheckbox setState:[state decodeBoolForKey:@"startAfterCheckbox"]];
    
    [stopAfterSelector setIntegerValue:[state decodeIntegerForKey:@"stopAfterSelector"]];
    [stopAfterUnitSelector selectItemAtIndex:[state decodeIntegerForKey:@"stopAfterUnitSelector"]];
    [stopAfterCheckbox setState:[state decodeBoolForKey:@"stopAfterCheckbox"]];
    
    [ifStationaryCheckbox setState:[state decodeBoolForKey:@"ifStationaryCheckbox"]];
    [ifStationaryForCheckbox setState:[state decodeBoolForKey:@"ifStationaryForCheckbox"]];
    [ifStationaryForSelector setIntegerValue:[state decodeIntegerForKey:@"ifStationaryForSelector"]];
    
    [rateSelector syncWithStepper];
    [startAfterSelector syncWithStepper];
    [stopAfterSelector syncWithStepper];
    [ifStationaryForSelector syncWithStepper];
    
    [self changedState:ifStationaryCheckbox];
}

- (void)awakeFromNib {
    clicker = [[Clicker alloc] init];
    [window setDelegate:(id<NSWindowDelegate>)self];
    [rateSelector syncWithStepper];
    [startAfterSelector syncWithStepper];
    [stopAfterSelector syncWithStepper];
    [ifStationaryForSelector syncWithStepper];
    
    [shortcutRecorder setAutosaveName:@"KeyboardShortcut"];
    [shortcutRecorder setDelegate:self];
    
    NSDictionary* keyCombo = [userDefaults objectForKey:[NSString stringWithFormat:@"ShortcutRecorder %@", [shortcutRecorder autosaveName]]];
    
    if (keyCombo)
    {
        KeyCombo combo;
        combo.flags = ([keyCombo objectForKey:@"modifierFlags"])?[[keyCombo objectForKey:@"modifierFlags"] integerValue]:0;
        combo.code = ([keyCombo objectForKey:@"keyCode"])?[[keyCombo objectForKey:@"keyCode"] integerValue]:-1;
    
        [shortcutRecorder setKeyCombo:combo];
    }
    
    // Position the mode button in the titlebar
    NSView *frameView = [[window contentView] superview];
    NSRect frame = [frameView frame];
    
    NSRect otherFrame = [modeButton frame];
    otherFrame.origin.x = NSMaxX( frame ) - NSWidth( otherFrame ) - 2;
    otherFrame.origin.y = NSMaxY( frame ) - NSHeight( otherFrame ) - 4;
    [modeButton setFrame: otherFrame];
    
    [frameView addSubview:modeButton];
    
    if (![userDefaults boolForKey:@"HasLaunchedBefore"])
    {
        CGPoint oldOrigin = [modeButton frame].origin;
        [modeButton setFrameOrigin:NSMakePoint(oldOrigin.x, oldOrigin.y+1)];
        [modeButton setShowsBorderOnlyWhileMouseInside:NO];
        [userDefaults setBool:YES forKey:@"HasLaunchedBefore"];
    }
    
    if (![userDefaults boolForKey:@"Advanced"])
        [self setMode:NO];
    else
        [self setMode:YES];
    
    if (floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_6)
    {
        NSData* data = [userDefaults objectForKey:@"State"];
        if (data)
        {
            NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
            [self window:window didDecodeRestorableState:unarchiver];
        }
    }
    
    [window setDelegate:(id<NSWindowDelegate>)self];
}

- (void)windowWillClose:(NSNotification*)note {
    @try {
        NSMenuItem* windowMenuItem = [[NSApp mainMenu] itemAtIndex:[[[NSApp mainMenu] itemArray] count]-2];
        
        NSMenuItem* separator = [NSMenuItem separatorItem];
        NSMenuItem* showAutoclick = [[NSMenuItem alloc] initWithTitle:@"Show Autoclick" action:@selector(applicationShouldHandleReopen:hasVisibleWindows:) keyEquivalent:@""];
        
        [[windowMenuItem submenu] insertItem:separator atIndex:0];
        [[windowMenuItem submenu] insertItem:showAutoclick atIndex:0];
    }
    @catch (NSException *exception) {
        
    }
}

- (void)windowDidBecomeKey:(NSNotification*)note {
    @try {
        NSMenuItem* windowMenuItem = [[NSApp mainMenu] itemAtIndex:[[[NSApp mainMenu] itemArray] count]-2];
        
        NSMenu* submenu = [windowMenuItem submenu];
        if ([[[submenu itemAtIndex:0] title] isEqualToString:@"Show Autoclick"])
        {
            [submenu removeItemAtIndex:0];
            [submenu removeItemAtIndex:0];
        }
    }
    @catch (NSException *exception) {
        
    }
}

- (IBAction)changeMode:(id)sender {
    [self setMode:!mode];
}

/* val: YES = Advanced / NO = Basic */
- (void)setMode:(BOOL)val {
    if (!val)
    {
        [modeButton setTitle:@"Basic"];
        
        [self resizeModeButtonToFit];
                
        [[advancedBox subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
            [obj setHidden:YES];
        }];
                
        NSRect frame = [window frame];
        if (frame.size.height >= 400)
        {
            frame.size.height = 206;
            frame.origin.y += 404 - 206;

            [window setFrame:frame display:YES animate:YES];
        }
    }
    else
    {
        [modeButton setTitle:@"Advanced"];

        [self resizeModeButtonToFit];
                
        [[advancedBox subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
            [obj setHidden:NO];
        }];
        
        NSRect frame = [window frame];
        if (frame.size.height <= 210)
        {
            frame.size.height = 404;
            frame.origin.y -= 404 - 206;

            [window setFrame:frame display:YES animate:YES];    
        }
    }
    
    mode = val;
    [userDefaults setBool:val forKey:@"Advanced"];
}

- (void)resizeModeButtonToFit {
    // Resize the button to match text
    NSFont* font = [NSFont systemFontOfSize:10];
    [modeButton setFont:font];
    
    NSDictionary* attrs = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    NSRect oldRect = [modeButton frame];
    CGFloat newWidth = [[modeButton title] sizeWithAttributes:attrs].width + 15;
    
    [modeButton setFrameSize:NSMakeSize(newWidth, oldRect.size.height)];
    if (newWidth != oldRect.size.width)
        [modeButton setFrame:NSMakeRect(oldRect.origin.x - (newWidth-oldRect.size.width), oldRect.origin.y, newWidth, oldRect.size.height)];
}

- (IBAction)startStop:(id)sender {
    if ([clicker isClicking])
    {
        [clicker stopClicking];
    }
    else
    {
        // Button
        int selectedButton;
        switch ([buttonSelector indexOfSelectedItem]) {
            case 0: selectedButton = LEFT; break;
            case 1: selectedButton = RIGHT; break;
            case 2: selectedButton = MIDDLE; break;
            default: selectedButton = LEFT; break;
        }
        
        // Rate
        NSInteger selectedRate = [rateSelector intValue];
        NSInteger selectedRateUnit = ([rateUnitSelector indexOfSelectedItem]==0)?1000:60000;
        
        NSInteger rate = (NSInteger)(selectedRateUnit / selectedRate); // a click every 'rate' (in ms)
        
        // Start Clicking or add the advanced preferences ?
        if (!mode)
            [clicker startClicking:selectedButton rate:rate startAfter:0 stopAfter:0 ifStationaryFor:0];
        else
        {
            NSInteger startAfter = ([startAfterCheckbox state])?([startAfterSelector intValue]*(([startAfterUnitSelector indexOfSelectedItem]==0)?1:60)):0;
                        
            NSInteger stopAfter = ([stopAfterCheckbox state])?([stopAfterSelector intValue]*(([stopAfterUnitSelector indexOfSelectedItem]==0)?1:60)):0;
                        
            NSInteger stationaryFor = ([ifStationaryCheckbox state])?([ifStationaryForCheckbox state]?[ifStationaryForSelector intValue]:1):0;
            
            [clicker startClicking:selectedButton rate:rate startAfter:startAfter stopAfter:stopAfter ifStationaryFor:stationaryFor];
        }
        
        [self startedClicking];
    }
}

- (void)startedClicking {
    [modeButton setEnabled:NO];
    [startStopButton setTitle:@"Stop"];
}

- (void)stoppedClicking {
    [modeButton setEnabled:YES];
    [startStopButton setTitle:@"Start"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [window makeKeyAndOrderFront:self];
    
    return YES;
}

- (IBAction)applicationShouldHandleReopen:(id)sender {
    [self applicationShouldHandleReopen:NSApp hasVisibleWindows:YES];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    if (floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_6)
    {
        NSMutableData* data = [NSMutableData data];
        NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

        [self window:window willEncodeRestorableState:archiver];
        [archiver finishEncoding];
        
        [userDefaults setObject:data forKey:@"State"];
        [userDefaults synchronize];
    }
}

- (IBAction)changedState:(id)sender {
    if (sender == ifStationaryCheckbox)
    {
        [ifStationaryForCheckbox setEnabled:[ifStationaryCheckbox state]];
        [ifStationaryForSelector setEnabled:[ifStationaryCheckbox state]];
        [[ifStationaryForSelector stepper] setEnabled:[ifStationaryCheckbox state]];
        
        if ([ifStationaryCheckbox state])
            [ifStationaryForText setTextColor:[NSColor textColor]];
        else
            [ifStationaryForText setTextColor:[NSColor disabledControlTextColor]];
    }
}

- (id)init {
    self = [super init];
    
    if (self)
    {
        userDefaults = [NSUserDefaults standardUserDefaults];
        iconArray = [NSArray arrayWithObjects:[NSImage imageNamed:@"clicking.icns"], [NSImage imageNamed:@"clicking1.icns"], [NSImage imageNamed:@"clicking2.icns"], [NSImage imageNamed:@"clicking3.icns"], nil];
        iconTimer = nil;
        [self defaultIcon];
        clicker = nil;
    }
    
    return self;
}

- (void)dealloc {
}

#pragma mark - ShortcutRecorder

OSStatus hotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData)
{
    //Do something once the key is pressed
	EventHotKeyID hotKeyID;
	GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hotKeyID), NULL, &hotKeyID);

    [[NSApp delegate] startStop:nil];
    
	return noErr;
}

- (void)registerGlobalHotKey:(NSString*)name withFlags:(unsigned int)flags code:(short)code recorder:(SRRecorderControl*)aRecorder {
    // Register the event
    EventTypeSpec eventType;
    eventType.eventClass=kEventClassKeyboard;
    eventType.eventKind=kEventHotKeyPressed;
    
    InstallApplicationEventHandler(&hotKeyHandler, 1, &eventType, NULL, NULL);
    
    EventHotKeyID gMyHotKeyID;
    UnregisterEventHotKey(hotkeyRef);
    gMyHotKeyID.signature='htk1';
    gMyHotKeyID.id=1;
    RegisterEventHotKey(code, flags, gMyHotKeyID, GetApplicationEventTarget(), 0, &hotkeyRef);
}

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(signed short)keyCode andFlagsTaken:(unsigned int)flags reason:(NSString **)aReason {
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo {
	if (newKeyCombo.flags != 0 && newKeyCombo.code != -1) {
		[self registerGlobalHotKey:[aRecorder autosaveName] withFlags:(unsigned int)[aRecorder cocoaToCarbonFlags:newKeyCombo.flags] code:newKeyCombo.code recorder:aRecorder];
	}
    else if (newKeyCombo.code == -1)
    {
        UnregisterEventHotKey(hotkeyRef);
    }
}

#pragma mark - Help & Support

- (IBAction)openSupport:(id)sender {
    NSString* subject = [@"Autoclick Support and Feedback" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:mahdi.adp@gmail.com?subject=%@", subject]];
    
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)openTwitter:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://twitter.com/autoclickapp"]];
}

#pragma mark - Icon Handling

- (void)defaultIcon {
    if (DEBUG_ENABLED) NSLog(@"defaultIcon call");
    [iconTimer invalidate];
    [NSApp setApplicationIconImage:[NSImage imageNamed:@"default.icns"]];
}

- (void)pausedIcon {
    if (DEBUG_ENABLED) NSLog(@"pausedIcon call");
    [iconTimer invalidate];
    [NSApp setApplicationIconImage:[NSImage imageNamed:@"paused.icns"]];
}

- (void)waitingIcon {
    if (DEBUG_ENABLED) NSLog(@"waitingIcon call");
    [iconTimer invalidate];
    [NSApp setApplicationIconImage:[NSImage imageNamed:@"waiting.icns"]];
}

- (void)clickingIcon {
    if (DEBUG_ENABLED) NSLog(@"clickingIcon call");
    if (!iconTimer || ![iconTimer isValid])
    {
        iconIndex = 1;
        [NSApp setApplicationIconImage:[iconArray objectAtIndex:0]];
        iconTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(nextIcon) userInfo:nil repeats:YES];
    }
}
                     
- (void)nextIcon {
    if (DEBUG_ENABLED) NSLog(@"nextIcon call");
    iconIndex++;
    if (iconIndex >= [iconArray count]) iconIndex = 0;
    [NSApp setApplicationIconImage:[iconArray objectAtIndex:iconIndex]];
}

@end
