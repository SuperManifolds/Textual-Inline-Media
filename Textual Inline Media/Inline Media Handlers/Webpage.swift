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

class Webpage: NSObject {
    private let data: Data
    private let response: HTTPURLResponse
    private let controller: TVCLogController
    private let line: String
    
    /**
    Show inline media information for a webpage
    
    - parameter data:       The HTML data returned from this webpage
    - parameter response:   The HTTP response object from the server
    - parameter controller: A Textual "Log Controller" for the view we want to insert the inline media
    - parameter line:       The unique identifier of the line we want to insert the inline media into
    
    - returns: An instance of a Webpage object
    */
    init(data: Data, response: HTTPURLResponse, controller: TVCLogController, line: String) {
        self.data = data
        self.response = response
        self.controller = controller
        self.line = line
        super.init()
    }
    
    /**
    Display the inline media in Textual
    */
    func start() {
        /* ObjectiveGumbo has no gracefully error handling for failure to decode data, so we will validate the data beforehand. */
        guard NSString(data: data, encoding: String.Encoding.utf8.rawValue) != nil else {
            return
        }
        
        /* Create an HTML parser object of the website using ObjectiveGumbo. */
        if let node = ObjectiveGumbo.parseDocument(with: data, encoding: String.Encoding.utf8.rawValue) {
            /* Attempt to retrieve the website title, if it cannot be located, we will not bother continuing. */
            let titleElements = node.elements(with: GUMBO_TAG_TITLE)
            if titleElements?.count > 0 {
                let title = titleElements?[0].text
                var description: String? = nil
                var previewImageUrl: String? = nil
                
                /* Attempt to retrieve the webpage description, and the og:image website thumbnail. */
                let metaElements = node.elements(with: GUMBO_TAG_META)
                for element in metaElements! {
                    if (element.attributes["name"]?.lowercased == "description") || element.attributes["property"]?.lowercased == "og:description" {
                        if let descriptionText = element.attributes["content"] as? String {
                            if descriptionText.characters.count > 0 {
                                description = descriptionText
                            }
                            
                            if description != nil && previewImageUrl != nil {
                                break
                            }
                        }
                    } else if element.attributes["property"]?.lowercased == "og:image" {
                        if let previewImageUrlTag = element.attributes["content"] as? String {
                            if previewImageUrlTag.characters.count > 0 {
                                previewImageUrl = previewImageUrlTag
                            }
                            
                            if description != nil && previewImageUrl != nil {
                                break
                            }
                        }
                    }
                }
                
                /* For websites that does not offer a description in any way we will desperately try to grab the first paragraph on the page */
                let paragraphs = node.elements(with: GUMBO_TAG_P)
                for paragraph in paragraphs! {
                    if paragraph.text != nil {
                        let descriptionText = paragraph.text!.trim()
                        if descriptionText.characters.count > 0 {
                            description = descriptionText
                            break
                        }
                    }
                }
                
                /* The og:image may be specified as a relative URL, if so, we will attemp to use NSURLs relativeToUrl feature to resolve the absolute path to this image file. */
                if previewImageUrl != nil {
                    if previewImageUrl!.hasPrefix("data:image/") == false && previewImageUrl!.hasPrefix("http://") == false && previewImageUrl!.hasPrefix("https://") == false {
                        if let resolvedRelativeUrl = URL(string: previewImageUrl!, relativeTo: response.url!) {
                            previewImageUrl = resolvedRelativeUrl.absoluteString
                        }
                    }
                }
                
                self.performBlock(onMainThread: {
                    let webView = self.controller.backingView
                    
                    /*  Because executeCommand is written in Objective C and takes a null terminated NSArray it is not possible to give it a nil, therefor we must force convert any nil values to NSNull, an Objective C object usde to represent nil in arrays */
                    let descriptionOrNull = description != nil ? description! : NSNull()
                    let imageOrNull = previewImageUrl != nil ? previewImageUrl! : NSNull()
                    
                    let args: [AnyObject] = [self.line, self.response.url!.absoluteString!, title!!, descriptionOrNull, imageOrNull]
                    
                    webView!.evaluateFunction("InlineMedia.Webpage.insert", withArguments: args)
                })
            }
        }
    }
}
