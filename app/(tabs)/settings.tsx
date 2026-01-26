import { ScreenLayout } from '@/components/ScreenLayout';
import { SansText, SerifText } from '@/components/Typography';
import { SHIELDABLE_APPS, colors, radius, spacing } from '@/constants';
import { useUserStore } from '@/stores';
import { ThemeType } from '@/types';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import React, { useState } from 'react';
import { Platform, Pressable, View } from 'react-native';
import Animated, { FadeIn, FadeInDown } from 'react-native-reanimated';
import { useScreenTime } from '../../hooks/useScreenTime';

// Section header component
const SectionHeader = ({ title, color = colors.textMuted }: { title: string; color?: string }) => (
  <SansText
    style={{
      fontSize: 11,
      color,
      letterSpacing: 3,
      textTransform: 'uppercase',
      marginBottom: spacing.md,
      marginLeft: spacing.xs,
      fontWeight: '600',
    }}
  >
    {title}
  </SansText>
);

// Toggle row component
const ToggleRow = ({
  title,
  description,
  isEnabled,
  onToggle,
  activeColor = colors.primary,
}: {
  title: string;
  description: string;
  isEnabled: boolean;
  onToggle: () => void;
  activeColor?: string;
}) => (
  <Pressable
    onPress={onToggle}
    className="flex-row items-center justify-between p-6 rounded-2xl border active:scale-[0.98]"
    style={{
      backgroundColor: isEnabled ? `${activeColor}10` : colors.surface,
      borderColor: isEnabled ? `${activeColor}40` : colors.border,
    }}
  >
    <View className="flex-1 mr-4">
      <SansText
        className={`text-base font-semibold mb-1 ${isEnabled ? 'text-white' : 'text-stone-400'}`}
      >
        {title}
      </SansText>
      <SansText className="text-[13px] text-stone-500 leading-[18px]">
        {description}
      </SansText>
    </View>
    <View
      className="w-[52px] h-[30px] rounded-full justify-center p-[3px]"
      style={{ backgroundColor: isEnabled ? activeColor : colors.borderAccent }}
    >
      <View
        className={`w-6 h-6 rounded-full bg-white ${isEnabled ? 'self-end shadow-sm' : 'self-start'}`}
      />
    </View>
  </Pressable>
);

// App checkbox component
const AppCheckbox = ({
  name,
  isSelected,
  onToggle,
}: {
  name: string;
  isSelected: boolean;
  onToggle: () => void;
}) => (
  <Pressable
    onPress={onToggle}
    className="flex-row items-center justify-between py-4 active:opacity-70"
  >
    <SansText
      className={`text-[15px] ${isSelected ? 'text-white font-medium' : 'text-stone-400'}`}
    >
      {name}
    </SansText>
    <View
      className={`w-11 h-11 rounded-full border-2 items-center justify-center ${
        isSelected ? 'bg-orange-500 border-orange-500' : 'bg-transparent border-stone-600'
      }`}
    >
      {isSelected && <Ionicons name="checkmark" size={24} color="#fff" />}
    </View>
  </Pressable>
);

// Theme button component
const ThemeButton = ({
  theme,
  isActive,
  onPress,
}: {
  theme: ThemeType;
  isActive: boolean;
  onPress: () => void;
}) => (
  <Pressable
    onPress={onPress}
    className={`flex-1 py-4 rounded-xl border-2 items-center active:scale-95 ${
      isActive ? 'bg-orange-500 border-orange-500' : 'bg-stone-900 border-stone-700'
    }`}
  >
    <SansText
      className={`text-sm font-semibold ${isActive ? 'text-white' : 'text-stone-400'}`}
    >
      {theme.charAt(0).toUpperCase() + theme.slice(1)}
    </SansText>
  </Pressable>
);

// Friction level paths
const FRICTION_PATHS = [
  {
    level: 1,
    name: 'Gentle',
    icon: 'leaf-outline' as const,
    description: 'Simple confirmation dialog',
    color: '#22c55e',
  },
  {
    level: 2,
    name: 'Moderate',
    icon: 'shield-half-outline' as const,
    description: 'Breathing exercise + confirm',
    color: '#f59e0b',
  },
  {
    level: 3,
    name: 'Warrior',
    icon: 'flame-outline' as const,
    description: 'Tasks, photos & challenges',
    color: '#ef4444',
  },
];

// Path selector component - vertical layout for readability
const PathButton = ({
  path,
  isActive,
  onPress,
}: {
  path: typeof FRICTION_PATHS[0];
  isActive: boolean;
  onPress: () => void;
}) => (
  <Pressable
    onPress={onPress}
    className="flex-row items-center p-4 rounded-2xl border-2 active:scale-[0.98]"
    style={{
      backgroundColor: isActive ? `${path.color}15` : colors.surface,
      borderColor: isActive ? path.color : colors.border,
      marginBottom: spacing.sm,
    }}
  >
    <View
      className="w-12 h-12 rounded-full items-center justify-center mr-4"
      style={{ backgroundColor: isActive ? `${path.color}25` : colors.borderAccent }}
    >
      <Ionicons name={path.icon} size={24} color={isActive ? path.color : colors.textMuted} />
    </View>
    <View className="flex-1">
      <SansText
        className={`text-base font-semibold mb-0.5 ${isActive ? 'text-white' : 'text-stone-400'}`}
      >
        {path.name}
      </SansText>
      <SansText className="text-[12px] text-stone-500">
        {path.description}
      </SansText>
    </View>
    {isActive && (
      <Ionicons name="checkmark-circle" size={24} color={path.color} />
    )}
  </Pressable>
);

export default function SettingsScreen() {
  const { user, updateSettings, toggleShieldedApp, setFrictionLevel, resetUser } = useUserStore();
  const [showResetConfirm, setShowResetConfirm] = useState(false);
  const {
    isAvailable: screenTimeAvailable,
    isAuthorized: screenTimeAuthorized,
    isLoading: screenTimeLoading,
    requestAuthorization: requestScreenTimeAuth,
  } = useScreenTime();

  const handleScreenTimeAuth = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    await requestScreenTimeAuth();
  };

  const handleThemeChange = (theme: ThemeType) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    updateSettings({ theme });
  };

  const handleToggleApp = (appId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    toggleShieldedApp(appId);
  };

  const handleToggleNudges = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    updateSettings({ nudgesEnabled: !user?.settings?.nudgesEnabled });
  };

  const handleToggleEternityMode = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    updateSettings({ eternityMode: !user?.settings?.eternityMode });
  };

  const handleFrictionLevelChange = (level: number) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setFrictionLevel(level);
  };

  const handleReset = () => {
    if (showResetConfirm) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
      resetUser();
    } else {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      setShowResetConfirm(true);
    }
  };

  if (!user) {
    return <View style={{ flex: 1, backgroundColor: colors.background }} />;
  }

  const isEternityMode = user.settings?.eternityMode;
  const isNudgesEnabled = user.settings?.nudgesEnabled;

  return (
    <ScreenLayout scrollable contentContainerClassName="px-6 pb-24">
      {/* Header */}
      <Animated.View entering={FadeIn.duration(400)}>
        <SerifText style={{ fontSize: 36, color: colors.textPrimary, marginBottom: spacing.xl }}>
          Settings
        </SerifText>
      </Animated.View>

      {/* Eternity Mode */}
      <Animated.View entering={FadeInDown.delay(100).duration(400)} style={{ marginBottom: spacing.xl }}>
        <SectionHeader title="The Cure" color={colors.danger} />
        <ToggleRow
          title="Eternity Mode"
          description="Strict mode that enforces focus even when you leave the app"
          isEnabled={isEternityMode || false}
          onToggle={handleToggleEternityMode}
          activeColor={colors.danger}
        />
      </Animated.View>

      {/* Friction Path Selection */}
      <Animated.View entering={FadeInDown.delay(125).duration(400)} style={{ marginBottom: spacing.xl }}>
        <SectionHeader title="Your Path" color={colors.primary} />
        <SansText style={{ fontSize: 13, color: colors.textTertiary, marginBottom: spacing.md, lineHeight: 18 }}>
          How hard should it be to quit a focus session early?
        </SansText>
        <View>
          {FRICTION_PATHS.map((path) => (
            <PathButton
              key={path.level}
              path={path}
              isActive={user.frictionLevel === path.level}
              onPress={() => handleFrictionLevelChange(path.level)}
            />
          ))}
        </View>
      </Animated.View>

      {/* Nudges */}
      <Animated.View entering={FadeInDown.delay(150).duration(400)} style={{ marginBottom: spacing.xl }}>
        <SectionHeader title="Notifications" />
        <ToggleRow
          title="Focus Reminders"
          description="Get gentle reminders to start focus sessions"
          isEnabled={isNudgesEnabled || false}
          onToggle={handleToggleNudges}
        />
      </Animated.View>

      {/* App Shielding */}
      <Animated.View entering={FadeInDown.delay(200).duration(400)} style={{ marginBottom: spacing.xl }}>
        <SectionHeader title="Blocked Apps" />
        <View
          style={{
            backgroundColor: colors.surface,
            borderRadius: radius.xl,
            borderWidth: 1,
            borderColor: colors.border,
            padding: spacing.lg,
          }}
        >
          {SHIELDABLE_APPS.map((app, index) => (
            <React.Fragment key={app.id}>
              {index > 0 && (
                <View style={{ height: 1, backgroundColor: colors.border, marginVertical: spacing.xs }} />
              )}
              <AppCheckbox
                name={app.name}
                isSelected={user.shieldedApps.includes(app.id)}
                onToggle={() => handleToggleApp(app.id)}
              />
            </React.Fragment>
          ))}
          <View style={{ marginTop: spacing.md, paddingTop: spacing.md, borderTopWidth: 1, borderTopColor: colors.border }}>
            <SansText style={{ fontSize: 12, color: colors.textMuted, textAlign: 'center' }}>
              Selected apps will be blocked during focus sessions
            </SansText>
          </View>
        </View>
      </Animated.View>

      {/* Screen Time (iOS only) */}
      {Platform.OS === 'ios' && screenTimeAvailable && (
        <Animated.View entering={FadeInDown.delay(250).duration(400)} style={{ marginBottom: spacing.xl }}>
          <SectionHeader title="System Integration" />
          <Pressable
            onPress={handleScreenTimeAuth}
            disabled={screenTimeLoading || screenTimeAuthorized}
            className={`flex-row items-center p-6 rounded-2xl border ${
              screenTimeAuthorized
                ? 'bg-green-500/10 border-green-500/40'
                : 'bg-stone-900 border-stone-800'
            } ${!screenTimeAuthorized ? 'active:opacity-80' : ''}`}
          >
            <View
              className={`w-12 h-12 rounded-full items-center justify-center mr-4 ${
                screenTimeAuthorized ? 'bg-green-500/20' : 'bg-orange-500/15'
              }`}
            >
              <Ionicons
                name={screenTimeAuthorized ? 'checkmark-circle' : 'time-outline'}
                size={24}
                color={screenTimeAuthorized ? colors.success : colors.primary}
              />
            </View>
            <View className="flex-1">
              <SansText
                className={`text-base font-semibold mb-0.5 ${
                  screenTimeAuthorized ? 'text-green-400' : 'text-white'
                }`}
              >
                {screenTimeAuthorized ? 'Screen Time Connected' : 'Connect Screen Time'}
              </SansText>
              <SansText className="text-[13px] text-stone-500">
                {screenTimeAuthorized
                  ? 'Apps will be blocked at system level'
                  : 'Enable for true app blocking'}
              </SansText>
            </View>
            {!screenTimeAuthorized && (
              <Ionicons name="chevron-forward" size={20} color={colors.textMuted} />
            )}
          </Pressable>
        </Animated.View>
      )}

      {/* Theme */}
      <Animated.View entering={FadeInDown.delay(300).duration(400)} style={{ marginBottom: spacing.xl }}>
        <SectionHeader title="Appearance" />
        <View style={{ flexDirection: 'row', gap: spacing.sm }}>
          {(['vibrant', 'eerie'] as ThemeType[]).map((theme) => (
            <ThemeButton
              key={theme}
              theme={theme}
              isActive={user.settings.theme === theme}
              onPress={() => handleThemeChange(theme)}
            />
          ))}
        </View>
      </Animated.View>

      {/* Reset */}
      <Animated.View entering={FadeInDown.delay(350).duration(400)} style={{ paddingTop: spacing.lg }}>
        <View className="border-t border-stone-800 pt-8 items-center">
          <Pressable
            onPress={handleReset}
            className={`py-4 px-8 rounded-xl border active:opacity-70 ${
              showResetConfirm
                ? 'bg-red-500/10 border-red-500'
                : 'bg-transparent border-stone-800'
            }`}
          >
            <SansText
              className={`text-sm font-medium ${
                showResetConfirm ? 'text-red-400' : 'text-stone-500'
              }`}
            >
              {showResetConfirm ? 'Tap again to confirm reset' : 'Reset All Data'}
            </SansText>
          </Pressable>

          {showResetConfirm && (
            <Pressable
              onPress={() => setShowResetConfirm(false)}
              className="mt-4 p-2"
            >
              <SansText className="text-[13px] text-stone-600">Cancel</SansText>
            </Pressable>
          )}
        </View>
      </Animated.View>
    </ScreenLayout>
  );
}
