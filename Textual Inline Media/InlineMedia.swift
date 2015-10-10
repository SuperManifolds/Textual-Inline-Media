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
import Sparkle

class InlineMedia: NSObject, THOPluginProtocol, SUUpdaterDelegate, TVCImageURLoaderDelegate {
    let imageFileExtensions = ["bmp", "gif", "jpg", "jpeg", "jp2", "j2k", "jpf", "jpx", "jpm", "mj2", "png", "svg", "tiff", "tif"]
    let inlineMediaMessageTypes = [TVCLogLineType.ActionType, TVCLogLineType.PrivateMessageType]
    static let mediaHandlers = [Twitter.self, YouTube.self, Wikipedia.self, xkcd.self, gfycat.self, imdb.self]
    var previouslyDisplayedLinks: [String] = []
    
    var preferencesView: NSView!
    var preferences: Preferences!
    
    var pluginPreferencesPaneMenuItemName: String {
        return "Inline Media"
    }
    
    var pluginPreferencesPaneView: NSView? {
        return preferencesView
    }
    
    /**
    Called when the plugin has been loaded into memory.
    */
    func pluginLoadedIntoMemory() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "logControllerViewFinishedLoading:", name: TVCLogControllerViewFinishedLoadingNotification, object: nil)
        
        let updater = SUUpdater(forBundle: NSBundle(forClass: object_getClass(self)))
        updater.delegate = self
        updater.resetUpdateCycle()
        updater.checkForUpdatesInBackground()
        
        let defaults: [String : AnyObject] = [
            "displayInformationForDuplicates": 1,
            "maximumPreviewsPerMessage": 10,
            "displayAnimatedImages": 1,
            "AutomaticallyConvertGifs": 1
        ]
        NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
        
        preferences = Preferences()
        NSBundle(forClass: object_getClass(self)).loadNibNamed("Preferences", owner: preferences, topLevelObjects: nil)
        self.preferencesView = preferences.preferences
        
        #if TEXTUAL_BUILT_INSIDE_SANDBOX
            let alert = NSAlert()
            alert.messageText = "Textual Inline Media Plugin"
            alert.addButtonWithTitle("OK")
            alert.informativeText = "This plugin will not work correctly because it is not compatible with your version of Textual"
            alert.runModal()
        #endif
    }
    
    func pathToRelaunchForUpdater(updater: SUUpdater!) -> String! {
        return NSBundle.mainBundle().bundlePath
    }
    
    func updater(updater: SUUpdater!, didFindValidUpdate item: SUAppcastItem!) {
        let updateNotification = NSUserNotification()
        updateNotification.title = "Textual Plugin Update Found"
        updateNotification.informativeText = "An update to Textual Inline Media Plugin was found."
        updateNotification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(updateNotification)
    }
    
    /**
    Called by the Textual plugin API when a new line has been added to the view.
    
    - parameter messageObject: An object containing all message information related to this line.
    - parameter logController: The Textual "Log Controller" responsible for the event.
    */
    func didPostNewMessage(messageObject: THOPluginDidPostNewMessageConcreteObject!, forViewController logController: TVCLogController!) {
        guard !messageObject.isProcessedInBulk && inlineMediaMessageTypes.contains(messageObject.lineType) && logController.inlineImagesEnabledForView == true else {
            return
        }
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let user = logController.associatedChannel?.findMember(messageObject.senderNickname) {
            let ignoreMatches = logController.associatedClient?.checkIgnoreAgainstHostmask(user.hostmask, withMatches: [IRCAddressBookDictionaryValueIgnoreInlineMediaKey])
            guard ignoreMatches?.ignoreInlineMedia != true else {
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
                    if Bool(defaults.integerForKey("displayInformationForDuplicates")) == false {
                        guard previouslyDisplayedLinks.contains(link.absoluteString) == false else {
                            continue
                        }
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
            let maximumLinkCount = defaults.integerForKey("maximumPreviewsPerMessage")
            
            var linkCount = 0
            linkLoop: for url in sortedLinks {
                linkCount++
                if linkCount > maximumLinkCount {
                    break
                }
                
                if previouslyDisplayedLinks.count == 50 {
                    previouslyDisplayedLinks.removeAtIndex(0)
                }
                previouslyDisplayedLinks.append(url.absoluteString)
                
                var isDirectImageLink = false
                
                /* Check if the url is a direct link to an image with a valid image file extension. */
                if let fileExtension = url.pathExtension {
                    isDirectImageLink = imageFileExtensions.contains(fileExtension.lowercaseString)
                    
                    /* Check if this is a link to a gif. */
                    if fileExtension.lowercaseString == "gif" && Bool(defaults.integerForKey("displayAnimatedImages")) {
                        self.performBlockOnMainThread({
                            GifConversion.displayLoopingAnimation(url, controller: logController, line: messageObject.lineNumber)
                        })
                        continue
                    } else if (isDirectImageLink) {
                        continue
                    }
                }
                
                /* If Textual already handles this link, we will not attempt to. */
                guard TVCImageURLParser.imageURLFromBase(url.absoluteString) == nil else {
                    continue
                }
                
                /* Iterate over the available media handlers and see if we have one that supports this url. */
                for mediaHandlerType in InlineMedia.mediaHandlers {
                    if let mediaHandler = mediaHandlerType as? InlineMediaHandler.Type {
                        if mediaHandler.matchesServiceSchema?(url, hasImageExtension: isDirectImageLink) == true {
                            mediaHandler.init(url: url, controller: logController, line: messageObject.lineNumber)
                            continue linkLoop
                        }
                    }
                }
                
                /* There were no media handlers for this url, we will attempt to retrieve the title, description, and preview thumbnail of the webpage instead. */
                WebpageHandler.displayInformation(url, controller: logController, line: messageObject.lineNumber)
            }
        }
        
    }
    
    /**
    Given an URL, returns the same URL or another that can be shown as an image inline in chat.
    
    - parameter resource: A URL that was detected in a message being rendered.
    
    - returns: A URL that can be shown as an inline image in relation to resource or nil to ignore.
    */
    func processInlineMediaContentURL(resource: String!) -> String! {
        if let url = NSString(string: resource).URLUsingWebKitPasteboard {
            /* Iterate over the available media handlers and see if we have one that supports this url. */
            for mediaHandlerType in InlineMedia.mediaHandlers {
                if let mediaHandler = mediaHandlerType as? InlineMediaHandler.Type {
                    if let link = mediaHandler.processInlineMediaContentURL?(url) {
                        return link
                    }
                }
            }
        }
        return nil
    }
    
    /**
    Called when a web view has been loaded in Textual. Is used to load any static resources into the webview necessary for plugin features.
    
    - parameter notification: an NSNotification object containing the Log Controller that for the webview that has loaded.
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
    
    - parameter controller: The Textual "Log Controller" responsible for the view we want to insert the media into.
    - parameter line:       The unique ID for the line we wish to modify.
    - parameter node:       The HTML DOM Node to insert.
    - parameter url:        The original URL of the media source.
    */
    static func insert(controller: TVCLogController, line: String, node: DOMNode, url: String) {
        let document = controller.webView.mainFrameDocument
        if let line = document.getElementById("line-" + line) {
            let message = line.querySelector(".innerMessage")
            
            let mediaContainer = document.createElement("span")
            mediaContainer.className = "inlineMediaCell"
            mediaContainer.setAttribute("href", value: url)
            
            let hideListener = HideElementEventListener()
            mediaContainer.addEventListener("click", listener: hideListener, useCapture: false)
            
            let showListener = ShowElementEventListener()
            let messageLinks = message.querySelectorAll("a");
            for index in 0...messageLinks.length {
                let node = messageLinks.item(index)
                if let element = node as? DOMElement {
                    if element.getAttribute("href") == url {
                        element.addEventListener("click", listener: showListener, useCapture: false)
                    }
                }
            }
            
            mediaContainer.appendChild(node)
            message.appendChild(mediaContainer)
        }
    }
    
    /**
    Create an inline image from a link.
    
    - parameter controller: The Textual "Log Controller" for the view we want to insert the media into.
    - parameter source:     The source link for the image to display.
    
    - returns: An HTML DOM Node containing the inline image element.
    */
    static func inlineImage(controller: TVCLogController, source: String) -> DOMNode {
        return InlineMedia.inlineImage(controller, source: source, link: source)
    }
    
    
    /**
    Creates an inline image from a link.
    
    - parameter controller: The Textual "Log Controller" for the view we want to insert the media into.
    - parameter source:     The source link for the image to display.
    - parameter link:       The link to open when the user interacts with the image.
    
    - returns: An HTML DOM Node containing the inline image element.
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
    
    - parameter controller: The Textual "Log Controller" for the view we want to insert the media into.
    - parameter source:     The source link for the video to display.
    - parameter loop:       Whether this video should be continously looped.
    - parameter autoPlay:   Whether this video should start playing automatically.
    
    - returns: An HTML DOM Node containing the video element.
    */
    static func inlineVideo(controller: TVCLogController, source: String, loop: Bool, autoPlay: Bool) -> DOMNode {
        let document = controller.webView.mainFrameDocument
        
        /* Create the video tag  */
        let video = document.createElement("video")
        video.setAttribute("loop", value: loop.description)
        video.setAttribute("autoplay", value: autoPlay.description)
        
        /* Set the event listener to start/pause it when the user clicks it. */
        let listener = VideoEventListener()
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