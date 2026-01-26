import { Button } from '@/components/Button';
import { ScreenLayout } from '@/components/ScreenLayout';
import { SansText, SerifText } from '@/components/Typography';
import { THEMES, colors, radius, shadows, spacing } from '@/constants';
import { useSessionStore, useUserStore } from '@/stores';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { useRouter } from 'expo-router';
import React, { useEffect, useState } from 'react';
import {
  Keyboard,
  Platform,
  Pressable,
  TextInput,
  TouchableWithoutFeedback,
  View,
} from 'react-native';
import Animated, {
  Easing,
  FadeIn,
  FadeInDown,
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withSequence,
  withSpring,
  withTiming,
} from 'react-native-reanimated';
import { useScreenTime } from '../../hooks/useScreenTime';

const DURATIONS = [10, 25, 45, 60, 90];

// Animated glow background
const BackgroundGlow = ({ color }: { color: string }) => {
  const scale = useSharedValue(1);
  const opacity = useSharedValue(0.1);

  useEffect(() => {
    scale.value = withRepeat(
      withSequence(
        withTiming(1.15, { duration: 4000, easing: Easing.inOut(Easing.ease) }),
        withTiming(1, { duration: 4000, easing: Easing.inOut(Easing.ease) })
      ),
      -1,
      true
    );
    opacity.value = withRepeat(
      withSequence(
        withTiming(0.2, { duration: 4000 }),
        withTiming(0.08, { duration: 4000 })
      ),
      -1,
      true
    );
  }, []);

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
          top: -150,
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

// Duration pill component
const DurationPill = ({
  minutes,
  isSelected,
  onPress,
  color,
}: {
  minutes: number;
  isSelected: boolean;
  onPress: () => void;
  color: string;
}) => {
  const scale = useSharedValue(1);

  const handlePress = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    scale.value = withSequence(
      withSpring(0.9, { damping: 10 }),
      withSpring(1, { damping: 10 })
    );
    onPress();
  };

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  return (
    <Pressable onPress={handlePress}>
      <Animated.View
        className="px-6 py-4 rounded-full min-w-[56px] items-center border-2"
        style={[
          {
            backgroundColor: isSelected ? color : colors.surface,
            borderColor: isSelected ? color : colors.borderAccent,
          },
          animatedStyle,
        ]}
      >
        <SansText
          className="text-base font-semibold"
          style={{ color: isSelected ? '#fff' : colors.textSecondary }}
        >
          {minutes}
        </SansText>
      </Animated.View>
    </Pressable>
  );
};

// Start button using Button component
const StartButton = ({
  onPress,
  color,
  disabled,
}: {
  onPress: () => void;
  color: string;
  disabled: boolean;
}) => (
  <Button
    onPress={onPress}
    disabled={disabled}
    color={color}
    size="lg"
    fullWidth
    icon={
      <View
        className="w-2.5 h-2.5 rounded-full"
        style={{ backgroundColor: color }}
      />
    }
  >
    <SerifText style={{ fontSize: 20, color: colors.textPrimary }}>
      Begin Session
    </SerifText>
  </Button>
);

export default function RitualScreen() {
  const router = useRouter();
  const { user, _hasHydrated } = useUserStore();
  const { startSession } = useSessionStore();
  const {
    isAvailable: screenTimeAvailable,
    isAuthorized: screenTimeAuthorized,
    startFocusSession,
  } = useScreenTime();

  const [task, setTask] = useState('');
  const [duration, setDuration] = useState(25);
  const [isReady, setIsReady] = useState(false);
  const [isStarting, setIsStarting] = useState(false);
  const [isFocused, setIsFocused] = useState(false);

  const theme = user?.settings?.theme || 'vibrant';
  const themeColors = THEMES[theme];

  // Auth check
  useEffect(() => {
    if (!_hasHydrated) return;

    const timer = setTimeout(() => {
      if (!user?.isAuthenticated) {
        router.replace('/auth');
      } else if (!user?.isOnboarded) {
        router.replace('/onboarding');
      } else {
        setIsReady(true);
      }
    }, 100);

    return () => clearTimeout(timer);
  }, [_hasHydrated, user?.isAuthenticated, user?.isOnboarded, router]);

  const handleStart = async () => {
    if (isStarting) return;
    setIsStarting(true);

    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

    if (screenTimeAvailable && screenTimeAuthorized && Platform.OS === 'ios') {
      await startFocusSession(duration);
    }

    startSession(task || 'Deep Work', duration, user?.shieldedApps || []);
    router.push(`/focus/${Date.now()}`);
    setIsStarting(false);
  };

  if (!isReady) {
    return <View style={{ flex: 1, backgroundColor: colors.background }} />;
  }

  return (
    <ScreenLayout scrollable={false} contentContainerClassName="p-0">
      <BackgroundGlow color={themeColors.primary} />

      <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
        <View style={{ flex: 1, paddingHorizontal: spacing.lg, paddingVertical: spacing.lg }}>
          {/* Header */}
          <Animated.View
            entering={FadeIn.delay(100).duration(600)}
            style={{ alignItems: 'center', marginBottom: spacing['2xl'], marginTop: spacing.xl }}
          >
            <View
              style={{
                flexDirection: 'row',
                alignItems: 'center',
                gap: spacing.sm,
                marginBottom: spacing.lg,
              }}
            >
              <View style={{ width: 20, height: 1, backgroundColor: themeColors.primary }} />
              <SansText style={{ fontSize: 12, color: colors.textMuted, letterSpacing: 2, textTransform: 'uppercase' }}>
                {user?.name ? `Welcome, ${user.name}` : 'Ready to focus'}
              </SansText>
              <View style={{ width: 20, height: 1, backgroundColor: themeColors.primary }} />
            </View>

            <SerifText style={{ fontSize: 42, color: colors.textPrimary, textAlign: 'center', lineHeight: 52 }}>
              Find your{'\n'}
              <SerifText style={{ color: themeColors.primary }}>clarity</SerifText>
            </SerifText>
          </Animated.View>

          {/* Main Content */}
          <Animated.View
            entering={FadeInDown.delay(300).duration(600)}
            style={{ flex: 1, justifyContent: 'center', gap: spacing['2xl'] }}
          >
            {/* Task Input */}
            <View>
              <SansText
                style={{
                  fontSize: 11,
                  color: colors.textMuted,
                  letterSpacing: 3,
                  textTransform: 'uppercase',
                  marginBottom: spacing.sm,
                  marginLeft: spacing.xs,
                }}
              >
                What will you focus on?
              </SansText>
              <View
                style={[
                  {
                    backgroundColor: colors.surface,
                    borderWidth: 1,
                    borderColor: isFocused ? themeColors.primary : colors.border,
                    borderRadius: radius.xl,
                    overflow: 'hidden',
                  },
                  isFocused && { backgroundColor: `${themeColors.primary}10` },
                ]}
              >
                <TextInput
                  value={task}
                  onChangeText={setTask}
                  onFocus={() => setIsFocused(true)}
                  onBlur={() => setIsFocused(false)}
                  placeholder="Deep work, studying, writing..."
                  placeholderTextColor={colors.textMuted}
                  style={{
                    paddingHorizontal: spacing.lg,
                    paddingVertical: spacing.lg,
                    fontSize: 16,
                    color: colors.textPrimary,
                    textAlign: 'center',
                  }}
                />
              </View>
            </View>

            {/* Duration Picker */}
            <View>
              <SansText
                style={{
                  fontSize: 11,
                  color: colors.textMuted,
                  letterSpacing: 3,
                  textTransform: 'uppercase',
                  marginBottom: spacing.md,
                  textAlign: 'center',
                }}
              >
                Duration (minutes)
              </SansText>
              <View
                style={{
                  flexDirection: 'row',
                  justifyContent: 'center',
                  gap: spacing.sm,
                }}
              >
                {DURATIONS.map((m) => (
                  <DurationPill
                    key={m}
                    minutes={m}
                    isSelected={duration === m}
                    onPress={() => setDuration(m)}
                    color={themeColors.primary}
                  />
                ))}
              </View>
            </View>

            {/* Start Button */}
            <View style={{ marginTop: spacing.lg }}>
              <StartButton
                onPress={handleStart}
                color={themeColors.primary}
                disabled={isStarting}
              />
            </View>
          </Animated.View>

          {/* Footer hint */}
          <Animated.View
            entering={FadeIn.delay(600).duration(600)}
            style={{
              flexDirection: 'row',
              alignItems: 'center',
              justifyContent: 'center',
              gap: spacing.sm,
              paddingVertical: spacing.lg,
            }}
          >
            <Ionicons name="shield-checkmark-outline" size={14} color={colors.textMuted} />
            <SansText style={{ fontSize: 12, color: colors.textMuted }}>
              {user?.shieldedApps?.length || 0} apps will be blocked
            </SansText>
          </Animated.View>
        </View>
      </TouchableWithoutFeedback>
    </ScreenLayout>
  );
}
