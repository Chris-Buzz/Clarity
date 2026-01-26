import React, { useEffect, useRef } from 'react';
import { View, Text, Pressable, LayoutChangeEvent } from 'react-native';
import { Tabs } from 'expo-router';
import * as Haptics from 'expo-haptics';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  interpolateColor,
  Easing,
} from 'react-native-reanimated';
import { THEMES } from '@/constants';
import { useUserStore } from '@/stores';

const AnimatedView = Animated.createAnimatedComponent(View);
const AnimatedText = Animated.createAnimatedComponent(Text);

// Individual tab item with smooth animations
function TabItem({
  label,
  isFocused,
  onPress,
  onLayout,
  color,
}: {
  label: string;
  isFocused: boolean;
  onPress: () => void;
  onLayout: (event: LayoutChangeEvent) => void;
  color: string;
}) {
  const scale = useSharedValue(1);
  const textColorProgress = useSharedValue(isFocused ? 1 : 0);

  useEffect(() => {
    textColorProgress.value = withTiming(isFocused ? 1 : 0, {
      duration: 250,
      easing: Easing.out(Easing.quad),
    });
  }, [isFocused]);

  const handlePressIn = () => {
    scale.value = withSpring(0.92, { damping: 15, stiffness: 400 });
  };

  const handlePressOut = () => {
    scale.value = withSpring(1, { damping: 15, stiffness: 400 });
  };

  const animatedContainerStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  const animatedTextStyle = useAnimatedStyle(() => ({
    color: interpolateColor(
      textColorProgress.value,
      [0, 1],
      ['rgba(255,255,255,0.35)', '#ffffff']
    ),
  }));

  return (
    <Pressable
      onPress={onPress}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      onLayout={onLayout}
      hitSlop={{ top: 16, bottom: 16, left: 16, right: 16 }}
    >
      <AnimatedView
        style={[
          {
            alignItems: 'center',
            paddingVertical: 16,
            paddingHorizontal: 24,
            minWidth: 80,
            minHeight: 52,
            justifyContent: 'center',
          },
          animatedContainerStyle,
        ]}
      >
        <AnimatedText
          style={[
            {
              fontSize: 11,
              textTransform: 'uppercase',
              letterSpacing: 3,
              fontFamily: 'Outfit-SemiBold',
            },
            animatedTextStyle,
          ]}
        >
          {label}
        </AnimatedText>
      </AnimatedView>
    </Pressable>
  );
}

// Custom tab bar with luxurious animations
function CustomTabBar({ state, descriptors, navigation }: any) {
  const { user } = useUserStore();
  const theme = user?.settings?.theme || 'vibrant';
  const themeColors = THEMES[theme];

  // Track tab positions for sliding indicator
  const tabPositions = useRef<{ x: number; width: number }[]>([]);
  const indicatorX = useSharedValue(0);
  const indicatorWidth = useSharedValue(24);
  const indicatorOpacity = useSharedValue(0);

  // Get visible tabs (excluding hidden ones)
  const visibleRoutes = state.routes.filter((route: any) => route.name !== 'tasks');

  // Find actual index in visible routes
  const getVisibleIndex = (routeName: string) => {
    return visibleRoutes.findIndex((r: any) => r.name === routeName);
  };

  const currentVisibleIndex = getVisibleIndex(state.routes[state.index]?.name);

  useEffect(() => {
    if (tabPositions.current[currentVisibleIndex]) {
      const { x, width } = tabPositions.current[currentVisibleIndex];
      const indicatorSize = 24;
      const centerX = x + (width - indicatorSize) / 2;

      indicatorX.value = withSpring(centerX, {
        damping: 20,
        stiffness: 300,
        mass: 0.8,
      });
      indicatorWidth.value = withSpring(indicatorSize, {
        damping: 20,
        stiffness: 300,
      });
      indicatorOpacity.value = withTiming(1, { duration: 300 });
    }
  }, [currentVisibleIndex]);

  const indicatorStyle = useAnimatedStyle(() => ({
    position: 'absolute',
    bottom: 0,
    left: indicatorX.value,
    width: indicatorWidth.value,
    height: 3,
    borderRadius: 1.5,
    backgroundColor: themeColors.primary,
    opacity: indicatorOpacity.value,
    shadowColor: themeColors.primary,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.6,
    shadowRadius: 6,
    elevation: 4,
  }));

  const handleTabLayout = (index: number, event: LayoutChangeEvent) => {
    const { x, width } = event.nativeEvent.layout;
    tabPositions.current[index] = { x, width };

    // Initialize indicator position on first layout
    if (index === currentVisibleIndex && indicatorOpacity.value === 0) {
      const indicatorSize = 24;
      const centerX = x + (width - indicatorSize) / 2;
      indicatorX.value = centerX;
      indicatorOpacity.value = withTiming(1, { duration: 400 });
    }
  };

  let visibleIndex = 0;

  return (
    <View
      style={{
        backgroundColor: '#000',
        paddingHorizontal: 16,
        paddingBottom: 32,
        paddingTop: 8,
      }}
    >
      <View
        style={{
          flexDirection: 'row',
          justifyContent: 'space-around',
          alignItems: 'center',
          position: 'relative',
        }}
      >
        {state.routes.map((route: any, index: number) => {
          const { options } = descriptors[route.key];
          const label = options.title || route.name;
          const isFocused = state.index === index;

          // Skip hidden tabs
          if (route.name === 'tasks') return null;

          const currentIndex = visibleIndex;
          visibleIndex++;

          const onPress = () => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            const event = navigation.emit({
              type: 'tabPress',
              target: route.key,
              canPreventDefault: true,
            });

            if (!isFocused && !event.defaultPrevented) {
              navigation.navigate(route.name);
            }
          };

          return (
            <TabItem
              key={route.key}
              label={label}
              isFocused={isFocused}
              onPress={onPress}
              onLayout={(e) => handleTabLayout(currentIndex, e)}
              color={themeColors.primary}
            />
          );
        })}

        {/* Animated sliding indicator */}
        <AnimatedView style={indicatorStyle} />
      </View>
    </View>
  );
}

export default function TabLayout() {
  return (
    <Tabs
      tabBar={(props) => <CustomTabBar {...props} />}
      screenOptions={{
        headerShown: false,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Ritual',
        }}
      />
      <Tabs.Screen
        name="tasks"
        options={{
          title: 'Tasks',
          href: null, // Hide from tab bar but keep accessible
        }}
      />
      <Tabs.Screen
        name="stats"
        options={{
          title: 'Echoes',
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Curate',
        }}
      />
    </Tabs>
  );
}
