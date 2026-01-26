import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  Pressable,
  TextInput,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import * as Haptics from 'expo-haptics';
import FontAwesome from '@expo/vector-icons/FontAwesome';
import Animated, {
  FadeIn,
  FadeInDown,
  FadeInUp,
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withSequence,
  withTiming,
  Easing,
  ZoomIn,
} from 'react-native-reanimated';
import { useSessionStore, useUserStore } from '@/stores';
import CandleVisual from '@/components/CandleVisual';
import { colors, THEMES } from '@/constants';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

export default function ReflectionScreen() {
  const router = useRouter();
  const { sessions, setRating, setNote } = useSessionStore();
  const { user, checkBadgeUnlocks } = useUserStore();

  const [rating, setLocalRating] = useState(0);
  const [note, setLocalNote] = useState('');
  const [showBadge, setShowBadge] = useState(false);
  const [isValid, setIsValid] = useState(false);

  // Get the most recent session
  const lastSession = sessions[0];

  // Validate session exists - redirect if not
  useEffect(() => {
    const timer = setTimeout(() => {
      if (!lastSession) {
        router.replace('/(tabs)');
      } else {
        setIsValid(true);
      }
    }, 100);
    return () => clearTimeout(timer);
  }, [lastSession, router]);

  const handleRating = (value: number) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setLocalRating(value);
  };

  const handleComplete = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);

    if (lastSession) {
      if (rating > 0) {
        setRating(lastSession.id, rating);
      }
      if (note.trim()) {
        setNote(lastSession.id, note.trim());
      }
    }

    // Check for new badges
    const newBadges = checkBadgeUnlocks();
    if (newBadges.length > 0) {
      setShowBadge(true);
      setTimeout(() => {
        router.replace('/(tabs)');
      }, 2000);
    } else {
      router.replace('/(tabs)');
    }
  };

  const theme = user?.settings?.theme || 'vibrant';
  const themeColors = THEMES[theme];

  // Show loading while validating
  if (!isValid || !lastSession) {
    return (
      <View style={{ flex: 1, backgroundColor: colors.background }} />
    );
  }

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: colors.background }}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={{ flex: 1 }}
      >
        <View style={{ flex: 1, justifyContent: 'space-between', paddingHorizontal: 24, paddingVertical: 32 }}>
          {/* Header */}
          <Animated.View
            entering={FadeInDown.delay(100).duration(600).springify()}
            style={{ alignItems: 'center', paddingTop: 16 }}
          >
            <Text style={{
              color: themeColors.primary,
              fontSize: 11,
              textTransform: 'uppercase',
              letterSpacing: 6,
              fontFamily: 'Outfit-Medium',
              marginBottom: 8,
            }}>
              Session Complete
            </Text>
            <Text style={{
              color: colors.textPrimary,
              fontSize: 36,
              fontFamily: 'PlayfairDisplay-Regular',
              textAlign: 'center',
            }}>
              Well Done
            </Text>
          </Animated.View>

          {/* Candle - burned down */}
          <Animated.View
            entering={FadeIn.delay(300).duration(800)}
            style={{ alignItems: 'center', paddingVertical: 16 }}
          >
            <CandleVisual
              progress={0.1}
              isActive={false}
              theme={theme}
            />
          </Animated.View>

          {/* Stats */}
          <Animated.View
            entering={FadeInUp.delay(400).duration(600).springify()}
            style={{
              backgroundColor: colors.surface,
              borderWidth: 1,
              borderColor: colors.border,
              borderRadius: 24,
              padding: 24,
              marginBottom: 24,
            }}
          >
            <Text style={{
              color: colors.textPrimary,
              fontSize: 20,
              textAlign: 'center',
              marginBottom: 16,
              fontFamily: 'PlayfairDisplay-Regular',
            }}>
              {lastSession.task}
            </Text>

            <View style={{ flexDirection: 'row', justifyContent: 'space-around' }}>
              <View style={{ alignItems: 'center' }}>
                <Text style={{
                  color: colors.textMuted,
                  fontSize: 11,
                  textTransform: 'uppercase',
                  letterSpacing: 2,
                }}>
                  Duration
                </Text>
                <Text style={{
                  color: themeColors.primary,
                  fontSize: 24,
                  fontWeight: '600',
                  marginTop: 4,
                }}>
                  {lastSession.actualDuration}m
                </Text>
              </View>

              <View style={{ alignItems: 'center' }}>
                <Text style={{
                  color: colors.textMuted,
                  fontSize: 11,
                  textTransform: 'uppercase',
                  letterSpacing: 2,
                }}>
                  XP Earned
                </Text>
                <Text style={{
                  color: themeColors.primary,
                  fontSize: 24,
                  fontWeight: '600',
                  marginTop: 4,
                }}>
                  +{lastSession.xpEarned}
                </Text>
              </View>

              <View style={{ alignItems: 'center' }}>
                <Text style={{
                  color: colors.textMuted,
                  fontSize: 11,
                  textTransform: 'uppercase',
                  letterSpacing: 2,
                }}>
                  Urges Resisted
                </Text>
                <Text style={{
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: '600',
                  marginTop: 4,
                }}>
                  {lastSession.urgesResisted}
                </Text>
              </View>
            </View>
          </Animated.View>

          {/* Rating - larger touch targets */}
          <Animated.View
            entering={FadeInUp.delay(500).duration(600).springify()}
            style={{ marginBottom: 24 }}
          >
            <Text style={{
              color: colors.textTertiary,
              fontSize: 11,
              marginBottom: 16,
              textTransform: 'uppercase',
              letterSpacing: 3,
              fontFamily: 'Outfit-Medium',
              textAlign: 'center',
            }}>
              How was your clarity?
            </Text>
            <View style={{ flexDirection: 'row', justifyContent: 'center' }}>
              {[1, 2, 3, 4, 5].map((value, index) => (
                <AnimatedPressable
                  key={value}
                  entering={ZoomIn.delay(550 + index * 50).duration(300).springify()}
                  onPress={() => handleRating(value)}
                  hitSlop={{ top: 8, bottom: 8, left: 4, right: 4 }}
                  style={{
                    marginHorizontal: 6,
                    padding: 12,
                    minWidth: 52,
                    minHeight: 52,
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <FontAwesome
                    name={value <= rating ? 'star' : 'star-o'}
                    size={36}
                    color={value <= rating ? themeColors.primary : colors.textMuted}
                  />
                </AnimatedPressable>
              ))}
            </View>
          </Animated.View>

          {/* Note */}
          <Animated.View
            entering={FadeInUp.delay(600).duration(600).springify()}
            style={{ marginBottom: 24 }}
          >
            <Text style={{
              color: colors.textTertiary,
              fontSize: 11,
              marginBottom: 8,
              textTransform: 'uppercase',
              letterSpacing: 2,
              fontFamily: 'Outfit-Medium',
            }}>
              Reflection (optional)
            </Text>
            <TextInput
              style={{
                backgroundColor: colors.surface,
                borderWidth: 1,
                borderColor: colors.border,
                borderRadius: 16,
                paddingHorizontal: 20,
                paddingVertical: 16,
                color: colors.textPrimary,
                fontSize: 15,
                minHeight: 80,
              }}
              placeholder="What did you accomplish?"
              placeholderTextColor={colors.textMuted}
              value={note}
              onChangeText={setLocalNote}
              multiline
              numberOfLines={3}
              textAlignVertical="top"
            />
          </Animated.View>

          {/* Complete Button */}
          <Animated.View entering={FadeInUp.delay(700).duration(600).springify()}>
            <AnimatedPressable
              onPress={handleComplete}
              style={{
                backgroundColor: themeColors.primary,
                paddingVertical: 20,
                minHeight: 64,
                borderRadius: 32,
                alignItems: 'center',
                justifyContent: 'center',
                shadowColor: themeColors.primary,
                shadowOffset: { width: 0, height: 4 },
                shadowOpacity: 0.3,
                shadowRadius: 12,
                elevation: 8,
              }}
            >
              <Text style={{
                color: '#030303',
                fontSize: 13,
                fontWeight: '600',
                textTransform: 'uppercase',
                letterSpacing: 3,
              }}>
                Seal This Session
              </Text>
            </AnimatedPressable>
          </Animated.View>
        </View>

        {/* Badge Popup */}
        {showBadge && (
          <Animated.View
            entering={FadeIn.duration(300)}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              backgroundColor: 'rgba(3,3,3,0.95)',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Animated.View
              entering={ZoomIn.delay(100).duration(400).springify()}
              style={{
                backgroundColor: `${themeColors.primary}20`,
                borderWidth: 1,
                borderColor: themeColors.primary,
                borderRadius: 24,
                padding: 32,
                alignItems: 'center',
                marginHorizontal: 24,
              }}
            >
              <Text style={{ fontSize: 64, marginBottom: 16 }}>🏆</Text>
              <Text style={{
                color: themeColors.primary,
                fontSize: 24,
                fontFamily: 'PlayfairDisplay-Regular',
                marginBottom: 8,
              }}>
                Achievement Unlocked!
              </Text>
              <Text style={{
                color: colors.textTertiary,
                textAlign: 'center',
                fontSize: 15,
              }}>
                Your dedication has been recognized.
              </Text>
            </Animated.View>
          </Animated.View>
        )}
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
