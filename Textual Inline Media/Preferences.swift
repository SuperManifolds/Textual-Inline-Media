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
import Sparkle

class Preferences: NSViewController, SUUpdaterDelegate, NSTabViewDelegate {
    @IBOutlet weak var preferences: NSView!
    @IBOutlet weak var displayInformationForDuplicates: NSButton!
    @IBOutlet weak var maximumPreviewsPerMessage: NSTextField!
    @IBOutlet weak var displayAnimatedImages: NSButton!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet var extensionPreferenceView: NSView!
    @IBOutlet var servicesTableView: PreferencesTableView!
    @IBOutlet var servicesContentViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var servicesContentViewHeigtConstraint: NSLayoutConstraint!
    
    var updater: SUUpdater?
    
    @IBAction func checkForUpdatesClicked(sender: AnyObject) {
        updater = SUUpdater(forBundle: NSBundle(forClass: object_getClass(self)))
        updater!.delegate = self
        updater!.resetUpdateCycle()
        updater!.checkForUpdates(sender)
    }
    
    override func viewDidAppear() {
        self.tabView.delegate = self
        let defaults = NSUserDefaults.standardUserDefaults()
        
        self.displayInformationForDuplicates.state = defaults.integerForKey("displayInformationForDuplicates")
        self.maximumPreviewsPerMessage.stringValue = String(defaults.integerForKey("maximumPreviewsPerMessage"))
        self.displayAnimatedImages.state           = defaults.integerForKey("displayAnimatedImages")
    }
    
    func pathToRelaunchForUpdater(updater: SUUpdater!) -> String! {
        return NSBundle.mainBundle().bundlePath
    }
    
    required override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @IBAction func displayInformationForDuplicatesChange(sender: NSButton) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(sender.state, forKey: "displayInformationForDuplicates")
        defaults.synchronize()
    }
    
    @IBAction func maximumPreviewsPerMessageChange(sender: NSTextField) {
        if let maxMessagePreviews = Int(sender.stringValue) {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setInteger(maxMessagePreviews, forKey: "maximumPreviewsPerMessage")
            defaults.synchronize()
        }
    }
    
    @IBAction func displayAnimatedImagesChange(sender: NSButton) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(sender.state, forKey: "displayAnimatedImages")
        defaults.synchronize()
    }
    
    
    @IBAction func tableViewSelectionChanged(sender: NSTableView) {
        if let preferenceMediaHandler = InlineMedia.mediaHandlers[sender.selectedRow] as? InlineMediaPreferenceHandler.Type {
            let handlerInstance = preferenceMediaHandler.init()
            self.extensionPreferenceView.attachSubview(handlerInstance.preferences()!, adjustedWidthConstraint: self.servicesContentViewWidthConstraint, adjustedHeightConstraint: self.servicesContentViewHeigtConstraint)
        }
    }
}