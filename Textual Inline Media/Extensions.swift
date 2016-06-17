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
    subscript(index: Int) -> Character {
        return self[characters.index(startIndex, offsetBy: index)]
    }

    subscript(range: Range<Int>) -> String {
        return self[characters.index(startIndex, offsetBy: range.lowerBound)..<characters.index(startIndex, offsetBy: range.upperBound)]
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}

extension DOMElement {
    var classList: [String] {
        get {
            return self.className.components(separatedBy: " ")
        } set(classes) {
            self.className = classes.joined(separator: " ")
        }
    }
}

extension FileManager {
    func getTemporaryDirectory(_ name: String) -> URL? {
        let tempDirURL = try! URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)

        if FileManager.default().fileExists(atPath: tempDirURL.absoluteString!) == false {
            do {
                try FileManager.default().createDirectory(at: tempDirURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        return tempDirURL
    }
}

extension NSImage {
    static func fromAssetCatalogue(_ name: String) -> NSImage? {
        let mainBundle = Bundle(for: InlineMedia.self)
        return mainBundle.image(forResource: name)
    }
}

extension TimeInterval {
    init?(iso8601String: String) {
        if iso8601String.hasPrefix("P") && iso8601String.contains("T") {

            var seconds: TimeInterval = 0
            var isTimeSegment = false

            let iso8601duration = Scanner(string: iso8601String)
            if iso8601String.hasPrefix("PT") {
                iso8601duration.charactersToBeSkipped = CharacterSet(charactersIn: "PT")
                isTimeSegment = true
            } else {
                iso8601duration.charactersToBeSkipped = CharacterSet(charactersIn: "P")
            }

            while iso8601duration.isAtEnd == false {
                var value = 0.0
                var units: NSString?

                if iso8601duration.scanDouble(&value) {
                    if iso8601duration.scanCharacters(from: CharacterSet.uppercaseLetters, into: &units) {
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
