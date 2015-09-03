/*
    Copyright (c) 2015, Alex S. Glomsaas
    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation


class InlineMedia: NSObject, THOPluginProtocol, TVCImageURLoaderDelegate {
    let imageFileExtensions = ["bmp", "gif", "jpg", "jpeg", "jp2", "j2k", "jpf", "jpx", "jpm", "mj2", "png", "svg", "tiff", "tif"]
    let inlineMediaMessageTypes = [TVCLogLineType.ActionType.rawValue, TVCLogLineType.PrivateMessageType.rawValue, TVCLogLineType.NoticeType.rawValue]
    let mediaHandlers = [Twitter.self, YouTube.self]
    
    func pluginLoadedIntoMemory() {
        NSLog("Plugin loaded")
    }
    
    
    /**
    Called by the Textual plugin API when a new line has been added to the view.
    
    :param: logController   The Textual "Log Controller" responsible for the event.
    :param: messageInfo     An anonymous dictionary containing information about the event.
    :param: isThemeReload   Whether or not this message was posted due to the theme being reloaded or changed.
    :param: isHistoryReload Whether or not the message was posted as log history.
    */
    func didPostNewMessageForViewController(logController: TVCLogController, messageInfo: [NSObject : AnyObject]!, isThemeReload: Bool, isHistoryReload: Bool) {
        guard !isThemeReload && !isHistoryReload else {
            return
        }
        
        /* Retrieve the line type of this message, we will only act on normal messages (privmsg) actions, and notices. */
        if let lineType = messageInfo[THOPluginProtocolDidPostNewMessageLineTypeAttribute] as? UInt {
            guard (inlineMediaMessageTypes.contains(lineType)) else {
                return
            }
            
            /* Iterate over the list of hyperlinks */
            if let links = messageInfo[THOPluginProtocolDidPostNewMessageListOfHyperlinksAttribute] as? [[AnyObject]] {
                let lineNumber = messageInfo[THOPluginProtocolDidPostNewMessageLineNumberAttribute] as! String
                for result in links {
                    let link = result[1] as! String
                    
                    /* NSURL is stupid and cannot comprehend unicode in domains, so we will use this method provided by Textual to convert it to "punycode" */
                    if let url = NSString(string: link).URLUsingWebKitPasteboard {
                        var isDirectImageLink = false
                        
                        /* Check if the url is a direct link to an image with a valid image file extension. */
                        if let fileExtension = url.pathExtension {
                            isDirectImageLink = imageFileExtensions.contains(fileExtension.lowercaseString)
                            
                            /* Check if this is a link to a gif. */
                            if (fileExtension.lowercaseString == "gif") {
                                self.performBlockOnMainThread({
                                    let image = InlineMedia.inlineImage(logController, source: link)
                                    InlineMedia.insert(logController, line: lineNumber, node: image)
                                })
                                return
                            }
                        }
                        
                        /* Iterate over the available media handlers and see if we have one that supports this url. */
                        for mediaHandlerType in mediaHandlers {
                            if let mediaHandler = mediaHandlerType as? InlineMediaHandler.Type {
                                if (mediaHandler.matchesServiceSchema(url, hasImageExtension: isDirectImageLink)) {
                                    mediaHandler.init(url: url, controller: logController, line: lineNumber)
                                    return
                                }
                            }
                        }
                        
                        /* There were no media handlers for this url, we will attempt to retrieve the title, description, and preview thumbnail of the webpage instead. */
                        WebpageHandler.displayInformation(url, controller: logController, line: lineNumber)
                    }
                    
                }
            }
        }
    }
    
    /**
    Inserts any HTML DOM Node as an inline media item in a message.
    
    :param: controller The Textual "Log Controller" responsible for the view we want to insert the media into.
    :param: line       The unique ID for the line we wish to modify.
    :param: node       The HTML DOM Node to insert.
    */
    static func insert(controller: TVCLogController, line: String, node: DOMNode) {
        let document = controller.webView.mainFrameDocument
        let line = document.getElementById("line-" + line)
        let message = line.querySelector(".innerMessage")
        
        let mediaContainer = document.createElement("span")
        mediaContainer.className = "inlineMediaCell"
        
        mediaContainer.appendChild(node)
        message.appendChild(mediaContainer)
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
    
    func isNotSafeToPresentImageWithID(uniqueID: String!) {
        
    }
    
    func isSafeToPresentImageWithID(uniqueID: String!) {
        
    }
}