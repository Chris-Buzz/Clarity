import React from 'react';
import { Text as RNText, TextProps, StyleSheet } from 'react-native';

/**
 * Typography components matching the web app's font system:
 * - Playfair Display (serif) for headers
 * - Outfit (sans-serif) for body text
 * - SpaceMono for monospace/technical text
 */

interface TypographyProps extends TextProps {
  children: React.ReactNode;
}

// Serif headers (Playfair Display) - for titles and large headers
export function SerifText({ children, style, ...props }: TypographyProps) {
  return (
    <RNText style={[styles.serif, style]} {...props}>
      {children}
    </RNText>
  );
}

// Sans-serif body text (Outfit) - for regular text
export function SansText({ children, style, ...props }: TypographyProps) {
  return (
    <RNText style={[styles.sans, style]} {...props}>
      {children}
    </RNText>
  );
}

// Monospace text (SpaceMono) - for labels, tracking text
export function MonoText({ children, style, ...props }: TypographyProps) {
  return (
    <RNText style={[styles.mono, style]} {...props}>
      {children}
    </RNText>
  );
}

const styles = StyleSheet.create({
  serif: {
    fontFamily: 'PlayfairDisplay-Regular',
  },
  sans: {
    fontFamily: 'Outfit-Regular',
  },
  mono: {
    fontFamily: 'SpaceMono',
  },
});

// Export font names for use in inline styles
export const FONTS = {
  serif: {
    regular: 'PlayfairDisplay-Regular',
    italic: 'PlayfairDisplay-Italic',
    semiBoldItalic: 'PlayfairDisplay-SemiBoldItalic',
  },
  sans: {
    thin: 'Outfit-Thin',
    extraLight: 'Outfit-ExtraLight',
    light: 'Outfit-Light',
    regular: 'Outfit-Regular',
    medium: 'Outfit-Medium',
    semiBold: 'Outfit-SemiBold',
  },
  mono: 'SpaceMono',
};
