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

class bash: NSObject, InlineMediaHandler {
    static func name() -> String {
        return "Bash.org"
    }
    
    static func icon() -> NSImage? {
        return NSImage.fromAssetCatalogue("bash")
    }
    
    required convenience init(url: NSURL, controller: TVCLogController, line: String) {
        self.init()
        let session = NSURLSession.sharedSession()
        session.dataTaskWithURL(url, completionHandler: {(data : NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let httpResponse = response as? NSHTTPURLResponse {
                /* Validate that the server obeyed our request to only receive HTML, abort if otherwise. */
                guard httpResponse.allHeaderFields["Content-Type"]?.contains("text/html") == true && data != nil else {
                    return
                }
                
                /* ObjectiveGumbo has no gracefully error handling for failure to decode data, so we will validate the data beforehand. */
                guard NSString(data: data!, encoding: NSUTF8StringEncoding) != nil else {
                    return
                }
                
                /* Create an HTML parser object of the website using ObjectiveGumbo. */
                if let node = ObjectiveGumbo.parseDocumentWithData(data, encoding: NSUTF8StringEncoding) {
                    if let quote = node.elementsWithClass("quote").first as? OGElement {
                        let votes = quote.elementsWithTag(GUMBO_TAG_FONT).first?.text
                        let quoteText = node.elementsWithClass("qt").first?.text
                        
                        self.performBlockOnMainThread({
                            let document = controller.webView.mainFrameDocument
                            
                            let bashContainer = document.createElement("div")
                            bashContainer.className = "inline_media_bash"
                            
                            /* Get the number of votes on this quote and create the title */
                            if votes != nil {
                                let bashTitle = document.createElement("p")
                                bashTitle.className = "inline_media_bash_title"
                                bashTitle.textContent = "#\(url.query![1..<url.query!.characters.count]) (\(votes!))"
                                bashContainer.appendChild(bashTitle)
                            }
                            
                            let bashText = document.createElement("p")
                            bashText.className = "inline_media_bash_text"
                            bashContainer.appendChild(bashText)
                            
                            /* Split the quotes by line */
                            if quoteText != nil {
                                let quoteLines = quoteText!.componentsSeparatedByString("\n")
                                
                                /* The only way to use Textuals nickname colour generator is to abuse TVCLogLine,
                                so we will retain an instance of it here and set each nickname on it */
                                let logLine = TVCLogLine()
                                logLine.lineType = .PrivateMessageType
                                
                                for line in quoteLines {
                                    let message = document.createElement("p")
                                    
                                    /* Scan the line for nicknames enclosed in <> and colour them appropriately */
                                    let scanner = NSScanner(string: line)
                                    scanner.charactersToBeSkipped = .None
                                    
                                    let startCharacter = NSCharacterSet(charactersInString: "<")
                                    let endCharacter = NSCharacterSet(charactersInString: ">")
                                    
                                    while scanner.atEnd == false {
                                        /* Save the text before the < as a normal text node */
                                        var beforeToken: NSString?
                                        scanner.scanUpToCharactersFromSet(startCharacter, intoString: &beforeToken)
                                        if (beforeToken != nil) {
                                            let textElement = document.createTextNode(beforeToken as! String)
                                            bashText.appendChild(textElement)
                                        }
                                        
                                        /* Eat the < */
                                        if scanner.atEnd == false {
                                            scanner.scanLocation++
                                        }
                                        
                                        /* Get the nickname inside the < and >  */
                                        var nicknameToken: NSString?
                                        scanner.scanUpToCharactersFromSet(endCharacter, intoString: &nicknameToken)
                                        if nicknameToken != nil {
                                            if nicknameToken?.hostmaskNickname == true {
                                                let nickname = nicknameToken as! String
                                                
                                                /* Create a coloured span using Textuals nickname colour generator and add it to the message */
                                                logLine.nickname = nickname
                                                let nicknameElement = document.createElement("span")
                                                nicknameElement.setAttribute("style", value: "color: \(logLine.nicknameColorStyle)")
                                                nicknameElement.textContent = "<\(nickname)>"
                                                bashText.appendChild(nicknameElement)
                                                
                                                scanner.scanLocation++
                                            } else {
                                                /* This isn't a nickname after all, add it as normal text. */
                                                let textElement = document.createTextNode("<\(beforeToken as! String)")
                                                bashText.appendChild(textElement)
                                            }
                                        }
                                    }
                                    bashText.appendChild(message)
                                }
                                controller.insertInlineMedia(line, node: bashContainer, url: url.absoluteString)
                            }
                        })
                    }
                }
            }
        }).resume()
    }
    
    static func matchesServiceSchema(url: NSURL) -> Bool {
        return url.host?.hasSuffix("bash.org") == true && url.query?.characters.count > 0
    }
}