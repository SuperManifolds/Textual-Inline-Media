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

#include <objc/runtime.h>

NSString * const IRCAddressBookDictionaryValueIgnoreInlineMediaKey	= @"ignoreInlineMedia";

@implementation IRCAddressBookEntry (Overrides)

#pragma mark -
#pragma mark -ignoreInlineMedia Property Getter/Setter

static void *_internalIgnoreInlineMediaPropertyValue = nil;

- (BOOL)ignoreInlineMedia
{
	NSNumber *ignoreInlineMedia = objc_getAssociatedObject(self, _internalIgnoreInlineMediaPropertyValue);

	if (ignoreInlineMedia) {
		return [ignoreInlineMedia boolValue];
	} else {
		return NO;
	}
}

- (void)setIgnoreInlineMedia:(BOOL)ignoreInlineMedia
{
	objc_setAssociatedObject(self, _internalIgnoreInlineMediaPropertyValue, [NSNumber numberWithBool:ignoreInlineMedia], OBJC_ASSOCIATION_COPY);
}

#pragma mark -
#pragma mark Overrides

+ (void)load
{
	XRExchangeImplementation(@"IRCAddressBookEntry", @"dictionaryValue", @"__tpi_dictionaryValue");
	XRExchangeImplementation(@"IRCAddressBookEntry", @"populateDictionaryValues:", @"__tpi_populateDictionaryValues:");
}

- (NSDictionary *)__tpi_dictionaryValue
{
	NSDictionary *parentDictionary = [self __tpi_dictionaryValue];

	NSMutableDictionary *newDictionary = [parentDictionary mutableCopy];

	[newDictionary setBool:self.ignoreInlineMedia forKey:IRCAddressBookDictionaryValueIgnoreInlineMediaKey];

	return newDictionary;
}

- (void)__tpi_populateDictionaryValues:(NSDictionary *)dic
{
	[self __tpi_populateDictionaryValues:dic];

	self.ignoreInlineMedia = [dic boolForKey:IRCAddressBookDictionaryValueIgnoreInlineMediaKey];
}

@end
