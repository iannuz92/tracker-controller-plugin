//
//  AudioUnitViewController.swift
//  TrackerControllerAU
//
//  Created by AI Assistant on 2025-01-27.
//  Copyright © 2025 Polyend Community. All rights reserved.
//

import CoreAudioKit
import SwiftUI
import TrackerControllerFramework

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    
    // MARK: - Properties
    
    private var audioUnit: TrackerControllerAudioUnit?
    private var hostingController: NSHostingController<TrackerControllerView>?
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set preferred content size
        preferredContentSize = NSSize(width: 600, height: 500)
        
        setupUI()
    }
    
    public override var preferredMaximumSize: NSSize {
        return NSSize(width: 800, height: 600)
    }
    
    public override var preferredMinimumSize: NSSize {
        return NSSize(width: 500, height: 400)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Create SwiftUI view
        let trackerView = TrackerControllerView(audioUnit: audioUnit)
        
        // Create hosting controller
        hostingController = NSHostingController(rootView: trackerView)
        
        guard let hostingController = hostingController else { return }
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
    
    // MARK: - AUAudioUnitFactory
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        
        let audioUnit = try TrackerControllerAudioUnit(
            componentDescription: componentDescription,
            options: []
        )
        
        self.audioUnit = audioUnit
        
        // Update UI on main thread
        DispatchQueue.main.async { [weak self] in
            self?.updateUIWithAudioUnit()
        }
        
        return audioUnit
    }
    
    private func updateUIWithAudioUnit() {
        guard let audioUnit = audioUnit else { return }
        
        // Recreate the SwiftUI view with the audio unit
        let trackerView = TrackerControllerView(audioUnit: audioUnit)
        hostingController?.rootView = trackerView
    }
}

// MARK: - NSViewController Sizing

extension AudioUnitViewController {
    
    public override func viewWillAppear() {
        super.viewWillAppear()
        
        // Ensure proper sizing when view appears
        if let window = view.window {
            let newSize = preferredContentSize
            window.setContentSize(newSize)
        }
    }
} 