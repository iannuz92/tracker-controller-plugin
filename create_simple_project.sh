#!/bin/bash

# Script to create a simplified Xcode project
# This avoids the complex dependency issues causing crashes

set -e

PROJECT_NAME="TrackerControllerSimple"
FRAMEWORK_NAME="TrackerControllerFramework"

echo "🔨 Creating simplified Xcode project..."

# Remove existing problematic project
if [ -d "TrackerController.xcodeproj" ]; then
    rm -rf "TrackerController.xcodeproj"
fi

# Create new project directory structure
mkdir -p "${PROJECT_NAME}.xcodeproj"

# Generate simplified project.pbxproj
cat > "${PROJECT_NAME}.xcodeproj/project.pbxproj" << 'EOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		AA001001 /* TrackerControllerFramework.h in Headers */ = {isa = PBXBuildFile; fileRef = AA001002 /* TrackerControllerFramework.h */; settings = {ATTRIBUTES = (Public, ); }; };
		AA001003 /* TrackerControllerAudioUnit.h in Headers */ = {isa = PBXBuildFile; fileRef = AA001004 /* TrackerControllerAudioUnit.h */; settings = {ATTRIBUTES = (Public, ); }; };
		AA001005 /* TrackerControllerAudioUnit.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA001006 /* TrackerControllerAudioUnit.swift */; };
		AA001007 /* MIDIController.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA001008 /* MIDIController.swift */; };
		AA001009 /* ControllerUI.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA001010 /* ControllerUI.swift */; };
		AA001011 /* TrackerControllerViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA001012 /* TrackerControllerViewModel.swift */; };
		AA001013 /* ErrorHandler.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA001014 /* ErrorHandler.swift */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		AA001002 /* TrackerControllerFramework.h */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.h; path = TrackerControllerFramework.h; sourceTree = "<group>"; };
		AA001004 /* TrackerControllerAudioUnit.h */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.h; path = TrackerControllerAudioUnit.h; sourceTree = "<group>"; };
		AA001006 /* TrackerControllerAudioUnit.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TrackerControllerAudioUnit.swift; sourceTree = "<group>"; };
		AA001008 /* MIDIController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MIDIController.swift; sourceTree = "<group>"; };
		AA001010 /* ControllerUI.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ControllerUI.swift; sourceTree = "<group>"; };
		AA001012 /* TrackerControllerViewModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TrackerControllerViewModel.swift; sourceTree = "<group>"; };
		AA001014 /* ErrorHandler.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ErrorHandler.swift; sourceTree = "<group>"; };
		AA001020 /* TrackerControllerFramework.framework */ = {isa = PBXFileReference; explicitFileType = wrapper.framework; includeInIndex = 0; path = TrackerControllerFramework.framework; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		AA001021 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		AA001030 = {
			isa = PBXGroup;
			children = (
				AA001031 /* TrackerControllerFramework */,
				AA001032 /* Products */,
			);
			sourceTree = "<group>";
		};
		AA001031 /* TrackerControllerFramework */ = {
			isa = PBXGroup;
			children = (
				AA001002 /* TrackerControllerFramework.h */,
				AA001004 /* TrackerControllerAudioUnit.h */,
				AA001006 /* TrackerControllerAudioUnit.swift */,
				AA001008 /* MIDIController.swift */,
				AA001010 /* ControllerUI.swift */,
				AA001012 /* TrackerControllerViewModel.swift */,
				AA001014 /* ErrorHandler.swift */,
			);
			path = TrackerControllerFramework;
			sourceTree = "<group>";
		};
		AA001032 /* Products */ = {
			isa = PBXGroup;
			children = (
				AA001020 /* TrackerControllerFramework.framework */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXHeadersBuildPhase section */
		AA001040 /* Headers */ = {
			isa = PBXHeadersBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AA001001 /* TrackerControllerFramework.h in Headers */,
				AA001003 /* TrackerControllerAudioUnit.h in Headers */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXHeadersBuildPhase section */

/* Begin PBXNativeTarget section */
		AA001050 /* TrackerControllerFramework */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = AA001060 /* Build configuration list for PBXNativeTarget "TrackerControllerFramework" */;
			buildPhases = (
				AA001040 /* Headers */,
				AA001051 /* Sources */,
				AA001021 /* Frameworks */,
				AA001052 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = TrackerControllerFramework;
			productName = TrackerControllerFramework;
			productReference = AA001020 /* TrackerControllerFramework.framework */;
			productType = "com.apple.product-type.framework";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		AA001070 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {
					AA001050 = {
						CreatedOnToolsVersion = 15.0;
					};
				};
			};
			buildConfigurationList = AA001080 /* Build configuration list for PBXProject "TrackerControllerSimple" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = AA001030;
			productRefGroup = AA001032 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				AA001050 /* TrackerControllerFramework */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		AA001052 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		AA001051 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AA001005 /* TrackerControllerAudioUnit.swift in Sources */,
				AA001007 /* MIDIController.swift in Sources */,
				AA001009 /* ControllerUI.swift in Sources */,
				AA001011 /* TrackerControllerViewModel.swift in Sources */,
				AA001013 /* ErrorHandler.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		AA001090 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		AA001091 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			};
			name = Release;
		};
		AA001100 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ARCHS = arm64;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEFINES_MODULE = YES;
				DYLIB_COMPATIBILITY_VERSION = 1;
				DYLIB_CURRENT_VERSION = 1;
				DYLIB_INSTALL_NAME_BASE = "@rpath";
				ENABLE_MODULE_VERIFIER = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © 2025 Polyend Community. All rights reserved.";
				INSTALL_PATH = "$(LOCAL_LIBRARY_DIR)/Frameworks";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
					"@loader_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				MODULE_VERIFIER_SUPPORTED_LANGUAGES = "objective-c objective-c++";
				MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS = "gnu11 gnu++20";
				PRODUCT_BUNDLE_IDENTIFIER = com.polyend.TrackerControllerFramework;
				PRODUCT_NAME = "$(TARGET_NAME:c99extidentifier)";
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				VERSIONING_SYSTEM = "apple-generic";
				VERSION_INFO_PREFIX = "";
			};
			name = Debug;
		};
		AA001101 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ARCHS = arm64;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEFINES_MODULE = YES;
				DYLIB_COMPATIBILITY_VERSION = 1;
				DYLIB_CURRENT_VERSION = 1;
				DYLIB_INSTALL_NAME_BASE = "@rpath";
				ENABLE_MODULE_VERIFIER = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © 2025 Polyend Community. All rights reserved.";
				INSTALL_PATH = "$(LOCAL_LIBRARY_DIR)/Frameworks";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
					"@loader_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				MODULE_VERIFIER_SUPPORTED_LANGUAGES = "objective-c objective-c++";
				MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS = "gnu11 gnu++20";
				PRODUCT_BUNDLE_IDENTIFIER = com.polyend.TrackerControllerFramework;
				PRODUCT_NAME = "$(TARGET_NAME:c99extidentifier)";
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				VERSIONING_SYSTEM = "apple-generic";
				VERSION_INFO_PREFIX = "";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		AA001060 /* Build configuration list for PBXNativeTarget "TrackerControllerFramework" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA001100 /* Debug */,
				AA001101 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		AA001080 /* Build configuration list for PBXProject "TrackerControllerSimple" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA001090 /* Debug */,
				AA001091 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = AA001070 /* Project object */;
}
EOF

# Create scheme file
mkdir -p "${PROJECT_NAME}.xcodeproj/xcshareddata/xcschemes"

cat > "${PROJECT_NAME}.xcodeproj/xcshareddata/xcschemes/TrackerControllerFramework.xcscheme" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "AA001050"
               BuildableName = "TrackerControllerFramework.framework"
               BlueprintName = "TrackerControllerFramework"
               ReferencedContainer = "container:TrackerControllerSimple.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
EOF

echo "✅ Created simplified Xcode project: ${PROJECT_NAME}.xcodeproj"
echo "This project contains only the framework without complex dependencies" 