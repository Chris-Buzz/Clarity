import { ScreenLayout } from '@/components/ScreenLayout';
import { MonoText, SansText, SerifText } from '@/components/Typography';
import { THEMES, colors } from '@/constants';
import { useSessionStore, useUserStore } from '@/stores';
import React, { useState } from 'react';
import { Pressable, View } from 'react-native';
import Animated, {
  FadeIn,
  FadeInDown,
  FadeInRight,
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

export default function StatsScreen() {
  const { user, stats } = useUserStore();
  const { sessions, getSessionHistory } = useSessionStore();
  const [showAll, setShowAll] = useState(false);

  const themeColors = THEMES[user?.settings?.theme || 'vibrant'];
  const allSessions = getSessionHistory(100);
  const displayedSessions = showAll ? allSessions : allSessions.slice(0, 5);

  // Helper to format relative time (matching web)
  const getRelativeTime = (timestamp: number) => {
    const diff = Date.now() - timestamp;
    const hours = Math.floor(diff / (1000 * 60 * 60));
    if (hours < 1) return 'Just now';
    if (hours < 24) return `${hours}h ago`;
    return new Date(timestamp).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
  };

  const totalHours = Math.floor(stats.totalFocusTime / 60);
  const totalMins = stats.totalFocusTime % 60;

  const handleToggleHistory = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setShowAll(!showAll);
  };

  return (
    <ScreenLayout scrollable>
      {/* Header */}
      <Animated.View
        entering={FadeInDown.delay(100).duration(600).springify()}
        className="mb-20"
      >
        <SerifText className="text-4xl text-white/90 mb-4 italic">
          Continuity
        </SerifText>
        <SansText className="text-white/20 text-[11px] tracking-[4px] uppercase font-[Outfit-Light]">
          The art of showing up.
        </SansText>
      </Animated.View>

      {/* Main Stat - Accumulated Stillness */}
      <Animated.View
        entering={FadeInDown.delay(200).duration(600).springify()}
        className="mb-16"
      >
        <MonoText className="text-white/10 text-[10px] tracking-[5px] uppercase mb-8 ml-1 font-bold">
          Accumulated Stillness
        </MonoText>
        <View className="flex-row items-baseline mb-8">
          <SerifText className="text-[64px] text-white/90 -tracking-widest italic leading-[64px]">
            {totalHours}
          </SerifText>
          <SansText className="text-white/20 text-sm tracking-[2px] uppercase ml-2 font-[Outfit-Light]">
            hours
          </SansText>
          <SerifText className="text-[64px] text-white/90 -tracking-widest italic ml-8 leading-[64px]">
            {totalMins}
          </SerifText>
          <SansText className="text-white/20 text-sm tracking-[2px] uppercase ml-2 font-[Outfit-Light]">
            mins
          </SansText>
        </View>
        <View
          className="h-[1px] w-full"
          style={{ backgroundColor: `${themeColors.primary}33` }}
        />
      </Animated.View>

      {/* Secondary Stats */}
      <Animated.View
        entering={FadeInDown.delay(300).duration(600).springify()}
        className="flex-row mb-20 gap-8"
      >
        <View className="flex-1">
          <MonoText className="text-white/10 text-[9px] tracking-[5px] uppercase mb-4 font-bold">
            Current Streak
          </MonoText>
          <SerifText
            className="text-5xl italic"
            style={{ color: themeColors.primary }}
          >
            {stats.dailyStreak}
          </SerifText>
        </View>
        <View className="flex-1">
          <MonoText className="text-white/10 text-[9px] tracking-[5px] uppercase mb-4 font-bold">
            Completed
          </MonoText>
          <SerifText className="text-5xl text-white/80 italic">
            {stats.sessionsCompleted}
          </SerifText>
        </View>
      </Animated.View>

      {/* Recent Echoes */}
      <Animated.View
        entering={FadeInDown.delay(400).duration(600).springify()}
        className="mt-5 mb-10"
      >
        <View className="flex-row items-center justify-between mb-10">
          <MonoText className="text-white/20 text-[10px] tracking-[5px] uppercase font-bold">
            Recent Echoes
          </MonoText>
          <View className="w-4 h-[1px] bg-white/5" />
        </View>

        <View className="gap-6">
          {allSessions.length === 0 ? (
            <SansText className="text-white/20 text-sm italic text-center py-8 font-[Outfit-Light]">
              Your journal is yet to be written.
            </SansText>
          ) : (
            displayedSessions.map((session, index) => (
              <Animated.View
                key={session.id}
                entering={FadeInRight.delay(450 + index * 80).duration(400).springify()}
                className="flex-row items-center justify-between p-4 rounded-2xl bg-[rgba(255,255,255,0.03)] border border-[rgba(255,255,255,0.08)]"
              >
                <View className="flex-row items-center flex-1 gap-5">
                  {/* Rating Indicator */}
                  <View
                    className="w-1.5 h-1.5 rounded-full"
                    style={{
                      backgroundColor:
                        session.rating && session.rating >= 4
                          ? themeColors.primary
                          : 'rgba(255,255,255,0.2)',
                      shadowColor:
                        session.rating && session.rating >= 4
                          ? themeColors.primary
                          : 'transparent',
                      shadowOpacity: session.rating && session.rating >= 4 ? 0.4 : 0,
                      shadowRadius: 10,
                      elevation: session.rating && session.rating >= 4 ? 5 : 0,
                    }}
                  />
                  <View className="flex-1">
                    <SansText className="text-white/90 text-sm tracking-wide mb-1.5" numberOfLines={1}>
                      {session.task}
                    </SansText>
                    <View className="flex-row items-center gap-3">
                      <MonoText className="text-white/30 text-[9px] tracking-[2px] uppercase">
                        {getRelativeTime(session.startTime)}
                      </MonoText>
                      {session.note && (
                        <>
                          <View className="w-0.5 h-0.5 rounded-full bg-white/20" />
                          <SansText className="text-white/40 text-[9px] italic max-w-[120px]" numberOfLines={1}>
                            {session.note}
                          </SansText>
                        </>
                      )}
                    </View>
                  </View>
                </View>
                <SerifText className="text-lg text-white/40 italic ml-4">
                  {session.actualDuration}m
                </SerifText>
              </Animated.View>
            ))
          )}
        </View>

        {allSessions.length > 5 && (
          <AnimatedPressable
            onPress={handleToggleHistory}
            className="items-center pt-4 mt-2"
            hitSlop={{ top: 20, bottom: 20, left: 20, right: 20 }}
          >
            <SansText className="text-white/30 text-[9px] tracking-[2px] uppercase">
              {showAll ? 'Collapse History' : 'View Full History'}
            </SansText>
          </AnimatedPressable>
        )}
      </Animated.View>
    </ScreenLayout>
  );
}


