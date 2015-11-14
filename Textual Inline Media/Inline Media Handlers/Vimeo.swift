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

class Vimeo: NSObject, InlineMediaHandler {
    static func name() -> String {
        return "Vimeo"
    }
    
    required convenience init(url: NSURL, controller: TVCLogController, line: String) {
        self.init()
        
        /* Retrieve the video id of this video.  */
        if let videoID = url.pathComponents?[1] {
            let requestUrl = NSURL(string: "https://vimeo.com/api/oembed.json?url=https%3A//vimeo.com/\(videoID)")
            guard requestUrl != nil else {
                return
            }
            
            
            /* Rquest information about this video from the YouTube API. */
            let session = NSURLSession.sharedSession()
            session.dataTaskWithURL(requestUrl!, completionHandler: {(data : NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                guard data != nil else {
                    return
                }
                
                do {
                    /* Attempt to serialise the JSON results into a dictionary. */
                    let root = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                    if let title = root["title"] as? String {
                        
                        /* Retrieve the author  */
                        let author = root["author_name"] as! String
                        
                        /* Retrieve the first line of the video description */
                        let fullDescription = root["description"] as! String
                        let descriptionLines = fullDescription.componentsSeparatedByString("\n")
                        let description = descriptionLines[0]
                        
                        /* Retrieve the thumbnail of the video. */
                        let thumbnailUrl = root["thumbnail_url"] as! String
                        
                        /* Retrieve the length of the video */
                        let timeInterval = NSTimeInterval(root["duration"] as! Int)
                        let formatter = NSDateComponentsFormatter()
                        
                        formatter.allowedUnits = timeInterval >= 3600 ? [.Hour, .Minute, .Second] : [.Minute, .Second]
                        formatter.zeroFormattingBehavior = .Pad
                        let duration = formatter.stringFromTimeInterval(timeInterval)
                        
                        self.performBlockOnMainThread({
                            let document = controller.webView.mainFrameDocument
                            
                            /* Create the container for the complete inline media item. */
                            let ytContainer = document.createElement("a")
                            ytContainer.setAttribute("href", value: url.absoluteString)
                            ytContainer.className = "inline_media_vimeo"
                            
                            let thumbnailContainer = document.createElement("div")
                            thumbnailContainer.className = "inline_media_vimeo_thumbnail"
                            ytContainer.appendChild(thumbnailContainer)
                            
                            /* Create the thumbnail image. */
                            let thumbnailImage = document.createElement("img")
                            thumbnailImage.setAttribute("src", value: thumbnailUrl)
                            thumbnailContainer.appendChild(thumbnailImage)
                            
                            /* Include the video length inside the thumbnail */
                            let videoLength = document.createElement("span")
                            videoLength.appendChild(document.createTextNode(duration))
                            thumbnailContainer.appendChild(videoLength)
                            
                            /* Create the container that holds the title and description. */
                            let infoContainer = document.createElement("div")
                            infoContainer.className = "inline_media_vimeo_info"
                            ytContainer.appendChild(infoContainer)
                            
                            /* Create the title */
                            let videoTitle = document.createElement("p")
                            videoTitle.className = "inline_media_vimeo_title"
                            videoTitle.appendChild(document.createTextNode(title))
                            infoContainer.appendChild(videoTitle)
                            
                            /* Create the author  */
                            let videoAuthor = document.createElement("p")
                            videoAuthor.className = "inline_media_vimeo_author"
                            videoAuthor.appendChild(document.createTextNode("by " + author))
                            infoContainer.appendChild(videoAuthor)
                            
                            /* Create the video description */
                            let videoDescription = document.createElement("p")
                            videoDescription.className = "inline_media_vimeo_desc"
                            videoDescription.textContent = description
                            infoContainer.appendChild(videoDescription)
                            
                            /* Insert the element into Textual's view. */
                            controller.insertInlineMedia(line, node: ytContainer, url: url.absoluteString)
                        })
                    }
                } catch {
                    return
                }
            }).resume()
        }
    }
    
    static func matchesServiceSchema(url: NSURL) -> Bool {
        return url.host?.hasSuffix("vimeo.com") == true  && url.path?.characters.count > 5
    }
}