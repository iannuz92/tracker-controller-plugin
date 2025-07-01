//
//  TrackerControllerViewModel.swift
//  TrackerControllerFramework
//
//  Created by AI Assistant on 2025-01-27.
//  Copyright © 2025 Polyend Community. All rights reserved.
//

import Foundation
import SwiftUI
import AudioUnit
import Combine

// MARK: - TrackerControllerViewModel

public class TrackerControllerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isPlaying: Bool = false
    @Published var isRecording: Bool = false
    @Published var currentPattern: Int = 0
    @Published var currentBPM: Int = 120
    
    @Published var trackVolumes: [Float] = Array(repeating: 0.8, count: 8)
    @Published var trackPans: [Float] = Array(repeating: 0.0, count: 8)
    @Published var trackMutes: [Bool] = Array(repeating: false, count: 8)
    
    @Published var delayLevel: Float = 0.0
    @Published var reverbLevel: Float = 0.0
    @Published var macroValues: [Float] = Array(repeating: 0.5, count: 6)
    
    // New advanced controls
    @Published var masterVolume: Float = 0.8
    @Published var swing: Float = 0.5
    @Published var patternLength: Int = 16
    @Published var quantizeEnabled: Bool = false
    
    // Connection and sync status
    @Published var isDeviceConnected: Bool = false
    @Published var deviceConnectionStatus: String = "Checking..."
    @Published var isTempoSyncEnabled: Bool = false
    @Published var isAutoSyncEnabled: Bool = true
    
    // Preset management
    @Published var availablePresets: [TrackerControllerPreset] = []
    @Published var currentPresetName: String = "Default"
    
    // Computed property for BPM slider
    var bpmSlider: Float {
        get { Float(currentBPM) }
        set { 
            currentBPM = Int(newValue)
            audioUnit?.setBPM(currentBPM)
        }
    }
    
    // MARK: - Private Properties
    
    private weak var audioUnit: TrackerControllerAudioUnit?
    private var cancellables = Set<AnyCancellable>()
    private var parameterObserverToken: AUParameterObserverToken?
    
    // MARK: - Initialization
    
    public init(audioUnit: TrackerControllerAudioUnit?) {
        self.audioUnit = audioUnit
        setupParameterObservation()
        setupBindings()
        syncWithAudioUnit()
    }
    
    deinit {
        if let token = parameterObserverToken {
            audioUnit?.parameterTree?.removeParameterObserver(token)
        }
    }
    
    // MARK: - Setup
    
    private func setupParameterObservation() {
        guard let audioUnit = audioUnit,
              let parameterTree = audioUnit.parameterTree else { return }
        
        parameterObserverToken = parameterTree.token(byAddingParameterObserver: { [weak self] address, value in
            DispatchQueue.main.async {
                self?.handleParameterChange(address: address, value: value)
            }
        })
    }
    
    private func setupBindings() {
        // Track Volume bindings
        for i in 0..<8 {
            $trackVolumes
                .map { $0[i] }
                .removeDuplicates()
                .sink { [weak self] volume in
                    self?.audioUnit?.setTrackVolume(volume, forTrack: i)
                }
                .store(in: &cancellables)
        }
        
        // Track Pan bindings
        for i in 0..<8 {
            $trackPans
                .map { $0[i] }
                .removeDuplicates()
                .sink { [weak self] pan in
                    self?.audioUnit?.setTrackPan(pan, forTrack: i)
                }
                .store(in: &cancellables)
        }
        
        // Delay Level binding
        $delayLevel
            .removeDuplicates()
            .sink { [weak self] level in
                self?.audioUnit?.setDelayLevel(level)
            }
            .store(in: &cancellables)
        
        // Reverb Level binding
        $reverbLevel
            .removeDuplicates()
            .sink { [weak self] level in
                self?.audioUnit?.setReverbLevel(level)
            }
            .store(in: &cancellables)
        
        // Macro bindings
        for i in 0..<6 {
            $macroValues
                .map { $0[i] }
                .removeDuplicates()
                .sink { [weak self] value in
                    self?.audioUnit?.setMacroValue(value, forMacro: i)
                }
                .store(in: &cancellables)
        }
    }
    
    private func syncWithAudioUnit() {
        guard let audioUnit = audioUnit else { return }
        
        // Sync state from audio unit
        isPlaying = audioUnit.isPlaying
        isRecording = audioUnit.isRecording
        currentPattern = audioUnit.currentPattern
        currentBPM = audioUnit.currentBPM
        
        // Sync track parameters
        for i in 0..<8 {
            if i < audioUnit.trackVolumes.count {
                trackVolumes[i] = audioUnit.trackVolumes[i].floatValue
            }
            if i < audioUnit.trackPans.count {
                trackPans[i] = audioUnit.trackPans[i].floatValue
            }
            if i < audioUnit.trackMutes.count {
                trackMutes[i] = audioUnit.trackMutes[i].boolValue
            }
        }
        
        // Sync FX parameters
        delayLevel = audioUnit.delayLevel
        reverbLevel = audioUnit.reverbLevel
        
        for i in 0..<6 {
            if i < audioUnit.macroValues.count {
                macroValues[i] = audioUnit.macroValues[i].floatValue
            }
        }
    }
    
    // MARK: - Parameter Change Handling
    
    private func handleParameterChange(address: AUParameterAddress, value: AUValue) {
        guard let param = TrackerControllerParameter(rawValue: address) else { return }
        
        switch param {
        case .pattern:
            currentPattern = Int(value)
        case .bpm:
            currentBPM = Int(value)
        case .playStop:
            isPlaying = value > 0.5
        case .record:
            isRecording = value > 0.5
        case .trackVolume1, .trackVolume2, .trackVolume3, .trackVolume4,
             .trackVolume5, .trackVolume6, .trackVolume7, .trackVolume8:
            let trackIndex = Int(address - TrackerControllerParameter.trackVolume1.rawValue)
            if trackIndex < trackVolumes.count {
                trackVolumes[trackIndex] = value
            }
        case .trackPan1, .trackPan2, .trackPan3, .trackPan4,
             .trackPan5, .trackPan6, .trackPan7, .trackPan8:
            let trackIndex = Int(address - TrackerControllerParameter.trackPan1.rawValue)
            if trackIndex < trackPans.count {
                trackPans[trackIndex] = value
            }
        case .trackMute1, .trackMute2, .trackMute3, .trackMute4,
             .trackMute5, .trackMute6, .trackMute7, .trackMute8:
            let trackIndex = Int(address - TrackerControllerParameter.trackMute1.rawValue)
            if trackIndex < trackMutes.count {
                trackMutes[trackIndex] = value > 0.5
            }
        case .delayLevel:
            delayLevel = value
        case .reverbLevel:
            reverbLevel = value
        case .macro1, .macro2, .macro3, .macro4, .macro5, .macro6:
            let macroIndex = Int(address - TrackerControllerParameter.macro1.rawValue)
            if macroIndex < macroValues.count {
                macroValues[macroIndex] = value
            }
        }
    }
    
    // MARK: - Transport Controls
    
    func togglePlayStop() {
        if isPlaying {
            audioUnit?.stopPattern()
        } else {
            audioUnit?.playPattern()
        }
    }
    
    func toggleRecord() {
        audioUnit?.toggleRecord()
    }
    
    // MARK: - Pattern Controls
    
    func selectPattern(_ pattern: Int) {
        let clampedPattern = max(0, min(127, pattern))
        currentPattern = clampedPattern
        audioUnit?.selectPattern(clampedPattern)
    }
    
    func selectNextPattern() {
        selectPattern(currentPattern + 1)
    }
    
    func selectPreviousPattern() {
        selectPattern(currentPattern - 1)
    }
    
    // MARK: - Track Controls
    
    func setTrackVolume(_ volume: Float, forTrack track: Int) {
        guard track >= 0 && track < trackVolumes.count else { return }
        trackVolumes[track] = max(0, min(1, volume))
    }
    
    func setTrackPan(_ pan: Float, forTrack track: Int) {
        guard track >= 0 && track < trackPans.count else { return }
        trackPans[track] = max(-1, min(1, pan))
    }
    
    func toggleMute(track: Int) {
        guard track >= 0 && track < trackMutes.count else { return }
        
        let newMuteState = !trackMutes[track]
        trackMutes[track] = newMuteState
        
        if newMuteState {
            audioUnit?.muteTrack(track)
        } else {
            audioUnit?.unmuteTrack(track)
        }
    }
    
    func soloTrack(_ track: Int) {
        audioUnit?.soloTrack(track)
        
        // Update local state
        for i in 0..<trackMutes.count {
            trackMutes[i] = (i != track)
        }
    }
    
    func triggerTrack(_ track: Int, velocity: UInt8 = 127) {
        // This would trigger the track via MIDI
        // For now, we'll just provide the interface
        // The actual implementation would depend on how the Tracker Mini handles track triggers
    }
    
    // MARK: - Performance FX Controls
    
    func setDelayLevel(_ level: Float) {
        delayLevel = max(0, min(1, level))
    }
    
    func setReverbLevel(_ level: Float) {
        reverbLevel = max(0, min(1, level))
    }
    
    func setMacroValue(_ value: Float, forMacro macro: Int) {
        guard macro >= 0 && macro < macroValues.count else { return }
        macroValues[macro] = max(0, min(1, value))
    }
    
    // MARK: - Utility Methods
    
    func resetAllControls() {
        // Reset to default values
        currentPattern = 0
        currentBPM = 120
        isPlaying = false
        isRecording = false
        
        trackVolumes = Array(repeating: 0.8, count: 8)
        trackPans = Array(repeating: 0.0, count: 8)
        trackMutes = Array(repeating: false, count: 8)
        
        delayLevel = 0.0
        reverbLevel = 0.0
        macroValues = Array(repeating: 0.5, count: 6)
        
        // Reset new controls
        masterVolume = 0.8
        swing = 0.5
        patternLength = 16
        quantizeEnabled = false
        
        // Apply to audio unit
        audioUnit?.selectPattern(0)
        audioUnit?.setBPM(120)
        audioUnit?.stopPattern()
        
        for i in 0..<8 {
            audioUnit?.setTrackVolume(0.8, forTrack: i)
            audioUnit?.setTrackPan(0.0, forTrack: i)
            audioUnit?.unmuteTrack(i)
        }
        
        audioUnit?.setDelayLevel(0.0)
        audioUnit?.setReverbLevel(0.0)
        
        for i in 0..<6 {
            audioUnit?.setMacroValue(0.5, forMacro: i)
        }
        
        // Apply new controls
        audioUnit?.setMasterVolume(0.8)
        audioUnit?.setSwing(0.5)
        audioUnit?.setPatternLength(16)
        audioUnit?.setQuantizeEnabled(false)
    }
    
    func savePreset(name: String) -> Bool {
        // Implementation for saving presets
        // This would save the current state to UserDefaults or a file
        let preset = TrackerControllerPreset(
            name: name,
            pattern: currentPattern,
            bpm: currentBPM,
            trackVolumes: trackVolumes,
            trackPans: trackPans,
            trackMutes: trackMutes,
            delayLevel: delayLevel,
            reverbLevel: reverbLevel,
            macroValues: macroValues,
            masterVolume: masterVolume,
            swing: swing,
            patternLength: patternLength,
            quantizeEnabled: quantizeEnabled
        )
        
        return PresetManager.shared.savePreset(preset)
    }
    
    func loadPreset(_ preset: TrackerControllerPreset) {
        currentPattern = preset.pattern
        currentBPM = preset.bpm
        trackVolumes = preset.trackVolumes
        trackPans = preset.trackPans
        trackMutes = preset.trackMutes
        delayLevel = preset.delayLevel
        reverbLevel = preset.reverbLevel
        macroValues = preset.macroValues
        masterVolume = preset.masterVolume
        swing = preset.swing
        patternLength = preset.patternLength
        quantizeEnabled = preset.quantizeEnabled
        
        // Apply to audio unit
        audioUnit?.selectPattern(preset.pattern)
        audioUnit?.setBPM(preset.bpm)
        
        for i in 0..<8 {
            if i < preset.trackVolumes.count {
                audioUnit?.setTrackVolume(preset.trackVolumes[i], forTrack: i)
            }
            if i < preset.trackPans.count {
                audioUnit?.setTrackPan(preset.trackPans[i], forTrack: i)
            }
            if i < preset.trackMutes.count {
                if preset.trackMutes[i] {
                    audioUnit?.muteTrack(i)
                } else {
                    audioUnit?.unmuteTrack(i)
                }
            }
        }
        
        audioUnit?.setDelayLevel(preset.delayLevel)
        audioUnit?.setReverbLevel(preset.reverbLevel)
        
        for i in 0..<6 {
            if i < preset.macroValues.count {
                audioUnit?.setMacroValue(preset.macroValues[i], forMacro: i)
            }
        }
        
        // Apply new advanced parameters
        audioUnit?.setMasterVolume(preset.masterVolume)
        audioUnit?.setSwing(preset.swing)
        audioUnit?.setPatternLength(preset.patternLength)
        audioUnit?.setQuantizeEnabled(preset.quantizeEnabled)
    }
    
    // MARK: - Advanced Control Methods
    
    func setMasterVolume(_ volume: Float) {
        masterVolume = max(0, min(1, volume))
        audioUnit?.setMasterVolume(masterVolume)
    }
    
    func setSwing(_ swingValue: Float) {
        swing = max(0, min(1, swingValue))
        audioUnit?.setSwing(swing)
    }
    
    func setPatternLength(_ length: Int) {
        patternLength = max(16, min(128, length))
        audioUnit?.setPatternLength(patternLength)
    }
    
    func setQuantizeEnabled(_ enabled: Bool) {
        quantizeEnabled = enabled
        audioUnit?.setQuantizeEnabled(enabled)
    }
    
    // MARK: - Connection Management
    
    func checkDeviceConnection() {
        // This would check the MIDI connection status
        DispatchQueue.global(qos: .background).async { [weak self] in
            // Simulate connection check
            let isConnected = self?.audioUnit?.midiController?.isTrackerMiniConnected() ?? false
            let deviceName = self?.audioUnit?.midiController?.getConnectedDeviceName()
            
            DispatchQueue.main.async {
                self?.isDeviceConnected = isConnected
                if isConnected {
                    self?.deviceConnectionStatus = "Connected to \(deviceName ?? "Tracker Mini")"
                } else {
                    self?.deviceConnectionStatus = "No device connected"
                }
            }
        }
    }
    
    func reconnectToDevice() {
        deviceConnectionStatus = "Reconnecting..."
        audioUnit?.midiController?.reconnectToDevice()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkDeviceConnection()
        }
    }
    
    // MARK: - Preset Management
    
    func loadPreset() {
        // Load available presets
        availablePresets = PresetManager.shared.loadAllPresets()
        
        // For now, load the first preset if available
        if let firstPreset = availablePresets.first {
            loadPreset(firstPreset)
            currentPresetName = firstPreset.name
        }
    }
    
    func savePreset() {
        let presetName = "Preset \(Date().timeIntervalSince1970)"
        if savePreset(name: presetName) {
            currentPresetName = presetName
            loadAvailablePresets()
        }
    }
    
    func loadAvailablePresets() {
        availablePresets = PresetManager.shared.loadAllPresets()
    }
    
    func deletePreset(_ preset: TrackerControllerPreset) {
        if PresetManager.shared.deletePreset(named: preset.name) {
            loadAvailablePresets()
        }
    }
    
    // MARK: - MIDI Learn
    
    func enableMIDILearn(for parameter: String) {
        // Implementation for MIDI learn functionality
        // This would allow users to assign MIDI CCs to parameters dynamically
    }
    
    // MARK: - Performance Features
    
    func triggerAllTracks() {
        for i in 0..<8 {
            if !trackMutes[i] {
                // Trigger track with current volume as velocity
                let velocity = UInt8(trackVolumes[i] * 127)
                audioUnit?.midiController?.triggerTrack(i, velocity: velocity)
            }
        }
    }
    
    func muteAllTracks() {
        for i in 0..<8 {
            if !trackMutes[i] {
                toggleMute(track: i)
            }
        }
    }
    
    func unmuteAllTracks() {
        for i in 0..<8 {
            if trackMutes[i] {
                toggleMute(track: i)
            }
        }
    }
    
    func randomizeTrackVolumes() {
        for i in 0..<8 {
            let randomVolume = Float.random(in: 0.3...1.0)
            setTrackVolume(randomVolume, forTrack: i)
        }
    }
    
    func randomizeMacros() {
        for i in 0..<6 {
            let randomValue = Float.random(in: 0...1)
            setMacroValue(randomValue, forMacro: i)
        }
    }
}

// MARK: - TrackerControllerPreset

struct TrackerControllerPreset: Codable {
    let name: String
    let pattern: Int
    let bpm: Int
    let trackVolumes: [Float]
    let trackPans: [Float]
    let trackMutes: [Bool]
    let delayLevel: Float
    let reverbLevel: Float
    let macroValues: [Float]
    
    // New advanced parameters
    let masterVolume: Float
    let swing: Float
    let patternLength: Int
    let quantizeEnabled: Bool
    
    let createdAt: Date
    let version: String // For future compatibility
    
    init(name: String, pattern: Int, bpm: Int, trackVolumes: [Float], trackPans: [Float], 
         trackMutes: [Bool], delayLevel: Float, reverbLevel: Float, macroValues: [Float],
         masterVolume: Float = 0.8, swing: Float = 0.5, patternLength: Int = 16, quantizeEnabled: Bool = false) {
        self.name = name
        self.pattern = pattern
        self.bpm = bpm
        self.trackVolumes = trackVolumes
        self.trackPans = trackPans
        self.trackMutes = trackMutes
        self.delayLevel = delayLevel
        self.reverbLevel = reverbLevel
        self.macroValues = macroValues
        self.masterVolume = masterVolume
        self.swing = swing
        self.patternLength = patternLength
        self.quantizeEnabled = quantizeEnabled
        self.createdAt = Date()
        self.version = "1.1.0"
    }
}

// MARK: - PresetManager

class PresetManager {
    static let shared = PresetManager()
    
    private let presetsKey = "TrackerControllerPresets"
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    func savePreset(_ preset: TrackerControllerPreset) -> Bool {
        do {
            var presets = loadAllPresets()
            
            // Remove existing preset with same name
            presets.removeAll { $0.name == preset.name }
            
            // Add new preset
            presets.append(preset)
            
            let data = try JSONEncoder().encode(presets)
            userDefaults.set(data, forKey: presetsKey)
            return true
        } catch {
            print("Failed to save preset: \(error)")
            return false
        }
    }
    
    func loadAllPresets() -> [TrackerControllerPreset] {
        guard let data = userDefaults.data(forKey: presetsKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([TrackerControllerPreset].self, from: data)
        } catch {
            print("Failed to load presets: \(error)")
            return []
        }
    }
    
    func deletePreset(named name: String) -> Bool {
        var presets = loadAllPresets()
        let initialCount = presets.count
        
        presets.removeAll { $0.name == name }
        
        if presets.count < initialCount {
            do {
                let data = try JSONEncoder().encode(presets)
                userDefaults.set(data, forKey: presetsKey)
                return true
            } catch {
                print("Failed to save presets after deletion: \(error)")
                return false
            }
        }
        
        return false
    }
} 