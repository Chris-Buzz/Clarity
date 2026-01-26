import React, { useEffect } from 'react';
import { View } from 'react-native';
import Svg, {
  Defs,
  LinearGradient,
  RadialGradient,
  Stop,
  Path,
  Rect,
  Ellipse,
  G,
  Circle,
} from 'react-native-svg';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  withSequence,
  Easing,
  interpolate,
} from 'react-native-reanimated';
import { THEMES } from '@/constants';
import { ThemeType } from '@/types';

interface CandleVisualProps {
  progress: number; // 0 to 1, where 1 is full candle
  isActive: boolean;
  theme?: ThemeType;
}

const AnimatedView = Animated.createAnimatedComponent(View);

export default function CandleVisual({
  progress,
  isActive,
  theme = 'vibrant',
}: CandleVisualProps) {
  const colors = THEMES[theme];

  // Base dimensions
  const baseHeight = 140;
  const currentHeight = Math.max(25, baseHeight * progress);
  const yOffset = baseHeight - currentHeight;

  // Animation values
  const glowOpacity = useSharedValue(0);
  const glowScale = useSharedValue(1);
  const outerGlowPulse = useSharedValue(0.3);
  const ambientPulse = useSharedValue(0);

  useEffect(() => {
    if (isActive) {
      // Main glow pulse - breathing effect
      glowOpacity.value = withRepeat(
        withSequence(
          withTiming(0.6, { duration: 2500, easing: Easing.inOut(Easing.sin) }),
          withTiming(0.35, { duration: 2500, easing: Easing.inOut(Easing.sin) })
        ),
        -1,
        true
      );

      glowScale.value = withRepeat(
        withSequence(
          withTiming(1.08, { duration: 2500, easing: Easing.inOut(Easing.sin) }),
          withTiming(0.95, { duration: 2500, easing: Easing.inOut(Easing.sin) })
        ),
        -1,
        true
      );

      // Outer glow pulse
      outerGlowPulse.value = withRepeat(
        withSequence(
          withTiming(0.5, { duration: 1800, easing: Easing.inOut(Easing.sin) }),
          withTiming(0.25, { duration: 1800, easing: Easing.inOut(Easing.sin) })
        ),
        -1,
        true
      );

      // Ambient background pulse
      ambientPulse.value = withRepeat(
        withSequence(
          withTiming(1, { duration: 4000, easing: Easing.inOut(Easing.sin) }),
          withTiming(0, { duration: 4000, easing: Easing.inOut(Easing.sin) })
        ),
        -1,
        true
      );
    } else {
      // Fade out gracefully
      glowOpacity.value = withTiming(0, { duration: 800, easing: Easing.out(Easing.quad) });
      glowScale.value = withTiming(1, { duration: 600 });
      outerGlowPulse.value = withTiming(0, { duration: 600 });
      ambientPulse.value = withTiming(0, { duration: 800 });
    }
  }, [isActive]);

  // Animated styles
  const glowStyle = useAnimatedStyle(() => ({
    opacity: glowOpacity.value,
    transform: [{ scale: glowScale.value }],
  }));

  const outerGlowStyle = useAnimatedStyle(() => ({
    opacity: outerGlowPulse.value,
    transform: [{ scale: interpolate(outerGlowPulse.value, [0.25, 0.5], [0.9, 1.1]) }],
  }));

  const ambientStyle = useAnimatedStyle(() => ({
    opacity: interpolate(ambientPulse.value, [0, 1], [0.05, 0.15]),
  }));

  return (
    <View className="relative items-center justify-center w-full h-80">
      {/* Ambient background glow - largest, softest */}
      {isActive && (
        <AnimatedView
          style={ambientStyle}
          className="absolute w-80 h-80 rounded-full"
        >
          <View
            className="w-full h-full rounded-full"
            style={{ backgroundColor: colors.primary }}
          />
        </AnimatedView>
      )}

      {/* Outer glow ring */}
      {isActive && (
        <AnimatedView
          style={outerGlowStyle}
          className="absolute w-56 h-56 rounded-full"
        >
          <View
            className="w-full h-full rounded-full"
            style={{
              backgroundColor: 'transparent',
              borderWidth: 1,
              borderColor: `${colors.primary}30`,
            }}
          />
        </AnimatedView>
      )}

      {/* Main glow */}
      {isActive && (
        <AnimatedView
          style={glowStyle}
          className="absolute w-44 h-44 rounded-full"
        >
          <View
            className="w-full h-full rounded-full"
            style={{
              backgroundColor: colors.primary,
              shadowColor: colors.primary,
              shadowOffset: { width: 0, height: 0 },
              shadowOpacity: 0.8,
              shadowRadius: 60,
              elevation: 25,
            }}
          />
        </AnimatedView>
      )}

      {/* Candle SVG */}
      <View style={{ zIndex: 10 }}>
        <Svg width={120} height={260} viewBox="0 0 120 260">
          <Defs>
            {/* Premium wax gradient - cream to ivory */}
            <LinearGradient id="waxGrad" x1="0%" y1="0%" x2="100%" y2="0%">
              <Stop offset="0%" stopColor="#E8DFD0" />
              <Stop offset="15%" stopColor="#F5EDE0" />
              <Stop offset="50%" stopColor="#FFFEF8" />
              <Stop offset="85%" stopColor="#F5EDE0" />
              <Stop offset="100%" stopColor="#E8DFD0" />
            </LinearGradient>

            {/* Outer flame - orange/red */}
            <RadialGradient id="flameOuter" cx="50%" cy="70%" r="50%">
              <Stop offset="0%" stopColor={colors.primary} />
              <Stop offset="60%" stopColor={colors.primary} stopOpacity={0.6} />
              <Stop offset="100%" stopColor="transparent" />
            </RadialGradient>

            {/* Middle flame - yellow */}
            <RadialGradient id="flameMid" cx="50%" cy="65%" r="45%">
              <Stop offset="0%" stopColor="#FFF4B8" />
              <Stop offset="50%" stopColor="#FFE066" />
              <Stop offset="100%" stopColor={colors.primary} stopOpacity={0.8} />
            </RadialGradient>

            {/* Inner flame - white hot */}
            <RadialGradient id="flameInner" cx="50%" cy="60%" r="30%">
              <Stop offset="0%" stopColor="#FFFFFF" />
              <Stop offset="40%" stopColor="#FFFEF0" />
              <Stop offset="100%" stopColor="#FFE066" stopOpacity={0.9} />
            </RadialGradient>

            {/* Flame glow */}
            <RadialGradient id="flameGlow" cx="50%" cy="80%" r="80%">
              <Stop offset="0%" stopColor={colors.primary} stopOpacity={0.4} />
              <Stop offset="100%" stopColor="transparent" />
            </RadialGradient>

            {/* Wax pool gradient */}
            <RadialGradient id="waxPool" cx="50%" cy="50%" r="50%">
              <Stop offset="0%" stopColor="#FFE4B5" stopOpacity={0.6} />
              <Stop offset="70%" stopColor="#DDD5C5" stopOpacity={0.3} />
              <Stop offset="100%" stopColor="transparent" />
            </RadialGradient>

            {/* Candle edge highlight */}
            <LinearGradient id="edgeHighlight" x1="0%" y1="0%" x2="100%" y2="0%">
              <Stop offset="0%" stopColor="rgba(0,0,0,0.08)" />
              <Stop offset="10%" stopColor="transparent" />
              <Stop offset="90%" stopColor="transparent" />
              <Stop offset="100%" stopColor="rgba(0,0,0,0.08)" />
            </LinearGradient>
          </Defs>

          {/* Flame group */}
          {isActive && (
            <G transform={`translate(0, ${yOffset})`}>
              {/* Flame glow background */}
              <Ellipse cx={60} cy={85} rx={25} ry={35} fill="url(#flameGlow)" />

              {/* Outer flame */}
              <Path
                d="M60 35 C60 35 48 55 46 72 C44 85 50 95 60 95 C70 95 76 85 74 72 C72 55 60 35 60 35Z"
                fill="url(#flameOuter)"
              />

              {/* Middle flame */}
              <Path
                d="M60 42 C60 42 52 58 51 70 C50 80 54 88 60 88 C66 88 70 80 69 70 C68 58 60 42 60 42Z"
                fill="url(#flameMid)"
              />

              {/* Inner flame - hottest */}
              <Path
                d="M60 50 C60 50 55 62 55 70 C55 77 57 82 60 82 C63 82 65 77 65 70 C65 62 60 50 60 50Z"
                fill="url(#flameInner)"
              />

              {/* Flame core - white */}
              <Path
                d="M60 58 C60 58 57 66 57 71 C57 75 58 77 60 77 C62 77 63 75 63 71 C63 66 60 58 60 58Z"
                fill="#FFFFFF"
                opacity={0.9}
              />
            </G>
          )}

          {/* Wick */}
          <Rect x={58.5} y={93 + yOffset} width={3} height={14} rx={1.5} fill="#2D2520" />

          {/* Wick glow when active */}
          {isActive && (
            <Circle cx={60} cy={94 + yOffset} r={4} fill={colors.primary} opacity={0.5} />
          )}

          {/* Candle body - main shape */}
          <Path
            d={`M38,${105 + yOffset} Q60,${100 + yOffset} 82,${105 + yOffset} L84,${105 + currentHeight + yOffset} Q60,${110 + currentHeight + yOffset} 36,${105 + currentHeight + yOffset} Z`}
            fill="url(#waxGrad)"
          />

          {/* Candle edge overlay for depth */}
          <Path
            d={`M38,${105 + yOffset} Q60,${100 + yOffset} 82,${105 + yOffset} L84,${105 + currentHeight + yOffset} Q60,${110 + currentHeight + yOffset} 36,${105 + currentHeight + yOffset} Z`}
            fill="url(#edgeHighlight)"
          />

          {/* Wax pool at top - melted wax effect */}
          <Ellipse cx={60} cy={104 + yOffset} rx={20} ry={3} fill="url(#waxPool)" />

          {/* Subtle rim highlight */}
          <Ellipse
            cx={60}
            cy={103 + yOffset}
            rx={21}
            ry={2}
            fill="none"
            stroke="rgba(255,255,255,0.3)"
            strokeWidth={0.5}
          />
        </Svg>
      </View>

      {/* Ground shadow - soft, elongated */}
      <View
        className="absolute bottom-4"
        style={{
          width: 100,
          height: 20,
          borderRadius: 50,
          backgroundColor: 'rgba(0,0,0,0.4)',
          shadowColor: '#000',
          shadowOffset: { width: 0, height: 0 },
          shadowOpacity: 0.5,
          shadowRadius: 15,
          transform: [{ scaleY: 0.3 }],
        }}
      />

      {/* Reflected light on surface */}
      {isActive && (
        <AnimatedView
          style={[
            {
              position: 'absolute',
              bottom: 8,
              width: 60,
              height: 10,
              borderRadius: 30,
            },
            glowStyle,
          ]}
        >
          <View
            style={{
              width: '100%',
              height: '100%',
              borderRadius: 30,
              backgroundColor: colors.primary,
              opacity: 0.3,
            }}
          />
        </AnimatedView>
      )}
    </View>
  );
}
