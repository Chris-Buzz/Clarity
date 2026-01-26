import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  Pressable,
  KeyboardAvoidingView,
  Platform,
  Keyboard,
  TouchableWithoutFeedback,
  StyleSheet,
  StatusBar,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import * as Haptics from 'expo-haptics';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  FadeInDown,
} from 'react-native-reanimated';
import { useUserStore } from '@/stores';

export default function AuthScreen() {
  const router = useRouter();
  const { initUser } = useUserStore();
  const [name, setName] = useState('');
  const [focusedField, setFocusedField] = useState<string | null>(null);

  const buttonScale = useSharedValue(1);

  const handleSubmit = () => {
    if (name.trim()) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      // Generate a simple local ID, no email needed for local-first app
      initUser(name.trim(), `${name.trim().toLowerCase().replace(/\s/g, '')}@local`);
      router.replace('/onboarding');
    }
  };

  const isValid = name.trim().length > 0;

  const buttonAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: buttonScale.value }],
  }));

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" />

      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <TouchableWithoutFeedback onPress={Keyboard.dismiss} accessible={false}>
          <View style={styles.content}>
            {/* Header */}
            <View style={styles.header}>
              <Text style={styles.logo}>Clarity</Text>
              <Text style={styles.tagline}>Break the scroll. Reclaim your time.</Text>
            </View>

            {/* Form */}
            <Animated.View
              entering={FadeInDown.delay(200).duration(500)}
              style={styles.form}
            >
              <Text style={styles.label}>What should we call you?</Text>
              <TextInput
                placeholder="Your name"
                placeholderTextColor="rgba(255,255,255,0.3)"
                value={name}
                onChangeText={setName}
                onFocus={() => setFocusedField('name')}
                onBlur={() => setFocusedField(null)}
                autoCapitalize="words"
                autoCorrect={false}
                style={[
                  styles.input,
                  focusedField === 'name' && styles.inputFocused,
                ]}
              />

              <Animated.View style={buttonAnimatedStyle}>
                <Pressable
                  onPress={handleSubmit}
                  disabled={!isValid}
                  onPressIn={() => {
                    if (isValid) buttonScale.value = withSpring(0.96);
                  }}
                  onPressOut={() => {
                    buttonScale.value = withSpring(1);
                  }}
                  style={[
                    styles.button,
                    isValid && styles.buttonValid,
                    !isValid && styles.buttonDisabled,
                  ]}
                >
                  <Text style={[styles.buttonText, isValid && styles.buttonTextValid]}>
                    Continue
                  </Text>
                </Pressable>
              </Animated.View>
            </Animated.View>

            {/* Footer */}
            <View style={styles.footer}>
              <Text style={styles.footerText}>Your data stays on your device</Text>
            </View>
          </View>
        </TouchableWithoutFeedback>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#030303',
  },
  keyboardView: {
    flex: 1,
  },
  content: {
    flex: 1,
    paddingHorizontal: 24,
    justifyContent: 'center',
  },

  // Header
  header: {
    alignItems: 'center',
    marginBottom: 48,
  },
  logo: {
    fontSize: 48,
    color: '#ffffff',
    fontFamily: 'PlayfairDisplay-Italic',
    marginBottom: 12,
  },
  tagline: {
    fontSize: 15,
    color: 'rgba(255,255,255,0.5)',
    fontFamily: 'Outfit-Regular',
    textAlign: 'center',
  },

  // Form
  form: {
    gap: 16,
  },
  label: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.6)',
    fontFamily: 'Outfit-Medium',
    marginBottom: 4,
  },
  input: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    paddingHorizontal: 20,
    paddingVertical: 18,
    fontSize: 17,
    color: '#ffffff',
    fontFamily: 'Outfit-Regular',
  },
  inputFocused: {
    borderColor: 'rgba(249,115,22,0.5)',
    backgroundColor: 'rgba(249,115,22,0.05)',
  },
  button: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 14,
    paddingVertical: 18,
    alignItems: 'center',
    marginTop: 8,
  },
  buttonValid: {
    backgroundColor: '#f97316',
  },
  buttonDisabled: {
    opacity: 0.5,
  },
  buttonText: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.4)',
    fontFamily: 'Outfit-SemiBold',
  },
  buttonTextValid: {
    color: '#ffffff',
  },

  // Footer
  footer: {
    position: 'absolute',
    bottom: 24,
    left: 0,
    right: 0,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.25)',
    fontFamily: 'Outfit-Regular',
  },
});
