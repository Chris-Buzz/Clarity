import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { FrictionEvent, FrictionChallenge, AppUsage, Task } from '@/types';
import { FRICTION_LEVELS, FRICTION_ESCALATION, QUICK_TASKS } from '@/constants';
import { useUserStore } from './userStore';

interface FrictionState {
  // Friction tracking
  frictionEvents: FrictionEvent[];
  currentFrictionLevel: number;
  lastFrictionTime: number;
  todayAttempts: Record<string, number>; // appId -> attempt count

  // App usage tracking
  appUsage: AppUsage[];

  // Tasks
  tasks: Task[];
  pendingTasks: Task[];

  // Actions
  getFrictionForApp: (appId: string) => FrictionChallenge;
  recordFrictionEvent: (event: Omit<FrictionEvent, 'id' | 'timestamp'>) => void;
  recordAppUsageStart: (appId: string) => void;
  recordAppUsageEnd: (appId: string, durationSeconds: number) => void;
  resetDailyTracking: () => void;

  // Task actions
  addTask: (task: Omit<Task, 'id' | 'createdAt' | 'completed'>) => void;
  completeTask: (taskId: string, photoUrl?: string) => void;
  deleteTask: (taskId: string) => void;
  getRandomVerificationTask: () => Task;

  // Computed
  getAppUsageToday: (appId: string) => number; // minutes
  getTotalUsageToday: () => number;
  shouldEscalate: (appId: string) => boolean;
}

export const useFrictionStore = create<FrictionState>()(
  persist(
    (set, get) => ({
      frictionEvents: [],
      currentFrictionLevel: 1,
      lastFrictionTime: 0,
      todayAttempts: {},
      appUsage: [],
      tasks: [],
      pendingTasks: [],

      getFrictionForApp: (appId) => {
        const state = get();
        const userStore = useUserStore.getState();

        // Check how many attempts today
        const attemptsToday = state.todayAttempts[appId] || 0;

        // Check total usage today
        const usageMinutes = state.getAppUsageToday(appId);

        // Calculate friction level
        let level = 1;

        // Escalate based on attempts
        level = Math.max(level, Math.ceil(attemptsToday / FRICTION_ESCALATION.attemptsPerLevel));

        // Escalate based on usage
        level = Math.max(
          level,
          Math.ceil(usageMinutes / FRICTION_ESCALATION.usageMinutesPerLevel)
        );

        // Check for pending tasks - if any, jump to level 7 (photo verification)
        const pendingTasks = state.tasks.filter((t) => !t.completed);
        if (pendingTasks.length > 0) {
          level = Math.max(level, 7);
        }

        // Night mode multiplier
        const now = new Date();
        const hour = now.getHours();
        if (userStore.user) {
          const { nightModeStart, nightModeEnd } = userStore.user.settings;
          const isNightMode =
            hour >= nightModeStart || hour < nightModeEnd;
          if (isNightMode) {
            level = Math.ceil(level * FRICTION_ESCALATION.nightModeMultiplier);
          }
        }

        // Cap at max level
        level = Math.min(level, FRICTION_LEVELS.length);

        // Update attempts
        set((s) => ({
          todayAttempts: {
            ...s.todayAttempts,
            [appId]: (s.todayAttempts[appId] || 0) + 1,
          },
          currentFrictionLevel: level,
          lastFrictionTime: Date.now(),
        }));

        // Get the challenge for this level
        const challenge = FRICTION_LEVELS[level - 1];

        // Generate dynamic content for certain challenge types
        if (challenge.type === 'math') {
          const difficulty = Math.min(level, 5);
          const a = Math.floor(Math.random() * (10 * difficulty)) + 5;
          const b = Math.floor(Math.random() * (10 * difficulty)) + 5;
          const operators: ('+' | '-' | '*')[] =
            difficulty > 3 ? ['+', '-', '*'] : ['+', '-'];
          const operator = operators[Math.floor(Math.random() * operators.length)];
          let answer: number;
          switch (operator) {
            case '+':
              answer = a + b;
              break;
            case '-':
              answer = a - b;
              break;
            case '*':
              answer = a * b;
              break;
          }
          return {
            ...challenge,
            mathProblem: { a, b, operator, answer },
          };
        }

        return challenge;
      },

      recordFrictionEvent: (event) => {
        const newEvent: FrictionEvent = {
          ...event,
          id: `friction_${Date.now()}`,
          timestamp: Date.now(),
        };

        set((state) => ({
          frictionEvents: [newEvent, ...state.frictionEvents].slice(0, 1000), // Keep last 1000
        }));

        // If resisted, give XP
        if (event.wasResisted) {
          useUserStore.getState().addXp(25); // Urge resisted bonus
        }
      },

      recordAppUsageStart: (appId) => {
        // This will be called when user proceeds through friction
        const today = new Date().toISOString().split('T')[0];

        set((state) => {
          const existingIndex = state.appUsage.findIndex(
            (u) => u.appName === appId && u.date === today
          );

          if (existingIndex >= 0) {
            const updated = [...state.appUsage];
            updated[existingIndex] = {
              ...updated[existingIndex],
              sessionCount: updated[existingIndex].sessionCount + 1,
              frictionEventsTriggered: updated[existingIndex].frictionEventsTriggered + 1,
              sessions: [
                ...updated[existingIndex].sessions,
                { startTime: Date.now(), endTime: 0 },
              ],
            };
            return { appUsage: updated };
          }

          return {
            appUsage: [
              ...state.appUsage,
              {
                appName: appId,
                date: today,
                totalMinutes: 0,
                sessionCount: 1,
                frictionEventsTriggered: 1,
                sessions: [{ startTime: Date.now(), endTime: 0 }],
              },
            ],
          };
        });
      },

      recordAppUsageEnd: (appId, durationSeconds) => {
        const today = new Date().toISOString().split('T')[0];

        set((state) => {
          const existingIndex = state.appUsage.findIndex(
            (u) => u.appName === appId && u.date === today
          );

          if (existingIndex >= 0) {
            const updated = [...state.appUsage];
            updated[existingIndex] = {
              ...updated[existingIndex],
              totalMinutes:
                updated[existingIndex].totalMinutes + Math.floor(durationSeconds / 60),
            };
            return { appUsage: updated };
          }

          return state;
        });
      },

      resetDailyTracking: () => {
        set({
          todayAttempts: {},
          currentFrictionLevel: 1,
        });
      },

      addTask: (taskData) => {
        const task: Task = {
          ...taskData,
          id: `task_${Date.now()}`,
          createdAt: Date.now(),
          completed: false,
        };
        set((state) => ({ tasks: [...state.tasks, task] }));
      },

      completeTask: (taskId, photoUrl) => {
        set((state) => ({
          tasks: state.tasks.map((t) =>
            t.id === taskId
              ? { ...t, completed: true, completedAt: Date.now(), photoUrl }
              : t
          ),
        }));

        // Award XP for task completion
        useUserStore.getState().addXp(30);
      },

      deleteTask: (taskId) => {
        set((state) => ({
          tasks: state.tasks.filter((t) => t.id !== taskId),
        }));
      },

      getRandomVerificationTask: () => {
        // Get a random quick task for level 7 friction
        const randomTask = QUICK_TASKS[Math.floor(Math.random() * QUICK_TASKS.length)];
        return {
          id: `quick_${Date.now()}`,
          title: randomTask.title,
          type: 'quick' as const,
          verificationType: randomTask.verificationType,
          verificationPrompt: randomTask.prompt,
          completed: false,
          createdAt: Date.now(),
        };
      },

      getAppUsageToday: (appId) => {
        const today = new Date().toISOString().split('T')[0];
        const usage = get().appUsage.find(
          (u) => u.appName === appId && u.date === today
        );
        return usage?.totalMinutes || 0;
      },

      getTotalUsageToday: () => {
        const today = new Date().toISOString().split('T')[0];
        return get()
          .appUsage.filter((u) => u.date === today)
          .reduce((sum, u) => sum + u.totalMinutes, 0);
      },

      shouldEscalate: (appId) => {
        const state = get();
        const timeSinceLast = Date.now() - state.lastFrictionTime;
        const hoursToReset = FRICTION_ESCALATION.resetAfterHours * 60 * 60 * 1000;

        // Reset if enough time has passed
        if (timeSinceLast > hoursToReset) {
          return false;
        }

        return true;
      },
    }),
    {
      name: 'clarity-friction-storage',
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({
        frictionEvents: state.frictionEvents.slice(0, 100), // Only persist last 100
        appUsage: state.appUsage.slice(0, 30), // Last 30 days
        tasks: state.tasks,
      }),
    }
  )
);
