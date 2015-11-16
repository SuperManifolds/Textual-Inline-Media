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

class FileInformation: NSObject {
    private let response: NSHTTPURLResponse
    private let controller: TVCLogController
    private let line: String
    
    /**
    Display information for a file on a webserver
    
    - parameter response:   The HTTP response object from the webserver
    - parameter controller: A Textual "Log Controller" for the view we want to insert the inline media
    - parameter line:       The unique identifier of the line we want to insert the inline media into
    
    - returns: An instance of a FileInformation object
    */
    init(response: NSHTTPURLResponse, controller: TVCLogController, line: String) {
        self.response = response
        self.controller = controller
        self.line = line
        super.init()
    }
    
    /**
    Display the file information in Textual
    */
    func start() {
        guard let fileType = self.response.allHeaderFields["Content-Type"] as? String else {
            return
        }
        
        let workspace = NSWorkspace.sharedWorkspace()
        let fileManager = NSFileManager.defaultManager()
        /* Request the 'human readable' localised file type for this file and the finder image for this filetype. */
        if let fileTypeSystemIdentifier = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, fileType, nil)?.takeRetainedValue() {
            var localisedFileType = workspace.localizedDescriptionForType(fileTypeSystemIdentifier as String)
            var icon = workspace.iconForFileType(fileTypeSystemIdentifier as String)
            if localisedFileType == nil && response.URL!.pathExtension != nil {
                if let fileExtensionSystemIdentifier = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, response.URL!.pathExtension!, nil)?.takeRetainedValue() {
                    localisedFileType = workspace.localizedDescriptionForType(fileExtensionSystemIdentifier as String)
                    icon = workspace.iconForFileType(fileExtensionSystemIdentifier as String)
                }
            }
            
            /* OSX returns an NSImage for the file icon, which is not useable in Webkit. We will therefor create a temporary file on disk to refer to in the image tag. */
            let iconData = icon.TIFFRepresentation
            let tempDir = fileManager.getTemporaryDirectory("textual_inline_media")
            if tempDir != nil && iconData != nil {
                /* Create a checsum of the icon and use it for the filename, so we can reuse it if we already have a temp file for this file type. */
                let iconFileLocation = tempDir!.URLByAppendingPathComponent("\(iconData!.sha1).tif")
                if fileManager.fileExistsAtPath(iconFileLocation.absoluteString) == false {
                    iconData!.writeToURL(iconFileLocation, atomically: true)
                }
                
                let fileName = response.URL!.lastPathComponent
                
                var size = "Unknown Size"
                if let contentLength = response.allHeaderFields["Content-Length"] {
                    size = NSByteCountFormatter.stringFromByteCountWithPaddedDigits(contentLength.longLongValue)
                }
                
                var modified: String? = nil
                if let dateModified = response.allHeaderFields["Last-Modified"] as? String {
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "EEE, dd MMM y HH:mm:ss zzz"
                    if let date = dateFormatter.dateFromString(dateModified) {
                        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
                        dateFormatter.timeStyle = NSDateFormatterStyle.LongStyle
                        modified = dateFormatter.stringFromDate(date)
                    } else {
                        modified = dateModified
                    }
                }
                
                self.performBlockOnMainThread({
                    let document = self.controller.webView.mainFrameDocument
                    
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
                    fileKind.textContent = localisedFileType != nil ? localisedFileType : "Unknown"
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
                    
                    self.controller.insertInlineMedia(self.line, node: fileContainer, url: self.response.URL!.absoluteString)
                })
            }
        }
    }
}