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

import Foundation


@objc protocol InlineMediaHandler {
    /**
    Inline Media Handler Protocol, can be extended to provide media handlers for urls that match certain conditions
    
    - parameter url:        The URL of the inline media source
    - parameter controller: A Textual "Log Controller" for the view we want to insert the inline media
    - parameter line:       The unique identifier of the line we want to insert the inline media into
    
    - returns: An instance of an inline media handler
    */
    init(url: NSURL, controller: TVCLogController, line: String)
    
    /**
    Name of the service this media handler is responsible for
    
    - returns: The name of the service
    */
    static func name() -> String
    
    /**
    Icon for the service this media handler is responsible for
    
    - returns: An image icon for the service this media handler is responsible for
    */
    optional static func icon() -> NSImage?
    
    /**
    Called to check whether the current URL matches the requirements for the inline media handler
    
    - parameter url:               The URL to test against
    
    - returns: A boolean representing whether or not this URL can be handled by this media handler
    */
    optional static func matchesServiceSchema(url: NSURL) -> Bool
    
    /**
    Given an URL, returns a corrected URL with a direct link to an image, to be displayed in Textual.
    
    - parameter url: URL that was detected in a message being rendered
    
    - returns: A string containing the corrected url, or nil if not applicable.
    */
    optional static func processInlineMediaContentURL(url: NSURL) -> String?
}