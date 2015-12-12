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

extension TVCLogController {
    /**
    Inserts any HTML DOM Node as an inline media item in a message.
    
    - parameter line:       The unique ID for the line we wish to modify.
    - parameter node:       The HTML DOM Node to insert.
    - parameter url:        The original URL of the media source.
    */
    func insertInlineMedia(line: String, node: DOMNode, url: String) {
        let document = self.webView.mainFrameDocument
        if let line = document.getElementById("line-" + line) {
            let message = line.querySelector(".innerMessage")
            
            let mediaContainer = document.createElement("span")
            mediaContainer.className = "inlineMediaCell"
            mediaContainer.setAttribute("href", value: url)
            
            let hideListener = HideElementEventListener()
            mediaContainer.addEventListener("click", listener: hideListener, useCapture: false)
            
            let showListener = ShowElementEventListener()
            let messageLinks = message.querySelectorAll("a")
            for index in 0...messageLinks.length {
                let node = messageLinks.item(index)
                if let element = node as? DOMElement {
                    if element.getAttribute("href") == url {
                        element.removeAttribute("onclick")
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
    
    - parameter source:     The source link for the image to display.
    - returns: An HTML DOM Node containing the inline image element.
    */
    func createInlineImage(source: String, uuid: String) -> DOMNode {
        return self.createInlineImage(source, link: source, uuid: uuid)
    }
    
    
    /**
    Creates an inline image from a link.
    
    - parameter source:     The source link for the image to display.
    - parameter link:       The link to open when the user interacts with the image.
    
    - returns: An HTML DOM Node containing the inline image element.
    */
    func createInlineImage(source: String, link: String, uuid: String) -> DOMNode {
        let document = self.webView.mainFrameDocument
        
        let inlineImageCell = document.createElement("span")
        inlineImageCell.classList += ["inlineImageCell"]
        inlineImageCell.setAttribute("id", value: "inlineImage-\(uuid)")
        inlineImageCell.setAttribute("style", value: "display: none;")
        
        let closeButton = document.createElement("span")
        closeButton.classList += ["closeButton"]
        closeButton.setAttribute("href", value: "#")
        closeButton.setAttribute("onclick", value: "Textual.toggleInlineImage('\(uuid)', false);")
        closeButton.textContent = "x"
        inlineImageCell.appendChild(closeButton)
        
        let imageLink = document.createElement("a")
        imageLink.setAttribute("href", value: link)
        imageLink.setAttribute("onclick", value: "return InlineImageLiveResize.negateAnchorOpen()")
        inlineImageCell.appendChild(imageLink)
        
        let image = document.createElement("img")
        image.setAttribute("src", value: source)
        image.classList += ["image"]
        image.setAttribute("style", value: "max-width: \(TPCPreferences.inlineImagesMaxWidth())px;")
        imageLink.appendChild(image)
        
        return inlineImageCell
    }
    
    /**
    Creates an inline video from a link
    
    - parameter source:     The source link for the video to display.
    - parameter loop:       Whether this video should be continously looped.
    - parameter autoPlay:   Whether this video should start playing automatically.
    - parameter muteAudio:  Whether the audio should be muted when the video begins. (True by default)
    
    - returns: An HTML DOM Node containing the video element.
    */
    func createInlineVideo(source: String, loop: Bool, autoPlay: Bool, muteAudio: Bool = true) -> DOMNode {
        let document = self.webView.mainFrameDocument
        
        /* Create the video tag  */
        let video = document.createElement("video")
        video.setAttribute("loop", value: loop.description)
        video.setAttribute("autoplay", value: autoPlay.description)
        video.setAttribute("muted", value: muteAudio.description)
        
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
    
    /**
    Truncates all the URLs in a message
    
    - parameter line: The unique ID for the line we wish to modify.
    */
    func truncateLinksInUrl(line: String) {
        let document = self.webView.mainFrameDocument
        if let line = document.getElementById("line-" + line) {
            guard let message = line.querySelector(".innerMessage") else {
                return
            }
            
            /* Iterate over all the links in the message */
            let messageLinks = message.querySelectorAll("a")
            for index in 0...messageLinks.length {
                let node = messageLinks.item(index)
                if let element = node as? DOMElement {
                    if let link = NSURL(string: element.getAttribute("href")) {
                        var truncatedUrl = link.host!
                        
                        /* If the path of the link has more than two components, truncate it. */
                        if link.pathComponents?.count > 2 {
                            /* Add elipses to clarify that part of the path has been truncated. */
                            truncatedUrl += "/../"
                            
                            /* If the last path component is longer than 20 characters, show just the last 15 characters */
                            if link.pathComponents?.last?.characters.count > 20 {
                                let lastPathComponent = link.pathComponents!.last!
                                let truncatedPathComponent = lastPathComponent[(lastPathComponent.characters.count - 15)..<lastPathComponent.characters.count]
                                truncatedUrl += "..\(truncatedPathComponent)"
                            } else {
                                truncatedUrl += link.pathComponents!.last!
                            }
                        } else {
                            truncatedUrl += link.path!
                        }
                        element.textContent = truncatedUrl
                    }
                }
            }
        }

    }
}
