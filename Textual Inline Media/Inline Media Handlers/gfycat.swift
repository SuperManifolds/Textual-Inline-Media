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

class Gfycat: NSObject, InlineMediaHandler {
    static func name() -> String {
        return "Gfycat"
    }
    
    static func icon() -> NSImage? {
        return NSImage.fromAssetCatalogue("gfycat")
    }
    
    required convenience init(url: URL, controller: TVCLogController, line: String) {
        self.init()
        /* Create a request to the gfycat API to find the mp4 version of this link.  */
        if let requestString = try! url.deletingPathExtension().pathComponents?[1] {
            let requestUrl = URL(string: "http://gfycat.com/cajax/get/\(requestString)")
            guard requestUrl != nil else {
                return
            }
            
            let session = URLSession.shared()
            session.dataTask(with: requestUrl!, completionHandler: {(data: Data?, response: URLResponse?, error: NSError?) -> Void in
                guard data != nil else {
                    return
                }
                
                do {
                    /* Attempt to serialise the JSON results into a dictionary. */
                    let root = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                    if let gfyItem = root["gfyItem"] as? Dictionary<String, AnyObject> {
                        if let videoUrl = gfyItem["mp4Url"] as? String {
                            self.performBlock(onMainThread: {
                                /* Create the video tag and set it to automatically play, and loop continously. */
                                //let video = controller.createInlineVideo(videoUrl, loop: true, autoPlay: true)
                                
                                /* Insert the element into Textual's view. */
                            })
                        }
                    }
                } catch {
                    return
                }
            }).resume()
        }
    }
    
    static func matchesServiceSchema(_ url: URL) -> Bool {
        return url.host?.hasSuffix("gfycat.com") == true
    }
}
