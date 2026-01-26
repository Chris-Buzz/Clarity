import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { User, UserSettings, UserStats, Badge } from '@/types';
import { DEFAULT_USER_SETTINGS, BADGES, LEVEL_THRESHOLDS, XP_CONFIG } from '@/constants';

interface UserState {
  user: User | null;
  stats: UserStats;
  _hasHydrated: boolean;

  // Actions
  setHasHydrated: (state: boolean) => void;
  initUser: (name: string, email: string) => void;
  completeOnboarding: () => void;
  updateSettings: (settings: Partial<UserSettings>) => void;
  toggleShieldedApp: (appId: string) => void;
  setFrictionLevel: (level: number) => void;
  addXp: (amount: number) => void;
  unlockBadge: (badgeId: string) => void;
  updateStreak: () => void;
  resetUser: () => void;

  // Computed
  getLevel: (xp: number) => number;
  getXpForNextLevel: () => { current: number; required: number; progress: number };
  checkBadgeUnlocks: () => Badge[];
}

const initialStats: UserStats = {
  dailyStreak: 0,
  totalFocusTime: 0,
  sessionsCompleted: 0,
  totalXp: 0,
  currentLevel: 1,
  lifetimeUrgesResisted: 0,
  longestSessionMinutes: 0,
  perfectSessionsCount: 0,
  lastActiveDate: '',
  weeklyXp: 0,
  monthlyXp: 0,
};

export const useUserStore = create<UserState>()(
  persist(
    (set, get) => ({
      user: null,
      stats: initialStats,
      _hasHydrated: false,

      setHasHydrated: (state) => set({ _hasHydrated: state }),

      initUser: (name, email) => {
        const now = Date.now();
        const newUser: User = {
          id: `user_${now}`,
          name,
          email,
          xp: 0,
          level: 1,
          badges: [],
          streak: 0,
          lastActiveDate: new Date().toISOString().split('T')[0],
          shieldedApps: ['instagram', 'tiktok', 'twitter', 'youtube'], // Default shielded
          frictionLevel: 1,
          isAuthenticated: true,
          isOnboarded: false,
          createdAt: now,
          settings: DEFAULT_USER_SETTINGS,
        };
        set({ user: newUser });
      },

      completeOnboarding: () => {
        set((state) => ({
          user: state.user ? { ...state.user, isOnboarded: true } : null,
        }));
      },

      updateSettings: (settings) => {
        set((state) => ({
          user: state.user
            ? { ...state.user, settings: { ...state.user.settings, ...settings } }
            : null,
        }));
      },

      toggleShieldedApp: (appId) => {
        set((state) => {
          if (!state.user) return state;
          const current = state.user.shieldedApps;
          const updated = current.includes(appId)
            ? current.filter((id) => id !== appId)
            : [...current, appId];
          return { user: { ...state.user, shieldedApps: updated } };
        });
      },

      setFrictionLevel: (level) => {
        set((state) => ({
          user: state.user ? { ...state.user, frictionLevel: level } : null,
        }));
      },

      addXp: (amount) => {
        set((state) => {
          if (!state.user) return state;

          const newXp = state.user.xp + amount;
          const newLevel = get().getLevel(newXp);
          const today = new Date().toISOString().split('T')[0];

          // Update weekly/monthly XP
          const weekStart = getWeekStart();
          const monthStart = getMonthStart();

          return {
            user: {
              ...state.user,
              xp: newXp,
              level: newLevel,
              lastActiveDate: today,
            },
            stats: {
              ...state.stats,
              totalXp: state.stats.totalXp + amount,
              currentLevel: newLevel,
              weeklyXp: state.stats.weeklyXp + amount,
              monthlyXp: state.stats.monthlyXp + amount,
              lastActiveDate: today,
            },
          };
        });
      },

      unlockBadge: (badgeId) => {
        set((state) => {
          if (!state.user || state.user.badges.includes(badgeId)) return state;
          return {
            user: {
              ...state.user,
              badges: [...state.user.badges, badgeId],
            },
          };
        });
      },

      updateStreak: () => {
        set((state) => {
          if (!state.user) return state;

          const today = new Date().toISOString().split('T')[0];
          const lastActive = state.user.lastActiveDate;

          let newStreak = state.user.streak;

          if (!lastActive || lastActive === today) {
            // Same day or first day - keep streak
            newStreak = Math.max(1, state.user.streak);
          } else if (isYesterday(lastActive)) {
            // Consecutive day - increment streak
            newStreak = state.user.streak + 1;
          } else {
            // Streak broken
            newStreak = 1;
          }

          return {
            user: {
              ...state.user,
              streak: newStreak,
              lastActiveDate: today,
            },
            stats: {
              ...state.stats,
              dailyStreak: newStreak,
              lastActiveDate: today,
            },
          };
        });
      },

      resetUser: () => {
        set({ user: null, stats: initialStats });
      },

      getLevel: (xp) => {
        let level = 1;
        for (let i = LEVEL_THRESHOLDS.length - 1; i >= 0; i--) {
          if (xp >= LEVEL_THRESHOLDS[i]) {
            level = i + 1;
            break;
          }
        }
        return Math.min(level, LEVEL_THRESHOLDS.length);
      },

      getXpForNextLevel: () => {
        const state = get();
        if (!state.user) return { current: 0, required: 100, progress: 0 };

        const currentLevel = state.user.level;
        const currentXp = state.user.xp;

        if (currentLevel >= LEVEL_THRESHOLDS.length) {
          return { current: currentXp, required: currentXp, progress: 100 };
        }

        const currentLevelXp = LEVEL_THRESHOLDS[currentLevel - 1] || 0;
        const nextLevelXp = LEVEL_THRESHOLDS[currentLevel] || currentLevelXp;
        const xpInLevel = currentXp - currentLevelXp;
        const xpRequired = nextLevelXp - currentLevelXp;
        const progress = Math.min(100, (xpInLevel / xpRequired) * 100);

        return { current: xpInLevel, required: xpRequired, progress };
      },

      checkBadgeUnlocks: () => {
        const state = get();
        if (!state.user) return [];

        const newBadges: Badge[] = [];

        for (const badge of BADGES) {
          if (state.user.badges.includes(badge.id)) continue;

          let shouldUnlock = false;

          switch (badge.criteria.type) {
            case 'sessions':
              shouldUnlock = state.stats.sessionsCompleted >= badge.criteria.threshold;
              break;
            case 'streak':
              shouldUnlock = state.stats.dailyStreak >= badge.criteria.threshold;
              break;
            case 'time':
              shouldUnlock = state.stats.longestSessionMinutes >= badge.criteria.threshold;
              break;
            case 'perfect':
              shouldUnlock = state.stats.perfectSessionsCount >= badge.criteria.threshold;
              break;
            case 'urges':
              shouldUnlock = state.stats.lifetimeUrgesResisted >= badge.criteria.threshold;
              break;
            case 'level':
              shouldUnlock = state.user.level >= badge.criteria.threshold;
              break;
          }

          if (shouldUnlock) {
            newBadges.push({ ...badge, unlockedAt: Date.now() });
            get().unlockBadge(badge.id);
          }
        }

        return newBadges;
      },
    }),
    {
      name: 'clarity-user-storage',
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({
        user: state.user,
        stats: state.stats,
      }),
      onRehydrateStorage: () => (state, error) => {
        if (error) {
          console.log('Hydration error:', error);
        }
        state?.setHasHydrated(true);
      },
    }
  )
);

// Helper functions
function isYesterday(dateStr: string): boolean {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  return dateStr === yesterday.toISOString().split('T')[0];
}

function getWeekStart(): string {
  const now = new Date();
  const day = now.getDay();
  const diff = now.getDate() - day + (day === 0 ? -6 : 1);
  return new Date(now.setDate(diff)).toISOString().split('T')[0];
}

function getMonthStart(): string {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0];
}
