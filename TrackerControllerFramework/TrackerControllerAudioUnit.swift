//
//  TrackerControllerAudioUnit.swift
//  TrackerControllerFramework
//
//  Created by AI Assistant on 2025-01-27.
//  Copyright © 2025 Polyend Community. All rights reserved.
//

import AudioUnit
import AudioToolbox
import AVFoundation
import CoreMIDI
import os.log

// MARK: - Atomic State for Thread Safety

private class AtomicState {
    private let queue = DispatchQueue(label: "com.polyend.TrackerController.atomicState", attributes: .concurrent)
    
    private var _currentPattern: Int = 0
    private var _currentBPM: Int = 120
    private var _isPlaying: Bool = false
    private var _isRecording: Bool = false
    
    var currentPattern: Int {
        get {
            return queue.sync { _currentPattern }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?._currentPattern = newValue
            }
        }
    }
    
    var currentBPM: Int {
        get {
            return queue.sync { _currentBPM }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?._currentBPM = newValue
            }
        }
    }
    
    var isPlaying: Bool {
        get {
            return queue.sync { _isPlaying }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?._isPlaying = newValue
            }
        }
    }
    
    var isRecording: Bool {
        get {
            return queue.sync { _isRecording }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?._isRecording = newValue
            }
        }
    }
}

// MARK: - Real-Time Safe Logger

class RTSafeLogger {
    private static let bufferSize = 1024
    private static var logBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    private static var writeIndex = 0
    private static let queue = DispatchQueue(label: "com.polyend.TrackerController.logging", qos: .utility)
    
    static func log(_ message: String, level: OSLogType = .debug) {
        queue.async {
            os_log("%{public}@", log: OSLog(subsystem: "com.polyend.TrackerController", category: "AudioUnit"), type: level, message)
        }
    }
    
    static func rtLog(eventType: UInt8, value: Float) {
        // Real-time safe logging - just store values for later processing
        let writePos = writeIndex
        if writePos < bufferSize - 8 {
            logBuffer.advanced(by: writePos).pointee = eventType
            logBuffer.advanced(by: writePos + 1).withMemoryRebound(to: Float.self, capacity: 1) { $0.pointee = value }
            writeIndex = writePos + 8
        }
    }
}

// MARK: - TrackerControllerParameter

enum TrackerControllerParameter: AUParameterAddress {
    case pattern = 1000
    case bpm = 1001
    case playStop = 1002
    case record = 1003
    
    // Track controls (8 tracks)
    case trackVolume1 = 2000, trackVolume2, trackVolume3, trackVolume4
    case trackVolume5, trackVolume6, trackVolume7, trackVolume8
    
    case trackPan1 = 2100, trackPan2, trackPan3, trackPan4
    case trackPan5, trackPan6, trackPan7, trackPan8
    
    case trackMute1 = 2200, trackMute2, trackMute3, trackMute4
    case trackMute5, trackMute6, trackMute7, trackMute8
    
    // Performance FX
    case delayLevel = 3000
    case reverbLevel = 3001
    case macro1 = 3100, macro2, macro3, macro4, macro5, macro6
    
    // New advanced parameters
    case masterVolume = 4000
    case swing = 4001
    case patternLength = 4002
    case quantize = 4003
    
    var name: String {
        switch self {
        case .pattern: return "Pattern"
        case .bpm: return "BPM"
        case .playStop: return "Play/Stop"
        case .record: return "Record"
        case .trackVolume1: return "Track 1 Volume"
        case .trackVolume2: return "Track 2 Volume"
        case .trackVolume3: return "Track 3 Volume"
        case .trackVolume4: return "Track 4 Volume"
        case .trackVolume5: return "Track 5 Volume"
        case .trackVolume6: return "Track 6 Volume"
        case .trackVolume7: return "Track 7 Volume"
        case .trackVolume8: return "Track 8 Volume"
        case .trackPan1: return "Track 1 Pan"
        case .trackPan2: return "Track 2 Pan"
        case .trackPan3: return "Track 3 Pan"
        case .trackPan4: return "Track 4 Pan"
        case .trackPan5: return "Track 5 Pan"
        case .trackPan6: return "Track 6 Pan"
        case .trackPan7: return "Track 7 Pan"
        case .trackPan8: return "Track 8 Pan"
        case .trackMute1: return "Track 1 Mute"
        case .trackMute2: return "Track 2 Mute"
        case .trackMute3: return "Track 3 Mute"
        case .trackMute4: return "Track 4 Mute"
        case .trackMute5: return "Track 5 Mute"
        case .trackMute6: return "Track 6 Mute"
        case .trackMute7: return "Track 7 Mute"
        case .trackMute8: return "Track 8 Mute"
        case .delayLevel: return "Delay Level"
        case .reverbLevel: return "Reverb Level"
        case .macro1: return "Macro 1"
        case .macro2: return "Macro 2"
        case .macro3: return "Macro 3"
        case .macro4: return "Macro 4"
        case .macro5: return "Macro 5"
        case .macro6: return "Macro 6"
        case .masterVolume: return "Master Volume"
        case .swing: return "Swing"
        case .patternLength: return "Pattern Length"
        case .quantize: return "Quantize"
        }
    }
    
    var identifier: String {
        return "param_\(rawValue)"
    }
    
    var min: AUValue {
        switch self {
        case .pattern: return 0
        case .bpm: return 60
        case .playStop, .record: return 0
        case .trackVolume1, .trackVolume2, .trackVolume3, .trackVolume4,
             .trackVolume5, .trackVolume6, .trackVolume7, .trackVolume8: return 0
        case .trackPan1, .trackPan2, .trackPan3, .trackPan4,
             .trackPan5, .trackPan6, .trackPan7, .trackPan8: return -1
        case .trackMute1, .trackMute2, .trackMute3, .trackMute4,
             .trackMute5, .trackMute6, .trackMute7, .trackMute8: return 0
        case .delayLevel, .reverbLevel: return 0
        case .macro1, .macro2, .macro3, .macro4, .macro5, .macro6: return 0
        case .masterVolume: return 0
        case .swing: return 0
        case .patternLength: return 16
        case .quantize: return 0
        }
    }
    
    var max: AUValue {
        switch self {
        case .pattern: return 127
        case .bpm: return 200
        case .playStop, .record: return 1
        case .trackVolume1, .trackVolume2, .trackVolume3, .trackVolume4,
             .trackVolume5, .trackVolume6, .trackVolume7, .trackVolume8: return 1
        case .trackPan1, .trackPan2, .trackPan3, .trackPan4,
             .trackPan5, .trackPan6, .trackPan7, .trackPan8: return 1
        case .trackMute1, .trackMute2, .trackMute3, .trackMute4,
             .trackMute5, .trackMute6, .trackMute7, .trackMute8: return 1
        case .delayLevel, .reverbLevel: return 1
        case .macro1, .macro2, .macro3, .macro4, .macro5, .macro6: return 1
        case .masterVolume: return 1
        case .swing: return 1
        case .patternLength: return 128
        case .quantize: return 1
        }
    }
    
    var defaultValue: AUValue {
        switch self {
        case .pattern: return 0
        case .bpm: return 120
        case .playStop, .record: return 0
        case .trackVolume1, .trackVolume2, .trackVolume3, .trackVolume4,
             .trackVolume5, .trackVolume6, .trackVolume7, .trackVolume8: return 0.8
        case .trackPan1, .trackPan2, .trackPan3, .trackPan4,
             .trackPan5, .trackPan6, .trackPan7, .trackPan8: return 0
        case .trackMute1, .trackMute2, .trackMute3, .trackMute4,
             .trackMute5, .trackMute6, .trackMute7, .trackMute8: return 0
        case .delayLevel, .reverbLevel: return 0
        case .macro1, .macro2, .macro3, .macro4, .macro5, .macro6: return 0.5
        case .masterVolume: return 0.8
        case .swing: return 0.5
        case .patternLength: return 16
        case .quantize: return 0
        }
    }
    
    var unit: AudioUnitParameterUnit {
        switch self {
        case .pattern, .patternLength: return .indexed
        case .bpm: return .beats
        case .playStop, .record, .quantize: return .boolean
        case .trackVolume1, .trackVolume2, .trackVolume3, .trackVolume4,
             .trackVolume5, .trackVolume6, .trackVolume7, .trackVolume8,
             .masterVolume: return .linearGain
        case .trackPan1, .trackPan2, .trackPan3, .trackPan4,
             .trackPan5, .trackPan6, .trackPan7, .trackPan8: return .pan
        case .trackMute1, .trackMute2, .trackMute3, .trackMute4,
             .trackMute5, .trackMute6, .trackMute7, .trackMute8: return .boolean
        case .delayLevel, .reverbLevel: return .linearGain
        case .macro1, .macro2, .macro3, .macro4, .macro5, .macro6, .swing: return .generic
        }
    }
}

// MARK: - TrackerControllerAudioUnit Implementation

@objc public class TrackerControllerAudioUnit: AUAudioUnit {
    
    // MARK: - Properties
    
    private let logger = OSLog(subsystem: "com.polyend.TrackerController", category: "AudioUnit")
    
    // Parameters
    private var _parameterTree: AUParameterTree!
    private var parameters: [TrackerControllerParameter: AUParameter] = [:]
    
    // MIDI
    private var midiController: MIDIController!
    
    // Real-time safe state (atomic access)
    private var atomicState = AtomicState()
    
    // State - using atomic wrapper for thread safety
    @objc public var currentPattern: NSInteger {
        get { atomicState.currentPattern }
        set { atomicState.currentPattern = newValue }
    }
    
    @objc public var currentBPM: NSInteger {
        get { atomicState.currentBPM }
        set { atomicState.currentBPM = newValue }
    }
    
    @objc public var isPlaying: Bool {
        get { atomicState.isPlaying }
        set { atomicState.isPlaying = newValue }
    }
    
    @objc public var isRecording: Bool {
        get { atomicState.isRecording }
        set { atomicState.isRecording = newValue }
    }
    
    @objc public private(set) var trackVolumes: [NSNumber] = Array(repeating: 0.8, count: 8).map(NSNumber.init)
    @objc public private(set) var trackPans: [NSNumber] = Array(repeating: 0.0, count: 8).map(NSNumber.init)
    @objc public private(set) var trackMutes: [NSNumber] = Array(repeating: false, count: 8).map(NSNumber.init)
    
    @objc public private(set) var delayLevel: Float = 0.0
    @objc public private(set) var reverbLevel: Float = 0.0
    @objc public private(set) var macroValues: [NSNumber] = Array(repeating: 0.5, count: 6).map(NSNumber.init)
    
    // New properties
    @objc public private(set) var masterVolume: Float = 0.8
    @objc public private(set) var swing: Float = 0.5
    @objc public private(set) var patternLength: Int = 16
    @objc public private(set) var quantizeEnabled: Bool = false
    
    // Performance optimization
    private let parameterUpdateQueue = DispatchQueue(label: "com.polyend.TrackerController.parameters", qos: .userInteractive)
    private var pendingParameterUpdates: [AUParameterAddress: AUValue] = [:]
    private var updateTimer: Timer?
    
    // MARK: - Initialization
    
    public override init(componentDescription: AudioComponentDescription, 
                        options: AudioComponentInstantiationOptions = []) throws {
        
        try super.init(componentDescription: componentDescription, options: options)
        
        RTSafeLogger.log("Initializing TrackerControllerAudioUnit", level: .info)
        
        // Initialize MIDI controller
        midiController = MIDIController()
        
        // Setup parameter tree
        setupParameterTree()
        
        // Setup MIDI
        setupMIDI()
        
        // Setup parameter batching
        setupParameterBatching()
        
        RTSafeLogger.log("TrackerControllerAudioUnit initialized successfully", level: .info)
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    // MARK: - Parameter Tree Setup
    
    private func setupParameterTree() {
        let allParameters = [
            TrackerControllerParameter.pattern,
            .bpm, .playStop, .record,
            .trackVolume1, .trackVolume2, .trackVolume3, .trackVolume4,
            .trackVolume5, .trackVolume6, .trackVolume7, .trackVolume8,
            .trackPan1, .trackPan2, .trackPan3, .trackPan4,
            .trackPan5, .trackPan6, .trackPan7, .trackPan8,
            .trackMute1, .trackMute2, .trackMute3, .trackMute4,
            .trackMute5, .trackMute6, .trackMute7, .trackMute8,
            .delayLevel, .reverbLevel,
            .macro1, .macro2, .macro3, .macro4, .macro5, .macro6,
            .masterVolume, .swing, .patternLength, .quantize
        ]
        
        let parameterObjects = allParameters.map { param in
            let parameter = AUParameterTree.createParameter(
                withIdentifier: param.identifier,
                name: param.name,
                address: param.rawValue,
                min: param.min,
                max: param.max,
                unit: param.unit,
                unitName: nil,
                flags: [],
                valueStrings: nil,
                dependentParameters: nil
            )
            parameter.value = param.defaultValue
            parameters[param] = parameter
            return parameter
        }
        
        _parameterTree = AUParameterTree.createTree(withChildren: parameterObjects)
        
        // Setup parameter observer with batching
        _parameterTree.implementorValueObserver = { [weak self] parameter, value in
            self?.scheduleParameterUpdate(address: parameter.address, value: value)
        }
        
        // Setup value provider
        _parameterTree.implementorValueProvider = { [weak self] parameter in
            return self?.getParameterValue(address: parameter.address) ?? 0
        }
    }
    
    // MARK: - Parameter Batching
    
    private func setupParameterBatching() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.processPendingParameterUpdates()
        }
    }
    
    private func scheduleParameterUpdate(address: AUParameterAddress, value: AUValue) {
        parameterUpdateQueue.async { [weak self] in
            self?.pendingParameterUpdates[address] = value
        }
    }
    
    private func processPendingParameterUpdates() {
        parameterUpdateQueue.async { [weak self] in
            guard let self = self else { return }
            
            let updates = self.pendingParameterUpdates
            self.pendingParameterUpdates.removeAll()
            
            DispatchQueue.main.async {
                for (address, value) in updates {
                    self.parameterChanged(address: address, value: value)
                }
            }
        }
    }
    
    // MARK: - MIDI Setup
    
    private func setupMIDI() {
        midiController.delegate = self
    }
    
    // MARK: - Parameter Handling
    
    private func parameterChanged(address: AUParameterAddress, value: AUValue) {
        guard let param = TrackerControllerParameter(rawValue: address) else { return }
        
        RTSafeLogger.log("Parameter changed: %{public}@ = %f", level: .debug)
        
        switch param {
        case .pattern:
            selectPattern(Int(value))
        case .bpm:
            setBPM(Int(value))
        case .playStop:
            if value > 0.5 {
                if isPlaying {
                    stopPattern()
                } else {
                    playPattern()
                }
            }
        case .record:
            if value > 0.5 {
                toggleRecord()
            }
        case .trackVolume1, .trackVolume2, .trackVolume3, .trackVolume4,
             .trackVolume5, .trackVolume6, .trackVolume7, .trackVolume8:
            let trackIndex = Int(address - TrackerControllerParameter.trackVolume1.rawValue)
            setTrackVolume(value, forTrack: trackIndex)
        case .trackPan1, .trackPan2, .trackPan3, .trackPan4,
             .trackPan5, .trackPan6, .trackPan7, .trackPan8:
            let trackIndex = Int(address - TrackerControllerParameter.trackPan1.rawValue)
            setTrackPan(value, forTrack: trackIndex)
        case .trackMute1, .trackMute2, .trackMute3, .trackMute4,
             .trackMute5, .trackMute6, .trackMute7, .trackMute8:
            let trackIndex = Int(address - TrackerControllerParameter.trackMute1.rawValue)
            if value > 0.5 {
                muteTrack(trackIndex)
            } else {
                unmuteTrack(trackIndex)
            }
        case .delayLevel:
            setDelayLevel(value)
        case .reverbLevel:
            setReverbLevel(value)
        case .macro1, .macro2, .macro3, .macro4, .macro5, .macro6:
            let macroIndex = Int(address - TrackerControllerParameter.macro1.rawValue)
            setMacroValue(value, forMacro: macroIndex)
        case .masterVolume:
            setMasterVolume(value)
        case .swing:
            setSwing(value)
        case .patternLength:
            setPatternLength(Int(value))
        case .quantize:
            setQuantizeEnabled(value > 0.5)
        }
    }
    
    private func getParameterValue(address: AUParameterAddress) -> AUValue {
        guard let param = TrackerControllerParameter(rawValue: address) else { return 0 }
        
        switch param {
        case .pattern: return AUValue(currentPattern)
        case .bpm: return AUValue(currentBPM)
        case .playStop: return isPlaying ? 1 : 0
        case .record: return isRecording ? 1 : 0
        case .trackVolume1, .trackVolume2, .trackVolume3, .trackVolume4,
             .trackVolume5, .trackVolume6, .trackVolume7, .trackVolume8:
            let trackIndex = Int(address - TrackerControllerParameter.trackVolume1.rawValue)
            return trackIndex < trackVolumes.count ? trackVolumes[trackIndex].floatValue : 0
        case .trackPan1, .trackPan2, .trackPan3, .trackPan4,
             .trackPan5, .trackPan6, .trackPan7, .trackPan8:
            let trackIndex = Int(address - TrackerControllerParameter.trackPan1.rawValue)
            return trackIndex < trackPans.count ? trackPans[trackIndex].floatValue : 0
        case .trackMute1, .trackMute2, .trackMute3, .trackMute4,
             .trackMute5, .trackMute6, .trackMute7, .trackMute8:
            let trackIndex = Int(address - TrackerControllerParameter.trackMute1.rawValue)
            return trackIndex < trackMutes.count ? (trackMutes[trackIndex].boolValue ? 1 : 0) : 0
        case .delayLevel: return delayLevel
        case .reverbLevel: return reverbLevel
        case .macro1, .macro2, .macro3, .macro4, .macro5, .macro6:
            let macroIndex = Int(address - TrackerControllerParameter.macro1.rawValue)
            return macroIndex < macroValues.count ? macroValues[macroIndex].floatValue : 0
        case .masterVolume: return masterVolume
        case .swing: return swing
        case .patternLength: return Float(patternLength)
        case .quantize: return quantizeEnabled ? 1 : 0
        }
    }
    
    // MARK: - AudioUnit Overrides
    
    public override var parameterTree: AUParameterTree? {
        return _parameterTree
    }
    
    public override var canProcessInPlace: Bool {
        return true
    }
    
    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()
        RTSafeLogger.log("Render resources allocated", level: .info)
    }
    
    public override func deallocateRenderResources() {
        super.deallocateRenderResources()
        RTSafeLogger.log("Render resources deallocated", level: .info)
    }
    
    // MARK: - Control Methods
    
    @objc public func playPattern() {
        isPlaying = true
        midiController.sendPlayCommand()
        RTSafeLogger.log("Pattern play started", level: .info)
    }
    
    @objc public func stopPattern() {
        isPlaying = false
        midiController.sendStopCommand()
        RTSafeLogger.log("Pattern stopped", level: .info)
    }
    
    @objc public func toggleRecord() {
        isRecording.toggle()
        midiController.sendRecordCommand(isRecording)
        RTSafeLogger.log("Record toggled: %{public}@", level: .info, isRecording ? "ON" : "OFF")
    }
    
    @objc public func selectPattern(_ patternNumber: Int) {
        let clampedPattern = max(0, min(127, patternNumber))
        currentPattern = clampedPattern
        midiController.sendPatternChange(clampedPattern)
        RTSafeLogger.log("Pattern selected: %d", level: .info, clampedPattern)
    }
    
    @objc public func setBPM(_ bpm: Int) {
        let clampedBPM = max(60, min(200, bpm))
        currentBPM = clampedBPM
        midiController.sendBPMChange(clampedBPM)
        RTSafeLogger.log("BPM set to: %d", level: .info, clampedBPM)
    }
    
    // MARK: - Track Control Methods
    
    @objc public func setTrackVolume(_ volume: Float, forTrack track: Int) {
        guard track >= 0 && track < 8 else { return }
        let clampedVolume = max(0, min(1, volume))
        trackVolumes[track] = NSNumber(value: clampedVolume)
        midiController.sendTrackVolume(clampedVolume, forTrack: track)
        RTSafeLogger.log("Track %d volume set to: %f", level: .debug, track + 1, clampedVolume)
    }
    
    @objc public func setTrackPan(_ pan: Float, forTrack track: Int) {
        guard track >= 0 && track < 8 else { return }
        let clampedPan = max(-1, min(1, pan))
        trackPans[track] = NSNumber(value: clampedPan)
        midiController.sendTrackPan(clampedPan, forTrack: track)
        RTSafeLogger.log("Track %d pan set to: %f", level: .debug, track + 1, clampedPan)
    }
    
    @objc public func muteTrack(_ track: Int) {
        guard track >= 0 && track < 8 else { return }
        trackMutes[track] = NSNumber(value: true)
        midiController.sendTrackMute(true, forTrack: track)
        RTSafeLogger.log("Track %d muted", level: .info, track + 1)
    }
    
    @objc public func unmuteTrack(_ track: Int) {
        guard track >= 0 && track < 8 else { return }
        trackMutes[track] = NSNumber(value: false)
        midiController.sendTrackMute(false, forTrack: track)
        RTSafeLogger.log("Track %d unmuted", level: .info, track + 1)
    }
    
    @objc public func soloTrack(_ track: Int) {
        guard track >= 0 && track < 8 else { return }
        // Mute all other tracks
        for i in 0..<8 {
            if i != track {
                muteTrack(i)
            } else {
                unmuteTrack(i)
            }
        }
        RTSafeLogger.log("Track %d soloed", level: .info, track + 1)
    }
    
    // MARK: - Performance FX Methods
    
    @objc public func setDelayLevel(_ level: Float) {
        let clampedLevel = max(0, min(1, level))
        delayLevel = clampedLevel
        midiController.sendDelayLevel(clampedLevel)
        RTSafeLogger.log("Delay level set to: %f", level: .debug, clampedLevel)
    }
    
    @objc public func setReverbLevel(_ level: Float) {
        let clampedLevel = max(0, min(1, level))
        reverbLevel = clampedLevel
        midiController.sendReverbLevel(clampedLevel)
        RTSafeLogger.log("Reverb level set to: %f", level: .debug, clampedLevel)
    }
    
    @objc public func setMacroValue(_ value: Float, forMacro macroIndex: Int) {
        guard macroIndex >= 0 && macroIndex < 6 else { return }
        let clampedValue = max(0, min(1, value))
        macroValues[macroIndex] = NSNumber(value: clampedValue)
        midiController.sendMacroValue(clampedValue, forMacro: macroIndex)
        RTSafeLogger.log("Macro %d set to: %f", level: .debug, macroIndex + 1, clampedValue)
    }
    
    @objc public func setMasterVolume(_ volume: Float) {
        let clampedVolume = max(0, min(1, volume))
        masterVolume = clampedVolume
        midiController.sendMasterVolume(clampedVolume)
        RTSafeLogger.log("Master volume set to: %f", level: .debug, clampedVolume)
    }
    
    @objc public func setSwing(_ swingValue: Float) {
        let clampedSwing = max(0, min(1, swingValue))
        swing = clampedSwing
        midiController.sendSwing(clampedSwing)
        RTSafeLogger.log("Swing set to: %f", level: .debug, clampedSwing)
    }
    
    @objc public func setPatternLength(_ length: Int) {
        let clampedLength = max(16, min(128, length))
        patternLength = clampedLength
        midiController.sendPatternLength(clampedLength)
        RTSafeLogger.log("Pattern length set to: %d", level: .info, clampedLength)
    }
    
    @objc public func setQuantizeEnabled(_ enabled: Bool) {
        quantizeEnabled = enabled
        midiController.sendQuantize(enabled)
        RTSafeLogger.log("Quantize enabled: %{public}@", level: .info, enabled ? "YES" : "NO")
    }
}

// MARK: - MIDIControllerDelegate

extension TrackerControllerAudioUnit: MIDIControllerDelegate {
    func midiController(_ controller: MIDIController, didReceivePatternChange pattern: Int) {
        currentPattern = pattern
        if let param = parameters[.pattern] {
            param.setValue(AUValue(pattern), originator: nil)
        }
    }
    
    func midiController(_ controller: MIDIController, didReceiveBPMChange bpm: Int) {
        currentBPM = bpm
        if let param = parameters[.bpm] {
            param.setValue(AUValue(bpm), originator: nil)
        }
    }
    
    func midiController(_ controller: MIDIController, didReceivePlayStateChange isPlaying: Bool) {
        self.isPlaying = isPlaying
        if let param = parameters[.playStop] {
            param.setValue(isPlaying ? 1 : 0, originator: nil)
        }
    }
} 