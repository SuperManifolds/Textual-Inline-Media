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

let MAXIMUM_RESPONSE_BODY_SIZE = 4194304

class WebRequest: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate {
    private var session: NSURLSession!
    private let url: NSURL
    private let controller: TVCLogController
    private let line: String
    private var data: NSMutableData
    private let originalUrl: NSURL?
    
    /**
    Create a web request to get information about this URL
    
    - parameter url:         The url of the page to make the request to
    - parameter controller:  A Textual "Log Controller" for the view we want to insert the inline media
    - parameter line:        The unique identifier of the line we want to insert the inline media into
    - parameter originalUrl: The original url if this request is the result of a previous redirect
    
    - returns: An instance of a WebRequest
    */
    required init(url: NSURL, controller: TVCLogController, line: String, originalUrl: NSURL? = nil) {
        self.url = url
        self.controller = controller
        self.line = line
        self.data = NSMutableData()
        self.originalUrl = originalUrl
        
        super.init()
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.HTTPAdditionalHeaders = ["User-Agent": "TextualInlineMedia/1.0 (https://github.com/xlexi/Textual-Inline-Media/; alex@sorlie.co.uk)"]
        self.session = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    /**
    Start the web request
    */
    func start() {
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 300)
        request.HTTPMethod = "GET"
        session.dataTaskWithRequest(request).resume()
    }
    
    /**
    Called when the webserver is giving us a redirect. We will intercept this redirect and go back to processInlineMediaFromUrl in case any of our media handlers are interested in this new URL
    
    - parameter session:           The NSURLSession object associated with this task
    - parameter task:              The NSURLSessionTask for this specific http request
    - parameter response:          The HTTP response by the server
    - parameter request:           A new NSURLRequest object containing the URL the server wishes us to go to
    - parameter completionHandler: A completion handler to call should we wish NSURLSession to continue through the redirect
    */
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        let originalUrl = self.originalUrl != nil ? self.originalUrl : self.url
        InlineMedia.processInlineMediaFromUrl(request.URL!, controller: self.controller, line: self.line, originalUrl: originalUrl)
        task.cancel()
    }
    
    /**
    Called when the web request has completed
    
    - parameter session: The NSURLSession object associated with this task
    - parameter task:    The NSURLSessionTask for this specific http request
    - parameter error:   The error message if the request was completed due to an error
    */
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        guard error == nil else {
            return
        }
        
        if let response = task.response as? NSHTTPURLResponse {
            Webpage(data: self.data, response: response, controller: self.controller, line: self.line).start()
        }
    }
    
    /**
    Called when we have received data from the response body
    
    - parameter session:  The NSURLSession object associated with this task
    - parameter dataTask: The NSURLSessionDataTask for this specific http response
    - parameter data:     The data returned from the server
    */
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        self.data.appendData(data)
        
        /* Disconnect if the response body is larger than the allowed request body size  */
        if self.data.length > MAXIMUM_RESPONSE_BODY_SIZE {
            dataTask.cancel()
        }
    }
    
    /**
    Called when we have received response headers from the server
    
    - parameter session:           The NSURLSession object associated with this task
    - parameter dataTask:          The NSURLSessionDataTask for this specific http response
    - parameter response:          The response from the server
    - parameter completionHandler: A completion handler to call with whether the session should get the response body or disconnect
    */
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        if let httpResponse = response as? NSHTTPURLResponse {
            /* If the request is HTML, continue the download. If not, just get the headers and act accordingly. */
            let contentType = httpResponse.allHeaderFields["Content-Type"]
            if contentType?.contains("text/html") == true {
                completionHandler(.Allow)
                return
            } else {
                if contentType?.hasPrefix("image/gif") == true {
                    AnimatedImage.create(controller, url: httpResponse.URL!, line: self.line)
                } else if contentType?.hasPrefix("image/") == true {
                    let originalUrl = self.originalUrl != nil ? self.originalUrl! : self.url
                    InlineImage(url: originalUrl, response: httpResponse, controller: controller, line: line).start()
                } else {
                    /* This is a file type that we do not have a special preview for, we will display a generic file information preview with file name, file type, file icon, and file size.  */
                    FileInformation(response: httpResponse, controller: controller, line: line).start()
                }
            } 
        }
        completionHandler(.Cancel)
    }
}