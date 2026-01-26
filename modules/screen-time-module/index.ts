import { NativeModules, Platform } from 'react-native';

const { ScreenTimeModule } = NativeModules;

export interface InstalledApp {
  packageName: string;
  name: string;
}

export interface ScreenTimeModuleInterface {
  checkAuthorization(): Promise<boolean>;
  requestAuthorization(): Promise<boolean>;
  getInstalledApps(): Promise<InstalledApp[]>;
  setBlockedApps(appPackages: string[]): Promise<boolean>;
  startBlocking(): Promise<boolean>;
  stopBlocking(): Promise<boolean>;
  startFocusSession(durationMinutes: number): Promise<boolean>;
  endFocusSession(): Promise<boolean>;
  // Android specific
  openUsageSettings?(): Promise<boolean>;
  getCurrentForegroundApp?(): Promise<{ packageName: string; lastTimeUsed: number } | null>;
}

// Export the native module with type safety
export const ScreenTime: ScreenTimeModuleInterface | null =
  ScreenTimeModule || null;

// Helper to check if the module is available
export function isScreenTimeAvailable(): boolean {
  if (Platform.OS === 'ios') {
    const version = parseInt(Platform.Version as string, 10);
    return version >= 15 && ScreenTimeModule != null;
  }
  if (Platform.OS === 'android') {
    return ScreenTimeModule != null;
  }
  return false;
}

export default ScreenTime;
