import { clsx, type ClassValue } from 'clsx';
import * as Haptics from 'expo-haptics';
import React from 'react';
import { ActivityIndicator, Pressable, View } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
  interpolate,
  Easing,
} from 'react-native-reanimated';
import { twMerge } from 'tailwind-merge';
import { SansText } from './Typography';

// Helper for Tailwind classes
function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
type ButtonSize = 'sm' | 'md' | 'lg';

interface ButtonProps {
  onPress?: () => void;
  children?: React.ReactNode;
  variant?: ButtonVariant;
  size?: ButtonSize;
  className?: string; // Container classes
  textClassName?: string; // Text classes
  disabled?: boolean;
  loading?: boolean;
  icon?: React.ReactNode;
  fullWidth?: boolean;
  hitSlop?: React.ComponentProps<typeof Pressable>['hitSlop'];
  style?: any;
  // Custom color override (for themed buttons)
  color?: string;
}

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

// Spring config for luxurious feel
const SPRING_CONFIG = {
  damping: 15,
  stiffness: 400,
  mass: 0.6,
};

export function Button({
  onPress,
  children,
  variant = 'primary',
  size = 'md',
  className,
  textClassName,
  disabled = false,
  loading = false,
  icon,
  fullWidth = false,
  hitSlop,
  style,
  color,
}: ButtonProps) {
  const scale = useSharedValue(1);
  const pressed = useSharedValue(0);

  const handlePressIn = () => {
    if (disabled || loading) return;
    scale.value = withSpring(0.96, SPRING_CONFIG);
    pressed.value = withTiming(1, { duration: 100, easing: Easing.out(Easing.quad) });
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  const handlePressOut = () => {
    if (disabled || loading) return;
    scale.value = withSpring(1, SPRING_CONFIG);
    pressed.value = withTiming(0, { duration: 200, easing: Easing.out(Easing.quad) });
  };

  const handlePress = () => {
    if (disabled || loading) return;
    if (onPress) onPress();
  };

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    opacity: interpolate(pressed.value, [0, 1], [1, 0.85]),
  }));

  // Base styles
  const baseStyles = "rounded-xl flex-row items-center justify-center";
  
  // Size styles
  const sizeStyles = {
    sm: "px-3 py-2",
    md: "px-5 py-3.5",
    lg: "px-6 py-4",
  };

  // Variant styles
  const variantStyles = {
    primary: "bg-orange-500 active:bg-orange-600",
    secondary: "bg-stone-800 active:bg-stone-700",
    outline: "border border-stone-700 bg-transparent active:bg-stone-800/50",
    ghost: "bg-transparent active:bg-stone-800/30",
    danger: "bg-red-500/10 border border-red-500/20 active:bg-red-500/20",
  };

  // Text variant styles
  const textVariantStyles = {
    primary: "text-white font-medium",
    secondary: "text-stone-300 font-medium",
    outline: "text-stone-300 font-medium",
    ghost: "text-stone-400 font-medium",
    danger: "text-red-400 font-medium",
  };

  // Text size styles
  const textSizeStyles = {
    sm: "text-sm",
    md: "text-base",
    lg: "text-lg",
  };

  // Custom color styles (overrides variant when color prop is provided)
  // Uses a bordered glow effect for better visibility on dark backgrounds
  const customColorStyle = color ? {
    backgroundColor: '#141414', // Surface color for contrast
    borderColor: color,
    borderWidth: 2,
    shadowColor: color,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.4,
    shadowRadius: 12,
    elevation: 8,
  } : undefined;

  return (
    <AnimatedPressable
      onPress={handlePress}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      disabled={disabled || loading}
      hitSlop={hitSlop}
      className={cn(
        baseStyles,
        sizeStyles[size],
        !color && variantStyles[variant],
        fullWidth ? 'w-full' : 'self-start',
        (disabled || loading) && 'opacity-60',
        className
      )}
      style={[animatedStyle, customColorStyle, style]}
    >
      {loading ? (
        <ActivityIndicator color={variant === 'outline' ? '#a8a29e' : '#ffffff'} size="small" />
      ) : (
        <>
          {icon && <View className={children ? "mr-2" : ""}>{icon}</View>}
          {children && (
            <SansText
              className={cn(
                textVariantStyles[variant],
                textSizeStyles[size],
                textClassName
              )}
            >
              {children}
            </SansText>
          )}
        </>
      )}
    </AnimatedPressable>
  );
}
