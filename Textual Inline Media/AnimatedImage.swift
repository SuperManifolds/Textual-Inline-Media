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

class AnimatedImage: NSObject {
    static func create(_ controller: TVCLogController, url: URL, line: String) {
        /* Create a request to the gfycat API to convert this gif into a video file. */
        let requestString = url.absoluteString?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!
        let requestUrl = URL(string: "http://upload.gfycat.com/transcode?fetchUrl=\(requestString)")
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
                if let videoUrl = root["mp4Url"] as? String {
                    self.performBlock(onMainThread: {
                        /* Create the video tag and set it to automatically play, and loop continously. */
                        //let video = controller.createInlineVideo(videoUrl, loop: true, autoPlay: true)
                        
                        /* Insert the element into Textual's view. */
                    })
                } else {
                    /* The image conversation was unsuccessful, this is most likely not an animated gif, we will fall back to displaying the normal image. */
                    self.performBlock(onMainThread: {
                        let document = controller.backingView
                        /*
                        if let line = document.getElementById("line-" + line) {
                            if let imageLink = line.querySelector(".inlineImageCell a[href='\(url.absoluteString)']") {
                                let imageId = imageLink.parentElement.getAttribute("id")
                                if let eventSink = controller.valueForKey("webViewScriptSink") as? TVCLogScriptEventSink {
                                    eventSink.toggleInlineImage(imageId)
                                }
                            }
                        }*/
                    })
                }
            } catch {
                return
            }
        }).resume()
    }
}
