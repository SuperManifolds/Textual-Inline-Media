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

public class InlineMedia: NSObject, THOPluginProtocol, SUUpdaterDelegate {
    static let imageFileExtensions = ["bmp", "gif", "jpg", "jpeg", "jp2", "j2k", "jpf", "jpx", "jpm", "mj2", "png", "svg", "tiff", "tif"]
    let inlineMediaMessageTypes = [TVCLogLineType.actionType, TVCLogLineType.privateMessageType]
    static let mediaHandlers = [Bash.self, Gfycat.self, IMDB.self, Imgur.self, Streamable.self, Twitter.self, Vimeo.self, Wikipedia.self, Xkcd.self, YouTube.self]
    var previouslyDisplayedLinks: [String] = []
    
    var preferencesView: NSView!
    var preferences: Preferences!
    
    public var pluginPreferencesPaneMenuItemName: String {
        return "Inline Media"
    }
    
    public var pluginPreferencesPaneView: NSView? {
        return preferencesView
    }
    
    /**
    Called when the plugin has been loaded into memory.
    */
    public func pluginLoadedIntoMemory() {
        NotificationCenter.default().addObserver(self, selector: #selector(InlineMedia.logControllerViewFinishedLoading(_:)), name: NSNotification.Name.TVCLogControllerViewFinishedLoading, object: nil)

        self.performBlock(onMainThread: {
			let updater = SUUpdater(for: Bundle(for: object_getClass(self)))

			updater?.delegate = self
			updater?.resetUpdateCycle()
			updater?.checkForUpdatesInBackground()
		})

        let defaults: [String : AnyObject] = [
            "displayInformationForDuplicates": 1,
            "maximumPreviewsPerMessage": 10,
            "displayAnimatedImages": 1,
            "AutomaticallyConvertGifs": 1
        ]
        UserDefaults.standard().register(defaults)
        
        preferences = Preferences()
        Bundle(for: object_getClass(self)).loadNibNamed("Preferences", owner: preferences, topLevelObjects: nil)
        self.preferencesView = preferences.preferences
    }
    
    public func pathToRelaunch(for updater: SUUpdater!) -> String! {
        return Bundle.main().bundlePath
    }
    
    public func updater(_ updater: SUUpdater!, didFindValidUpdate item: SUAppcastItem!) {
        let updateNotification = NSUserNotification()
        updateNotification.title = "Textual Plugin Update Found"
        updateNotification.informativeText = "An update to Textual Inline Media Plugin was found."
        updateNotification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default().deliver(updateNotification)
    }
    
    /**
    Called by the Textual plugin API when a new line has been added to the view.
    
    - parameter messageObject: An object containing all message information related to this line.
    - parameter logController: The Textual "Log Controller" responsible for the event.
    */
    public func didPostNewMessage(_ messageObject: THOPluginDidPostNewMessageConcreteObject!, forViewController logController: TVCLogController!) {
        self.performBlock(onMainThread: {
            logController.truncateLinksInUrl(messageObject.lineNumber)
        })
        
        guard !messageObject.isProcessedInBulk && inlineMediaMessageTypes.contains(messageObject.lineType) && logController.inlineImagesEnabledForView == true else {
            return
        }
        
        let defaults = UserDefaults.standard()
        if let user = logController.associatedChannel?.findMember(messageObject.senderNickname) {
            let ignoreMatches = logController.associatedClient?.checkIgnoreAgainstHostmask(user.hostmask, withMatches: [IRCAddressBookDictionaryValueIgnoreInlineMediaKey])
            guard ignoreMatches?.ignoreInlineMedia != true else {
                return
            }
            
            let linkScanner = AHHyperlinkScanner.init()
            let links = linkScanner.strictMatches(for: messageObject.messageContents) as? [[String]]
            guard links != nil else {
                return
            }
            
            var linkPriorityDict = Dictionary<String, [URL]>()
            var sortedLinks: [URL] = []
            for result in links! {
                let rawLink = result[1]
                
                /* NSURL is stupid and cannot comprehend unicode in domains, so we will use this method provided by Textual to convert it to "punycode" */
                if let link = NSString(string: rawLink).urlUsingWebKitPasteboard {
                    guard ((link.scheme?.hasPrefix("http")) != nil) else {
                        continue
                    }
                    if Bool(defaults.integer(forKey: "displayInformationForDuplicates")) == false {
                        guard previouslyDisplayedLinks.contains(link.absoluteString!) == false else {
                            continue
                        }
                    }
                    
                    /* Organise links into a dictionary by what domain they are from. */
                    if !linkPriorityDict.keys.contains(link.host!) {
                        linkPriorityDict[link.host!] = []
                    }
                    linkPriorityDict[link.host!]?.append(link)
                }
            }
            
            /* Prioritise links from the same domain by the number of path components. This will favour  a link to a subpage over a generic index page link and so on. */
            for domain in linkPriorityDict {
                let sorted = domain.1.sorted {
                    /* Terrible workaround to give subreddit links a low priority. */
                    if $1.pathComponents?.count > 2 {
                        if $1.pathComponents![1] == "r" {
                            return true
                        }
                    }
                    return $0.pathComponents?.count > $1.pathComponents?.count
                }
                sortedLinks.append(sorted[0])
            }
            let maximumLinkCount = defaults.integer(forKey: "maximumPreviewsPerMessage")
            
            var linkCount = 0
            linkLoop: for url in sortedLinks {
                linkCount += 1
                if linkCount > maximumLinkCount {
                    break
                }
                
                if previouslyDisplayedLinks.count == 50 {
                    previouslyDisplayedLinks.remove(at: 0)
                }
                previouslyDisplayedLinks.append(url.absoluteString!)
                InlineMedia.processInlineMediaFromUrl(url, controller: logController, line: messageObject.lineNumber)
            }
        }
        
    }
    
    /**
    Process a URL to display inline media
    
    - parameter url:         The URL that needs to be processed
    - parameter controller:  A Textual "Log Controller" for the view we want to insert the inline media
    - parameter line:        The unique identifier of the line we want to insert the inline media into
    - parameter originalUrl: The original url if this call is the result of a previous redirect
    */
    static func processInlineMediaFromUrl(_ url: URL, controller: TVCLogController, line: String, originalUrl: URL? = nil) {
        let defaults = UserDefaults.standard()
        
        /* If Textual already handles this link, we will not attempt to. */
        if url.host?.hasSuffix("youtube.com") == false && url.host?.hasSuffix("youtu.be") == false && originalUrl == nil {
            guard TVCImageURLParser.imageURL(fromBase: url.absoluteString) == nil else {
                return
            }
        }
        
        /* Iterate over the available media handlers and see if we have one that supports this url. */
        for mediaHandlerType in InlineMedia.mediaHandlers {
            if let mediaHandler = mediaHandlerType as? InlineMediaHandler.Type {
                if Preferences.serviceIsEnabled(mediaHandler) && mediaHandler.matchesServiceSchema?(url) == true {
                    mediaHandler.init(url: url, controller: controller, line: line)
                    return
                }
            }
        }
        
        /* Check if the url is a direct link to an image with a valid image file extension. */
        if let fileExtension = url.pathExtension {
            /* Check if this is a link to a gif. */
            if fileExtension.lowercased() == "gif" && Bool(defaults.integer(forKey: "displayAnimatedImages")) {
                self.performBlock(onMainThread: {
                    AnimatedImage.create(controller, url: url, line: line)
                })
                return
            }
        }
        /* There were no media handlers for this url, we will attempt to connect to this URL to retrieve basic information */
        WebRequest(url: url, controller: controller, line: line, originalUrl: originalUrl).start()
        return
    }
    
    /**
    Given an URL, returns the same URL or another that can be shown as an image inline in chat.
    
    - parameter resource: A URL that was detected in a message being rendered.
    
    - returns: A URL that can be shown as an inline image in relation to resource or nil to ignore.
    */
    public func processInlineMediaContentURL(_ resource: String!) -> String! {
        if let url = NSString(string: resource).urlUsingWebKitPasteboard {
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
    func logControllerViewFinishedLoading(_ notification: Notification) {
        self.performBlock(onMainThread: {
            if let controller = notification.object as? TVCLogController {
                let webView = controller.backingView
                
                let scriptNames = ["InlineMedia"]
                
                let fileManager = FileManager.default()
                let sandboxedTempDirectory = URL(fileURLWithPath: TXSharedApplication.sharedThemeController().temporaryPath)
                let sandBoxedTempPluginDirectory = try! sandboxedTempDirectory.appendingPathComponent("InlineMedia")
                
                let sandboxedStylesheetPath = try! sandBoxedTempPluginDirectory.appendingPathComponent("style.css")
                
                if fileManager.fileExists(atPath: sandBoxedTempPluginDirectory.absoluteString!) == false {
                    do {
                        try fileManager.createDirectory(at: sandBoxedTempPluginDirectory, withIntermediateDirectories: false, attributes: nil)
                        
                        let mainBundle = Bundle(for: InlineMedia.self)
                        let stylesheetPath = mainBundle.urlForResource("style", withExtension: "css")!
                        
                        try fileManager.copyItem(at: stylesheetPath, to: sandboxedStylesheetPath)
                        
                        for script in scriptNames {
                            let scriptPath = mainBundle.urlForResource(script, withExtension: "js")!
                            let sandboxedScriptPath = try! sandBoxedTempPluginDirectory.appendingPathComponent("\(script).js")
                            try fileManager.copyItem(at: scriptPath, to: sandboxedScriptPath)
                        }
                    } catch let error {
                        print(error)
                    }
                }
                
                for script in scriptNames {
                    let sandboxedScriptPath = try! sandBoxedTempPluginDirectory.appendingPathComponent("\(script).js")
                    webView!.evaluateFunction("Textual.includeScriptResourceFile", withArguments: [sandboxedScriptPath.absoluteString!])
                }
                
                
                webView!.evaluateFunction("Textual.includeStyleResourceFile", withArguments: [sandboxedStylesheetPath.absoluteString!])
                
                /*
                
                let twitterTheme = document.createElement("meta")
                twitterTheme.setAttribute("name", value: "twitter:widgets:theme")
                twitterTheme.setAttribute("content", value: "dark")*/
            }
        })
    }
    
    public static func isSafeToPresentImageWithID(_ uniqueID: String!, onController controller: TVCLogController) {
        self.performBlock(onMainThread: {
            let webkit = controller.backingView
            /*
            NSLog("#inlineImage-\(uniqueID) img")
            if let image = document.querySelector("#inlineImage-\(uniqueID) img") {
                let toggleInlineImage = TextualToggleInlineImageEventListener()
                image.addEventListener("click", listener: toggleInlineImage, useCapture: false)
            }*/
        })
    }
}
