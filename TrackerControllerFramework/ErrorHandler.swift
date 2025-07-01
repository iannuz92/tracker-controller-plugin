//
//  ErrorHandler.swift
//  TrackerControllerFramework
//
//  Created by AI Assistant on 2025-01-27.
//  Copyright © 2025 Polyend Community. All rights reserved.
//

import Foundation
import os.log

// MARK: - Error Types

public enum TrackerControllerError: Error, LocalizedError {
    case midiConnectionFailed(String)
    case deviceNotFound
    case parameterOutOfRange(String, Float, Float, Float)
    case presetLoadFailed(String)
    case presetSaveFailed(String)
    case audioUnitInitFailed(String)
    case realTimeSafetyViolation(String)
    case deviceDisconnected
    case invalidPresetFormat
    case unsupportedOperation(String)
    
    public var errorDescription: String? {
        switch self {
        case .midiConnectionFailed(let reason):
            return "MIDI connection failed: \(reason)"
        case .deviceNotFound:
            return "Polyend Tracker Mini not found. Please connect your device and try again."
        case .parameterOutOfRange(let param, let value, let min, let max):
            return "Parameter '\(param)' value \(value) is out of range [\(min), \(max)]"
        case .presetLoadFailed(let reason):
            return "Failed to load preset: \(reason)"
        case .presetSaveFailed(let reason):
            return "Failed to save preset: \(reason)"
        case .audioUnitInitFailed(let reason):
            return "Audio Unit initialization failed: \(reason)"
        case .realTimeSafetyViolation(let operation):
            return "Real-time safety violation in operation: \(operation)"
        case .deviceDisconnected:
            return "Device was disconnected during operation"
        case .invalidPresetFormat:
            return "Invalid preset file format"
        case .unsupportedOperation(let operation):
            return "Unsupported operation: \(operation)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .midiConnectionFailed:
            return "Check MIDI connections and restart the application"
        case .deviceNotFound:
            return "Connect your Polyend Tracker Mini via USB and ensure it's powered on"
        case .parameterOutOfRange:
            return "Use a value within the specified range"
        case .presetLoadFailed:
            return "Check if the preset file exists and is not corrupted"
        case .presetSaveFailed:
            return "Check disk space and file permissions"
        case .audioUnitInitFailed:
            return "Restart the host application and try again"
        case .realTimeSafetyViolation:
            return "This is a programming error - contact support"
        case .deviceDisconnected:
            return "Reconnect your device and try again"
        case .invalidPresetFormat:
            return "Use a valid preset file created by this plugin"
        case .unsupportedOperation:
            return "This operation is not supported in the current context"
        }
    }
}

// MARK: - Error Handler

public class TrackerControllerErrorHandler {
    
    public static let shared = TrackerControllerErrorHandler()
    
    private let logger = OSLog(subsystem: "com.polyend.TrackerController", category: "ErrorHandler")
    private var errorCallbacks: [(TrackerControllerError) -> Void] = []
    
    private init() {}
    
    // MARK: - Error Reporting
    
    public func reportError(_ error: TrackerControllerError, file: String = #file, line: Int = #line, function: String = #function) {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"
        
        os_log("Error reported at %{public}@: %{public}@", 
               log: logger, 
               type: .error, 
               location, 
               error.localizedDescription)
        
        // Notify callbacks
        DispatchQueue.main.async { [weak self] in
            self?.errorCallbacks.forEach { callback in
                callback(error)
            }
        }
        
        // Log additional context
        if let suggestion = error.recoverySuggestion {
            os_log("Recovery suggestion: %{public}@", log: logger, type: .info, suggestion)
        }
    }
    
    public func addErrorCallback(_ callback: @escaping (TrackerControllerError) -> Void) {
        errorCallbacks.append(callback)
    }
    
    public func removeAllErrorCallbacks() {
        errorCallbacks.removeAll()
    }
    
    // MARK: - Validation Helpers
    
    public func validateParameter<T: Comparable>(_ name: String, value: T, min: T, max: T) throws {
        guard value >= min && value <= max else {
            let error = TrackerControllerError.parameterOutOfRange(name, Float(value as! Double), Float(min as! Double), Float(max as! Double))
            reportError(error)
            throw error
        }
    }
    
    public func validateMIDIConnection(_ isConnected: Bool) throws {
        guard isConnected else {
            let error = TrackerControllerError.deviceNotFound
            reportError(error)
            throw error
        }
    }
    
    // MARK: - Safe Execution
    
    public func safeExecute<T>(_ operation: () throws -> T, defaultValue: T, context: String = "") -> T {
        do {
            return try operation()
        } catch let error as TrackerControllerError {
            reportError(error)
            return defaultValue
        } catch {
            let wrappedError = TrackerControllerError.unsupportedOperation("\(context): \(error.localizedDescription)")
            reportError(wrappedError)
            return defaultValue
        }
    }
    
    public func safeExecuteAsync<T>(_ operation: @escaping () async throws -> T, 
                                   defaultValue: T, 
                                   context: String = "",
                                   completion: @escaping (T) -> Void) {
        Task {
            let result = await safeExecuteAsync(operation, defaultValue: defaultValue, context: context)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    public func safeExecuteAsync<T>(_ operation: () async throws -> T, defaultValue: T, context: String = "") async -> T {
        do {
            return try await operation()
        } catch let error as TrackerControllerError {
            reportError(error)
            return defaultValue
        } catch {
            let wrappedError = TrackerControllerError.unsupportedOperation("\(context): \(error.localizedDescription)")
            reportError(wrappedError)
            return defaultValue
        }
    }
}

// MARK: - Error Recovery Strategies

public enum ErrorRecoveryStrategy {
    case retry
    case useDefault
    case reconnect
    case ignore
    case abort
}

public class ErrorRecoveryManager {
    
    public static let shared = ErrorRecoveryManager()
    
    private init() {}
    
    public func suggestRecoveryStrategy(for error: TrackerControllerError) -> ErrorRecoveryStrategy {
        switch error {
        case .midiConnectionFailed, .deviceNotFound, .deviceDisconnected:
            return .reconnect
        case .parameterOutOfRange:
            return .useDefault
        case .presetLoadFailed, .presetSaveFailed:
            return .retry
        case .audioUnitInitFailed:
            return .abort
        case .realTimeSafetyViolation:
            return .ignore // Log but continue
        case .invalidPresetFormat:
            return .useDefault
        case .unsupportedOperation:
            return .ignore
        }
    }
    
    public func executeRecoveryStrategy(_ strategy: ErrorRecoveryStrategy, 
                                      for error: TrackerControllerError,
                                      context: Any? = nil) {
        switch strategy {
        case .retry:
            // Implement retry logic
            break
        case .useDefault:
            // Reset to default values
            break
        case .reconnect:
            // Attempt reconnection
            if let midiController = context as? MIDIController {
                midiController.reconnectToDevice()
            }
        case .ignore:
            // Just log and continue
            break
        case .abort:
            // Critical error - should stop operation
            TrackerControllerErrorHandler.shared.reportError(error)
        }
    }
} 