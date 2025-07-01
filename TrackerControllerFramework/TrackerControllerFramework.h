//
//  TrackerControllerFramework.h
//  TrackerControllerFramework
//
//  Created by AI Assistant on 2025-01-27.
//  Copyright © 2025 Polyend Community. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for TrackerControllerFramework.
FOUNDATION_EXPORT double TrackerControllerFrameworkVersionNumber;

//! Project version string for TrackerControllerFramework.
FOUNDATION_EXPORT const unsigned char TrackerControllerFrameworkVersionString[];

// In this header, you should import all the public headers of your framework using statements like:
// #import <TrackerControllerFramework/PublicHeader.h>

// Import main Audio Unit header
#import <TrackerControllerFramework/TrackerControllerAudioUnit.h>

// Error handling constants
extern NSString * const TrackerControllerErrorDomain;

typedef NS_ENUM(NSInteger, TrackerControllerError) {
    TrackerControllerErrorNone = 0,
    TrackerControllerErrorMIDIConnectionFailed = 1000,
    TrackerControllerErrorDeviceNotFound = 1001,
    TrackerControllerErrorParameterOutOfRange = 1002,
    TrackerControllerErrorPresetLoadFailed = 1003,
    TrackerControllerErrorPresetSaveFailed = 1004,
    TrackerControllerErrorAudioUnitInitFailed = 1005,
    TrackerControllerErrorRealTimeSafetyViolation = 1006
}; 