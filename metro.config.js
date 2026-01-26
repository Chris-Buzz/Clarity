const { getDefaultConfig } = require('expo/metro-config');
const { withNativeWind } = require('nativewind/metro');

const config = getDefaultConfig(__dirname);

// Fix for react-native-css-interop with newer Node versions
config.watcher = {
  ...config.watcher,
  healthCheck: {
    enabled: true,
  },
};

// Ensure proper file watching on Windows
config.resolver = {
  ...config.resolver,
  unstable_enablePackageExports: false,
};

module.exports = withNativeWind(config, { input: './global.css' });
