//
//  ControllerUI.swift
//  TrackerControllerFramework
//
//  Created by AI Assistant on 2025-01-27.
//  Copyright © 2025 Polyend Community. All rights reserved.
//

import SwiftUI
import AudioUnit

// MARK: - TrackerControllerView

public struct TrackerControllerView: View {
    
    @ObservedObject var viewModel: TrackerControllerViewModel
    
    public init(audioUnit: TrackerControllerAudioUnit?) {
        self.viewModel = TrackerControllerViewModel(audioUnit: audioUnit)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header
            headerView
            
            // Connection Status
            connectionStatusView
            
            // Transport Section
            transportSection
            
            // Pattern Section
            patternSection
            
            // Advanced Controls Section
            advancedControlsSection
            
            // Mixer Section
            mixerSection
            
            // Performance FX Section
            performanceFXSection
            
            // Preset Management
            presetManagementSection
            
            Spacer()
        }
        .padding()
        .background(Color.black)
        .foregroundColor(.white)
        .frame(minWidth: 700, minHeight: 600)
        .onAppear {
            viewModel.checkDeviceConnection()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "music.note")
                .font(.title)
                .foregroundColor(.orange)
            
            Text("Tracker Controller")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Text("Polyend Tracker Mini")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Connection Status
    
    private var connectionStatusView: some View {
        GroupBox("Connection Status") {
            Text(viewModel.deviceConnectionStatus)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .groupBoxStyle(TrackerGroupBoxStyle())
    }
    
    // MARK: - Transport Section
    
    private var transportSection: some View {
        GroupBox("Transport") {
            HStack(spacing: 20) {
                // Play/Stop Button
                Button(action: viewModel.togglePlayStop) {
                    Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.isPlaying ? .red : .green)
                }
                .buttonStyle(TransportButtonStyle())
                
                // Record Button
                Button(action: viewModel.toggleRecord) {
                    Image(systemName: "record.circle")
                        .font(.title2)
                        .foregroundColor(viewModel.isRecording ? .red : .gray)
                }
                .buttonStyle(TransportButtonStyle())
                
                Spacer()
                
                // BPM Control
                VStack {
                    Text("BPM")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("\(viewModel.currentBPM)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(width: 50)
                        
                        Slider(value: $viewModel.bpmSlider, in: 60...200, step: 1)
                            .accentColor(.orange)
                            .frame(width: 120)
                    }
                }
            }
            .padding()
        }
        .groupBoxStyle(TrackerGroupBoxStyle())
    }
    
    // MARK: - Pattern Section
    
    private var patternSection: some View {
        GroupBox("Pattern") {
            HStack(spacing: 20) {
                // Pattern Selection
                VStack {
                    Text("Pattern")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Button("-") {
                            viewModel.selectPreviousPattern()
                        }
                        .buttonStyle(SmallButtonStyle())
                        
                        Text(String(format: "%03d", viewModel.currentPattern))
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(width: 60)
                        
                        Button("+") {
                            viewModel.selectNextPattern()
                        }
                        .buttonStyle(SmallButtonStyle())
                    }
                }
                
                Spacer()
                
                // Pattern Grid (simplified)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 4) {
                    ForEach(0..<16, id: \.self) { step in
                        Rectangle()
                            .fill(step % 4 == 0 ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: 20, height: 8)
                    }
                }
                .frame(width: 120)
            }
            .padding()
        }
        .groupBoxStyle(TrackerGroupBoxStyle())
    }
    
    // MARK: - Advanced Controls Section
    
    private var advancedControlsSection: some View {
        GroupBox("Advanced Controls") {
            HStack(spacing: 20) {
                // Tempo Sync
                VStack {
                    Text("Tempo Sync")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Toggle("", isOn: $viewModel.isTempoSyncEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                }
                
                // Auto-Sync
                VStack {
                    Text("Auto-Sync")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Toggle("", isOn: $viewModel.isAutoSyncEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                }
            }
            .padding()
        }
        .groupBoxStyle(TrackerGroupBoxStyle())
    }
    
    // MARK: - Mixer Section
    
    private var mixerSection: some View {
        GroupBox("Mixer") {
            VStack(spacing: 12) {
                // Track Labels
                HStack {
                    ForEach(1...8, id: \.self) { track in
                        Text("T\(track)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 60)
                    }
                }
                
                // Volume Sliders
                HStack {
                    ForEach(0..<8, id: \.self) { track in
                        VStack {
                            Slider(value: $viewModel.trackVolumes[track], in: 0...1)
                                .rotationEffect(.degrees(-90))
                                .frame(width: 20, height: 80)
                                .accentColor(.orange)
                            
                            Text(String(format: "%.0f", viewModel.trackVolumes[track] * 100))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60)
                    }
                }
                
                // Pan Knobs
                HStack {
                    ForEach(0..<8, id: \.self) { track in
                        VStack {
                            KnobView(value: $viewModel.trackPans[track], range: -1...1)
                                .frame(width: 40, height: 40)
                            
                            Text("PAN")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60)
                    }
                }
                
                // Mute Buttons
                HStack {
                    ForEach(0..<8, id: \.self) { track in
                        Button(action: { viewModel.toggleMute(track: track) }) {
                            Text("M")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.trackMutes[track] ? .black : .white)
                                .frame(width: 30, height: 20)
                                .background(viewModel.trackMutes[track] ? .red : .gray.opacity(0.3))
                                .cornerRadius(4)
                        }
                        .frame(width: 60)
                    }
                }
            }
            .padding()
        }
        .groupBoxStyle(TrackerGroupBoxStyle())
    }
    
    // MARK: - Performance FX Section
    
    private var performanceFXSection: some View {
        GroupBox("Performance FX") {
            HStack(spacing: 30) {
                // Delay & Reverb
                VStack {
                    Text("Sends")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 20) {
                        VStack {
                            KnobView(value: $viewModel.delayLevel, range: 0...1)
                                .frame(width: 50, height: 50)
                            Text("DELAY")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        VStack {
                            KnobView(value: $viewModel.reverbLevel, range: 0...1)
                                .frame(width: 50, height: 50)
                            Text("REVERB")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Macros
                VStack {
                    Text("Macros")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                        ForEach(0..<6, id: \.self) { macro in
                            VStack {
                                KnobView(value: $viewModel.macroValues[macro], range: 0...1)
                                    .frame(width: 40, height: 40)
                                Text("M\(macro + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .groupBoxStyle(TrackerGroupBoxStyle())
    }
    
    // MARK: - Preset Management
    
    private var presetManagementSection: some View {
        GroupBox("Preset Management") {
            HStack(spacing: 20) {
                // Load Preset
                Button(action: viewModel.loadPreset) {
                    Text("Load Preset")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 100, height: 30)
                        .background(Color.orange)
                        .cornerRadius(4)
                }
                
                // Save Preset
                Button(action: viewModel.savePreset) {
                    Text("Save Preset")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 100, height: 30)
                        .background(Color.orange)
                        .cornerRadius(4)
                }
            }
            .padding()
        }
        .groupBoxStyle(TrackerGroupBoxStyle())
    }
}

// MARK: - KnobView

struct KnobView: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    
    @State private var isDragging = false
    @State private var lastDragValue: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 3)
            
            // Value arc
            Circle()
                .trim(from: 0.125, to: 0.125 + 0.75 * CGFloat(normalizedValue))
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
            
            // Value indicator
            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: 12)
                .offset(y: -15)
                .rotationEffect(.degrees(Double(normalizedValue * 270 - 135)))
        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if !isDragging {
                        isDragging = true
                        lastDragValue = gesture.translation.y
                    }
                    
                    let delta = lastDragValue - gesture.translation.y
                    let sensitivity: CGFloat = 0.01
                    let newValue = value + Float(delta * sensitivity)
                    
                    value = max(range.lowerBound, min(range.upperBound, newValue))
                    lastDragValue = gesture.translation.y
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
    
    private var normalizedValue: Float {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
}

// MARK: - Custom Styles

struct TrackerGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .font(.headline)
                .foregroundColor(.orange)
            
            configuration.content
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TransportButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 50, height: 50)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 30, height: 25)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview

struct TrackerControllerView_Previews: PreviewProvider {
    static var previews: some View {
        TrackerControllerView(audioUnit: nil)
            .frame(width: 700, height: 600)
    }
} 