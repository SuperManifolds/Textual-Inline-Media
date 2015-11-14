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

class WebpageInformation: NSObject {
    static func create(url: NSURL, controller: TVCLogController, line: String) {
        let request = NSMutableURLRequest(URL: url)
            
        let session = NSURLSession.sharedSession()
        session.dataTaskWithRequest(request, completionHandler: {(data : NSData?, response: NSURLResponse?, error: NSError?) -> Void in
        if let httpResponse = response as? NSHTTPURLResponse {
            guard data != nil else {
                return
            }
            
            /* Validate that the server obeyed our request to only receive HTML, abort if otherwise. */
            let contentType = httpResponse.allHeaderFields["Content-Type"]
            guard contentType?.contains("text/html") == true else {
                if contentType?.hasPrefix("image/gif") == true {
                    AnimatedImage.create(controller, url: httpResponse.URL!, line: line)
                } else if contentType?.hasPrefix("image/") == true {
                    let redirectUrl = httpResponse.URL!.absoluteString
                    
                    self.performBlockOnMainThread({
                        
                        let document = controller.webView.mainFrameDocument
                        if let line = document.getElementById("line-" + line) {
                            let message = line.querySelector(".innerMessage")
                            
                            
                            let messageLinks = message.querySelectorAll("a");
                            for index in 0...messageLinks.length {
                                let node = messageLinks.item(index)
                                if let element = node as? DOMElement {
                                    if element.getAttribute("href") == url.absoluteString {
                                        let onclickComponents = element.getAttribute("onclick").componentsSeparatedByString("'")
                                        let uuid = onclickComponents[1]
                                        
                                        let image = controller.createInlineImage(redirectUrl, uuid: uuid)
                                        message.appendChild(image)
                                        
                                        let imageURLLoader = TVCImageURLoader()
                                        imageURLLoader.delegate = controller
                                        imageURLLoader.assesURL(redirectUrl, withID: uuid)
                                    }
                                }
                            }
                            
                        }
                    })
                } else {
                    /* This is a file type that we do not have a special preview for, we will display a generic file information preview with file name, file type, file icon, and file size.  */
                    guard let fileType = contentType as? String else {
                        return
                    }
                    
                    let workspace = NSWorkspace.sharedWorkspace()
                    let fileManager = NSFileManager.defaultManager()
                    /* Request the 'human readable' localised file type for this file and the finder image for this filetype. */
                    if let fileTypeSystemIdentifier = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, fileType, nil)?.takeRetainedValue() {
                        let localisedFileType = workspace.localizedDescriptionForType(fileTypeSystemIdentifier as String)
                        let icon = workspace.iconForFileType(fileTypeSystemIdentifier as String)
                        
                        /* OSX returns an NSImage for the file icon, which is not useable in Webkit. We will therefor create a temporary file on disk to refer to in the image tag. */
                        let iconData = icon.TIFFRepresentation
                        let tempDir = fileManager.getTemporaryDirectory("textual_inline_media")
                        if tempDir != nil && iconData != nil {
                            /* Create a checsum of the icon and use it for the filename, so we can reuse it if we already have a temp file for this file type. */
                            let iconFileLocation = tempDir!.URLByAppendingPathComponent("\(iconData!.sha1).tif")
                            if fileManager.fileExistsAtPath(iconFileLocation.absoluteString) == false {
                                iconData!.writeToURL(iconFileLocation, atomically: true)
                            }
                            
                            let fileName = httpResponse.URL!.lastPathComponent
                            
                            var size = "Unknown Size"
                            if let contentLength = httpResponse.allHeaderFields["Content-Length"] {
                                size = NSByteCountFormatter.stringFromByteCountWithPaddedDigits(contentLength.longLongValue)
                            }
                            
                            var modified: String? = nil
                            if let dateModified = httpResponse.allHeaderFields["Last-Modified"] as? String {
                                let dateFormatter = NSDateFormatter()
                                dateFormatter.dateFormat = "EEE, dd MMM y hh:mm:ss zzz"
                                if let date = dateFormatter.dateFromString(dateModified) {
                                    dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
                                    dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
                                    modified = dateFormatter.stringFromDate(date)
                                } else {
                                    modified = dateModified
                                }
                            }
                            
                            self.performBlockOnMainThread({
                                let document = controller.webView.mainFrameDocument
                                
                                let fileContainer = document.createElement("div")
                                fileContainer.className = "inline_media_file"
                                
                                let fileIcon = document.createElement("img")
                                fileIcon.className = "inline_media_file_icon"
                                fileIcon.setAttribute("src", value: iconFileLocation.absoluteString)
                                fileContainer.appendChild(fileIcon)
                                
                                let fileInfo = document.createElement("div")
                                fileInfo.className = "inline_media_file_info"
                                fileContainer.appendChild(fileInfo)
                                
                                let fileTitle = document.createElement("p")
                                fileTitle.className = "inline_media_file_title"
                                fileTitle.textContent = fileName
                                fileInfo.appendChild(fileTitle)
                                
                                
                                let fileKindContainer = document.createElement("p")
                                fileInfo.appendChild(fileKindContainer)
                                
                                let fileKindLabel = document.createElement("strong")
                                fileKindLabel.textContent = "Kind: "
                                fileKindContainer.appendChild(fileKindLabel)
                                
                                let fileKind = document.createElement("spam")
                                fileKind.className = "inline_media_file_kind"
                                fileKind.textContent = localisedFileType!
                                fileKindContainer.appendChild(fileKind)
                                
                                
                                let fileSizeContainer = document.createElement("p")
                                fileInfo.appendChild(fileSizeContainer)
                                
                                let fileSizeLabel = document.createElement("strong")
                                fileSizeLabel.textContent = "Size: "
                                fileSizeContainer.appendChild(fileSizeLabel)
                                
                                let fileSize = document.createElement("spam")
                                fileSize.className = "inline_media_file_size"
                                fileSize.textContent = size
                                fileSizeContainer.appendChild(fileSize)
                                
                                if modified != nil {
                                    let fileModifiedContainer = document.createElement("p")
                                    fileInfo.appendChild(fileModifiedContainer)
                                    
                                    let fileModifiedLabel = document.createElement("strong")
                                    fileModifiedLabel.textContent = "Last Modified: "
                                    fileModifiedContainer.appendChild(fileModifiedLabel)
                                    
                                    let fileModified = document.createElement("spam")
                                    fileModified.className = "inline_media_file_mod"
                                    fileModified.textContent = modified
                                    fileModifiedContainer.appendChild(fileModified)
                                }
                                
                                controller.insertInlineMedia(line, node: fileContainer, url: url.absoluteString)
                            })
                        }
                    }
                }
                return
            }
            
            /* ObjectiveGumbo has no gracefully error handling for failure to decode data, so we will validate the data beforehand. */
            guard NSString(data: data!, encoding: NSUTF8StringEncoding) != nil else {
                return
            }
            
            /* Create an HTML parser object of the website using ObjectiveGumbo. */
            if let node = ObjectiveGumbo.parseDocumentWithData(data, encoding: NSUTF8StringEncoding) {
                /* Attempt to retrieve the website title, if it cannot be located, we will not bother continuing. */
                let titleElements = node.elementsWithTag(GUMBO_TAG_TITLE)
                if titleElements.count > 0 {
                    let title = titleElements[0].text
                    var description = ""
                    var previewImageUrl = ""
                    
                    /* Attempt to retrieve the webpage description, and the og:image website thumbnail. */
                    let metaElements = node.elementsWithTag(GUMBO_TAG_META)
                    for element in metaElements {
                        if (element.attributes["name"]?.lowercaseString == "description") || element.attributes["property"]?.lowercaseString == "og:description" {
                            if let descriptionText = element.attributes["content"] as? String {
                                description = descriptionText
                                if (description.characters.count > 0 && previewImageUrl.characters.count > 0) {
                                    break
                                }
                            }
                        } else if (element.attributes["property"]?.lowercaseString == "og:image") {
                            if let previewImageUrlTag = element.attributes["content"] as? String {
                                previewImageUrl = previewImageUrlTag
                                if (description.characters.count > 0 && previewImageUrl.characters.count > 0) {
                                    break
                                }
                            }
                        }
                    }
                    
                    /* The og:image may be specified as a relative URL, if so, we will attemp to use NSURLs relativeToUrl feature to resolve the absolute path to this image file. */
                    if (previewImageUrl.characters.count > 0) {
                        if previewImageUrl.hasPrefix("data:image/") == false && previewImageUrl.hasPrefix("http://") == false && previewImageUrl.hasPrefix("https://") == false {
                            if let resolvedRelativeUrl = NSURL(string: previewImageUrl, relativeToURL: httpResponse.URL) {
                                previewImageUrl = resolvedRelativeUrl.absoluteString
                            }
                        }
                    }
                    
                    self.performBlockOnMainThread({
                        let document = controller.webView.mainFrameDocument
                        
                        /* Create the container for the entire inline media element. */
                        let websiteContainer = document.createElement("a")
                        websiteContainer.setAttribute("href", value: url.absoluteString)
                        websiteContainer.className = "inline_media_website"
                        
                        /* If we found a preview image element, we will add it. */
                        if (previewImageUrl.characters.count > 0) {
                            let previewImage = document.createElement("img")
                            previewImage.className = "inline_media_website_thumbnail"
                            previewImage.setAttribute("src", value: previewImageUrl)
                            websiteContainer.appendChild(previewImage)
                        }
                        
                        /* Create the container that holds the title and description. */
                        let infoContainer = document.createElement("div")
                        infoContainer.className = "inline_media_website_info"
                        websiteContainer.appendChild(infoContainer)
                        
                        /* Create the title element */
                        let titleElement = document.createElement("div")
                        titleElement.className = "inline_media_website_title"
                        titleElement.appendChild(document.createTextNode(title))
                        infoContainer.appendChild(titleElement)
                        
                        /* If we found a description, create the description element. */
                        if (description.characters.count > 0) {
                            let descriptionElement = document.createElement("div")
                            descriptionElement.className = "inline_media_website_desc"
                            descriptionElement.appendChild(document.createTextNode(description))
                            infoContainer.appendChild(descriptionElement)
                        }
                        controller.insertInlineMedia(line, node: websiteContainer, url: url.absoluteString)
                    })
                }
            }
        }
    }).resume()
    }
}