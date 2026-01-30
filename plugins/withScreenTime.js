const {
  withEntitlementsPlist,
  withInfoPlist,
  withAndroidManifest,
  AndroidConfig,
} = require('@expo/config-plugins');

/**
 * Expo config plugin for Screen Time/App Blocking functionality
 *
 * iOS: Uses Family Controls entitlement (APPROVED) with Screen Time API
 * Android: Uses UsageStatsManager + Foreground Service for app monitoring
 */

// iOS: Add Family Controls entitlement
// NOTE: Temporarily disabled — EAS auto-provisioning cannot generate profiles
// with the restricted Family Controls entitlement. The native module code still
// compiles fine; Screen Time auth will just fail at runtime until a manually
// provisioned build is set up.
const withScreenTimeEntitlements = (config) => {
  return withEntitlementsPlist(config, (config) => {
    config.modResults['com.apple.developer.family-controls'] = true;
    return config;
  });
};

// iOS: Add Info.plist configuration
const withScreenTimeInfoPlist = (config) => {
  return withInfoPlist(config, (config) => {
    config.modResults['NSFamilyControlsUsageDescription'] =
      'Clarity needs Screen Time access to help you stay focused by blocking distracting apps.';

    if (!config.modResults.UIBackgroundModes) {
      config.modResults.UIBackgroundModes = [];
    }
    if (!config.modResults.UIBackgroundModes.includes('processing')) {
      config.modResults.UIBackgroundModes.push('processing');
    }

    return config;
  });
};

// Android: Add required permissions and service to AndroidManifest
const withAndroidScreenTime = (config) => {
  return withAndroidManifest(config, async (config) => {
    const manifest = config.modResults;
    const mainApplication = AndroidConfig.Manifest.getMainApplicationOrThrow(manifest);

    const permissions = [
      'android.permission.PACKAGE_USAGE_STATS',
      'android.permission.SYSTEM_ALERT_WINDOW',
      'android.permission.FOREGROUND_SERVICE',
      'android.permission.FOREGROUND_SERVICE_SPECIAL_USE',
      'android.permission.QUERY_ALL_PACKAGES',
    ];

    if (!manifest.manifest['uses-permission']) {
      manifest.manifest['uses-permission'] = [];
    }

    for (const permission of permissions) {
      const exists = manifest.manifest['uses-permission'].some(
        (p) => p.$['android:name'] === permission
      );
      if (!exists) {
        manifest.manifest['uses-permission'].push({
          $: { 'android:name': permission },
        });
      }
    }

    if (!mainApplication.service) {
      mainApplication.service = [];
    }

    const serviceExists = mainApplication.service.some(
      (s) => s.$['android:name'] === 'com.clarity.screentime.AppBlockerService'
    );

    if (!serviceExists) {
      mainApplication.service.push({
        $: {
          'android:name': 'com.clarity.screentime.AppBlockerService',
          'android:enabled': 'true',
          'android:exported': 'false',
          'android:foregroundServiceType': 'specialUse',
        },
        property: [
          {
            $: {
              'android:name': 'android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE',
              'android:value': 'App blocking for focus sessions',
            },
          },
        ],
      });
    }

    return config;
  });
};

const withScreenTime = (config) => {
  // iOS configuration - Family Controls APPROVED
  config = withScreenTimeEntitlements(config);
  config = withScreenTimeInfoPlist(config);

  // Android configuration
  config = withAndroidScreenTime(config);

  return config;
};

module.exports = withScreenTime;
