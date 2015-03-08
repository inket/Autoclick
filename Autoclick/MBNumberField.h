//
//  MBNumberField.h
//  Autoclick
//
//  Created by Mahdi Bchetnia on 05/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface MBNumberField : NSTextField {
    __unsafe_unretained IBOutlet NSStepper* stepper;
    NSInteger oldValue;
}

@property (assign, readwrite) NSStepper* stepper;

- (IBAction)step:(id)sender;
- (void)syncWithStepper;

@end
