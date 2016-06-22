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

class Xkcd: NSObject, InlineMediaHandler {
    static func name() -> String {
        return "xkcd"
    }
    
    static func icon() -> NSImage? {
        return NSImage.fromAssetCatalogue("xkcd")
    }
    
    required convenience init(url: URL, controller: TVCLogController, line: String) {
        self.init()
        var request = URLRequest(url: url)
        
        /* Inform the server that we only accept HTML documents, it should reject our connection otherwise. */
        request.setValue("text/html", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared()
        session.dataTask(with: request, completionHandler: {(data: Data?, response: URLResponse?, error: NSError?) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                /* Validate that the server obeyed our request to only receive HTML, abort if otherwise. */
                let contentType = httpResponse.allHeaderFields["Content-Type"] as? String
                guard contentType?.contains("text/html") == true && data != nil else {
                    return
                }
                
                /* ObjectiveGumbo has no gracefully error handling for failure to decode data, so we will validate the data beforehand. */
                guard NSString(data: data!, encoding: String.Encoding.utf8.rawValue) != nil else {
                    return
                }
                
                /* Create an HTML parser object of the website using ObjectiveGumbo. */
                if let node = ObjectiveGumbo.parseDocument(with: data, encoding: String.Encoding.utf8.rawValue) {
                    if let comicContainer = node.elements(withID: "comic").first as? OGElement {
                        guard let comic = comicContainer.elements(with: GUMBO_TAG_IMG).first as? OGElement else {
                            return
                        }
                        
                        /* Retrieve the image source and alternate text */
                        let comicUrl = comic.attributes["src"] as? String
                        let comicAlt = comic.attributes["title"] as? String
                        
                        /* Retrieve the image title */
                        let comicTitle = node.elements(withID: "ctitle").first as? OGElement
                        let comicTitleText = comicTitle!.text()
                        
                        
                        self.performBlock(onMainThread: {
                            let webView = controller.backingView
                            webView!.evaluateFunction("InlineMedia.xkcd.insert", withArguments: [line, response!.url!.absoluteString!, comicTitleText!, comicUrl!, comicAlt!])
                        })
                    }
                    
                }
            }
        }).resume()
    }
    
    static func matchesServiceSchema(_ url: URL) -> Bool {
        return url.host!.hasSuffix("xkcd.com")
    }
}
