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

class YouTube: NSObject, InlineMediaHandler {
    required convenience init(url: NSURL, controller: TVCLogController, line: String) {
        self.init()
        var videoID = ""
        
        /* Retrieve the video id of this video. If this is a youtube.com link, extract it from the "v" query parameter. If it is a youtu.be link, extract it from the path. */
        if url.host?.hasSuffix("youtube.com") == true {
            if url.path?.hasPrefix("/watch") == true {
                if let queries = url.query?.componentsSeparatedByString("&") {
                    for query in queries {
                        let components = query.componentsSeparatedByString("=")
                        guard components.count > 1 else {
                            continue
                        }
                        if components[0] == "v" {
                            videoID = components[1]
                            break
                        }
                    }
                }
            }
        } else if url.host?.hasSuffix("youtu.be") == true {
            if (url.path?.characters.count > 1) {
                let path = url.path!
                videoID = path[1..<path.characters.count]
            }
        }
        
        if videoID.characters.count > 0 {
            let requestUrl = NSURL(string: String(format: "https://www.googleapis.com/youtube/v3/videos?id=%@&part=snippet,contentDetails&key=AIzaSyDzFtmfVnm9-iGnmrpJeR-26rau1SGjq04", videoID))
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
                    if let items = root["items"] as? [AnyObject] {
                        guard items.count > 0 else {
                            return
                        }
                        
                        let item = items[0]
                        if let video = item["snippet"] as? Dictionary<String, AnyObject> {
                            /* Retrieve the video title. */
                            let title = video["title"] as! String
                            
                            /* Retrieve only the first paragraph of the description. */
                            let fullDescription = video["description"] as? String
                            let descriptionLines = fullDescription!.componentsSeparatedByString("\n")
                            let description = descriptionLines[0]
                            
                            /* Retrieve the thumbnail of the video. */
                            let thumbnails = video["thumbnails"] as! Dictionary<String, AnyObject>
                            let standardThumbnail = thumbnails["medium"] as! Dictionary<String, AnyObject>
                            let thumbnailUrl = standardThumbnail["url"] as! String
                            
                            /* Retrieve the length of the video */
                            let contentDetails = item["contentDetails"] as! Dictionary<String, AnyObject>
                            let timeInterval = NSTimeInterval(iso8601String: contentDetails["duration"] as! String)
                            let formatter = NSDateComponentsFormatter()
                            
                            formatter.allowedUnits = timeInterval >= 3600 ? [.Hour, .Minute, .Second] : [.Minute, .Second]
                            formatter.zeroFormattingBehavior = .Pad
                            let duration = formatter.stringFromTimeInterval(timeInterval!)
                            
                            self.performBlockOnMainThread({
                                let document = controller.webView.mainFrameDocument
                                
                                /* Create the container for the complete inline media item. */
                                let ytContainer = document.createElement("a")
                                ytContainer.setAttribute("href", value: url.absoluteString)
                                ytContainer.className = "inline_media_youtube"
                                
                                let thumbnailContainer = document.createElement("div")
                                thumbnailContainer.className = "inline_media_youtube_thumbnail"
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
                                infoContainer.className = "inline_media_youtube_info"
                                ytContainer.appendChild(infoContainer)
                                
                                /* Create the title */
                                let videoTitle = document.createElement("p")
                                videoTitle.className = "inline_media_youtube_title"
                                videoTitle.appendChild(document.createTextNode(title))
                                infoContainer.appendChild(videoTitle)
                                
                                /* Create the description */
                                let videoDescription = document.createElement("p")
                                videoDescription.className = "inline_media_youtube_desc"
                                videoDescription.appendChild(document.createTextNode(description))
                                infoContainer.appendChild(videoDescription)
                                
                                /* Insert the element into Textual's view. */
                                InlineMedia.insert(controller, line: line, node: ytContainer)
                            })
                        }
                    }
                } catch {
                    return
                }
            }).resume()
        }
    }
    
    static func matchesServiceSchema(url: NSURL, hasImageExtension: Bool) -> Bool {
        if url.host?.hasSuffix("youtube.com") == true {
            return url.path?.hasPrefix("/watch") == true
        } else if url.host?.hasSuffix("youtu.be") == true {
            return url.path?.characters.count > 1
        }
        return false
    }
}