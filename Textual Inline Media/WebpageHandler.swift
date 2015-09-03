/*
Copyright (c) 2015, Alex S. Glomsaas
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

class WebpageHandler: NSObject {
        static func displayInformation(url: NSURL, controller: TVCLogController, line: String) {
        let request = NSMutableURLRequest(URL: url)
            
        /* Inform the server that we only accept HTML documents, it should reject our connection otherwise. */
        request.setValue("text/html", forHTTPHeaderField: "Content-Type")
        
        let session = NSURLSession.sharedSession()
        session.dataTaskWithRequest(request, completionHandler: {(data : NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let httpResponse = response as? NSHTTPURLResponse {
                /* Validate that the server obeyed our request to only receive HTML, abort if otherwise. */
                guard httpResponse.allHeaderFields["Content-Type"]?.contains("text/html") == true && data != nil else {
                    return
                }
                
                /* ObjectiveGumbo has no gracefully error handling for failure to decode data, so we will validate the data beforehand. */
                guard NSString(data: data!, encoding: NSUTF8StringEncoding) != nil else {
                    return
                }
                
                /* Create an HTML parser object of the website using ObjectiveGumbo. */
                if let node = ObjectiveGumbo.parseDocumentWithData(data, encoding: NSUTF8StringEncoding) {
                    /* Attempt to retrieve the website title, if it cannot be located, we will not bother continuing. */
                    let titleElements = node.elementsWithTag(GUMBO_TAG_TITLE)
                    if titleElements.count > 0 {
                        let title = titleElements[0].text
                        var description = ""
                        var previewImageUrl = ""
                        
                        /* Attempt to retrieve the webpage description, and the og:image website thumbnail. */
                        let metaElements = node.elementsWithTag(GUMBO_TAG_META)
                        for element in metaElements {
                            if (element.attributes["name"]?.lowercaseString == "description") {
                                if let descriptionText = element.attributes["content"] as? String {
                                    description = descriptionText
                                    if (description.characters.count > 0 && previewImageUrl.characters.count > 0) {
                                        break
                                    }
                                }
                            } else if (element.attributes["property"]?.lowercaseString == "og:image") {
                                if let previewImageUrlTag = element.attributes["content"] as? String {
                                    previewImageUrl = previewImageUrlTag
                                    if (description.characters.count > 0 && previewImageUrl.characters.count > 0) {
                                        break
                                    }
                                }
                            }
                        }
                        
                        /* The og:image may be specified as a relative URL, if so, we will attemp to use NSURLs relativeToUrl feature to resolve the absolute path to this image file. */
                        if (previewImageUrl.characters.count > 0) {
                            if previewImageUrl.hasPrefix("data:image/") == false && previewImageUrl.hasPrefix("http://") == false && previewImageUrl.hasPrefix("https://") == false {
                                if let resolvedRelativeUrl = NSURL(string: previewImageUrl, relativeToURL: url) {
                                    previewImageUrl = resolvedRelativeUrl.absoluteString
                                }
                            }
                        }
                        
                        self.performBlockOnMainThread({
                            let document = controller.webView.mainFrameDocument
                            
                            /* Create the container for the entire inline media element. */
                            let websiteContainer = document.createElement("div")
                            websiteContainer.className = "inline_media_website"
                            
                            /* If we found a preview image element, we will add it. */
                            if (previewImageUrl.characters.count > 0) {
                                let previewImage = document.createElement("img")
                                previewImage.className = "inline_media_website_thumbnail"
                                previewImage.setAttribute("src", value: previewImageUrl)
                                websiteContainer.appendChild(previewImage)
                            }
                            
                            /* Create the container that holds the title and description. */
                            let infoContainer = document.createElement("div")
                            infoContainer.className = "inline_media_website_info"
                            websiteContainer.appendChild(infoContainer)
                            
                            /* Create the title element */
                            let titleElement = document.createElement("div")
                            titleElement.className = "inline_media_website_title"
                            titleElement.appendChild(document.createTextNode(title))
                            infoContainer.appendChild(titleElement)
                            
                            /* If we found a description, create the description element. */
                            if (description.characters.count > 0) {
                                let descriptionElement = document.createElement("div")
                                descriptionElement.className = "inline_media_website_desc"
                                descriptionElement.appendChild(document.createTextNode(description))
                                infoContainer.appendChild(descriptionElement)
                            }
                            InlineMedia.insert(controller, line: line, node: websiteContainer)
                        })
                    }
                }
            }
            
            
        }).resume()
    }
}