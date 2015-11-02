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

class Wikipedia: NSObject, InlineMediaHandler {
    static func name() -> String {
        return "Wikipedia"
    }
    
    required convenience init(url: NSURL, controller: TVCLogController, line: String) {
        self.init()
        if let query = url.pathComponents?[2] {
            let requestString = "format=json&action=query&exsentences=4&prop=extracts|pageimages&titles=\(query)&pithumbsize=200"
                .stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
            
            let subdomain = url.host?.componentsSeparatedByString(".")[0]
            guard subdomain != nil else {
                return
            }
            
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            config.HTTPAdditionalHeaders = ["User-Agent": "TextualInlineMedia/1.0 (https://github.com/xlexi/Textual-Inline-Media/; alex@sorlie.co.uk)"]
            
            let session = NSURLSession(configuration: config)
            if let requestUrl = NSURL(string: "https://\(subdomain!).wikipedia.org/w/api.php?\(requestString)") {
                session.dataTaskWithURL(requestUrl, completionHandler: {(data : NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                    guard data != nil else {
                        return
                    }
                    
                    do {
                        /* Attempt to serialise the JSON results into a dictionary. */
                        let root = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                        let query = root["query"] as! Dictionary<String, AnyObject>
                        let pages = query["pages"] as! Dictionary<String, AnyObject>
                        let page = pages.first!
                        if (page.0 != "-1") {
                            let article = page.1 as! Dictionary<String, AnyObject>
                            let title = article["title"] as! String
                            let description = article["extract"] as! String
                            
                            var thumbnailUrl = ""
                            if let thumbnail = article["thumbnail"] as? Dictionary<String, AnyObject> {
                                thumbnailUrl = thumbnail["source"] as! String
                            }
                            
                            self.performBlockOnMainThread({
                                let document = controller.webView.mainFrameDocument
                                
                                /* Create the container for the entire inline media element. */
                                let wikiContainer = document.createElement("a")
                                wikiContainer.setAttribute("href", value: url.absoluteString)
                                wikiContainer.className = "inline_media_wiki"
                                
                                /* If we found a preview image element, we will add it. */
                                if (thumbnailUrl.characters.count > 0) {
                                    let previewImage = document.createElement("img")
                                    previewImage.className = "inline_media_wiki_thumbnail"
                                    previewImage.setAttribute("src", value: thumbnailUrl)
                                    wikiContainer.appendChild(previewImage)
                                }
                                
                                /* Create the container that holds the title and description. */
                                let infoContainer = document.createElement("div")
                                infoContainer.className = "inline_media_wiki_info"
                                wikiContainer.appendChild(infoContainer)
                                
                                /* Create the title element */
                                let titleElement = document.createElement("div")
                                titleElement.className = "inline_media_wiki_title"
                                titleElement.appendChild(document.createTextNode(title))
                                infoContainer.appendChild(titleElement)
                                
                                /* If we found a description, create the description element. */
                                if (description.characters.count > 0) {
                                    let descriptionElement = document.createElement("div")
                                    descriptionElement.className = "inline_media_wiki_desc"
                                    descriptionElement.innerHTML = description
                                    infoContainer.appendChild(descriptionElement)
                                }
                                controller.insertInlineMedia(line, node: wikiContainer, url: url.absoluteString)
                            })
                        }
                    } catch {
                        return
                    }
                }).resume()
            }
        }
    }
    
    static func matchesServiceSchema(url: NSURL, hasImageExtension: Bool) -> Bool {
        if url.host?.hasSuffix(".wikipedia.org") == true && url.pathComponents?.count === 3 {
            return url.pathComponents![1] == "wiki"
        }
        return false
    }
}