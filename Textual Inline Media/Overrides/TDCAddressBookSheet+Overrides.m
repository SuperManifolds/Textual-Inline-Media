/*
    Copyright (c) 2015, Alex S. Glomsaas
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:
    
        1. Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
        
        2. Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.
        
        3. Neither the name of the copyright holder nor the names of its
        contributors may be used to endorse or promote products derived from
        this software without specific prior written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
    ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "IRCAddressBookEntry+Overrides.h"

@implementation TDCAddressBookSheet (Overrides)

+ (void)load
{
    XRExchangeImplementation(@"TDCAddressBookSheet", @"start", @"__tpi_start");
}

#pragma mark - Method Swizzling

- (void)__tpi_start
{
	[self __tpi_start];

    if ([[self ignore] entryType] == IRCAddressBookIgnoreEntryType) {
		/* Maybe set default value for property */
		if ([self newItem]) {
			[[self ignore] setIgnoreInlineMedia:YES];
		}

		/* Create the button to add. */
		/* The frame the button is created with is the default. Constraints
		 are added later on in this method which will position it correctly. */
        NSButton *inlineMediaCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 272, 18)];

		[inlineMediaCheckbox setTarget:self];
		[inlineMediaCheckbox setAction:@selector(inlineMediaCheckboxToggled:)];
		[inlineMediaCheckbox setButtonType:NSSwitchButton];
		[inlineMediaCheckbox setFont:[NSFont systemFontOfSize:13.0]];
		[inlineMediaCheckbox setState:[[self ignore] ignoreInlineMedia]];
		[inlineMediaCheckbox setTitle:@"Do not display inline media from this user"];
		[inlineMediaCheckbox setTranslatesAutoresizingMaskIntoConstraints:NO];

		[inlineMediaCheckbox sizeToFit];

        [[[self sheet] contentView] addSubview:inlineMediaCheckbox];

		/* Add constraints for new button. */
		id ignoreMessagesContainingMatchCheck = [self valueForKey:@"ignoreMessagesContainingMatchCheck"];

		id ignoreEntrySaveButton = [self valueForKey:@"ignoreEntrySaveButton"];

		[[[self sheet] contentView] addConstraint:
		 [NSLayoutConstraint constraintWithItem:inlineMediaCheckbox
									  attribute:NSLayoutAttributeTop
									  relatedBy:NSLayoutRelationEqual
										 toItem:ignoreMessagesContainingMatchCheck
									  attribute:NSLayoutAttributeBottom
									 multiplier:1.0
									   constant:14.0]
		 ];

		[[[self sheet] contentView] addConstraint:
		 [NSLayoutConstraint constraintWithItem:inlineMediaCheckbox
									  attribute:NSLayoutAttributeLeading
									  relatedBy:NSLayoutRelationEqual
										 toItem:ignoreMessagesContainingMatchCheck
									  attribute:NSLayoutAttributeLeading
									 multiplier:1.0
									   constant:0.0]
		 ];

		[[[self sheet] contentView] addConstraint:
		 [NSLayoutConstraint constraintWithItem:ignoreEntrySaveButton
									  attribute:NSLayoutAttributeTop
									  relatedBy:NSLayoutRelationEqual
										 toItem:inlineMediaCheckbox
									  attribute:NSLayoutAttributeBottom
									 multiplier:1.0
									   constant:40.0]
		 ];
    }
}

- (void)inlineMediaCheckboxToggled:(NSButton *)sender
{
	[[self ignore] setIgnoreInlineMedia:[sender state]];
}

@end
