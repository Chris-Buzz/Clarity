import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { FocusSession, SessionStatus } from '@/types';
import { XP_CONFIG } from '@/constants';
import { useUserStore } from './userStore';

interface SessionState {
  sessions: FocusSession[];
  currentSession: FocusSession | null;
  status: SessionStatus;
  timeRemaining: number; // seconds
  isPaused: boolean;

  // Actions
  startSession: (task: string, durationMinutes: number, shieldedApps: string[]) => void;
  pauseSession: () => void;
  resumeSession: () => void;
  endSession: (wasCompleted: boolean) => void;
  recordTabLeave: () => void;
  recordUrgeResisted: () => void;
  recordAppViolation: (appId: string) => void;
  tick: () => void;
  setRating: (sessionId: string, rating: number) => void;
  setNote: (sessionId: string, note: string) => void;
  deleteSession: (sessionId: string) => void;

  // Computed
  calculateSessionXp: (session: FocusSession) => number;
  getSessionHistory: (limit?: number) => FocusSession[];
  getTodaySessions: () => FocusSession[];
}

export const useSessionStore = create<SessionState>()(
  persist(
    (set, get) => ({
      sessions: [],
      currentSession: null,
      status: SessionStatus.IDLE,
      timeRemaining: 0,
      isPaused: false,

      startSession: (task, durationMinutes, shieldedApps) => {
        const session: FocusSession = {
          id: `session_${Date.now()}`,
          startTime: Date.now(),
          plannedDuration: durationMinutes,
          actualDuration: 0,
          task,
          wasCompleted: false,
          appViolations: [],
          tabLeavesCount: 0,
          urgesResisted: 0,
          xpEarned: 0,
          shieldedApps,
        };

        set({
          currentSession: session,
          status: SessionStatus.ACTIVE,
          timeRemaining: durationMinutes * 60,
          isPaused: false,
        });

        // Update user streak
        useUserStore.getState().updateStreak();
      },

      pauseSession: () => {
        set({ status: SessionStatus.PAUSED, isPaused: true });
      },

      resumeSession: () => {
        set({ status: SessionStatus.ACTIVE, isPaused: false });
      },

      endSession: (wasCompleted) => {
        const state = get();
        if (!state.currentSession) return;

        const endTime = Date.now();
        const actualDuration = Math.floor(
          (endTime - state.currentSession.startTime) / 60000
        );

        const completedSession: FocusSession = {
          ...state.currentSession,
          endTime,
          actualDuration,
          wasCompleted,
          xpEarned: 0, // Will be calculated next
        };

        // Calculate XP
        const xpEarned = get().calculateSessionXp(completedSession);
        completedSession.xpEarned = xpEarned;

        // Add XP to user
        useUserStore.getState().addXp(xpEarned);

        // Update user stats
        const userStore = useUserStore.getState();
        const isPerfect = completedSession.tabLeavesCount === 0 && wasCompleted;

        set((s) => ({
          sessions: [completedSession, ...s.sessions],
          currentSession: null,
          status: wasCompleted ? SessionStatus.COMPLETED : SessionStatus.INTERRUPTED,
          timeRemaining: 0,
          isPaused: false,
        }));

        // Update stats in user store (this would need to be enhanced)
        // For now, the stats are updated via the addXp call
      },

      recordTabLeave: () => {
        set((state) => {
          if (!state.currentSession) return state;
          return {
            currentSession: {
              ...state.currentSession,
              tabLeavesCount: state.currentSession.tabLeavesCount + 1,
            },
          };
        });
      },

      recordUrgeResisted: () => {
        set((state) => {
          if (!state.currentSession) return state;
          return {
            currentSession: {
              ...state.currentSession,
              urgesResisted: state.currentSession.urgesResisted + 1,
            },
          };
        });

        // Give immediate XP for resisting
        useUserStore.getState().addXp(XP_CONFIG.urgeResistedBonus);
      },

      recordAppViolation: (appId) => {
        set((state) => {
          if (!state.currentSession) return state;
          return {
            currentSession: {
              ...state.currentSession,
              appViolations: [...state.currentSession.appViolations, appId],
            },
          };
        });
      },

      tick: () => {
        set((state) => {
          if (state.status !== SessionStatus.ACTIVE || state.isPaused) {
            return state;
          }

          const newTime = state.timeRemaining - 1;

          if (newTime <= 0) {
            // Timer complete - will trigger end session
            return { ...state, timeRemaining: 0 };
          }

          return { timeRemaining: newTime };
        });
      },

      setRating: (sessionId, rating) => {
        set((state) => ({
          sessions: state.sessions.map((s) =>
            s.id === sessionId ? { ...s, rating } : s
          ),
        }));
      },

      setNote: (sessionId, note) => {
        set((state) => ({
          sessions: state.sessions.map((s) =>
            s.id === sessionId ? { ...s, note } : s
          ),
        }));
      },

      deleteSession: (sessionId) => {
        set((state) => ({
          sessions: state.sessions.filter((s) => s.id !== sessionId),
        }));
      },

      calculateSessionXp: (session) => {
        let xp = 0;

        // Base XP for time focused
        xp += session.actualDuration * XP_CONFIG.perMinuteFocused;

        // Urges resisted bonus
        xp += session.urgesResisted * XP_CONFIG.urgeResistedBonus;

        // Completion bonus
        if (session.wasCompleted) {
          xp += XP_CONFIG.sessionCompletionBonus;
        }

        // Perfect session bonus (no tab leaves, completed)
        if (session.tabLeavesCount === 0 && session.wasCompleted) {
          xp += XP_CONFIG.perfectSessionBonus;
        }

        // Streak multiplier
        const userStore = useUserStore.getState();
        if (userStore.user) {
          const streakBonus = Math.min(
            userStore.user.streak * XP_CONFIG.streakMultiplier,
            XP_CONFIG.maxStreakBonus
          );
          xp = Math.floor(xp * (1 + streakBonus));
        }

        return xp;
      },

      getSessionHistory: (limit) => {
        const sessions = get().sessions;
        return limit ? sessions.slice(0, limit) : sessions;
      },

      getTodaySessions: () => {
        const today = new Date().toISOString().split('T')[0];
        return get().sessions.filter((s) => {
          const sessionDate = new Date(s.startTime).toISOString().split('T')[0];
          return sessionDate === today;
        });
      },
    }),
    {
      name: 'clarity-session-storage',
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({
        sessions: state.sessions,
        // Don't persist current session or timer state
      }),
    }
  )
);
