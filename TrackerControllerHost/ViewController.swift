//
//  ViewController.swift
//  TrackerControllerHost
//
//  Created by AI Assistant on 2025-01-27.
//  Copyright © 2025 Polyend Community. All rights reserved.
//

import Cocoa
import AudioUnit
import CoreAudioKit
import AVFoundation
import TrackerControllerFramework

class ViewController: NSViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var auContainerView: NSView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var loadButton: NSButton!
    @IBOutlet weak var testButton: NSButton!
    
    // MARK: - Properties
    
    private var audioUnit: TrackerControllerAudioUnit?
    private var auViewController: AudioUnitViewController?
    private var audioEngine: AVAudioEngine?
    private var midiOutput: AVAudioUnitMIDIInstrument?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAudio()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        statusLabel.stringValue = "Ready to load Audio Unit"
        loadButton.title = "Load Tracker Controller"
        testButton.title = "Test MIDI Output"
        testButton.isEnabled = false
        
        auContainerView.wantsLayer = true
        auContainerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }
    
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        
        do {
            try audioEngine?.start()
            statusLabel.stringValue = "Audio engine started"
        } catch {
            statusLabel.stringValue = "Failed to start audio engine: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Actions
    
    @IBAction func loadAudioUnit(_ sender: NSButton) {
        loadTrackerController()
    }
    
    @IBAction func testMIDIOutput(_ sender: NSButton) {
        testMIDI()
    }
    
    // MARK: - Audio Unit Loading
    
    private func loadTrackerController() {
        statusLabel.stringValue = "Loading Tracker Controller..."
        
        let componentDescription = AudioComponentDescription(
            componentType: kAudioUnitType_MIDIProcessor,
            componentSubType: 0x54435452, // 'TCTR'
            componentManufacturer: 0x504F4C59, // 'POLY'
            componentFlags: 0,
            componentFlagsMask: 0
        )
        
        AVAudioUnit.instantiate(with: componentDescription) { [weak self] audioUnit, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.statusLabel.stringValue = "Failed to load AU: \(error.localizedDescription)"
                    return
                }
                
                guard let audioUnit = audioUnit else {
                    self?.statusLabel.stringValue = "Audio Unit is nil"
                    return
                }
                
                self?.setupAudioUnit(audioUnit)
            }
        }
    }
    
    private func setupAudioUnit(_ avAudioUnit: AVAudioUnit) {
        guard let trackerAU = avAudioUnit.auAudioUnit as? TrackerControllerAudioUnit else {
            statusLabel.stringValue = "Failed to cast to TrackerControllerAudioUnit"
            return
        }
        
        self.audioUnit = trackerAU
        
        // Create view controller
        let auViewController = AudioUnitViewController()
        
        do {
            let audioUnit = try auViewController.createAudioUnit(with: avAudioUnit.audioComponentDescription)
            self.auViewController = auViewController
            
            // Add to container view
            addChild(auViewController)
            auContainerView.addSubview(auViewController.view)
            
            // Setup constraints
            auViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                auViewController.view.topAnchor.constraint(equalTo: auContainerView.topAnchor),
                auViewController.view.leadingAnchor.constraint(equalTo: auContainerView.leadingAnchor),
                auViewController.view.trailingAnchor.constraint(equalTo: auContainerView.trailingAnchor),
                auViewController.view.bottomAnchor.constraint(equalTo: auContainerView.bottomAnchor)
            ])
            
            auViewController.didMove(toParent: self)
            
            // Connect to audio engine
            audioEngine?.attach(avAudioUnit)
            
            statusLabel.stringValue = "Tracker Controller loaded successfully"
            testButton.isEnabled = true
            loadButton.title = "Reload"
            
        } catch {
            statusLabel.stringValue = "Failed to create audio unit: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Testing
    
    private func testMIDI() {
        guard let audioUnit = audioUnit else {
            statusLabel.stringValue = "No audio unit loaded"
            return
        }
        
        statusLabel.stringValue = "Testing MIDI..."
        
        // Test various MIDI commands
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            audioUnit.playPattern()
            self.statusLabel.stringValue = "Sent play command"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            audioUnit.selectPattern(1)
            self.statusLabel.stringValue = "Changed to pattern 1"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            audioUnit.setBPM(140)
            self.statusLabel.stringValue = "Set BPM to 140"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            audioUnit.setTrackVolume(0.5, forTrack: 0)
            self.statusLabel.stringValue = "Set track 1 volume to 50%"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            audioUnit.stopPattern()
            self.statusLabel.stringValue = "Sent stop command - Test complete"
        }
    }
}

// MARK: - Storyboard Setup

extension ViewController {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Additional setup that requires the nib to be loaded
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
} 