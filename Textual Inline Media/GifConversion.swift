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

class GifConversion: NSObject {
    static func displayLoopingAnimation(url: NSURL, controller: TVCLogController, line: String) {
        if url.host!.hasSuffix("imgur.com") {
            /* Imgur already has video versions of gifs so we will not need to convert these, we will just change the extension to .mp4 and make it a video element. */
            let imgurVideoUrl = "\(url.URLByDeletingPathExtension!).mp4"
            let video = InlineMedia.inlineVideo(controller, source: imgurVideoUrl, loop: true, autoPlay: true)
            
            /* Insert the element into Textual's view. */
            InlineMedia.insert(controller, line: line, node: video)
        } else {
            /* Create a request to the gfycat API to convert this gif into a video file. */
            let requestString = url.absoluteString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
            let requestUrl = NSURL(string: "http://upload.gfycat.com/transcode?fetchUrl=\(requestString)")
            guard requestUrl != nil else {
                return
            }
            
            let session = NSURLSession.sharedSession()
            session.dataTaskWithURL(requestUrl!, completionHandler: {(data : NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                guard data != nil else {
                    return
                }
                
                do {
                    /* Attempt to serialise the JSON results into a dictionary. */
                    let root = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                    if let videoUrl = root["mp4Url"] as? String {
                        self.performBlockOnMainThread({
                            /* Create the video tag and set it to automatically play, and loop continously. */
                            let video = InlineMedia.inlineVideo(controller, source: videoUrl, loop: true, autoPlay: true)
                            
                            /* Insert the element into Textual's view. */
                            InlineMedia.insert(controller, line: line, node: video)
                        })
                    }
                } catch {
                    return
                }
            }).resume()
        }
        
        
    }
}