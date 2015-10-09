//
//  gfycat.swift
//  Textual Inline Media
//
//  Created by Alex S. Glomsaas on 2015-10-10.
//  Copyright © 2015 Alex S. Glomsaas. All rights reserved.
//

import Foundation

class gfycat: NSObject, InlineMediaHandler {
    static func name() -> String {
        return "Gfycat"
    }
    
    required convenience init(url: NSURL, controller: TVCLogController, line: String) {
        self.init()
        /* Create a request to the gfycat API to find the mp4 version of this link.  */
        if let requestString = url.URLByDeletingPathExtension?.pathComponents?[1] {
            NSLog(requestString)
            let requestUrl = NSURL(string: "http://gfycat.com/cajax/get/\(requestString)")
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
                    if let gfyItem = root["gfyItem"] as? Dictionary<String, AnyObject> {
                        if let videoUrl = gfyItem["mp4Url"] as? String {
                            self.performBlockOnMainThread({
                                /* Create the video tag and set it to automatically play, and loop continously. */
                                let video = InlineMedia.inlineVideo(controller, source: videoUrl, loop: true, autoPlay: true)
                                
                                /* Insert the element into Textual's view. */
                                InlineMedia.insert(controller, line: line, node: video, url: url.absoluteString)
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
        return url.host?.hasSuffix("gfycat.com") == true
    }
}