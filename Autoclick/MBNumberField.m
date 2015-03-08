//
//  MBNumberField.m
//  Autoclick
//
//  Created by Mahdi Bchetnia on 05/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MBNumberField.h"

@implementation MBNumberField

@synthesize stepper;

- (void)textDidChange:(NSNotification *)notification {
    if ([self integerValue] > [stepper maxValue] || [self integerValue] < [stepper minValue])
        [self setIntegerValue:oldValue];
    else
        [self setIntegerValue:[self integerValue]];
    
    oldValue = [self integerValue];
    [self syncWithStepper];
        
    [_delegate controlTextDidChange:notification];
}

- (void)setIntegerValue:(NSInteger)anInteger {
    [super setIntegerValue:anInteger];
    oldValue = [self intValue];
}

- (IBAction)step:(id)sender {
    [self setIntegerValue:[sender integerValue]];
}

- (void)syncWithStepper {
    [stepper setIntegerValue:[self integerValue]];
}

@end
