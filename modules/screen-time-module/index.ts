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
  enableAlwaysOnFriction?(frictionLevel: number): Promise<boolean>;
  disableAlwaysOnFriction?(): Promise<boolean>;
  // Android specific
  openUsageSettings?(): Promise<boolean>;
  getCurrentForegroundApp?(): Promise<{ packageName: string; lastTimeUsed: number } | null>;
}

// iOS stub implementation (until Screen Time entitlement is approved)
const iOSStub: ScreenTimeModuleInterface = {
  checkAuthorization: async () => false,
  requestAuthorization: async () => false,
  getInstalledApps: async () => [],
  setBlockedApps: async () => true,
  startBlocking: async () => true,
  stopBlocking: async () => true,
  startFocusSession: async () => true,
  endFocusSession: async () => true,
  enableAlwaysOnFriction: async () => false,
  disableAlwaysOnFriction: async () => true,
};

// Export the native module with type safety
// iOS: Uses real native module (Family Controls entitlement APPROVED)
// Android: Uses the native module
export const ScreenTime: ScreenTimeModuleInterface | null =
  ScreenTimeModule || null;

// Helper to check if the module is available
export function isScreenTimeAvailable(): boolean {
  return ScreenTimeModule != null;
}

export default ScreenTime;
