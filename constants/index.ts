import { Badge, ShieldableApp, ThemeColors, FrictionChallenge, UserSettings } from '@/types';

// Re-export design system
export * from './design';

// ============================================
// Theme Colors
// ============================================

export const THEMES: Record<'vibrant' | 'eerie', ThemeColors> = {
  vibrant: {
    primary: '#FFA500',
    secondary: '#FFD700',
    wax: '#F5E6D3',
    background: '#030303',
    text: '#FFFFFF',
    textMuted: '#888888',
  },
  eerie: {
    primary: '#CC5500',
    secondary: '#8B4513',
    wax: '#E8D5C4',
    background: '#030303',
    text: '#F0E6DC',
    textMuted: '#6B5B4F',
  },
};

// ============================================
// XP & Gamification
// ============================================

export const XP_CONFIG = {
  perMinuteFocused: 10,
  urgeResistedBonus: 25,
  sessionCompletionBonus: 50,
  perfectSessionBonus: 100,
  taskCompletedBonus: {
    quick: 20,
    verified: 50,
    custom: 30,
  },
  streakMultiplier: 0.1, // +10% per streak day
  maxStreakBonus: 0.5, // cap at 50%
};

export const LEVEL_THRESHOLDS = [
  0,      // Level 1: Ember
  100,    // Level 2
  300,    // Level 3
  600,    // Level 4
  1000,   // Level 5: Flame
  1500,   // Level 6
  2200,   // Level 7
  3000,   // Level 8
  4000,   // Level 9
  5500,   // Level 10: Torch
  7500,   // Level 11
  10000,  // Level 12
  13000,  // Level 13
  17000,  // Level 14
  22000,  // Level 15: Bonfire
  28000,  // Level 16
  35000,  // Level 17
  43000,  // Level 18
  52000,  // Level 19
  62000,  // Level 20: Inferno
];

export const LEVEL_NAMES: Record<number, string> = {
  1: 'Ember',
  5: 'Flame',
  10: 'Torch',
  15: 'Bonfire',
  20: 'Inferno',
};

// ============================================
// Badges
// ============================================

export const BADGES: Badge[] = [
  {
    id: 'first_flame',
    name: 'First Flame',
    description: 'Complete your first focus session',
    icon: '🕯️',
    criteria: { type: 'sessions', threshold: 1 },
  },
  {
    id: 'week_warrior',
    name: 'Week Warrior',
    description: 'Maintain a 7-day streak',
    icon: '⚔️',
    criteria: { type: 'streak', threshold: 7 },
  },
  {
    id: 'hour_master',
    name: 'Hour Master',
    description: 'Focus for 60+ minutes in one session',
    icon: '⏰',
    criteria: { type: 'time', threshold: 60 },
  },
  {
    id: 'iron_will',
    name: 'Iron Will',
    description: 'Resist 50 urges to leave',
    icon: '🛡️',
    criteria: { type: 'urges', threshold: 50 },
  },
  {
    id: 'perfectionist',
    name: 'Perfectionist',
    description: 'Complete 10 sessions with zero interruptions',
    icon: '✨',
    criteria: { type: 'perfect', threshold: 10 },
  },
  {
    id: 'centurion',
    name: 'Centurion',
    description: 'Complete 100 focus sessions',
    icon: '🏛️',
    criteria: { type: 'sessions', threshold: 100 },
  },
  {
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Start a focus session before 7am',
    icon: '🌅',
    criteria: { type: 'special', threshold: 1 },
  },
  {
    id: 'night_guardian',
    name: 'Night Guardian',
    description: 'No phone use after 10pm for 7 days',
    icon: '🌙',
    criteria: { type: 'special', threshold: 7 },
  },
  {
    id: 'torch_bearer',
    name: 'Torch Bearer',
    description: 'Reach level 10',
    icon: '🔥',
    criteria: { type: 'level', threshold: 10 },
  },
  {
    id: 'thirty_day_flame',
    name: '30-Day Flame',
    description: 'Maintain a 30-day streak',
    icon: '🏆',
    criteria: { type: 'streak', threshold: 30 },
  },
];

// ============================================
// Friction System
// ============================================

export const FRICTION_LEVELS: FrictionChallenge[] = [
  {
    level: 1,
    type: 'confirm',
    title: 'Pause',
    description: 'Take a breath. Is this where your presence belongs?',
    timeoutSeconds: 3,
  },
  {
    level: 2,
    type: 'delay',
    title: 'Breathe',
    description: 'Breathe with the flame for a moment.',
    timeoutSeconds: 15,
  },
  {
    level: 3,
    type: 'math',
    title: 'Clarity Check',
    description: 'Solve this to proceed.',
    timeoutSeconds: 30,
  },
  {
    level: 4,
    type: 'typing',
    title: 'Intention',
    description: 'Type this phrase to continue.',
    typingPhrase: 'I am choosing distraction over presence',
  },
  {
    level: 5,
    type: 'puzzle',
    title: 'Pattern',
    description: 'Complete the pattern to unlock.',
    timeoutSeconds: 60,
  },
  {
    level: 6,
    type: 'pushups',
    title: 'Move',
    description: 'Complete 10 pushups to proceed.',
    requiredReps: 10,
  },
  {
    level: 7,
    type: 'photo',
    title: 'Verify',
    description: 'Complete a task and show proof.',
  },
];

export const FRICTION_ESCALATION = {
  attemptsPerLevel: 1, // Escalate after each attempt
  usageMinutesPerLevel: 10, // Or escalate every 10 minutes of usage
  nightModeMultiplier: 1.5, // Stricter at night
  resetAfterHours: 4, // Reset friction level after 4 hours of no attempts
};

// ============================================
// Shieldable Apps
// ============================================

export const SHIELDABLE_APPS: ShieldableApp[] = [
  {
    id: 'instagram',
    name: 'Instagram',
    icon: '📷',
    packageName: 'com.instagram.android',
    bundleId: 'com.burbn.instagram',
    url: 'https://instagram.com',
  },
  {
    id: 'tiktok',
    name: 'TikTok',
    icon: '🎵',
    packageName: 'com.zhiliaoapp.musically',
    bundleId: 'com.zhiliaoapp.musically',
    url: 'https://tiktok.com',
  },
  {
    id: 'twitter',
    name: 'X (Twitter)',
    icon: '🐦',
    packageName: 'com.twitter.android',
    bundleId: 'com.atebits.Tweetie2',
    url: 'https://x.com',
  },
  {
    id: 'youtube',
    name: 'YouTube',
    icon: '▶️',
    packageName: 'com.google.android.youtube',
    bundleId: 'com.google.ios.youtube',
    url: 'https://youtube.com',
  },
  {
    id: 'reddit',
    name: 'Reddit',
    icon: '🤖',
    packageName: 'com.reddit.frontpage',
    bundleId: 'com.reddit.Reddit',
    url: 'https://reddit.com',
  },
  {
    id: 'facebook',
    name: 'Facebook',
    icon: '👤',
    packageName: 'com.facebook.katana',
    bundleId: 'com.facebook.Facebook',
    url: 'https://facebook.com',
  },
  {
    id: 'snapchat',
    name: 'Snapchat',
    icon: '👻',
    packageName: 'com.snapchat.android',
    bundleId: 'com.toyopagroup.picaboo',
    url: 'https://snapchat.com',
  },
  {
    id: 'discord',
    name: 'Discord',
    icon: '💬',
    packageName: 'com.discord',
    bundleId: 'com.hammerandchisel.discord',
    url: 'https://discord.com',
  },
];

// ============================================
// Focus Session Durations
// ============================================

export const FOCUS_DURATIONS = [
  { minutes: 10, label: '10 min', description: 'Quick focus' },
  { minutes: 25, label: '25 min', description: 'Pomodoro' },
  { minutes: 45, label: '45 min', description: 'Deep work' },
  { minutes: 60, label: '60 min', description: 'Hour block' },
  { minutes: 90, label: '90 min', description: 'Flow state' },
];

// ============================================
// Soundscapes
// ============================================

export const SOUNDSCAPES = [
  { id: 'fire', name: 'Crackling Fire', icon: '🔥' },
  { id: 'rain', name: 'Gentle Rain', icon: '🌧️' },
  { id: 'forest', name: 'Forest Ambience', icon: '🌲' },
  { id: 'white', name: 'White Noise', icon: '📻' },
  { id: 'none', name: 'Silence', icon: '🔇' },
];

// ============================================
// Default Values
// ============================================

export const DEFAULT_USER_SETTINGS: UserSettings = {
  soundscape: 'fire',
  theme: 'vibrant',
  portalDelaySeconds: 10,
  usageInterruptionInterval: 5,
  nightModeStart: 22, // 10 PM
  nightModeEnd: 6, // 6 AM
  eternityMode: false, // Stricter mode off by default
  nudgesEnabled: true, // Presence reminders on by default
};

// ============================================
// Quick Tasks (for friction level 7)
// ============================================

export const QUICK_TASKS = [
  { id: 'water', title: 'Drink a glass of water', verificationType: 'photo' as const, prompt: 'A glass or bottle of water being held' },
  { id: 'bed', title: 'Make your bed', verificationType: 'photo' as const, prompt: 'A neatly made bed' },
  { id: 'outside', title: 'Step outside', verificationType: 'photo' as const, prompt: 'An outdoor scene with natural light' },
  { id: 'stretch', title: 'Do 30 seconds of stretching', verificationType: 'motion' as const, prompt: '' },
  { id: 'breathe', title: 'Take 5 deep breaths', verificationType: 'none' as const, prompt: '' },
];
