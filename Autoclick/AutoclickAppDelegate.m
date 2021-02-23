//
//  AutoclickAppDelegate.m
//  Autoclick
//

#import "AutoclickAppDelegate.h"

@implementation NSApplication (AppDelegate)

- (AutoclickAppDelegate *)appDelegate {
    return (AutoclickAppDelegate *)[NSApp delegate];
}

@end

@implementation AutoclickAppDelegate {
    NSUserDefaultsController *_defaults;
}

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

    [shortcutRecorder setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:YES];

    _defaults = NSUserDefaultsController.sharedUserDefaultsController;
    NSString *keyPath = @"values.shortcut";
    NSDictionary *options = @{NSValueTransformerNameBindingOption: NSKeyedUnarchiveFromDataTransformerName};

    SRShortcutAction *shortcutAction = [SRShortcutAction shortcutActionWithKeyPath:keyPath
                                                                          ofObject:_defaults
                                                                     actionHandler:^BOOL(SRShortcutAction *anAction) {
        [[NSApp appDelegate] startStop:nil];
        return YES;
    }];
    [[SRGlobalShortcutMonitor sharedMonitor] addAction:shortcutAction forKeyEvent:SRKeyEventTypeDown];

    [shortcutRecorder bind:NSValueBinding toObject:_defaults withKeyPath:keyPath options:options];
    
    // Position the mode button in the titlebar
    NSView *frameView = [[window contentView] superview];
    [frameView addSubview:modeButton];
    [modeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [modeButton.trailingAnchor constraintEqualToAnchor:frameView.trailingAnchor constant:-6],
        [modeButton.topAnchor constraintEqualToAnchor:frameView.topAnchor constant:6]
    ]];
    
    if (![userDefaults boolForKey:@"Advanced"])
        [self setMode:NO];
    else
        [self setMode:YES];
    
    if (floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_6)
    {
        NSData* data = [userDefaults objectForKey:@"State"];
        if (data)
        {
            NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:nil];
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

- (IBAction)startStop:(id)sender {
    if ([clicker isClicking])
    {
        [clicker stopClicking];
    }
    else
    {
        NSDictionary *options = @{(__bridge id) kAXTrustedCheckOptionPrompt : @YES};
        BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef) options);

        if (!accessibilityEnabled) {
            // Do not enable clicking if accessibility is off because the user might open the Privacy > Accessibility
            // settings then check the box next to Autoclick which will immediately be unchecked by the automatic
            // clicking.
            return;
        }

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
        NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
        [self window:window willEncodeRestorableState:archiver];
        [archiver finishEncoding];
        
        [userDefaults setObject:archiver.encodedData forKey:@"State"];
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

#pragma mark - Help & Support

- (IBAction)openSupport:(id)sender {
    NSString* subject = [@"Autoclick Support and Feedback" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:autoclick@mahdi.jp?subject=%@", subject]];
    
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)openGitHub:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://github.com/inket/Autoclick"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)openBuyMeACoffee:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://www.buymeacoffee.com/mahdibchatnia"];
    [[NSWorkspace sharedWorkspace] openURL:url];
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
