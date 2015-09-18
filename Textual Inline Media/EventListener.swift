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

class VideoEventListener: NSObject, DOMEventListener {
    /**
    Triggered when the user has clicked a video element. Toggles the play/pause state.
    
    - parameter event: <#event description#>
    */
    func handleEvent(event: DOMEvent!) {
        if let video = event.target as? DOMElement {
            let paused = video.valueForKey("paused") as? Bool
            if (paused == true) {
                video.callWebScriptMethod("play", withArguments: nil)
            } else {
                video.callWebScriptMethod("pause", withArguments: nil)
            }
        }
        
    }
}


class HideElementEventListener: NSObject, DOMEventListener {
    /**
    Triggered when the user has clicked an inline media element. Checks if the user is holding the shift key and hides the element.
    
    - parameter event: The event object for this click event.
    */
    func handleEvent(event: DOMEvent!) {
        let mouseEvent = event as! DOMMouseEvent
        if mouseEvent.shiftKey == true {
            let mediaElement = event.currentTarget as! DOMElement
            mediaElement.classList += ["hidden"]
            event.preventDefault()
        }
    }
}

class ShowElementEventListener: NSObject, DOMEventListener {
    /**
    Triggered when the user has clicked a url for an inline media element. Checks if the user is holding the shift key and displays the element.
    
    - parameter event: The event object for this click event.
    */
    func handleEvent(event: DOMEvent!) {
        let mouseEvent = event as! DOMMouseEvent
        if mouseEvent.shiftKey == true {
            let linkElement = event.target as! DOMElement
            let url = linkElement.getAttribute("href")
            let mediaElement = linkElement.parentElement.querySelector(".inlineMediaCell[href='\(url)']")
            if let index = mediaElement.classList.indexOf("hidden") {
                mediaElement.classList.removeAtIndex(index)
            }
            event.preventDefault()
        }
    }
}

