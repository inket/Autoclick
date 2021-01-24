//
//  MBNumberField.h
//  Autoclick
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
