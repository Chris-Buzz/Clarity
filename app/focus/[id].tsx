import { Button } from '@/components/Button';
import CandleVisual from '@/components/CandleVisual';
import { FrictionChallenge } from '@/components/FrictionChallenge';
import { ScreenLayout } from '@/components/ScreenLayout';
import { SansText, SerifText } from '@/components/Typography';
import { THEMES, colors, radius, shadows, spacing } from '@/constants';
import { useSessionStore, useUserStore } from '@/stores';
import { SessionStatus } from '@/types';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { useRouter } from 'expo-router';
import React, { useEffect, useRef, useState } from 'react';
import { AppState, AppStateStatus, Pressable, View } from 'react-native';
import Animated, {
  Easing,
  FadeIn,
  FadeInDown,
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withSequence,
  withTiming,
} from 'react-native-reanimated';
import { useScreenTime } from '../../hooks/useScreenTime';

// Breathing background glow
const BreathingGlow = ({ color, isActive }: { color: string; isActive: boolean }) => {
  const scale = useSharedValue(1);
  const opacity = useSharedValue(0);

  useEffect(() => {
    if (isActive) {
      opacity.value = withTiming(0.15, { duration: 1000 });
      scale.value = withRepeat(
        withSequence(
          withTiming(1.1, { duration: 4000, easing: Easing.inOut(Easing.ease) }),
          withTiming(1, { duration: 4000, easing: Easing.inOut(Easing.ease) })
        ),
        -1,
        true
      );
    } else {
      opacity.value = withTiming(0.05, { duration: 500 });
    }
  }, [isActive]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    opacity: opacity.value,
  }));

  return (
    <Animated.View
      pointerEvents="none"
      style={[
        {
          position: 'absolute',
          top: '30%',
          left: '50%',
          marginLeft: -200,
          width: 400,
          height: 400,
          borderRadius: 200,
          backgroundColor: color,
        },
        animatedStyle,
      ]}
    />
  );
};

// Back button component
const BackButton = ({ onPress }: { onPress: () => void }) => (
  <Pressable
    onPress={onPress}
    hitSlop={{ top: 16, bottom: 16, left: 16, right: 16 }}
    className="w-[52px] h-[52px] rounded-full bg-stone-900 border-2 border-stone-700 items-center justify-center active:bg-stone-800 active:scale-95"
  >
    <Ionicons name="arrow-back" size={22} color={colors.textSecondary} />
  </Pressable>
);

// Control button (pause/resume)
const ControlButton = ({
  isPaused,
  onPress,
  color,
}: {
  isPaused: boolean;
  onPress: () => void;
  color: string;
}) => (
  <Pressable
    onPress={onPress}
    className="flex-row items-center justify-center gap-2 py-4 px-8 rounded-full border-2 active:scale-95"
    style={{
      backgroundColor: isPaused ? `${color}20` : colors.surface,
      borderColor: isPaused ? color : colors.border,
    }}
  >
    <Ionicons
      name={isPaused ? 'play' : 'pause'}
      size={18}
      color={isPaused ? color : colors.textSecondary}
    />
    <SansText
      className="text-sm font-semibold uppercase tracking-wider"
      style={{ color: isPaused ? color : colors.textSecondary }}
    >
      {isPaused ? 'Resume' : 'Pause'}
    </SansText>
  </Pressable>
);

export default function FocusTimerScreen() {
  const router = useRouter();
  const { user } = useUserStore();
  const {
    currentSession,
    status,
    timeRemaining,
    isPaused,
    tick,
    pauseSession,
    resumeSession,
    endSession,
    recordTabLeave,
    recordUrgeResisted,
  } = useSessionStore();
  const { endFocusSession } = useScreenTime();

  const [showFrictionChallenge, setShowFrictionChallenge] = useState(false);
  const [isValidSession, setIsValidSession] = useState(false);
  const appState = useRef(AppState.currentState);
  const leaveTime = useRef<number | null>(null);

  const theme = user?.settings?.theme || 'vibrant';
  const themeColors = THEMES[theme];
  const frictionLevel = user?.frictionLevel || 1;

  // Validate session
  useEffect(() => {
    const timer = setTimeout(() => {
      if (!currentSession) {
        router.replace('/(tabs)');
      } else {
        setIsValidSession(true);
      }
    }, 100);
    return () => clearTimeout(timer);
  }, [currentSession, router]);

  // Timer tick
  useEffect(() => {
    if (status !== SessionStatus.ACTIVE || isPaused || showFrictionChallenge) return;
    const interval = setInterval(() => tick(), 1000);
    return () => clearInterval(interval);
  }, [status, isPaused, tick, showFrictionChallenge]);

  // Check for completion
  useEffect(() => {
    if (timeRemaining <= 0 && status === SessionStatus.ACTIVE) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      endFocusSession();
      endSession(true);
      router.replace('/reflection');
    }
  }, [timeRemaining, status, endFocusSession, endSession, router]);

  // App state handling
  const statusRef = useRef(status);
  const sessionRef = useRef(currentSession);

  useEffect(() => {
    statusRef.current = status;
    sessionRef.current = currentSession;
  }, [status, currentSession]);

  useEffect(() => {
    const handleAppStateChange = async (nextAppState: AppStateStatus) => {
      const currentStatus = statusRef.current;
      const session = sessionRef.current;

      if (currentStatus !== SessionStatus.ACTIVE) return;

      if (appState.current === 'active' && nextAppState.match(/inactive|background/)) {
        leaveTime.current = Date.now();
        recordTabLeave();
      }

      if (appState.current.match(/inactive|background/) && nextAppState === 'active') {
        if (leaveTime.current) {
          const awayDuration = Date.now() - leaveTime.current;
          leaveTime.current = null;

          if (awayDuration < 5000) {
            // Quick return
          } else if (awayDuration < 30000) {
            recordUrgeResisted();
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
          } else if (awayDuration < 60000 && session && session.tabLeavesCount < 3) {
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
          } else {
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
            await endFocusSession();
            endSession(false);
            router.replace('/(tabs)');
          }
        }
      }
      appState.current = nextAppState;
    };

    const subscription = AppState.addEventListener('change', handleAppStateChange);
    return () => subscription.remove();
  }, [recordTabLeave, recordUrgeResisted, endFocusSession, endSession, router]);

  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const progress = currentSession
    ? timeRemaining / (currentSession.plannedDuration * 60)
    : 1;

  const handleBack = () => {
    pauseSession();
    setShowFrictionChallenge(true);
  };

  const handleCancelExit = () => {
    setShowFrictionChallenge(false);
    resumeSession();
  };

  const handleConfirmExit = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    setShowFrictionChallenge(false);
    await endFocusSession();
    endSession(false);
    router.replace('/(tabs)');
  };

  const handleTogglePause = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    if (isPaused) resumeSession();
    else pauseSession();
  };

  if (!isValidSession || !currentSession) {
    return <View style={{ flex: 1, backgroundColor: colors.background }} />;
  }

  const isActive = status === SessionStatus.ACTIVE && !isPaused;

  return (
    <ScreenLayout scrollable={false} contentContainerClassName="p-0">
      <Animated.View entering={FadeIn.duration(800)} style={{ flex: 1 }}>
        <BreathingGlow color={themeColors.primary} isActive={isActive} />

        {/* Header */}
        <View
          style={{
            flexDirection: 'row',
            alignItems: 'center',
            paddingHorizontal: spacing.lg,
            paddingTop: spacing.md,
            zIndex: 10,
          }}
        >
          <BackButton onPress={handleBack} />
        </View>

        {/* Main Content */}
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'space-around', paddingHorizontal: spacing.lg }}>
          {/* Task */}
          <Animated.View entering={FadeInDown.delay(200).duration(600)} style={{ alignItems: 'center' }}>
            <SansText
              style={{
                fontSize: 11,
                color: colors.textMuted,
                letterSpacing: 4,
                textTransform: 'uppercase',
                marginBottom: spacing.sm,
              }}
            >
              Focusing on
            </SansText>
            <SerifText
              style={{
                fontSize: 22,
                color: colors.textSecondary,
                textAlign: 'center',
                maxWidth: 280,
              }}
            >
              {currentSession.task}
            </SerifText>
          </Animated.View>

          {/* Candle */}
          <Animated.View entering={FadeIn.delay(400).duration(800)}>
            <CandleVisual
              progress={progress}
              isActive={isActive}
              theme={theme}
            />
          </Animated.View>

          {/* Timer & Controls */}
          <Animated.View entering={FadeInDown.delay(600).duration(600)} style={{ alignItems: 'center' }}>
            <Pressable onPress={handleTogglePause}>
              <SansText
                style={{
                  fontSize: 72,
                  fontWeight: '200',
                  color: isActive ? colors.textPrimary : colors.textTertiary,
                  letterSpacing: -2,
                }}
              >
                {formatTime(timeRemaining)}
              </SansText>
            </Pressable>

            <View style={{ marginTop: spacing.lg }}>
              <ControlButton
                isPaused={isPaused}
                onPress={handleTogglePause}
                color={themeColors.primary}
              />
            </View>
          </Animated.View>
        </View>

        {/* Friction Challenge */}
        {showFrictionChallenge && (
          <FrictionChallenge
            level={frictionLevel}
            onComplete={handleConfirmExit}
            onCancel={handleCancelExit}
            themeColor={themeColors.primary}
          />
        )}
      </Animated.View>
    </ScreenLayout>
  );
}
