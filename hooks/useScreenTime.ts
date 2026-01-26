import { useState, useEffect, useCallback } from 'react';
import { NativeModules, Platform, Alert, Linking } from 'react-native';

const { ScreenTimeModule } = NativeModules;

export interface InstalledApp {
  packageName: string;
  name: string;
}

interface UseScreenTimeReturn {
  isAvailable: boolean;
  isAuthorized: boolean;
  isLoading: boolean;
  error: string | null;
  installedApps: InstalledApp[];
  blockedApps: string[];
  isFrictionActive: boolean;
  requestAuthorization: () => Promise<boolean>;
  getInstalledApps: () => Promise<InstalledApp[]>;
  setBlockedApps: (apps: string[]) => Promise<boolean>;
  startBlocking: () => Promise<boolean>;
  stopBlocking: () => Promise<boolean>;
  startFocusSession: (durationMinutes: number) => Promise<boolean>;
  endFocusSession: () => Promise<boolean>;
  // Always-on friction - the main feature!
  enableFriction: (frictionLevel: number) => Promise<boolean>;
  disableFriction: () => Promise<boolean>;
  openSettings: () => void;
}

/**
 * Hook for using Screen Time API (iOS 15+) and UsageStats (Android)
 * Provides app blocking functionality during focus sessions
 */
export function useScreenTime(): UseScreenTimeReturn {
  const [isAuthorized, setIsAuthorized] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [installedApps, setInstalledApps] = useState<InstalledApp[]>([]);
  const [blockedApps, setBlockedAppsState] = useState<string[]>([]);
  const [isFrictionActive, setIsFrictionActive] = useState(false);

  // Check platform availability
  const isAvailable = (() => {
    if (Platform.OS === 'ios') {
      const version = parseInt(Platform.Version as string, 10);
      return version >= 15;
    }
    if (Platform.OS === 'android') {
      return true; // Android UsageStats available on API 21+
    }
    return false;
  })();

  // Check authorization status on mount
  useEffect(() => {
    if (!isAvailable) {
      setIsLoading(false);
      return;
    }

    checkAuthorization();
  }, [isAvailable]);

  const checkAuthorization = async () => {
    if (!ScreenTimeModule) {
      setError('Screen Time module not available. Please use a development build.');
      setIsLoading(false);
      return;
    }

    try {
      const authorized = await ScreenTimeModule.checkAuthorization();
      setIsAuthorized(authorized);
      setError(null);
    } catch (err: any) {
      setError(err.message || 'Failed to check authorization');
    } finally {
      setIsLoading(false);
    }
  };

  const requestAuthorization = useCallback(async (): Promise<boolean> => {
    if (!isAvailable) {
      Alert.alert(
        'Not Available',
        Platform.OS === 'ios'
          ? 'Screen Time blocking requires iOS 15 or later and a development build.'
          : 'App blocking requires a development build with proper permissions.',
        [{ text: 'OK' }]
      );
      return false;
    }

    if (!ScreenTimeModule) {
      Alert.alert(
        'Development Build Required',
        'App blocking is only available in development builds. Please build the app using EAS Build.',
        [{ text: 'OK' }]
      );
      return false;
    }

    try {
      setIsLoading(true);
      const authorized = await ScreenTimeModule.requestAuthorization();
      setIsAuthorized(authorized);

      if (!authorized) {
        const message = Platform.OS === 'ios'
          ? 'Clarity needs Screen Time access to block distracting apps. Please enable it in Settings.'
          : 'Clarity needs Usage Access permission to monitor and block apps. Please enable it in Settings.';

        Alert.alert(
          'Permission Required',
          message,
          [
            { text: 'Cancel', style: 'cancel' },
            { text: 'Open Settings', onPress: () => openSettings() },
          ]
        );
      }

      return authorized;
    } catch (err: any) {
      setError(err.message || 'Failed to request authorization');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, [isAvailable]);

  const getInstalledApps = useCallback(async (): Promise<InstalledApp[]> => {
    if (!ScreenTimeModule) {
      return [];
    }

    try {
      const apps = await ScreenTimeModule.getInstalledApps();
      setInstalledApps(apps);
      return apps;
    } catch (err: any) {
      setError(err.message || 'Failed to get installed apps');
      return [];
    }
  }, []);

  const setBlockedApps = useCallback(async (apps: string[]): Promise<boolean> => {
    if (!ScreenTimeModule) {
      // Store locally even without module
      setBlockedAppsState(apps);
      return true;
    }

    try {
      await ScreenTimeModule.setBlockedApps(apps);
      setBlockedAppsState(apps);
      return true;
    } catch (err: any) {
      setError(err.message || 'Failed to set blocked apps');
      return false;
    }
  }, []);

  const startBlocking = useCallback(async (): Promise<boolean> => {
    if (!isAuthorized || !ScreenTimeModule) {
      return false;
    }

    try {
      await ScreenTimeModule.startBlocking();
      return true;
    } catch (err: any) {
      setError(err.message || 'Failed to start blocking');
      return false;
    }
  }, [isAuthorized]);

  const stopBlocking = useCallback(async (): Promise<boolean> => {
    if (!ScreenTimeModule) {
      return false;
    }

    try {
      await ScreenTimeModule.stopBlocking();
      return true;
    } catch (err: any) {
      setError(err.message || 'Failed to stop blocking');
      return false;
    }
  }, []);

  const startFocusSession = useCallback(async (durationMinutes: number): Promise<boolean> => {
    if (!ScreenTimeModule) {
      // Fall back to non-blocking mode in Expo Go
      console.log('Screen Time not available, starting session without blocking');
      return true;
    }

    if (!isAuthorized) {
      // Try to request authorization first
      const granted = await requestAuthorization();
      if (!granted) {
        // Still allow session to start, just without blocking
        console.log('Screen Time not authorized, starting session without blocking');
        return true;
      }
    }

    try {
      await ScreenTimeModule.startFocusSession(durationMinutes);
      return true;
    } catch (err: any) {
      setError(err.message || 'Failed to start focus session');
      // Don't fail the session, just log the error
      console.warn('Screen Time blocking failed:', err);
      return true;
    }
  }, [isAuthorized, requestAuthorization]);

  const endFocusSession = useCallback(async (): Promise<boolean> => {
    if (!ScreenTimeModule) {
      return true;
    }

    try {
      await ScreenTimeModule.endFocusSession();
      return true;
    } catch (err: any) {
      setError(err.message || 'Failed to end focus session');
      return false;
    }
  }, []);

  const openSettings = useCallback(() => {
    if (Platform.OS === 'ios') {
      Linking.openURL('App-Prefs:SCREEN_TIME');
    } else if (Platform.OS === 'android') {
      // Open usage access settings on Android
      if (ScreenTimeModule?.openUsageSettings) {
        ScreenTimeModule.openUsageSettings();
      } else {
        Linking.openSettings();
      }
    }
  }, []);

  /**
   * Enable always-on friction mode
   * This is the main feature - adds friction to social media apps 24/7
   */
  const enableFriction = useCallback(async (frictionLevel: number): Promise<boolean> => {
    if (!ScreenTimeModule) {
      Alert.alert(
        'Development Build Required',
        'Always-on friction requires a development build. In Expo Go, you can test the friction challenges when exiting focus sessions.',
        [{ text: 'OK' }]
      );
      return false;
    }

    if (!isAuthorized) {
      const granted = await requestAuthorization();
      if (!granted) {
        return false;
      }
    }

    try {
      setIsLoading(true);
      await ScreenTimeModule.enableAlwaysOnFriction(frictionLevel);
      setIsFrictionActive(true);
      setError(null);
      return true;
    } catch (err: any) {
      setError(err.message || 'Failed to enable friction');
      Alert.alert('Error', err.message || 'Failed to enable friction mode');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, [isAuthorized, requestAuthorization]);

  /**
   * Disable always-on friction mode
   */
  const disableFriction = useCallback(async (): Promise<boolean> => {
    if (!ScreenTimeModule) {
      setIsFrictionActive(false);
      return true;
    }

    try {
      setIsLoading(true);
      await ScreenTimeModule.disableAlwaysOnFriction();
      setIsFrictionActive(false);
      setError(null);
      return true;
    } catch (err: any) {
      setError(err.message || 'Failed to disable friction');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Check if friction is active on mount
  useEffect(() => {
    if (ScreenTimeModule?.isAlwaysOnFrictionEnabled) {
      ScreenTimeModule.isAlwaysOnFrictionEnabled()
        .then((active: boolean) => setIsFrictionActive(active))
        .catch(() => {});
    }
  }, []);

  return {
    isAvailable,
    isAuthorized,
    isLoading,
    error,
    installedApps,
    blockedApps,
    isFrictionActive,
    requestAuthorization,
    getInstalledApps,
    setBlockedApps,
    startBlocking,
    stopBlocking,
    startFocusSession,
    endFocusSession,
    enableFriction,
    disableFriction,
    openSettings,
  };
}

export default useScreenTime;
