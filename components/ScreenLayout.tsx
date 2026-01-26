import { clsx, type ClassValue } from 'clsx';
import React from 'react';
import { ScrollView, StatusBar, View, ViewStyle } from 'react-native';
import { SafeAreaView, SafeAreaViewProps } from 'react-native-safe-area-context';
import { twMerge } from 'tailwind-merge';

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

interface ScreenLayoutProps extends React.PropsWithChildren {
  className?: string;
  edges?: SafeAreaViewProps['edges'];
  scrollable?: boolean;
  contentContainerClassName?: string;
  refreshControl?: React.ReactElement;
  style?: ViewStyle;
}

export function ScreenLayout({
  children,
  className,
  edges = ['top', 'left', 'right'],
  scrollable = false,
  contentContainerClassName,
  refreshControl,
  style,
}: ScreenLayoutProps) {
  // Default background color matches the rest of the app (obsidian/near-black)
  const baseClasses = "flex-1 bg-[#030303]";

  if (scrollable) {
    return (
      <SafeAreaView
        edges={edges}
        className={cn(baseClasses, className)}
        style={style}
      >
        <StatusBar barStyle="light-content" backgroundColor="#030303" />
        <ScrollView
          className="flex-1"
          contentContainerClassName={cn("px-6 py-4", contentContainerClassName)}
          showsVerticalScrollIndicator={false}
          refreshControl={refreshControl}
        >
          {children}
        </ScrollView>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView
      edges={edges}
      className={cn(baseClasses, className)}
      style={style}
    >
      <StatusBar barStyle="light-content" backgroundColor="#030303" />
      <View className={cn("flex-1 px-6 py-4", contentContainerClassName)}>
        {children}
      </View>
    </SafeAreaView>
  );
}
