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

extension String {
    subscript(i: Int) -> Character {
        return self[startIndex.advancedBy(i)]
    }
    
    subscript(range: Range<Int>) -> String {
        return self[startIndex.advancedBy(range.startIndex)..<startIndex.advancedBy(range.endIndex)]
    }
    
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}

extension DOMElement {
    var classList: [String] {
        get {
            return self.className.componentsSeparatedByString(" ")
        } set(classes) {
            self.className = classes.joinWithSeparator(" ")
        }
    }
}

extension NSFileManager {
    func getTemporaryDirectory(name: String) -> NSURL? {
        let tempDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(name)
    
        if NSFileManager.defaultManager().fileExistsAtPath(tempDirURL.absoluteString) == false {
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(tempDirURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        return tempDirURL
    }
}

extension NSImage {
    static func fromAssetCatalogue(name: String) -> NSImage? {
        let mainBundle = NSBundle(forClass: InlineMedia.self)
        return mainBundle.imageForResource(name)
    }
}

extension NSTimeInterval {
    init?(iso8601String: String) {
        if iso8601String.hasPrefix("P") && iso8601String.containsString("T") {
            
            var seconds: NSTimeInterval = 0
            var isTimeSegment = false
            
            let iso8601duration = NSScanner(string: iso8601String)
            if iso8601String.hasPrefix("PT") {
                iso8601duration.charactersToBeSkipped = NSCharacterSet(charactersInString: "PT")
                isTimeSegment = true
            } else {
                iso8601duration.charactersToBeSkipped = NSCharacterSet(charactersInString: "P")
            }
            
            while iso8601duration.atEnd == false {
                var value = 0.0
                var units: NSString?
                
                if iso8601duration.scanDouble(&value) {
                    if iso8601duration.scanCharactersFromSet(NSCharacterSet.uppercaseLetterCharacterSet(), intoString: &units) {
                        if let unitString = units as? String {
                            for unit in unitString.characters {
                                switch unit {
                                    case  "Y":
                                        seconds += 31557600*value
                                        
                                    case "M":
                                        if isTimeSegment {
                                            seconds += 60*value
                                        } else {
                                            seconds += 2629800*value
                                        }
                                        
                                    case "W":
                                        seconds += 604800*value
                                        
                                    case "D":
                                        seconds += 86400*value
                                        
                                    case "H":
                                        seconds += 3600*value
                                        
                                    case "S":
                                        seconds += value
                                        
                                    case "T":
                                        isTimeSegment = true
                                        
                                    default:
                                        return nil
                                }
                            }
                        }
                    }
                } else {
                    break
                }
            }
            self.init(seconds)
            return
        }
        return nil
    }
}