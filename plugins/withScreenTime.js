const {
  withEntitlementsPlist,
  withInfoPlist,
  withAndroidManifest,
  withMainApplication,
  AndroidConfig,
} = require('@expo/config-plugins');

/**
 * Expo config plugin to enable Screen Time API (iOS) and UsageStats (Android)
 *
 * iOS: Requires Apple Developer Program and Family Controls entitlement approval
 * Android: Requires UsageStats permission granted by user
 */

// iOS: Add Family Controls entitlements
const withScreenTimeEntitlements = (config) => {
  return withEntitlementsPlist(config, (config) => {
    // Add Family Controls entitlement
    config.modResults['com.apple.developer.family-controls'] = {
      AuthorizationScope: 'individual',
    };
    return config;
  });
};

// iOS: Add Info.plist configuration
const withScreenTimeInfoPlist = (config) => {
  return withInfoPlist(config, (config) => {
    // Add usage description for Screen Time access
    config.modResults['NSFamilyControlsUsageDescription'] =
      'Clarity needs Screen Time access to help you stay focused by temporarily blocking distracting apps during focus sessions.';

    // Add background modes if needed
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

    // Add permissions
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

    // Add the blocking service
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

// Android: Register the native module package
const withScreenTimePackage = (config) => {
  return withMainApplication(config, (config) => {
    const mainApplication = config.modResults;

    // Add import
    const importStatement = 'import com.clarity.screentime.ScreenTimePackage;';
    if (!mainApplication.contents.includes(importStatement)) {
      // Find the last import statement and add after it
      const lastImportIndex = mainApplication.contents.lastIndexOf('import ');
      const endOfLine = mainApplication.contents.indexOf('\n', lastImportIndex);
      mainApplication.contents =
        mainApplication.contents.slice(0, endOfLine + 1) +
        importStatement +
        '\n' +
        mainApplication.contents.slice(endOfLine + 1);
    }

    // Add to packages list
    const packageStatement = 'packages.add(new ScreenTimePackage());';
    if (!mainApplication.contents.includes(packageStatement)) {
      // Find getPackages method and add the package
      const getPackagesRegex = /override fun getPackages\(\): List<ReactPackage> \{[\s\S]*?val packages = PackageList\(this\)\.packages/;
      const match = mainApplication.contents.match(getPackagesRegex);
      if (match) {
        const insertPoint = match.index + match[0].length;
        mainApplication.contents =
          mainApplication.contents.slice(0, insertPoint) +
          '\n            ' +
          packageStatement +
          mainApplication.contents.slice(insertPoint);
      }
    }

    return config;
  });
};

const withScreenTime = (config) => {
  // iOS configuration
  config = withScreenTimeEntitlements(config);
  config = withScreenTimeInfoPlist(config);

  // Android configuration
  config = withAndroidScreenTime(config);
  // Note: Package registration is handled automatically by autolinking

  return config;
};

module.exports = withScreenTime;
