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

#import "TextualApplication.h"
#import "IRCAddressBookEntry+Overrides.h"


@implementation TVCLogController (Overrides)

+ (void)load {
    XRExchangeImplementation(@"TVCLogController", @"isSafeToPresentImageWithID:", @"__tpi_isSafeToPresentImageWithID:");
}

#pragma mark - Method Swizzling

- (void)__tpi_isSafeToPresentImageWithID:(NSString *)uniqueID {
    DOMDocument *document = [[self webView] mainFrameDocument];
    DOMElement *image = [document getElementById:[@"inlineImage-" stringByAppendingString:uniqueID]];
    NSString *imageUrl = [[image querySelector:@"a"] getAttribute:@"href"];
    
    NSURL *urlObject = [imageUrl URLUsingWebKitPasteboard];
    if ([[urlObject pathExtension] isEqualIgnoringCase:@"gif"] ||
        [[urlObject host] hasSuffix:@"youtube.com"] ||
        [[urlObject host] hasSuffix:@"youtu.be"]) {
            return;
    }
    
    DOMElement *sender = [[[image parentElement] parentElement] querySelector:@".sender"];
    NSString *nickname = [sender getAttribute:@"nickname"];
    if (nickname != nil) {
        IRCUser *user = [[self associatedChannel] findMember:nickname];
        IRCAddressBookEntry *ignore = [[self associatedClient] checkIgnoreAgainstHostmask:[user hostmask] withMatches:@[IRCAddressBookDictionaryValueIgnoreInlineMediaKey]];
        if ([ignore ignoreInlineMedia] == NO) {
            [self __tpi_isSafeToPresentImageWithID:uniqueID];
        }
    }
}


@end
