//
//  TrackerControllerAudioUnit.h
//  TrackerControllerFramework
//
//  Created by AI Assistant on 2025-01-27.
//  Copyright © 2025 Polyend Community. All rights reserved.
//

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface TrackerControllerAudioUnit : AUAudioUnit

// MIDI Controller Properties
@property (nonatomic, readonly) NSInteger currentPattern;
@property (nonatomic, readonly) NSInteger currentBPM;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) BOOL isRecording;

// Track Properties
@property (nonatomic, readonly) NSArray<NSNumber *> *trackVolumes;
@property (nonatomic, readonly) NSArray<NSNumber *> *trackPans;
@property (nonatomic, readonly) NSArray<NSNumber *> *trackMutes;

// Performance FX Properties
@property (nonatomic, readonly) float delayLevel;
@property (nonatomic, readonly) float reverbLevel;
@property (nonatomic, readonly) NSArray<NSNumber *> *macroValues;

// Control Methods
- (void)playPattern;
- (void)stopPattern;
- (void)toggleRecord;
- (void)selectPattern:(NSInteger)patternNumber;
- (void)setBPM:(NSInteger)bpm;

// Track Control Methods
- (void)setTrackVolume:(float)volume forTrack:(NSInteger)track;
- (void)setTrackPan:(float)pan forTrack:(NSInteger)track;
- (void)muteTrack:(NSInteger)track;
- (void)unmuteTrack:(NSInteger)track;
- (void)soloTrack:(NSInteger)track;

// Performance FX Methods
- (void)setDelayLevel:(float)level;
- (void)setReverbLevel:(float)level;
- (void)setMacroValue:(float)value forMacro:(NSInteger)macroIndex;

@end

NS_ASSUME_NONNULL_END 