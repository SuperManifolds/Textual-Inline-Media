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

class Twitter: NSObject, InlineMediaHandler {
    required convenience init(url: NSURL, controller: TVCLogController, line: String) {
        self.init()
        if (url.pathComponents!.count > 3) {
            let tweetId = url.pathComponents![3]
            let requestUrl = NSURL(string: "https://api.twitter.com/1/statuses/oembed.json?id=\(tweetId)&omit_script=true&align=left&maxwidth=550")
            guard requestUrl != nil else {
                return
            }
            
            /* Rquest information about this tweet from the Twitter API. */
            let session = NSURLSession.sharedSession()
            session.dataTaskWithURL(requestUrl!, completionHandler: {(data : NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                guard data != nil else {
                    return
                }
                
                do {
                   /* Attempt to serialise the JSON results into a dictionary. */
                    let root = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                    if let tweetHTML = root["html"] as? String {
                        self.performBlockOnMainThread({
                            let document = controller.webView.mainFrameDocument
                            
                            let tweet = document.createElement("div")
                            tweet.className = "inline_media_twitter"
                            tweet.innerHTML = tweetHTML
                            
                            InlineMedia.insert(controller, line: line, node: tweet)
                            document.evaluateWebScript("twttr.widgets.load(document.getElementById('line-\(line)'))")
                        })
                    }
                } catch {
                    return
                }
            }).resume()
        }
    }
    
    static func matchesServiceSchema(url: NSURL, hasImageExtension: Bool) -> Bool {
        return url.host?.hasSuffix("twitter.com") == true && url.path?.lowercaseString.containsString("/status/") == true
    }
}