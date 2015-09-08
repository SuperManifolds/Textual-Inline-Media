//
//  IRCAddressBook+Overrides.h
//  Textual Inline Media
//
//  Created by Alex S. Glomsaas on 2015-09-06.
//  Copyright © 2015 Alex S. Glomsaas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TextualApplication.h"

TEXTUAL_EXTERN NSString * const IRCAddressBookDictionaryValueIgnoreInlineMediaKey;

@interface IRCAddressBookEntry (Overrides)
@property (nonatomic, assign) BOOL ignoreInlineMedia;

@end
