// ============================================
// User & Profile Types
// ============================================

export interface UserSettings {
  soundscape: SoundscapeType;
  theme: ThemeType;
  portalDelaySeconds: number;
  usageInterruptionInterval: number; // minutes between interruptions
  nightModeStart: number; // hour (0-23) when stricter friction kicks in
  nightModeEnd: number;
  eternityMode: boolean; // Stricter mode - watcher never sleeps
  nudgesEnabled: boolean; // Random presence reminders
}

export interface User {
  id: string;
  name: string;
  email: string;
  xp: number;
  level: number;
  badges: string[];
  streak: number;
  lastActiveDate: string; // YYYY-MM-DD
  shieldedApps: string[];
  frictionLevel: number;
  isAuthenticated: boolean;
  isOnboarded: boolean;
  createdAt: number;
  settings: UserSettings;
}

// ============================================
// Focus Session Types
// ============================================

export enum SessionStatus {
  IDLE = 'IDLE',
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  COMPLETED = 'COMPLETED',
  INTERRUPTED = 'INTERRUPTED',
}

export interface FocusSession {
  id: string;
  startTime: number;
  endTime?: number;
  plannedDuration: number; // minutes
  actualDuration: number; // minutes
  task: string;
  wasCompleted: boolean;
  appViolations: string[];
  tabLeavesCount: number;
  urgesResisted: number;
  rating?: number; // 1-5
  note?: string;
  xpEarned: number;
  shieldedApps: string[];
}

export interface UserStats {
  dailyStreak: number;
  totalFocusTime: number; // minutes
  sessionsCompleted: number;
  totalXp: number;
  currentLevel: number;
  lifetimeUrgesResisted: number;
  longestSessionMinutes: number;
  perfectSessionsCount: number;
  lastActiveDate: string;
  weeklyXp: number;
  monthlyXp: number;
}

// ============================================
// Task Types (for friction/verification)
// ============================================

export type TaskType = 'quick' | 'verified' | 'custom';
export type VerificationType = 'photo' | 'motion' | 'none';

export interface Task {
  id: string;
  title: string;
  type: TaskType;
  verificationType: VerificationType;
  verificationPrompt?: string; // AI prompt to verify photo
  completed: boolean;
  completedAt?: number;
  photoUrl?: string;
  createdAt: number;
}

// ============================================
// Friction System Types
// ============================================

export type FrictionChallengeType =
  | 'confirm'      // Level 1: Simple confirmation
  | 'delay'        // Level 2: Wait with breathing
  | 'math'         // Level 3: Math problem
  | 'typing'       // Level 4: Type a phrase
  | 'puzzle'       // Level 5: Pattern matching
  | 'pushups'      // Level 6: Physical task
  | 'photo';       // Level 7: Verification photo

export interface FrictionEvent {
  id: string;
  timestamp: number;
  targetApp: string;
  frictionLevel: number;
  challengeType: FrictionChallengeType;
  wasCompleted: boolean;
  wasResisted: boolean; // User chose to go back
  durationSeconds: number;
}

export interface FrictionChallenge {
  level: number;
  type: FrictionChallengeType;
  title: string;
  description: string;
  timeoutSeconds?: number;
  requiredReps?: number; // for pushups
  mathProblem?: { a: number; b: number; operator: '+' | '-' | '*'; answer: number };
  typingPhrase?: string;
}

// ============================================
// App Usage Tracking
// ============================================

export interface AppUsage {
  appName: string;
  date: string; // YYYY-MM-DD
  totalMinutes: number;
  sessionCount: number;
  frictionEventsTriggered: number;
  sessions: { startTime: number; endTime: number }[];
}

// ============================================
// Badge System
// ============================================

export interface Badge {
  id: string;
  name: string;
  description: string;
  icon: string;
  unlockedAt?: number;
  criteria: {
    type: 'sessions' | 'time' | 'streak' | 'perfect' | 'urges' | 'level' | 'special';
    threshold: number;
  };
}

// ============================================
// Theme & UI Types
// ============================================

export type ThemeType = 'vibrant' | 'eerie';
export type SoundscapeType = 'fire' | 'rain' | 'forest' | 'white' | 'none';

export interface ThemeColors {
  primary: string;
  secondary: string;
  wax: string;
  background: string;
  text: string;
  textMuted: string;
}

// ============================================
// Shieldable App Definition
// ============================================

export interface ShieldableApp {
  id: string;
  name: string;
  icon: string;
  packageName?: string; // Android package name
  bundleId?: string; // iOS bundle ID
  url?: string; // For web-based access through portal
}
