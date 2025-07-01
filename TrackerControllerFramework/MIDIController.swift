//
//  MIDIController.swift
//  TrackerControllerFramework
//
//  Created by AI Assistant on 2025-01-27.
//  Copyright © 2025 Polyend Community. All rights reserved.
//

import Foundation
import CoreMIDI
import os.log

// MARK: - MIDIControllerDelegate

protocol MIDIControllerDelegate: AnyObject {
    func midiController(_ controller: MIDIController, didReceivePatternChange pattern: Int)
    func midiController(_ controller: MIDIController, didReceiveBPMChange bpm: Int)
    func midiController(_ controller: MIDIController, didReceivePlayStateChange isPlaying: Bool)
}

// MARK: - TrackerMiniMIDIMapping

struct TrackerMiniMIDIMapping {
    // Control Change mappings for Tracker Mini
    static let volumeCC: UInt8 = 7          // Main volume
    static let panCC: UInt8 = 10            // Pan
    static let expressionCC: UInt8 = 11     // Expression
    static let delayCC: UInt8 = 93          // Delay send
    static let reverbCC: UInt8 = 91         // Reverb send
    
    // Track volume CCs (12-19 for tracks 1-8)
    static let trackVolumeBaseCC: UInt8 = 12
    
    // Macro CCs (20-25 for macros 1-6)
    static let macroBaseCC: UInt8 = 20
    
    // Track mute CCs (30-37 for tracks 1-8)
    static let trackMuteBaseCC: UInt8 = 30
    
    // Advanced control CCs
    static let masterVolumeCC: UInt8 = 7        // Main volume
    static let swingCC: UInt8 = 16              // Swing amount
    static let patternLengthCC: UInt8 = 17      // Pattern length
    static let quantizeCC: UInt8 = 18           // Quantize on/off
    
    // Transport control notes
    static let playStopNote: UInt8 = 60     // C4
    static let recordNote: UInt8 = 62       // D4
    
    // Track trigger notes (48-55 = C3-G3 for tracks 1-8)
    static let trackTriggerBaseNote: UInt8 = 48
    
    // MIDI channels
    static let controlChannel: UInt8 = 1    // Channel for control messages
    static let trackChannel: UInt8 = 1      // Channel for track triggers
}

// MARK: - MIDIController

class MIDIController {
    
    // MARK: - Properties
    
    weak var delegate: MIDIControllerDelegate?
    
    private let logger = OSLog(subsystem: "com.polyend.TrackerController", category: "MIDI")
    
    private var midiClient: MIDIClientRef = 0
    private var outputPort: MIDIPortRef = 0
    private var inputPort: MIDIPortRef = 0
    
    private var destinationEndpoint: MIDIEndpointRef = 0
    private var sourceEndpoint: MIDIEndpointRef = 0
    
    // MARK: - Initialization
    
    init() {
        setupMIDI()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - MIDI Setup
    
    private func setupMIDI() {
        var status: OSStatus
        
        // Create MIDI client
        status = MIDIClientCreate("TrackerController" as CFString, nil, nil, &midiClient)
        if status != noErr {
            os_log("Failed to create MIDI client: %d", log: logger, type: .error, status)
            return
        }
        
        // Create output port
        status = MIDIOutputPortCreate(midiClient, "TrackerController Output" as CFString, &outputPort)
        if status != noErr {
            os_log("Failed to create MIDI output port: %d", log: logger, type: .error, status)
            return
        }
        
        // Create input port
        status = MIDIInputPortCreate(midiClient, "TrackerController Input" as CFString, midiReadProc, 
                                   Unmanaged.passUnretained(self).toOpaque(), &inputPort)
        if status != noErr {
            os_log("Failed to create MIDI input port: %d", log: logger, type: .error, status)
            return
        }
        
        // Find Tracker Mini endpoints
        findTrackerMiniEndpoints()
        
        os_log("MIDI setup completed", log: logger, type: .info)
    }
    
    private func findTrackerMiniEndpoints() {
        let deviceCount = MIDIGetNumberOfDevices()
        
        for i in 0..<deviceCount {
            let device = MIDIGetDevice(i)
            
            var nameRef: Unmanaged<CFString>?
            let status = MIDIObjectGetStringProperty(device, kMIDIPropertyName, &nameRef)
            
            if status == noErr, let name = nameRef?.takeRetainedValue() as String? {
                os_log("Found MIDI device: %{public}@", log: logger, type: .debug, name)
                
                // Look for Tracker Mini (or similar names)
                if name.lowercased().contains("tracker") || name.lowercased().contains("polyend") {
                    connectToDevice(device, deviceName: name)
                    break
                }
            }
        }
        
        // If no specific device found, use first available destination
        if destinationEndpoint == 0 {
            let destCount = MIDIGetNumberOfDestinations()
            if destCount > 0 {
                destinationEndpoint = MIDIGetDestination(0)
                os_log("Using first available MIDI destination", log: logger, type: .info)
            }
        }
        
        // If no specific device found, use first available source
        if sourceEndpoint == 0 {
            let srcCount = MIDIGetNumberOfSources()
            if srcCount > 0 {
                sourceEndpoint = MIDIGetSource(0)
                let status = MIDIPortConnectSource(inputPort, sourceEndpoint, nil)
                if status == noErr {
                    os_log("Connected to first available MIDI source", log: logger, type: .info)
                } else {
                    os_log("Failed to connect to MIDI source: %d", log: logger, type: .error, status)
                }
            }
        }
    }
    
    private func connectToDevice(_ device: MIDIDeviceRef, deviceName: String) {
        let entityCount = MIDIDeviceGetNumberOfEntities(device)
        
        for i in 0..<entityCount {
            let entity = MIDIDeviceGetEntity(device, i)
            
            // Connect to destination (for output)
            let destCount = MIDIEntityGetNumberOfDestinations(entity)
            if destCount > 0 && destinationEndpoint == 0 {
                destinationEndpoint = MIDIEntityGetDestination(entity, 0)
                os_log("Connected to %{public}@ destination", log: logger, type: .info, deviceName)
            }
            
            // Connect to source (for input)
            let srcCount = MIDIEntityGetNumberOfSources(entity)
            if srcCount > 0 && sourceEndpoint == 0 {
                sourceEndpoint = MIDIEntityGetSource(entity, 0)
                let status = MIDIPortConnectSource(inputPort, sourceEndpoint, nil)
                if status == noErr {
                    os_log("Connected to %{public}@ source", log: logger, type: .info, deviceName)
                } else {
                    os_log("Failed to connect to %{public}@ source: %d", log: logger, type: .error, deviceName, status)
                }
            }
        }
    }
    
    private func cleanup() {
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
        }
        if outputPort != 0 {
            MIDIPortDispose(outputPort)
        }
        if midiClient != 0 {
            MIDIClientDispose(midiClient)
        }
    }
    
    // MARK: - MIDI Send Methods
    
    func sendPlayCommand() {
        sendNoteOn(note: TrackerMiniMIDIMapping.playStopNote, velocity: 127, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent play command", log: logger, type: .debug)
    }
    
    func sendStopCommand() {
        sendNoteOff(note: TrackerMiniMIDIMapping.playStopNote, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent stop command", log: logger, type: .debug)
    }
    
    func sendRecordCommand(_ isRecording: Bool) {
        if isRecording {
            sendNoteOn(note: TrackerMiniMIDIMapping.recordNote, velocity: 127, channel: TrackerMiniMIDIMapping.controlChannel)
        } else {
            sendNoteOff(note: TrackerMiniMIDIMapping.recordNote, channel: TrackerMiniMIDIMapping.controlChannel)
        }
        os_log("Sent record command: %{public}@", log: logger, type: .debug, isRecording ? "ON" : "OFF")
    }
    
    func sendPatternChange(_ pattern: Int) {
        sendProgramChange(program: UInt8(max(0, min(127, pattern))), channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent pattern change: %d", log: logger, type: .debug, pattern)
    }
    
    func sendBPMChange(_ bpm: Int) {
        // BPM might be handled via SysEx or specific CC, for now use CC 1 (Modulation)
        let bpmValue = UInt8((Float(bpm - 60) / 140.0) * 127.0) // Map 60-200 BPM to 0-127
        sendControlChange(controller: 1, value: bpmValue, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent BPM change: %d (CC value: %d)", log: logger, type: .debug, bpm, bpmValue)
    }
    
    func sendTrackVolume(_ volume: Float, forTrack track: Int) {
        guard track >= 0 && track < 8 else { return }
        let cc = TrackerMiniMIDIMapping.trackVolumeBaseCC + UInt8(track)
        let value = UInt8(max(0, min(127, volume * 127)))
        sendControlChange(controller: cc, value: value, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent track %d volume: %f (CC %d = %d)", log: logger, type: .debug, track + 1, volume, cc, value)
    }
    
    func sendTrackPan(_ pan: Float, forTrack track: Int) {
        guard track >= 0 && track < 8 else { return }
        // Use main pan CC for now, could be extended with track-specific CCs
        let value = UInt8(max(0, min(127, (pan + 1.0) * 63.5))) // Map -1 to 1 -> 0 to 127
        sendControlChange(controller: TrackerMiniMIDIMapping.panCC, value: value, channel: UInt8(track + 1))
        os_log("Sent track %d pan: %f (CC %d = %d)", log: logger, type: .debug, track + 1, pan, TrackerMiniMIDIMapping.panCC, value)
    }
    
    func sendTrackMute(_ mute: Bool, forTrack track: Int) {
        guard track >= 0 && track < 8 else { return }
        let cc = TrackerMiniMIDIMapping.trackMuteBaseCC + UInt8(track)
        let value: UInt8 = mute ? 127 : 0
        sendControlChange(controller: cc, value: value, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent track %d mute: %{public}@ (CC %d = %d)", log: logger, type: .debug, track + 1, mute ? "ON" : "OFF", cc, value)
    }
    
    func sendDelayLevel(_ level: Float) {
        let value = UInt8(max(0, min(127, level * 127)))
        sendControlChange(controller: TrackerMiniMIDIMapping.delayCC, value: value, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent delay level: %f (CC %d = %d)", log: logger, type: .debug, level, TrackerMiniMIDIMapping.delayCC, value)
    }
    
    func sendReverbLevel(_ level: Float) {
        let value = UInt8(max(0, min(127, level * 127)))
        sendControlChange(controller: TrackerMiniMIDIMapping.reverbCC, value: value, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent reverb level: %f (CC %d = %d)", log: logger, type: .debug, level, TrackerMiniMIDIMapping.reverbCC, value)
    }
    
    func sendMacroValue(_ value: Float, forMacro macro: Int) {
        guard macro >= 0 && macro < 6 else { return }
        let cc = TrackerMiniMIDIMapping.macroBaseCC + UInt8(macro)
        let ccValue = UInt8(max(0, min(127, value * 127)))
        sendControlChange(controller: cc, value: ccValue, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent macro %d: %f (CC %d = %d)", log: logger, type: .debug, macro + 1, value, cc, ccValue)
    }
    
    func triggerTrack(_ track: Int, velocity: UInt8 = 127) {
        guard track >= 0 && track < 8 else { return }
        let note = TrackerMiniMIDIMapping.trackTriggerBaseNote + UInt8(track)
        sendNoteOn(note: note, velocity: velocity, channel: TrackerMiniMIDIMapping.trackChannel)
        os_log("Triggered track %d (note %d, velocity %d)", log: logger, type: .debug, track + 1, note, velocity)
    }
    
    // MARK: - Low-level MIDI Send Methods
    
    private func sendNoteOn(note: UInt8, velocity: UInt8, channel: UInt8) {
        let status: UInt8 = 0x90 | (channel - 1) // Note On + channel
        sendMIDIMessage([status, note, velocity])
    }
    
    private func sendNoteOff(note: UInt8, channel: UInt8) {
        let status: UInt8 = 0x80 | (channel - 1) // Note Off + channel
        sendMIDIMessage([status, note, 0])
    }
    
    private func sendControlChange(controller: UInt8, value: UInt8, channel: UInt8) {
        let status: UInt8 = 0xB0 | (channel - 1) // Control Change + channel
        sendMIDIMessage([status, controller, value])
    }
    
    private func sendProgramChange(program: UInt8, channel: UInt8) {
        let status: UInt8 = 0xC0 | (channel - 1) // Program Change + channel
        sendMIDIMessage([status, program])
    }
    
    private func sendMIDIMessage(_ data: [UInt8]) {
        guard destinationEndpoint != 0 else {
            os_log("No MIDI destination available", log: logger, type: .warning)
            return
        }
        
        var packetList = MIDIPacketList()
        var packet = MIDIPacketListInit(&packetList)
        
        packet = MIDIPacketListAdd(&packetList, 1024, packet, 0, data.count, data)
        
        if packet == nil {
            os_log("Failed to create MIDI packet", log: logger, type: .error)
            return
        }
        
        let status = MIDISend(outputPort, destinationEndpoint, &packetList)
        if status != noErr {
            os_log("Failed to send MIDI message: %d", log: logger, type: .error, status)
        }
    }
    
    // MARK: - Advanced Control Methods
    
    func sendMasterVolume(_ volume: Float) {
        let value = UInt8(max(0, min(127, volume * 127)))
        sendControlChange(controller: TrackerMiniMIDIMapping.masterVolumeCC, value: value, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent master volume: %f (CC %d = %d)", log: logger, type: .debug, volume, TrackerMiniMIDIMapping.masterVolumeCC, value)
    }
    
    func sendSwing(_ swing: Float) {
        let value = UInt8(max(0, min(127, swing * 127)))
        sendControlChange(controller: TrackerMiniMIDIMapping.swingCC, value: value, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent swing: %f (CC %d = %d)", log: logger, type: .debug, swing, TrackerMiniMIDIMapping.swingCC, value)
    }
    
    func sendPatternLength(_ length: Int) {
        let value = UInt8(max(16, min(128, length)) - 16) // Map 16-128 to 0-112
        sendControlChange(controller: TrackerMiniMIDIMapping.patternLengthCC, value: value, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent pattern length: %d (CC %d = %d)", log: logger, type: .debug, length, TrackerMiniMIDIMapping.patternLengthCC, value)
    }
    
    func sendQuantize(_ enabled: Bool) {
        let value: UInt8 = enabled ? 127 : 0
        sendControlChange(controller: TrackerMiniMIDIMapping.quantizeCC, value: value, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent quantize: %{public}@ (CC %d = %d)", log: logger, type: .debug, enabled ? "ON" : "OFF", TrackerMiniMIDIMapping.quantizeCC, value)
    }
    
    // MARK: - Enhanced MIDI Features
    
    func sendAllNotesOff() {
        // Send All Notes Off (CC 123)
        sendControlChange(controller: 123, value: 0, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent All Notes Off", log: logger, type: .info)
    }
    
    func sendAllControllersOff() {
        // Reset All Controllers (CC 121)
        sendControlChange(controller: 121, value: 0, channel: TrackerMiniMIDIMapping.controlChannel)
        os_log("Sent All Controllers Off", log: logger, type: .info)
    }
    
    func sendPanic() {
        // Send panic - all notes off on all channels
        for channel in 1...16 {
            sendControlChange(controller: 123, value: 0, channel: UInt8(channel))
        }
        os_log("Sent MIDI Panic", log: logger, type: .info)
    }
    
    // MARK: - Device Detection and Health
    
    func isTrackerMiniConnected() -> Bool {
        return destinationEndpoint != 0 && sourceEndpoint != 0
    }
    
    func getConnectedDeviceName() -> String? {
        guard destinationEndpoint != 0 else { return nil }
        
        var nameRef: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(destinationEndpoint, kMIDIPropertyName, &nameRef)
        
        if status == noErr, let name = nameRef?.takeRetainedValue() as String? {
            return name
        }
        
        return nil
    }
    
    func reconnectToDevice() {
        cleanup()
        setupMIDI()
        os_log("Attempted to reconnect to MIDI device", log: logger, type: .info)
    }
}

// MARK: - MIDI Input Handling

private func midiReadProc(pktlist: UnsafePointer<MIDIPacketList>,
                         readProcRefCon: UnsafeMutableRawPointer?,
                         srcConnRefCon: UnsafeMutableRawPointer?) {
    
    guard let refCon = readProcRefCon else { return }
    let midiController = Unmanaged<MIDIController>.fromOpaque(refCon).takeUnretainedValue()
    
    midiController.handleMIDIInput(pktlist)
}

extension MIDIController {
    
    func handleMIDIInput(_ pktlist: UnsafePointer<MIDIPacketList>) {
        let packetList = pktlist.pointee
        var packet = packetList.packet
        
        for _ in 0..<packetList.numPackets {
            let data = withUnsafePointer(to: packet.data) {
                $0.withMemoryRebound(to: UInt8.self, capacity: Int(packet.length)) {
                    Array(UnsafeBufferPointer(start: $0, count: Int(packet.length)))
                }
            }
            
            processMIDIData(data)
            packet = MIDIPacketNext(&packet).pointee
        }
    }
    
    private func processMIDIData(_ data: [UInt8]) {
        guard data.count >= 2 else { return }
        
        let status = data[0]
        let messageType = status & 0xF0
        let channel = status & 0x0F
        
        switch messageType {
        case 0xB0: // Control Change
            if data.count >= 3 {
                handleControlChange(controller: data[1], value: data[2], channel: channel)
            }
        case 0xC0: // Program Change
            handleProgramChange(program: data[1], channel: channel)
        case 0x90: // Note On
            if data.count >= 3 {
                handleNoteOn(note: data[1], velocity: data[2], channel: channel)
            }
        case 0x80: // Note Off
            if data.count >= 3 {
                handleNoteOff(note: data[1], velocity: data[2], channel: channel)
            }
        default:
            break
        }
    }
    
    private func handleControlChange(controller: UInt8, value: UInt8, channel: UInt8) {
        os_log("Received CC %d = %d on channel %d", log: logger, type: .debug, controller, value, channel + 1)
        
        // Handle incoming control changes from Tracker Mini
        switch controller {
        case 1: // Modulation - could be BPM feedback
            let bpm = Int(60 + (Float(value) / 127.0) * 140) // Map 0-127 to 60-200 BPM
            delegate?.midiController(self, didReceiveBPMChange: bpm)
        default:
            break
        }
    }
    
    private func handleProgramChange(program: UInt8, channel: UInt8) {
        os_log("Received Program Change %d on channel %d", log: logger, type: .debug, program, channel + 1)
        delegate?.midiController(self, didReceivePatternChange: Int(program))
    }
    
    private func handleNoteOn(note: UInt8, velocity: UInt8, channel: UInt8) {
        os_log("Received Note On %d (vel %d) on channel %d", log: logger, type: .debug, note, velocity, channel + 1)
        
        if note == TrackerMiniMIDIMapping.playStopNote && velocity > 0 {
            delegate?.midiController(self, didReceivePlayStateChange: true)
        }
    }
    
    private func handleNoteOff(note: UInt8, velocity: UInt8, channel: UInt8) {
        os_log("Received Note Off %d on channel %d", log: logger, type: .debug, note, channel + 1)
        
        if note == TrackerMiniMIDIMapping.playStopNote {
            delegate?.midiController(self, didReceivePlayStateChange: false)
        }
    }
} 