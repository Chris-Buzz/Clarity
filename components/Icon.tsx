import { Ionicons } from '@expo/vector-icons';
import React from 'react';
import { View } from 'react-native';

// Icon names we use in the app
export type IconName =
  | 'flame'
  | 'shield'
  | 'time'
  | 'phone-portrait'
  | 'apps'
  | 'ban'
  | 'checkmark'
  | 'arrow-back'
  | 'arrow-forward'
  | 'close'
  | 'settings'
  | 'timer'
  | 'pause'
  | 'play'
  | 'calendar'
  | 'list'
  | 'trending-up'
  | 'lock-closed'
  | 'notifications'
  | 'sparkles'
  | 'leaf'
  | 'flash'
  | 'heart'
  | 'eye-off'
  | 'hourglass'
  | 'rocket'
  | 'sunny'
  | 'moon'
  | 'color-palette'
  | 'refresh';

// Map our icon names to Ionicons names
const iconMap: Record<IconName, keyof typeof Ionicons.glyphMap> = {
  'flame': 'flame',
  'shield': 'shield-checkmark',
  'time': 'time-outline',
  'phone-portrait': 'phone-portrait-outline',
  'apps': 'apps',
  'ban': 'ban',
  'checkmark': 'checkmark',
  'arrow-back': 'arrow-back',
  'arrow-forward': 'arrow-forward',
  'close': 'close',
  'settings': 'settings-outline',
  'timer': 'timer-outline',
  'pause': 'pause',
  'play': 'play',
  'calendar': 'calendar-outline',
  'list': 'list',
  'trending-up': 'trending-up',
  'lock-closed': 'lock-closed',
  'notifications': 'notifications-outline',
  'sparkles': 'sparkles',
  'leaf': 'leaf',
  'flash': 'flash',
  'heart': 'heart',
  'eye-off': 'eye-off-outline',
  'hourglass': 'hourglass-outline',
  'rocket': 'rocket',
  'sunny': 'sunny',
  'moon': 'moon',
  'color-palette': 'color-palette',
  'refresh': 'refresh',
};

interface IconProps {
  name: IconName;
  size?: number;
  color?: string;
  className?: string;
}

export function Icon({ name, size = 24, color = '#ffffff', className }: IconProps) {
  const ionName = iconMap[name];

  return (
    <View className={className}>
      <Ionicons name={ionName} size={size} color={color} />
    </View>
  );
}

// Circular icon with background
interface CircleIconProps extends IconProps {
  bgColor?: string;
  bgOpacity?: number;
}

export function CircleIcon({
  name,
  size = 24,
  color = '#ffffff',
  bgColor = '#f97316',
  bgOpacity = 0.15,
  className
}: CircleIconProps) {
  const containerSize = size * 2;

  return (
    <View
      className={className}
      style={{
        width: containerSize,
        height: containerSize,
        borderRadius: containerSize / 2,
        backgroundColor: bgColor,
        opacity: bgOpacity > 1 ? bgOpacity : undefined,
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <View style={{ backgroundColor: `${bgColor}${Math.round(bgOpacity * 255).toString(16).padStart(2, '0')}`, width: containerSize, height: containerSize, borderRadius: containerSize / 2, alignItems: 'center', justifyContent: 'center' }}>
        <Ionicons name={iconMap[name]} size={size} color={color} />
      </View>
    </View>
  );
}
