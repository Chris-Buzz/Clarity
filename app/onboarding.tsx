import { Button } from '@/components/Button';
import { ScreenLayout } from '@/components/ScreenLayout';
import { SansText, SerifText } from '@/components/Typography';
import { SHIELDABLE_APPS } from '@/constants';
import { colors, radius, shadows, spacing } from '@/constants/design';
import { useUserStore } from '@/stores';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { useRouter } from 'expo-router';
import React, { useCallback, useEffect, useState } from 'react';
import { Linking, Platform, Pressable, ScrollView, View } from 'react-native';
import Animated, {
  Easing,
  FadeIn,
  FadeInDown,
  FadeInUp,
  FadeOut,
  interpolate,
  runOnJS,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withRepeat,
  withSequence,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

const TOTAL_STEPS = 4;

// Premium animated background orb
const HeroOrb = () => {
  const scale = useSharedValue(1);
  const opacity = useSharedValue(0.4);
  const rotate = useSharedValue(0);

  useEffect(() => {
    // Breathing effect
    scale.value = withRepeat(
      withSequence(
        withTiming(1.15, { duration: 3000, easing: Easing.inOut(Easing.ease) }),
        withTiming(1, { duration: 3000, easing: Easing.inOut(Easing.ease) })
      ),
      -1,
      true
    );
    opacity.value = withRepeat(
      withSequence(
        withTiming(0.6, { duration: 3000 }),
        withTiming(0.3, { duration: 3000 })
      ),
      -1,
      true
    );
    // Slow rotation
    rotate.value = withRepeat(
      withTiming(360, { duration: 20000, easing: Easing.linear }),
      -1,
      false
    );
  }, []);

  const outerStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }, { rotate: `${rotate.value}deg` }],
    opacity: opacity.value * 0.5,
  }));

  const innerStyle = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(scale.value, [1, 1.15], [1, 0.95]) }],
    opacity: opacity.value,
  }));

  return (
    <View className="items-center justify-center" style={{ width: 200, height: 200 }}>
      {/* Outer glow ring */}
      <Animated.View
        style={[
          {
            position: 'absolute',
            width: 200,
            height: 200,
            borderRadius: 100,
            borderWidth: 1,
            borderColor: colors.primary,
          },
          outerStyle,
        ]}
      />
      {/* Middle glow */}
      <Animated.View
        style={[
          {
            position: 'absolute',
            width: 160,
            height: 160,
            borderRadius: 80,
            backgroundColor: colors.primaryGlow,
          },
          innerStyle,
        ]}
      />
      {/* Core icon */}
      <View
        style={[
          {
            width: 100,
            height: 100,
            borderRadius: 50,
            backgroundColor: colors.primary,
            alignItems: 'center',
            justifyContent: 'center',
          },
          shadows.glow(colors.primary),
        ]}
      >
        <Ionicons name="flame" size={48} color="#fff" />
      </View>
    </View>
  );
};

// Feature card component
const FeatureCard = ({
  icon,
  iconColor,
  iconBg,
  title,
  description,
  delay = 0,
}: {
  icon: keyof typeof Ionicons.glyphMap;
  iconColor: string;
  iconBg: string;
  title: string;
  description: string;
  delay?: number;
}) => (
  <Animated.View
    entering={FadeInUp.delay(delay).duration(500).springify()}
    style={{
      flexDirection: 'row',
      alignItems: 'flex-start',
      gap: spacing.md,
      padding: spacing.lg,
      backgroundColor: colors.surface,
      borderRadius: radius.xl,
      borderWidth: 1,
      borderColor: colors.border,
    }}
  >
    <View
      style={{
        width: 48,
        height: 48,
        borderRadius: radius.lg,
        backgroundColor: iconBg,
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <Ionicons name={icon} size={24} color={iconColor} />
    </View>
    <View style={{ flex: 1 }}>
      <SansText style={{ color: colors.textPrimary, fontSize: 16, fontWeight: '600', marginBottom: 4 }}>
        {title}
      </SansText>
      <SansText style={{ color: colors.textTertiary, fontSize: 14, lineHeight: 20 }}>
        {description}
      </SansText>
    </View>
  </Animated.View>
);

// Step 1: Welcome
const WelcomeStep = ({ onNext }: { onNext: () => void }) => (
  <View style={{ flex: 1 }}>
    <ScrollView
      showsVerticalScrollIndicator={false}
      contentContainerStyle={{ flexGrow: 1, paddingBottom: spacing.lg }}
    >
      {/* Hero */}
      <View style={{ alignItems: 'center', paddingTop: spacing.xl, paddingBottom: spacing.xl }}>
        <HeroOrb />
      </View>

      {/* Title */}
      <Animated.View entering={FadeInDown.delay(300).duration(600)}>
        <SerifText
          style={{
            fontSize: 36,
            color: colors.textPrimary,
            textAlign: 'center',
            marginBottom: spacing.sm,
          }}
        >
          Reclaim Your Focus
        </SerifText>
        <SansText
          style={{
            fontSize: 16,
            color: colors.textTertiary,
            textAlign: 'center',
            lineHeight: 24,
            paddingHorizontal: spacing.md,
            marginBottom: spacing.xl,
          }}
        >
          Block distracting apps during work sessions and build better habits.
        </SansText>
      </Animated.View>

      {/* Features */}
      <View style={{ gap: spacing.md }}>
        <FeatureCard
          icon="timer-outline"
          iconColor={colors.primary}
          iconBg={colors.primaryMuted}
          title="Focus Sessions"
          description="Set a timer, commit to work. Distracting apps get blocked automatically."
          delay={400}
        />
        <FeatureCard
          icon="shield-checkmark"
          iconColor={colors.danger}
          iconBg={colors.dangerMuted}
          title="Smart Blocking"
          description="Choose apps to shield. They stay locked until your session ends."
          delay={500}
        />
        <FeatureCard
          icon="trending-up"
          iconColor={colors.success}
          iconBg={colors.successMuted}
          title="Track Progress"
          description="Build streaks and watch your focus improve over time."
          delay={600}
        />
      </View>
    </ScrollView>

    {/* CTA - Fixed at bottom */}
    <View style={{ paddingTop: spacing.md, paddingBottom: spacing.sm }}>
      <Button onPress={onNext} variant="primary" size="lg" fullWidth>
        Get Started
      </Button>
    </View>
  </View>
);

// Step 2: App Selection
const AppSelectionStep = ({
  selectedApps,
  onToggleApp,
  onNext,
  onBack,
}: {
  selectedApps: string[];
  onToggleApp: (id: string) => void;
  onNext: () => void;
  onBack: () => void;
}) => {
  const handleToggle = (id: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onToggleApp(id);
  };

  return (
    <View className="flex-1">
      {/* Header */}
      <View className="items-center mb-6">
        <View className="w-16 h-16 rounded-full bg-red-500/15 items-center justify-center mb-4">
          <Ionicons name="shield-checkmark" size={32} color={colors.danger} />
        </View>
        <SerifText className="text-[28px] text-white mb-1">
          Shield Your Focus
        </SerifText>
        <SansText className="text-sm text-stone-400 text-center">
          Select apps to block during focus sessions
        </SansText>
      </View>

      {/* App Grid */}
      <ScrollView
        showsVerticalScrollIndicator={false}
        className="flex-1"
        contentContainerStyle={{ paddingBottom: spacing.md }}
      >
        <View className="flex-row flex-wrap justify-center gap-2">
          {SHIELDABLE_APPS.map((app) => {
            const isSelected = selectedApps.includes(app.id);
            return (
              <Pressable
                key={app.id}
                onPress={() => handleToggle(app.id)}
                className={`w-[47%] p-5 rounded-2xl border-2 items-center active:scale-95 ${
                  isSelected
                    ? 'bg-orange-500/15 border-orange-500'
                    : 'bg-stone-900 border-stone-700'
                }`}
              >
                <View
                  className={`w-12 h-12 rounded-full border-2 items-center justify-center mb-2 ${
                    isSelected
                      ? 'bg-orange-500/30 border-orange-500'
                      : 'bg-stone-900 border-stone-700'
                  }`}
                >
                  <Ionicons
                    name={isSelected ? 'checkmark' : 'phone-portrait-outline'}
                    size={24}
                    color={isSelected ? colors.primary : colors.textTertiary}
                  />
                </View>
                <SansText
                  className={`text-sm font-semibold ${
                    isSelected ? 'text-white' : 'text-stone-400'
                  }`}
                >
                  {app.name}
                </SansText>
              </Pressable>
            );
          })}
        </View>
      </ScrollView>

      {/* Footer - Fixed at bottom */}
      <View className="pt-4 pb-2">
        <SansText className="text-stone-500 text-center mb-4 text-[13px]">
          {selectedApps.length} app{selectedApps.length !== 1 ? 's' : ''} selected
        </SansText>
        <View className="flex-row gap-2">
          <View className="flex-1">
            <Button onPress={onBack} variant="outline" size="lg" fullWidth>
              Back
            </Button>
          </View>
          <View className="flex-[2]">
            <Button
              onPress={onNext}
              variant="primary"
              size="lg"
              fullWidth
              disabled={selectedApps.length === 0}
            >
              Continue
            </Button>
          </View>
        </View>
      </View>
    </View>
  );
};

// Step 3: Permissions
const PermissionsStep = ({ onNext, onBack }: { onNext: () => void; onBack: () => void }) => {
  const [granted, setGranted] = useState(false);

  const requestPermission = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    if (Platform.OS === 'ios') {
      await Linking.openSettings();
    } else {
      try {
        await Linking.sendIntent('android.settings.USAGE_ACCESS_SETTINGS');
      } catch {
        await Linking.openSettings();
      }
    }
    setGranted(true);
  };

  return (
    <View className="flex-1">
      {/* Main content - centered */}
      <View className="flex-1 justify-center">
        {/* Header */}
        <View className="items-center mb-8">
          <View className="w-20 h-20 rounded-full bg-blue-500/15 items-center justify-center mb-6">
            <Ionicons name="lock-closed" size={40} color="#3b82f6" />
          </View>
          <SerifText className="text-[28px] text-white mb-1">
            Enable Protection
          </SerifText>
          <SansText className="text-sm text-stone-400 text-center px-6">
            {Platform.OS === 'ios'
              ? 'Screen Time access lets Clarity block apps during focus'
              : 'Usage Access permission is needed to block distracting apps'}
          </SansText>
        </View>

        {/* Permission Card */}
        <Pressable
          onPress={requestPermission}
          className={`flex-row items-center p-6 rounded-2xl border-2 mb-4 active:scale-[0.98] ${
            granted
              ? 'bg-green-500/15 border-green-500'
              : 'bg-stone-900 border-stone-700'
          }`}
        >
          <View
            className={`w-14 h-14 rounded-full items-center justify-center mr-4 ${
              granted ? 'bg-green-500/20' : 'bg-orange-500/15'
            }`}
          >
            <Ionicons
              name={granted ? 'checkmark-circle' : 'time-outline'}
              size={28}
              color={granted ? colors.success : colors.primary}
            />
          </View>
          <View className="flex-1">
            <SansText
              className={`text-base font-semibold mb-0.5 ${
                granted ? 'text-green-400' : 'text-white'
              }`}
            >
              {Platform.OS === 'ios' ? 'Screen Time' : 'Usage Access'}
            </SansText>
            <SansText className="text-[13px] text-stone-400">
              {granted ? 'Permission granted' : 'Tap to enable'}
            </SansText>
          </View>
          <View
            className={`px-4 py-2 rounded-full ${
              granted ? 'bg-green-500/20' : 'bg-orange-500'
            }`}
          >
            <SansText
              className={`text-[13px] font-semibold ${
                granted ? 'text-green-400' : 'text-white'
              }`}
            >
              {granted ? 'Done' : 'Enable'}
            </SansText>
          </View>
        </Pressable>

        {/* Privacy note */}
        <View className="flex-row items-center p-4 rounded-xl bg-stone-900 border-2 border-stone-700">
          <Ionicons name="shield-checkmark-outline" size={20} color={colors.textTertiary} />
          <SansText className="flex-1 ml-3 text-[13px] text-stone-400 leading-[18px]">
            Your data stays on-device. We never collect usage information.
          </SansText>
        </View>
      </View>

      {/* Footer - Fixed at bottom */}
      <View className="pt-4 pb-2">
        <View className="flex-row gap-2">
          <View className="flex-1">
            <Button onPress={onBack} variant="outline" size="lg" fullWidth>
              Back
            </Button>
          </View>
          <View className="flex-[2]">
            <Button onPress={onNext} variant="primary" size="lg" fullWidth>
              {granted ? 'Continue' : 'Skip for now'}
            </Button>
          </View>
        </View>
      </View>
    </View>
  );
};

// Step 4: Ready
const ReadyStep = ({ onFinish, onBack }: { onFinish: () => void; onBack: () => void }) => {
  const scale = useSharedValue(1);
  const glow = useSharedValue(0.3);

  useEffect(() => {
    scale.value = withRepeat(
      withSequence(
        withSpring(1.08, { damping: 3 }),
        withSpring(1, { damping: 3 })
      ),
      -1,
      true
    );
    glow.value = withRepeat(
      withSequence(
        withTiming(0.6, { duration: 1200 }),
        withTiming(0.25, { duration: 1200 })
      ),
      -1,
      true
    );
  }, []);

  const iconStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  const glowStyle = useAnimatedStyle(() => ({
    opacity: glow.value,
  }));

  return (
    <View className="flex-1">
      {/* Main content - centered */}
      <View className="flex-1 justify-center items-center">
        {/* Animated Icon */}
        <View className="items-center mb-8">
          <View className="w-40 h-40 items-center justify-center">
            <Animated.View
              className="absolute w-[140px] h-[140px] rounded-full bg-orange-500"
              style={glowStyle}
            />
            <Animated.View style={iconStyle}>
              <View
                className="w-[100px] h-[100px] rounded-full bg-orange-500 items-center justify-center"
                style={shadows.glow(colors.primary)}
              >
                <Ionicons name="flame" size={48} color="#fff" />
              </View>
            </Animated.View>
          </View>

          <SerifText className="text-[32px] text-white mb-2">
            You're Ready
          </SerifText>
          <SansText className="text-base text-stone-400 text-center px-6">
            Start your first focus session and reclaim your attention.
          </SansText>
        </View>

        {/* How it works */}
        <View className="flex-row items-center justify-center gap-4">
          {[
            { icon: 'timer-outline' as const, label: 'Set Timer', color: colors.primary },
            { icon: 'shield' as const, label: 'Apps Block', color: colors.danger },
            { icon: 'checkmark-circle' as const, label: 'Complete', color: colors.success },
          ].map((step, i) => (
            <React.Fragment key={step.label}>
              {i > 0 && <View className="w-5 h-0.5 bg-stone-700" />}
              <View className="items-center">
                <View className="w-12 h-12 rounded-full bg-stone-900 border-2 border-stone-700 items-center justify-center mb-1">
                  <Ionicons name={step.icon} size={22} color={step.color} />
                </View>
                <SansText className="text-[11px] text-stone-400">{step.label}</SansText>
              </View>
            </React.Fragment>
          ))}
        </View>
      </View>

      {/* Footer - Fixed at bottom */}
      <View className="pt-4 pb-2">
        <View className="flex-row gap-2">
          <View className="flex-1">
            <Button onPress={onBack} variant="outline" size="lg" fullWidth>
              Back
            </Button>
          </View>
          <View className="flex-[2]">
            <Button onPress={onFinish} variant="primary" size="lg" fullWidth>
              Start Focusing
            </Button>
          </View>
        </View>
      </View>
    </View>
  );
};

// Progress indicator
const ProgressIndicator = ({ current, total }: { current: number; total: number }) => (
  <View style={{ flexDirection: 'row', justifyContent: 'center', gap: spacing.sm, paddingVertical: spacing.md }}>
    {Array.from({ length: total }).map((_, i) => (
      <View
        key={i}
        style={{
          width: i + 1 === current ? 24 : 8,
          height: 8,
          borderRadius: 4,
          backgroundColor: i + 1 <= current ? colors.primary : colors.border,
        }}
      />
    ))}
  </View>
);

export default function OnboardingScreen() {
  const router = useRouter();
  const { user, completeOnboarding, toggleShieldedApp } = useUserStore();

  const [step, setStep] = useState(1);
  const [selectedApps, setSelectedApps] = useState<string[]>(
    user?.shieldedApps || ['instagram', 'tiktok', 'twitter', 'youtube']
  );

  const next = useCallback(() => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setStep((s) => Math.min(s + 1, TOTAL_STEPS));
  }, []);

  const back = useCallback(() => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setStep((s) => Math.max(s - 1, 1));
  }, []);

  const toggleApp = useCallback((id: string) => {
    setSelectedApps((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  }, []);

  const finish = useCallback(() => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

    // Sync selected apps
    const current = user?.shieldedApps || [];
    selectedApps.filter((id) => !current.includes(id)).forEach((id) => toggleShieldedApp(id));
    current.filter((id) => !selectedApps.includes(id)).forEach((id) => toggleShieldedApp(id));

    completeOnboarding();
    router.replace('/(tabs)');
  }, [selectedApps, user, toggleShieldedApp, completeOnboarding, router]);

  return (
    <ScreenLayout scrollable={false} contentContainerClassName="px-6 pb-6">
      <ProgressIndicator current={step} total={TOTAL_STEPS} />

      {step === 1 && <WelcomeStep onNext={next} />}
      {step === 2 && (
        <AppSelectionStep
          selectedApps={selectedApps}
          onToggleApp={toggleApp}
          onNext={next}
          onBack={back}
        />
      )}
      {step === 3 && <PermissionsStep onNext={next} onBack={back} />}
      {step === 4 && <ReadyStep onFinish={finish} onBack={back} />}
    </ScreenLayout>
  );
}
