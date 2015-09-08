//
//  TDCAddressBookSheet+Overrides.m
//  Textual Inline Media
//
//  Created by Alex S. Glomsaas on 2015-09-06.
//  Copyright © 2015 Alex S. Glomsaas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "IRCAddressBookEntry+Overrides.h"
#import "TextualApplication.h"

@implementation TDCAddressBookSheet (Overrides)

+ (void)load {
    NSLog(@"load");
    XRExchangeImplementation(@"TDCAddressBookSheet", @"start", @"startOverride");
    XRExchangeImplementation(@"TDCAddressBookSheet", @"ok:", @"okOverride:");
}

void XRExchangeImplementation(NSString *className, NSString *originalMethod, NSString *replacementMethod) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = NSClassFromString(className);
        
        SEL originalSelector = NSSelectorFromString(originalMethod);
        SEL swizzledSelector = NSSelectorFromString(replacementMethod);
        
        Method originalMethodDcl = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethodDcl = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL methodAdded =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethodDcl),
                        method_getTypeEncoding(swizzledMethodDcl));
        
        if (methodAdded) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethodDcl),
                                method_getTypeEncoding(originalMethodDcl));
        } else {
            method_exchangeImplementations(originalMethodDcl, swizzledMethodDcl);
        }
    });
}

#pragma mark - Method Swizzling

- (void)startOverride {
    [self startOverride];
    if ([self.ignore entryType] == IRCAddressBookIgnoreEntryType) {
        NSRect frame;
        frame.size.height = 18;
        frame.size.width = 350;
        frame.origin.x = 74;
        frame.origin.y = 52;
        NSButton *inlineMediaCheckbox = [[NSButton alloc] initWithFrame:frame];
        //[inlineMediaCheckbox setState: [self.ignore ignoreInlineMedia]];
        [inlineMediaCheckbox setButtonType:NSSwitchButton];
        [inlineMediaCheckbox setTitle:@"Do not display inline media from this user"];
        
        
        [[self sheet].contentView addSubview:inlineMediaCheckbox];
    }
}

- (void)okOverride:(id)sender {
    NSLog(@"ok");
    [self okOverride:sender];
    NSLog(@"ok");
}


@end