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
        request.setValue("text/html", forHTTPHeaderField: "Content-Type")
        
        let session = NSURLSession.sharedSession()
        session.dataTaskWithRequest(request, completionHandler: {(data : NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let httpResponse = response as? NSHTTPURLResponse {
                guard httpResponse.allHeaderFields["Content-Type"]?.contains("text/html") == true && data != nil else {
                    return
                }
                
                guard NSString(data: data!, encoding: NSUTF8StringEncoding) != nil else {
                    return
                }
                
                if let node = ObjectiveGumbo.parseDocumentWithData(data, encoding: NSUTF8StringEncoding) {
                    let titleElements = node.elementsWithTag(GUMBO_TAG_TITLE)
                    if titleElements.count > 0 {
                        let title = titleElements[0].text
                        var description = ""
                        let descriptionElements = node.elementsWithTag(GUMBO_TAG_META)
                        for element in descriptionElements {
                            guard element.attributes["name"]?.lowercaseString == "description" else {
                                continue
                            }
                            
                            if let descriptionText = element.attributes["content"] as? String {
                                description = descriptionText
                                break
                            }
                        }
                        
                        self.performBlockOnMainThread({
                            let document = controller.webView.mainFrameDocument
                            
                            let infoContainer = document.createElement("div")
                            infoContainer.className = "inline_media_website_info"
                            
                            let titleElement = document.createElement("div")
                            titleElement.className = "inline_media_website_title"
                            titleElement.appendChild(document.createTextNode(title))
                            infoContainer.appendChild(titleElement)
                            
                            if (description.characters.count > 0) {
                                let descriptionElement = document.createElement("div")
                                descriptionElement.className = "inline_media_website_desc"
                                descriptionElement.appendChild(document.createTextNode(description))
                                infoContainer.appendChild(descriptionElement)
                            }
                            InlineMedia.insert(controller, line: line, node: infoContainer)
                        })
                    }
                }
            }
            
            
        }).resume()
    }
}