#!/usr/bin/env python3
"""
generate_xcodeproj.py
Generates a valid Xcode 15+ multiplatform project (.xcodeproj) for EM Copilot.
Targets: macOS 14+ and iOS 17+
Run: python3 generate_xcodeproj.py
Then: open EMCopilot.xcodeproj
"""

import os
import uuid
import json

# ---------------------------------------------------------------------------
# UUID helpers
# ---------------------------------------------------------------------------

def make_uuid():
    return uuid.uuid4().hex[:24].upper()

# ---------------------------------------------------------------------------
# Source file registry
# ---------------------------------------------------------------------------

SOURCE_FILES = [
    # App entry point
    "EMCopilot/App/EMCopilotApp.swift",
    # Models
    "EMCopilot/Models/DirectReport.swift",
    "EMCopilot/Models/GeneratedDocument.swift",
    "EMCopilot/Models/Program.swift",
    "EMCopilot/Models/OneOnOneSession.swift",       # Phase 2: 1:1 models
    # Services
    "EMCopilot/Services/ClaudeService.swift",
    "EMCopilot/Services/Prompts.swift",
    # Shared views
    "EMCopilot/Views/ContentView.swift",
    "EMCopilot/Views/Shared/MarkdownContentView.swift",  # Phase 2: markdown renderer
    # Onboarding
    "EMCopilot/Views/Onboarding/OnboardingView.swift",   # Phase 2: first-run flow
    # Home
    "EMCopilot/Views/Home/HomeView.swift",
    # Direct Reports
    "EMCopilot/Views/DirectReports/DirectReportsView.swift",
    "EMCopilot/Views/DirectReports/AddDirectReportView.swift",
    # Document generator
    "EMCopilot/Views/Generator/DocumentGeneratorView.swift",
    "EMCopilot/Views/Generator/GeneratedDocumentOutputView.swift",
    # Programs
    "EMCopilot/Views/Programs/ProgramManagerView.swift",
    # 1:1 workflow (Phase 2)
    "EMCopilot/Views/OneOnOne/OneOnOneHubView.swift",
    "EMCopilot/Views/OneOnOne/OneOnOneSessionView.swift",
    "EMCopilot/Views/OneOnOne/AddArtifactView.swift",
    # Settings
    "EMCopilot/Views/Settings/SettingsView.swift",
]

RESOURCE_FILES = [
    "EMCopilot/Resources/Assets.xcassets",
]

# ---------------------------------------------------------------------------
# Project constants
# ---------------------------------------------------------------------------

APP_NAME        = "EMCopilot"
BUNDLE_ID_BASE  = "com.yourname.emcopilot"    # Change this!
MACOS_DEPLOY    = "14.0"
IOS_DEPLOY      = "17.0"
SWIFT_VERSION   = "5.10"

# ---------------------------------------------------------------------------
# Generate UUIDs for every object we'll reference
# ---------------------------------------------------------------------------

PROJECT_UUID            = make_uuid()
MAIN_GROUP_UUID         = make_uuid()
PRODUCTS_GROUP_UUID     = make_uuid()
TARGET_UUID             = make_uuid()
PRODUCT_REF_UUID        = make_uuid()

SOURCES_PHASE_UUID      = make_uuid()
RESOURCES_PHASE_UUID    = make_uuid()
FRAMEWORKS_PHASE_UUID   = make_uuid()

DEBUG_CONFIG_UUID       = make_uuid()
RELEASE_CONFIG_UUID     = make_uuid()
TARGET_DEBUG_CFG_UUID   = make_uuid()
TARGET_RELEASE_CFG_UUID = make_uuid()
PROJECT_CFGLIST_UUID    = make_uuid()
TARGET_CFGLIST_UUID     = make_uuid()

SWIFTDATA_FW_REF_UUID   = make_uuid()
SWIFTDATA_BUILD_UUID    = make_uuid()

# Per-file UUIDs
file_refs   = {}   # path -> fileRef UUID
build_files = {}   # path -> buildFile UUID
for f in SOURCE_FILES:
    file_refs[f]   = make_uuid()
    build_files[f] = make_uuid()
for r in RESOURCE_FILES:
    file_refs[r]   = make_uuid()
    build_files[r] = make_uuid()

ASSETS_XCASSETS = "EMCopilot/Resources/Assets.xcassets"

# ---------------------------------------------------------------------------
# Build the project.pbxproj content
# ---------------------------------------------------------------------------

def indent(n, s):
    return "\t" * n + s

def pbxproj():
    lines = []
    lines.append("// !$*UTF8*$!")
    lines.append("{")
    lines.append("\tarchiveVersion = 1;")
    lines.append("\tclasses = {")
    lines.append("\t};")
    lines.append("\tobjectVersion = 77;")
    lines.append("\tobjects = {")
    lines.append("")

    # --- PBXBuildFile ---
    lines.append("\n/* Begin PBXBuildFile section */")
    for path, uid in build_files.items():
        name = os.path.basename(path)
        lines.append(f"\t\t{uid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {name} */; }};")
    lines.append(f"\t\t{SWIFTDATA_BUILD_UUID} /* SwiftData.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {SWIFTDATA_FW_REF_UUID} /* SwiftData.framework */; }};")
    lines.append("/* End PBXBuildFile section */")

    # --- PBXFileReference ---
    lines.append("\n/* Begin PBXFileReference section */")
    for path, uid in file_refs.items():
        name = os.path.basename(path)
        if path.endswith(".swift"):
            lines.append(f"\t\t{uid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = {name}; path = {path}; sourceTree = \"<group>\"; }};")
        elif path.endswith(".xcassets"):
            lines.append(f"\t\t{uid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; name = {name}; path = {path}; sourceTree = \"<group>\"; }};")
    lines.append(f"\t\t{PRODUCT_REF_UUID} /* {APP_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {APP_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    lines.append(f"\t\t{SWIFTDATA_FW_REF_UUID} /* SwiftData.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = SwiftData.framework; path = System/Library/Frameworks/SwiftData.framework; sourceTree = SDKROOT; }};")
    lines.append("/* End PBXFileReference section */")

    # --- PBXFrameworksBuildPhase ---
    lines.append("\n/* Begin PBXFrameworksBuildPhase section */")
    lines.append(f"\t\t{FRAMEWORKS_PHASE_UUID} /* Frameworks */ = {{")
    lines.append(f"\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append(f"\t\t\tbuildActionMask = 2147483647;")
    lines.append(f"\t\t\tfiles = (")
    lines.append(f"\t\t\t\t{SWIFTDATA_BUILD_UUID} /* SwiftData.framework in Frameworks */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXFrameworksBuildPhase section */")

    # --- PBXGroup ---
    lines.append("\n/* Begin PBXGroup section */")

    # Main group
    lines.append(f"\t\t{MAIN_GROUP_UUID} = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    for path, uid in file_refs.items():
        name = os.path.basename(path)
        lines.append(f"\t\t\t\t{uid} /* {name} */,")
    lines.append(f"\t\t\t\t{PRODUCTS_GROUP_UUID} /* Products */,")
    lines.append(f"\t\t\t\t{SWIFTDATA_FW_REF_UUID} /* SwiftData.framework */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    # Products group
    lines.append(f"\t\t{PRODUCTS_GROUP_UUID} /* Products */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{PRODUCT_REF_UUID} /* {APP_NAME}.app */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tname = Products;")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXGroup section */")

    # --- PBXNativeTarget ---
    lines.append("\n/* Begin PBXNativeTarget section */")
    lines.append(f"\t\t{TARGET_UUID} /* {APP_NAME} */ = {{")
    lines.append(f"\t\t\tisa = PBXNativeTarget;")
    lines.append(f"\t\t\tbuildConfigurationList = {TARGET_CFGLIST_UUID} /* Build configuration list for PBXNativeTarget \"{APP_NAME}\" */;")
    lines.append(f"\t\t\tbuildPhases = (")
    lines.append(f"\t\t\t\t{SOURCES_PHASE_UUID} /* Sources */,")
    lines.append(f"\t\t\t\t{RESOURCES_PHASE_UUID} /* Resources */,")
    lines.append(f"\t\t\t\t{FRAMEWORKS_PHASE_UUID} /* Frameworks */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tbuildRules = (")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tdependencies = (")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tname = {APP_NAME};")
    lines.append(f"\t\t\tpackageProductDependencies = (")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tproductName = {APP_NAME};")
    lines.append(f"\t\t\tproductReference = {PRODUCT_REF_UUID} /* {APP_NAME}.app */;")
    lines.append(f"\t\t\tproductType = \"com.apple.product-type.application\";")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXNativeTarget section */")

    # --- PBXProject ---
    lines.append("\n/* Begin PBXProject section */")
    lines.append(f"\t\t{PROJECT_UUID} /* Project object */ = {{")
    lines.append(f"\t\t\tisa = PBXProject;")
    lines.append(f"\t\t\tattributes = {{")
    lines.append(f"\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    lines.append(f"\t\t\t\tLastSwiftUpdateCheck = 1500;")
    lines.append(f"\t\t\t\tLastUpgradeCheck = 1500;")
    lines.append(f"\t\t\t\tTargetAttributes = {{")
    lines.append(f"\t\t\t\t\t{TARGET_UUID} = {{")
    lines.append(f"\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    lines.append(f"\t\t\t\t\t}};")
    lines.append(f"\t\t\t\t}};")
    lines.append(f"\t\t\t}};")
    lines.append(f"\t\t\tbuildConfigurationList = {PROJECT_CFGLIST_UUID} /* Build configuration list for PBXProject \"{APP_NAME}\" */;")
    lines.append(f"\t\t\tcompatibilityVersion = \"Xcode 15.0\";")
    lines.append(f"\t\t\tdevelopmentRegion = en;")
    lines.append(f"\t\t\thasScannedForEncodings = 0;")
    lines.append(f"\t\t\tknownRegions = (")
    lines.append(f"\t\t\t\ten,")
    lines.append(f"\t\t\t\tBase,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tmainGroup = {MAIN_GROUP_UUID};")
    lines.append(f"\t\t\tproductRefGroup = {PRODUCTS_GROUP_UUID} /* Products */;")
    lines.append(f"\t\t\tprojectDirPath = \"\";")
    lines.append(f"\t\t\tprojectRoot = \"\";")
    lines.append(f"\t\t\ttargets = (")
    lines.append(f"\t\t\t\t{TARGET_UUID} /* {APP_NAME} */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXProject section */")

    # --- PBXResourcesBuildPhase ---
    lines.append("\n/* Begin PBXResourcesBuildPhase section */")
    lines.append(f"\t\t{RESOURCES_PHASE_UUID} /* Resources */ = {{")
    lines.append(f"\t\t\tisa = PBXResourcesBuildPhase;")
    lines.append(f"\t\t\tbuildActionMask = 2147483647;")
    lines.append(f"\t\t\tfiles = (")
    # Add assets to resources
    if ASSETS_XCASSETS in build_files:
        name = os.path.basename(ASSETS_XCASSETS)
        lines.append(f"\t\t\t\t{build_files[ASSETS_XCASSETS]} /* {name} in Resources */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXResourcesBuildPhase section */")

    # --- PBXSourcesBuildPhase ---
    lines.append("\n/* Begin PBXSourcesBuildPhase section */")
    lines.append(f"\t\t{SOURCES_PHASE_UUID} /* Sources */ = {{")
    lines.append(f"\t\t\tisa = PBXSourcesBuildPhase;")
    lines.append(f"\t\t\tbuildActionMask = 2147483647;")
    lines.append(f"\t\t\tfiles = (")
    for path in SOURCE_FILES:
        name = os.path.basename(path)
        lines.append(f"\t\t\t\t{build_files[path]} /* {name} in Sources */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXSourcesBuildPhase section */")

    # --- XCBuildConfiguration ---
    lines.append("\n/* Begin XCBuildConfiguration section */")

    # Project Debug
    lines.append(f"\t\t{DEBUG_CONFIG_UUID} /* Debug */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tbuildSettings = {{")
    lines.append(f"\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    lines.append(f"\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    lines.append(f"\t\t\t\tCOPY_PHASE_STRIP = NO;")
    lines.append(f"\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
    lines.append(f"\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
    lines.append(f"\t\t\t\tENABLE_TESTABILITY = YES;")
    lines.append(f"\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;")
    lines.append(f"\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
    lines.append(f"\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
    lines.append(f"\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (\"DEBUG=1\", \"$(inherited)\");")
    lines.append(f"\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;")
    lines.append(f"\t\t\t\tMTL_FAST_MATH = YES;")
    lines.append(f"\t\t\t\tONLY_ACTIVE_ARCH = YES;")
    lines.append(f"\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
    lines.append(f"\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
    lines.append(f"\t\t\t}};")
    lines.append(f"\t\t\tname = Debug;")
    lines.append(f"\t\t}};")

    # Project Release
    lines.append(f"\t\t{RELEASE_CONFIG_UUID} /* Release */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tbuildSettings = {{")
    lines.append(f"\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    lines.append(f"\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    lines.append(f"\t\t\t\tCOPY_PHASE_STRIP = NO;")
    lines.append(f"\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";")
    lines.append(f"\t\t\t\tENABLE_NS_ASSERTIONS = NO;")
    lines.append(f"\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
    lines.append(f"\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;")
    lines.append(f"\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;")
    lines.append(f"\t\t\t\tMTL_FAST_MATH = YES;")
    lines.append(f"\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
    lines.append(f"\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";")
    lines.append(f"\t\t\t}};")
    lines.append(f"\t\t\tname = Release;")
    lines.append(f"\t\t}};")

    # Target Debug
    lines.append(f"\t\t{TARGET_DEBUG_CFG_UUID} /* Debug */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tbuildSettings = {{")
    lines.append(f"\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
    lines.append(f"\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;")
    lines.append(f"\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;")
    lines.append(f"\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
    lines.append(f"\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    lines.append(f"\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = \"public.app-category.productivity\";")
    lines.append(f"\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = \"\";")
    lines.append(f"\t\t\t\tINFOPLIST_KEY_NSPrincipalClass = NSApplication;")
    lines.append(f"\t\t\t\tMARKETING_VERSION = 1.0;")
    lines.append(f"\t\t\t\tMACOS_DEPLOYMENT_TARGET = {MACOS_DEPLOY};")
    lines.append(f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {IOS_DEPLOY};")
    lines.append(f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = \"{BUNDLE_ID_BASE}\";")
    lines.append(f"\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    lines.append(f"\t\t\t\tSDKROOT = auto;")
    lines.append(f"\t\t\t\tSUPPORTED_PLATFORMS = \"macosx iphoneos iphonesimulator\";")
    lines.append(f"\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
    lines.append(f"\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};")
    lines.append(f"\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    lines.append(f"\t\t\t}};")
    lines.append(f"\t\t\tname = Debug;")
    lines.append(f"\t\t}};")

    # Target Release
    lines.append(f"\t\t{TARGET_RELEASE_CFG_UUID} /* Release */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tbuildSettings = {{")
    lines.append(f"\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
    lines.append(f"\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;")
    lines.append(f"\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;")
    lines.append(f"\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
    lines.append(f"\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    lines.append(f"\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = \"public.app-category.productivity\";")
    lines.append(f"\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = \"\";")
    lines.append(f"\t\t\t\tINFOPLIST_KEY_NSPrincipalClass = NSApplication;")
    lines.append(f"\t\t\t\tMARKETING_VERSION = 1.0;")
    lines.append(f"\t\t\t\tMACOS_DEPLOYMENT_TARGET = {MACOS_DEPLOY};")
    lines.append(f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {IOS_DEPLOY};")
    lines.append(f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = \"{BUNDLE_ID_BASE}\";")
    lines.append(f"\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    lines.append(f"\t\t\t\tSDKROOT = auto;")
    lines.append(f"\t\t\t\tSUPPORTED_PLATFORMS = \"macosx iphoneos iphonesimulator\";")
    lines.append(f"\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
    lines.append(f"\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};")
    lines.append(f"\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    lines.append(f"\t\t\t}};")
    lines.append(f"\t\t\tname = Release;")
    lines.append(f"\t\t}};")

    lines.append("/* End XCBuildConfiguration section */")

    # --- XCConfigurationList ---
    lines.append("\n/* Begin XCConfigurationList section */")
    lines.append(f"\t\t{PROJECT_CFGLIST_UUID} /* Build configuration list for PBXProject \"{APP_NAME}\" */ = {{")
    lines.append(f"\t\t\tisa = XCConfigurationList;")
    lines.append(f"\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{DEBUG_CONFIG_UUID} /* Debug */,")
    lines.append(f"\t\t\t\t{RELEASE_CONFIG_UUID} /* Release */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append(f"\t\t\tdefaultConfigurationName = Release;")
    lines.append(f"\t\t}};")
    lines.append(f"\t\t{TARGET_CFGLIST_UUID} /* Build configuration list for PBXNativeTarget \"{APP_NAME}\" */ = {{")
    lines.append(f"\t\t\tisa = XCConfigurationList;")
    lines.append(f"\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{TARGET_DEBUG_CFG_UUID} /* Debug */,")
    lines.append(f"\t\t\t\t{TARGET_RELEASE_CFG_UUID} /* Release */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append(f"\t\t\tdefaultConfigurationName = Release;")
    lines.append(f"\t\t}};")
    lines.append("/* End XCConfigurationList section */")

    lines.append("\t};")
    lines.append(f"\trootObject = {PROJECT_UUID} /* Project object */;")
    lines.append("}")

    return "\n".join(lines)

# ---------------------------------------------------------------------------
# Asset catalog stubs
# ---------------------------------------------------------------------------

def create_asset_catalog():
    base = "EMCopilot/Resources/Assets.xcassets"
    os.makedirs(base, exist_ok=True)
    os.makedirs(f"{base}/AppIcon.appiconset", exist_ok=True)
    os.makedirs(f"{base}/AccentColor.colorset", exist_ok=True)

    # Contents.json for catalog root
    with open(f"{base}/Contents.json", "w") as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)

    # AppIcon Contents.json (universal)
    appicon_contents = {
        "images": [{"idiom": "universal", "platform": "ios", "size": "1024x1024"},
                   {"idiom": "mac", "size": "1024x1024", "scale": "1x"}],
        "info": {"author": "xcode", "version": 1}
    }
    with open(f"{base}/AppIcon.appiconset/Contents.json", "w") as f:
        json.dump(appicon_contents, f, indent=2)

    # AccentColor
    accent_contents = {
        "colors": [{"idiom": "universal", "color": {"color-space": "srgb",
                    "components": {"red": "0.337", "green": "0.333", "blue": "0.996", "alpha": "1.000"}}}],
        "info": {"author": "xcode", "version": 1}
    }
    with open(f"{base}/AccentColor.colorset/Contents.json", "w") as f:
        json.dump(accent_contents, f, indent=2)

    print(f"  ✓ Created {base}")

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print("🔨 Generating EM Copilot Xcode project…\n")

    proj_dir = "EMCopilot.xcodeproj"
    os.makedirs(proj_dir, exist_ok=True)

    # Write project.pbxproj
    proj_path = os.path.join(proj_dir, "project.pbxproj")
    content = pbxproj()
    with open(proj_path, "w") as f:
        f.write(content)
    print(f"  ✓ Created {proj_path}")

    # Create asset catalog
    create_asset_catalog()

    # Verify all source files exist
    print("\n📋 Checking source files…")
    missing = []
    for path in SOURCE_FILES:
        if os.path.exists(path):
            print(f"  ✓ {path}")
        else:
            print(f"  ✗ MISSING: {path}")
            missing.append(path)

    print()
    if missing:
        print(f"⚠️  {len(missing)} source file(s) are missing. Create them before building.")
    else:
        print("✅ All source files present.")
        print("\n🚀 Next steps:")
        print("   1. open EMCopilot.xcodeproj")
        print("   2. Select your team in Signing & Capabilities")
        print("   3. Set your API key in Settings and build!")
        print()
        print(f"   Bundle ID: {BUNDLE_ID_BASE}  ← change this to your reverse domain")

if __name__ == "__main__":
    main()
