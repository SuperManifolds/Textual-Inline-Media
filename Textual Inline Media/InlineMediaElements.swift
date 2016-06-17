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
    Truncates all the URLs in a message
    
    - parameter line: The unique ID for the line we wish to modify.
    */
    func truncateLinksInUrl(_ line: String) {
        /*if let line = document.getElementById("line-" + line) {
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
        }*/

    }
}
