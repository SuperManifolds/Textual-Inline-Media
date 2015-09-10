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

class InlineMedia: NSObject, THOPluginProtocol, TVCImageURLoaderDelegate {
    let imageFileExtensions = ["bmp", "gif", "jpg", "jpeg", "jp2", "j2k", "jpf", "jpx", "jpm", "mj2", "png", "svg", "tiff", "tif"]
    let inlineMediaMessageTypes = [TVCLogLineType.ActionType, TVCLogLineType.PrivateMessageType, TVCLogLineType.NoticeType]
    let mediaHandlers = [Twitter.self, YouTube.self, Wikipedia.self]
    
    func pluginLoadedIntoMemory() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "logControllerViewFinishedLoading:", name: TVCLogControllerViewFinishedLoadingNotification, object: nil)
    }
    
    /**
    Called by the Textual plugin API when a new line has been added to the view.
    
    :param: messageObject An object containing all message information related to this line.
    :param: logController The Textual "Log Controller" responsible for the event.
    */
    func didPostNewMessage(messageObject: THOPluginDidPostNewMessageConcreteObject!, forViewController logController: TVCLogController!) {
        guard !messageObject.isProcessedInBulk && inlineMediaMessageTypes.contains(messageObject.lineType) else {
            return
        }
        
        let linkScanner = AHHyperlinkScanner.init()
        let links = linkScanner.strictMatchesForString(messageObject.messageContents)
        
        var linkPriorityDict = Dictionary<String, [NSURL]>()
        var sortedLinks: [NSURL] = []
        for result in links {
            let rawLink = result[1] as! String
            
            /* NSURL is stupid and cannot comprehend unicode in domains, so we will use this method provided by Textual to convert it to "punycode" */
            if var link = NSString(string: rawLink).URLUsingWebKitPasteboard {
                guard link.scheme.hasPrefix("http") else {
                    continue
                }
                
                /* Replace Reddit shortlinks */
                if link.host!.hasSuffix("redd.it") {
                    link = NSURL(string: String(format: "%@://www.reddit.com/tb%@", link.scheme, link.path!))!
                }
                
                /* Organise links into a dictionary by what domain they are from. */
                if (!linkPriorityDict.keys.contains(link.host!)) {
                    linkPriorityDict[link.host!] = []
                }
                linkPriorityDict[link.host!]?.append(link)
            }
        }
        
        /* Prioritise links from the same domain by the number of path components. This will favour  a link to a subpage over a generic index page link and so on. */
        for domain in linkPriorityDict {
            let sorted = domain.1.sort {
                /* Terrible workaround to give subreddit links a low priority. */
                if ($1.pathComponents?.count > 2) {
                    if ($1.pathComponents![1] == "r") {
                        return true
                    }
                }
                return $0.pathComponents?.count > $1.pathComponents?.count
            }
            sortedLinks.append(sorted[0])
        }
        
        for url in sortedLinks {
            var isDirectImageLink = false
            
            /* Check if the url is a direct link to an image with a valid image file extension. */
            if let fileExtension = url.pathExtension {
                isDirectImageLink = imageFileExtensions.contains(fileExtension.lowercaseString)
                
                /* Check if this is a link to a gif. */
                if (fileExtension.lowercaseString == "gif") {
                    self.performBlockOnMainThread({
                        GifConversion.displayLoopingAnimation(url, controller: logController, line: messageObject.lineNumber)
                        return
                    })
                } else if (isDirectImageLink) {
                    return
                }
            }
            
            /* Iterate over the available media handlers and see if we have one that supports this url. */
            for mediaHandlerType in mediaHandlers {
                if let mediaHandler = mediaHandlerType as? InlineMediaHandler.Type {
                    if (mediaHandler.matchesServiceSchema(url, hasImageExtension: isDirectImageLink)) {
                        mediaHandler.init(url: url, controller: logController, line: messageObject.lineNumber)
                        return
                    }
                }
            }
            
            /* There were no media handlers for this url, we will attempt to retrieve the title, description, and preview thumbnail of the webpage instead. */
            WebpageHandler.displayInformation(url, controller: logController, line: messageObject.lineNumber)
        }
    }
    
    /**
    Called when a web view has been loaded in Textual. Is used to load any static resources into the webview necessary for plugin features.
    
    :param notification an NSNotification object containing the Log Controller that for the webview that has loaded.
    */
    func logControllerViewFinishedLoading(notification: NSNotification) {
        self.performBlockOnMainThread({
            if let controller = notification.object as? TVCLogController {
                let document = controller.webView.mainFrameDocument
                let head = document.getElementsByTagName("head").item(0)
                
                let mainBundle = NSBundle(forClass: InlineMedia.self)
                let stylesheetPath = mainBundle.pathForResource("style", ofType: "css")
                let scriptPath = mainBundle.pathForResource("media", ofType: "js")
                
                let stylesheet = document.createElement("link")
                stylesheet.setAttribute("rel", value: "stylesheet")
                stylesheet.setAttribute("type", value: "text/css")
                stylesheet.setAttribute("href", value: stylesheetPath)
                
                let script = document.createElement("script")
                script.setAttribute("type", value: "application/ecmascript")
                script.setAttribute("src", value: scriptPath)
                
                let twitterTheme = document.createElement("meta")
                twitterTheme.setAttribute("name", value: "twitter:widgets:theme")
                twitterTheme.setAttribute("content", value: "dark")
                
                head.appendChild(stylesheet)
                head.appendChild(script)
                head.appendChild(twitterTheme)
            }
        })
    }
    
    /**
    Inserts any HTML DOM Node as an inline media item in a message.
    
    :param: controller The Textual "Log Controller" responsible for the view we want to insert the media into.
    :param: line       The unique ID for the line we wish to modify.
    :param: node       The HTML DOM Node to insert.
    */
    static func insert(controller: TVCLogController, line: String, node: DOMNode) {
        let document = controller.webView.mainFrameDocument
        if let line = document.getElementById("line-" + line) {
            let message = line.querySelector(".innerMessage")
            
            let mediaContainer = document.createElement("span")
            mediaContainer.className = "inlineMediaCell"
            
            mediaContainer.appendChild(node)
            message.appendChild(mediaContainer)
        }
    }
    
    
    /**
    Converts a Unicode link to it's ASCII representation.
    
    :param: unicodeLink The original link to process.
    
    :returns: A string containing a link with any unicode characters converted to ASCII representations or "punycode"
    */
    func convertToAsciiUrl(unicodeLink: String) -> NSURL {
        let pasteboard = NSPasteboard.pasteboardWithUniqueName()
        pasteboard.stringContent = unicodeLink
        
        var asciiLink = WebView.URLFromPasteboard(pasteboard)
        if (asciiLink == nil) {
            asciiLink = NSURL(string: unicodeLink)
        }
        return asciiLink
    }
    
    
    /**
    Create an inline image from a link.
    
    :param: controller The Textual "Log Controller" for the view we want to insert the media into.
    :param: source     The source link for the image to display.
    
    :returns: An HTML DOM Node containing the inline image element.
    */
    static func inlineImage(controller: TVCLogController, source: String) -> DOMNode {
        return InlineMedia.inlineImage(controller, source: source, link: source)
    }
    
    
    /**
    Creates an inline image from a link.
    
    :param: controller The Textual "Log Controller" for the view we want to insert the media into.
    :param: source     The source link for the image to display.
    :param: link       The link to open when the user interacts with the image.
    
    :returns: An HTML DOM Node containing the inline image element.
    */
    static func inlineImage(controller: TVCLogController, source: String, link: String) -> DOMNode {
        let document = controller.webView.mainFrameDocument
        
        let imageLink = document.createElement("a")
        imageLink.setAttribute("href", value: link)
        
        let image = document.createElement("img")
        image.setAttribute("src", value: link)
        
        imageLink.appendChild(image)
        return imageLink
    }
    
    /**
    Creates an inline video from a link
    
    :param: controller The Textual "Log Controller" for the view we want to insert the media into.
    :param: source     The source link for the video to display.
    :param: loop       Whether this video should be continously looped.
    :param: autoPlay   Whether this video should start playing automatically.
    
    :returns: An HTML DOM Node containing the video element.
    */
    static func inlineVideo(controller: TVCLogController, source: String, loop: Bool, autoPlay: Bool) -> DOMNode {
        let document = controller.webView.mainFrameDocument
        
        /* Create the video tag  */
        let video = document.createElement("video")
        video.setAttribute("loop", value: loop.description)
        video.setAttribute("autoplay", value: autoPlay.description)
        
        /* Set the event listener to start/pause it when the user clicks it. */
        let listener = EventListener()
        video.addEventListener("click", listener: listener, useCapture: false)
        
        /* Set the source of the video */
        let videoSource = document.createElement("source")
        videoSource.setAttribute("type", value: "video/mp4")
        videoSource.setAttribute("src", value: source)
        video.appendChild(videoSource)
        return video
    }
    
    func isNotSafeToPresentImageWithID(uniqueID: String!) {
        
    }
    
    func isSafeToPresentImageWithID(uniqueID: String!) {
        
    }
}