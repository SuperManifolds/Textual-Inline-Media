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

class YouTube: NSObject, InlineMediaHandler, InlineMediaPreferenceHandler {
    @IBOutlet var preferenceView: NSView!
    @IBOutlet weak var displayVideosInsteadOfPreview: NSButton!
    @IBOutlet weak var startVideoWithAudioPlaying: NSButton!
    @IBOutlet weak var displayVideoInPausedState: NSButton!
    
    static func name() -> String {
        return "YouTube"
    }
    
    static func icon() -> NSImage? {
        return NSImage.fromAssetCatalogue("YouTube")
    }
    
    func preferences() -> NSView? {
        return self.preferenceView
    }
    
    override func awakeFromNib() {
        let defaults = UserDefaults.standard()
        self.displayVideosInsteadOfPreview.state = defaults.integer(forKey: "youtubeDisplayVideoInsteadOfPreview")
        self.startVideoWithAudioPlaying.state = defaults.integer(forKey: "youtubeAutomaticallyPlayAudio")
        self.displayVideoInPausedState.state = defaults.integer(forKey: "youtubeDisplayVideoAsPaused")
        
        self.updateVideoEnabledCheckboxState()
    }
    
    required override init() {
        super.init()
        let defaultConfiguration: [String : AnyObject] = [
            "youtubeDisplayVideoInsteadOfPreview": 0,
            "youtubeAutomaticallyPlayAudio": 0,
            "youtubeDisplayVideoAsPaused": 1
        ]
        UserDefaults.standard().register(defaultConfiguration)
        
        Bundle(for: object_getClass(self)).loadNibNamed("YouTube", owner: self, topLevelObjects: nil)
    }
    
    required convenience init(url: URL, controller: TVCLogController, line: String) {
        self.init()
        var videoID = ""
        
        /* Retrieve the video id of this video. If this is a youtube.com link, extract it from the "v" query parameter. If it is a youtu.be link, extract it from the path. */
        if url.host?.hasSuffix("youtube.com") == true {
            if url.path?.hasPrefix("/watch") == true {
                if let queries = url.query?.components(separatedBy: "&") {
                    for query in queries {
                        let components = query.components(separatedBy: "=")
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
            if url.path?.characters.count > 1 {
                let path = url.path!
                videoID = path[1..<path.characters.count]
            }
        }
        
        if videoID.characters.count > 0 {
            let defaults = UserDefaults.standard()
            if Bool(defaults.integer(forKey: "youtubeDisplayVideoInsteadOfPreview")) {
                self.performBlock(onMainThread: {
                    let webView = controller.backingView
                    let autoplay = !Bool(defaults.integer(forKey: "youtubeDisplayVideoAsPaused"))
                    webView!.evaluateFunction("InlineMedia.YouTube.insertPlayer", withArguments: [line, url.absoluteString!, videoID, autoplay])
                })
            } else {
                let requestUrl = URL(string: "https://www.googleapis.com/youtube/v3/videos?id=\(videoID)&part=snippet,contentDetails,statistics&key=AIzaSyDzFtmfVnm9-iGnmrpJeR-26rau1SGjq04")
                guard requestUrl != nil else {
                    return
                }
                
                /* Rquest information about this video from the YouTube API. */
                let session = URLSession.shared()
                session.dataTask(with: requestUrl!, completionHandler: {(data: Data?, response: URLResponse?, error: NSError?) -> Void in
                    guard data != nil else {
                        return
                    }
                    
                    do {
                        /* Attempt to serialise the JSON results into a dictionary. */
                        let root = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                        if let items = root["items"] as? [AnyObject] {
                            guard items.count > 0 else {
                                return
                            }
                            
                            let item = items[0]
                            if let video = item["snippet"] as? Dictionary<String, AnyObject> {
                                /* Retrieve the video title. */
                                let title = video["title"] as? String
                                
                                /* Retrieve the author  */
                                let author = video["channelTitle"] as? String
                                
                                /* Retrieve the view count */
                                let statistics = item["statistics"] as? Dictionary<String, AnyObject>
                                let numberFormatter = NumberFormatter()
                                numberFormatter.numberStyle = .decimal
                                let unformattedViewCount = statistics!["viewCount"] as? String
                                let viewCount = numberFormatter.string(from: Int(unformattedViewCount!)!)
                                
                                /* Retrieve the thumbnail of the video. */
                                let thumbnails = video["thumbnails"] as? Dictionary<String, AnyObject>
                                let standardThumbnail = thumbnails!["medium"] as? Dictionary<String, AnyObject>
                                let thumbnailUrl = standardThumbnail!["url"] as? String
                                
                                /* Retrieve the length of the video */
                                let contentDetails = item["contentDetails"] as? Dictionary<String, AnyObject>
                                let durationString = contentDetails!["duration"] as? String
                                let timeInterval = TimeInterval(iso8601String: durationString!)
                                let formatter = DateComponentsFormatter()
                                
                                formatter.allowedUnits = timeInterval >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
                                formatter.zeroFormattingBehavior = .pad
                                let duration = formatter.string(from: timeInterval!)
                                
                                self.performBlock(onMainThread: {
                                    let webView = controller.backingView
                                    let videoInfo: Dictionary<String, String> = [
                                        "thumbnailUrl": thumbnailUrl!,
                                        "duration": duration!,
                                        "title": title!,
                                        "author": author!,
                                        "views": viewCount!
                                    ]
                                    webView!.evaluateFunction("InlineMedia.YouTube.insert", withArguments: [line, response!.url!.absoluteString!, videoInfo])
                                })
                            }
                        }
                    } catch {
                        return
                    }
                }).resume()
            }
        }
    }
    
    static func matchesServiceSchema(_ url: URL) -> Bool {
        if url.host?.hasSuffix("youtube.com") == true {
            return url.path?.hasPrefix("/watch") == true
        } else if url.host?.hasSuffix("youtu.be") == true {
            return url.path?.characters.count > 1
        }
        return false
    }
    
    func updateVideoEnabledCheckboxState() {
        let defaults = UserDefaults.standard()
        let inlineVideoEnabled = Bool(defaults.integer(forKey: "youtubeDisplayVideoInsteadOfPreview"))
        
        self.displayVideoInPausedState.isEnabled = inlineVideoEnabled
        self.startVideoWithAudioPlaying.isEnabled = inlineVideoEnabled
    }
    
    
    @IBAction func displayVideoInsteadOfPreviewChange(_ sender: NSButton) {
        let defaults = UserDefaults.standard()
        defaults.set(sender.state, forKey: "youtubeDisplayVideoInsteadOfPreview")
        defaults.synchronize()
        
        self.updateVideoEnabledCheckboxState()
    }
    
    
    @IBAction func displayVideoInPausedStateChange(_ sender: NSButton) {
        let defaults = UserDefaults.standard()
        defaults.set(sender.state, forKey: "youtubeDisplayVideoAsPaused")
        defaults.synchronize()
    }
    
    
    @IBAction func startVideoWithAudioPlayingChange(_ sender: NSButton) {
        let defaults = UserDefaults.standard()
        defaults.set(sender.state, forKey: "youtubeAutomaticallyPlayAudio")
        defaults.synchronize()
    }
}
