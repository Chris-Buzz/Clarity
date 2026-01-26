import React, { useEffect, useState } from 'react';
import { View, TextInput, Pressable, Image } from 'react-native';
import Animated, {
  FadeIn,
  FadeInDown,
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  ZoomIn,
} from 'react-native-reanimated';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { SansText, SerifText } from './Typography';
import { Button } from './Button';
import { colors, radius, spacing } from '@/constants';

interface FrictionChallengeProps {
  level: number;
  onComplete: () => void;
  onCancel: () => void;
  themeColor: string;
}

// Generate a random math problem
const generateMathProblem = () => {
  const operators = ['+', '-', '*'] as const;
  const operator = operators[Math.floor(Math.random() * 3)];
  let a: number, b: number, answer: number;

  switch (operator) {
    case '+':
      a = Math.floor(Math.random() * 50) + 10;
      b = Math.floor(Math.random() * 50) + 10;
      answer = a + b;
      break;
    case '-':
      a = Math.floor(Math.random() * 50) + 30;
      b = Math.floor(Math.random() * 30) + 1;
      answer = a - b;
      break;
    case '*':
      a = Math.floor(Math.random() * 12) + 2;
      b = Math.floor(Math.random() * 12) + 2;
      answer = a * b;
      break;
  }

  return { a, b, operator, answer };
};

// Phrases for typing challenge
const TYPING_PHRASES = [
  'I choose focus over distraction',
  'My attention is valuable',
  'I am in control of my time',
  'Deep work leads to deep results',
  'Stay present, stay focused',
];

// Breathing animation component
const BreathingCircle = ({ color, onComplete }: { color: string; onComplete: () => void }) => {
  const scale = useSharedValue(0.6);
  const [phase, setPhase] = useState<'inhale' | 'hold' | 'exhale'>('inhale');
  const [countdown, setCountdown] = useState(4);
  const [cycles, setCycles] = useState(0);

  useEffect(() => {
    const totalTime = 12000; // 4s inhale + 4s hold + 4s exhale
    let elapsed = 0;

    const interval = setInterval(() => {
      elapsed += 1000;
      const cycleTime = elapsed % totalTime;

      if (cycleTime < 4000) {
        setPhase('inhale');
        setCountdown(4 - Math.floor(cycleTime / 1000));
        scale.value = withTiming(0.6 + (cycleTime / 4000) * 0.4, { duration: 100 });
      } else if (cycleTime < 8000) {
        setPhase('hold');
        setCountdown(4 - Math.floor((cycleTime - 4000) / 1000));
      } else {
        setPhase('exhale');
        setCountdown(4 - Math.floor((cycleTime - 8000) / 1000));
        scale.value = withTiming(1 - ((cycleTime - 8000) / 4000) * 0.4, { duration: 100 });
      }

      if (cycleTime === 0 && elapsed > 0) {
        setCycles((c) => c + 1);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    if (cycles >= 2) {
      onComplete();
    }
  }, [cycles, onComplete]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  return (
    <View style={{ alignItems: 'center', paddingVertical: spacing.xl }}>
      <Animated.View
        style={[
          {
            width: 160,
            height: 160,
            borderRadius: 80,
            backgroundColor: `${color}20`,
            alignItems: 'center',
            justifyContent: 'center',
            borderWidth: 3,
            borderColor: color,
          },
          animatedStyle,
        ]}
      >
        <SansText style={{ fontSize: 48, color: color, fontWeight: '200' }}>
          {countdown}
        </SansText>
      </Animated.View>
      <SansText
        style={{
          marginTop: spacing.lg,
          fontSize: 16,
          color: colors.textSecondary,
          textTransform: 'uppercase',
          letterSpacing: 4,
        }}
      >
        {phase === 'inhale' ? 'Breathe In' : phase === 'hold' ? 'Hold' : 'Breathe Out'}
      </SansText>
      <SansText style={{ marginTop: spacing.sm, fontSize: 12, color: colors.textMuted }}>
        {2 - cycles} cycle{2 - cycles !== 1 ? 's' : ''} remaining
      </SansText>
    </View>
  );
};

// Level 1: Simple confirmation
const ConfirmChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => (
  <View style={{ alignItems: 'center', paddingVertical: spacing.xl }}>
    <View
      style={{
        width: 80,
        height: 80,
        borderRadius: 40,
        backgroundColor: colors.dangerMuted,
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: spacing.lg,
      }}
    >
      <Ionicons name="warning-outline" size={40} color={colors.danger} />
    </View>
    <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.sm }}>
      Are you sure?
    </SerifText>
    <SansText
      style={{
        fontSize: 14,
        color: colors.textTertiary,
        textAlign: 'center',
        lineHeight: 20,
        marginBottom: spacing.xl,
        paddingHorizontal: spacing.lg,
      }}
    >
      Ending your session early will reduce your focus score and break your momentum.
    </SansText>
    <View style={{ width: '100%', gap: spacing.sm }}>
      <Button onPress={onCancel} color={color} size="lg" fullWidth>
        Keep Going
      </Button>
      <Button onPress={onComplete} variant="danger" size="lg" fullWidth>
        End Session
      </Button>
    </View>
  </View>
);

// Level 2: Breathing delay
const DelayChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [breathingComplete, setBreathingComplete] = useState(false);

  if (!breathingComplete) {
    return (
      <View style={{ alignItems: 'center' }}>
        <SansText
          style={{
            fontSize: 11,
            color: colors.textMuted,
            textTransform: 'uppercase',
            letterSpacing: 3,
            marginBottom: spacing.md,
          }}
        >
          Take a moment to reflect
        </SansText>
        <BreathingCircle color={color} onComplete={() => setBreathingComplete(true)} />
        <Pressable onPress={onCancel} style={{ padding: spacing.md }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Cancel
          </SansText>
        </Pressable>
      </View>
    );
  }

  return <ConfirmChallenge onComplete={onComplete} onCancel={onCancel} color={color} />;
};

// Level 3: Math problem
const MathChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [problem] = useState(() => generateMathProblem());
  const [answer, setAnswer] = useState('');
  const [error, setError] = useState(false);

  const handleSubmit = () => {
    if (parseInt(answer) === problem.answer) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      onComplete();
    } else {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      setError(true);
      setAnswer('');
      setTimeout(() => setError(false), 500);
    }
  };

  return (
    <View style={{ alignItems: 'center', paddingVertical: spacing.lg }}>
      <View
        style={{
          width: 72,
          height: 72,
          borderRadius: 36,
          backgroundColor: `${color}20`,
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: spacing.lg,
        }}
      >
        <Ionicons name="calculator-outline" size={36} color={color} />
      </View>
      <SansText
        style={{
          fontSize: 11,
          color: colors.textMuted,
          textTransform: 'uppercase',
          letterSpacing: 3,
          marginBottom: spacing.sm,
        }}
      >
        Solve to continue
      </SansText>
      <SerifText style={{ fontSize: 36, color: colors.textPrimary, marginBottom: spacing.lg }}>
        {problem.a} {problem.operator} {problem.b} = ?
      </SerifText>
      <TextInput
        value={answer}
        onChangeText={setAnswer}
        keyboardType="number-pad"
        placeholder="Your answer"
        placeholderTextColor={colors.textMuted}
        style={{
          width: '100%',
          backgroundColor: error ? colors.dangerMuted : colors.surface,
          borderWidth: 2,
          borderColor: error ? colors.danger : colors.border,
          borderRadius: radius.xl,
          paddingHorizontal: spacing.lg,
          paddingVertical: spacing.md,
          fontSize: 24,
          color: colors.textPrimary,
          textAlign: 'center',
          marginBottom: spacing.lg,
        }}
      />
      <View style={{ width: '100%', gap: spacing.sm }}>
        <Button
          onPress={handleSubmit}
          color={color}
          size="lg"
          fullWidth
          disabled={!answer}
        >
          Submit
        </Button>
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center' }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Keep focusing instead
          </SansText>
        </Pressable>
      </View>
    </View>
  );
};

// Level 3+: Typing challenge
const TypingChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [phrase] = useState(() => TYPING_PHRASES[Math.floor(Math.random() * TYPING_PHRASES.length)]);
  const [input, setInput] = useState('');
  const isCorrect = input.toLowerCase().trim() === phrase.toLowerCase();

  useEffect(() => {
    if (isCorrect) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      setTimeout(onComplete, 300);
    }
  }, [isCorrect, onComplete]);

  return (
    <View style={{ alignItems: 'center', paddingVertical: spacing.lg }}>
      <View
        style={{
          width: 72,
          height: 72,
          borderRadius: 36,
          backgroundColor: `${color}20`,
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: spacing.lg,
        }}
      >
        <Ionicons name="text-outline" size={36} color={color} />
      </View>
      <SansText
        style={{
          fontSize: 11,
          color: colors.textMuted,
          textTransform: 'uppercase',
          letterSpacing: 3,
          marginBottom: spacing.md,
        }}
      >
        Type this phrase to continue
      </SansText>
      <SerifText
        style={{
          fontSize: 20,
          color: colors.textSecondary,
          textAlign: 'center',
          marginBottom: spacing.lg,
          fontStyle: 'italic',
        }}
      >
        "{phrase}"
      </SerifText>
      <TextInput
        value={input}
        onChangeText={setInput}
        placeholder="Type the phrase above..."
        placeholderTextColor={colors.textMuted}
        autoCapitalize="none"
        autoCorrect={false}
        style={{
          width: '100%',
          backgroundColor: isCorrect ? `${colors.success}20` : colors.surface,
          borderWidth: 2,
          borderColor: isCorrect ? colors.success : colors.border,
          borderRadius: radius.xl,
          paddingHorizontal: spacing.lg,
          paddingVertical: spacing.md,
          fontSize: 16,
          color: colors.textPrimary,
          textAlign: 'center',
          marginBottom: spacing.lg,
        }}
      />
      <Pressable onPress={onCancel} style={{ padding: spacing.md }}>
        <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
          Keep focusing instead
        </SansText>
      </Pressable>
    </View>
  );
};

// Physical tasks
const PHYSICAL_TASKS = [
  { task: 'jumping jacks', count: 10, icon: 'fitness-outline' as const },
  { task: 'deep squats', count: 10, icon: 'body-outline' as const },
  { task: 'push-ups', count: 5, icon: 'barbell-outline' as const },
  { task: 'standing stretches', count: 30, unit: 'seconds', icon: 'walk-outline' as const },
];

// Physical challenge
const PhysicalChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [task] = useState(() => PHYSICAL_TASKS[Math.floor(Math.random() * PHYSICAL_TASKS.length)]);
  const [countdown, setCountdown] = useState(task.unit === 'seconds' ? task.count : 15);
  const [isActive, setIsActive] = useState(false);
  const [isDone, setIsDone] = useState(false);

  useEffect(() => {
    if (!isActive || isDone) return;

    const interval = setInterval(() => {
      setCountdown((c) => {
        if (c <= 1) {
          setIsDone(true);
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
          return 0;
        }
        return c - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [isActive, isDone]);

  if (isDone) {
    return (
      <View style={{ alignItems: 'center', paddingVertical: spacing.lg }}>
        <Animated.View
          entering={ZoomIn.duration(300).springify()}
          style={{
            width: 80,
            height: 80,
            borderRadius: 40,
            backgroundColor: `${colors.success}20`,
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: spacing.lg,
          }}
        >
          <Ionicons name="checkmark-circle" size={48} color={colors.success} />
        </Animated.View>
        <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.sm }}>
          Great work!
        </SerifText>
        <SansText style={{ fontSize: 14, color: colors.textTertiary, marginBottom: spacing.xl }}>
          You completed the physical challenge
        </SansText>
        <Button onPress={onComplete} color={color} size="lg" fullWidth>
          Continue
        </Button>
      </View>
    );
  }

  return (
    <View style={{ alignItems: 'center', paddingVertical: spacing.lg }}>
      <View
        style={{
          width: 72,
          height: 72,
          borderRadius: 36,
          backgroundColor: `${color}20`,
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: spacing.lg,
        }}
      >
        <Ionicons name={task.icon} size={36} color={color} />
      </View>
      <SansText
        style={{
          fontSize: 11,
          color: colors.textMuted,
          textTransform: 'uppercase',
          letterSpacing: 3,
          marginBottom: spacing.sm,
        }}
      >
        Physical Challenge
      </SansText>
      <SerifText style={{ fontSize: 28, color: colors.textPrimary, marginBottom: spacing.sm, textAlign: 'center' }}>
        Do {task.count} {task.task}
      </SerifText>
      {isActive ? (
        <View style={{ alignItems: 'center', marginVertical: spacing.lg }}>
          <SansText style={{ fontSize: 64, color: color, fontWeight: '200' }}>
            {countdown}
          </SansText>
          <SansText style={{ fontSize: 14, color: colors.textMuted }}>
            {task.unit === 'seconds' ? 'seconds remaining' : 'seconds to complete'}
          </SansText>
        </View>
      ) : (
        <SansText
          style={{
            fontSize: 14,
            color: colors.textTertiary,
            textAlign: 'center',
            marginBottom: spacing.lg,
            paddingHorizontal: spacing.md,
          }}
        >
          Take a moment to move your body and reset your mind.
        </SansText>
      )}
      <View style={{ width: '100%', gap: spacing.sm }}>
        {!isActive ? (
          <Button onPress={() => setIsActive(true)} color={color} size="lg" fullWidth>
            Start Challenge
          </Button>
        ) : null}
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center' }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Keep focusing instead
          </SansText>
        </Pressable>
      </View>
    </View>
  );
};

// Photo prompts
const PHOTO_PROMPTS = [
  'Take a photo of your workspace',
  'Take a photo of something green',
  'Take a photo of the sky or ceiling',
  'Take a selfie with a smile',
];

// Photo challenge
const PhotoChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [prompt] = useState(() => PHOTO_PROMPTS[Math.floor(Math.random() * PHOTO_PROMPTS.length)]);
  const [photo, setPhoto] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const takePhoto = async () => {
    setIsLoading(true);
    try {
      // Dynamic import to avoid crash in Expo Go
      const ImagePicker = await import('expo-image-picker');

      const { status } = await ImagePicker.requestCameraPermissionsAsync();
      if (status !== 'granted') {
        // If no camera permission, skip to confirm
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
        onComplete();
        return;
      }

      const result = await ImagePicker.launchCameraAsync({
        allowsEditing: false,
        quality: 0.5,
      });

      if (!result.canceled && result.assets[0]) {
        setPhoto(result.assets[0].uri);
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      }
    } catch (error) {
      console.log('Camera error:', error);
      // If camera fails, just complete the challenge
      onComplete();
    } finally {
      setIsLoading(false);
    }
  };

  if (photo) {
    return (
      <View style={{ alignItems: 'center', paddingVertical: spacing.lg }}>
        <Animated.View
          entering={ZoomIn.duration(300).springify()}
          style={{
            width: 160,
            height: 160,
            borderRadius: 16,
            overflow: 'hidden',
            marginBottom: spacing.lg,
            borderWidth: 3,
            borderColor: colors.success,
          }}
        >
          <Image source={{ uri: photo }} style={{ width: '100%', height: '100%' }} />
        </Animated.View>
        <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.sm }}>
          Photo taken!
        </SerifText>
        <SansText style={{ fontSize: 14, color: colors.textTertiary, marginBottom: spacing.xl }}>
          Challenge completed successfully
        </SansText>
        <Button onPress={onComplete} color={color} size="lg" fullWidth>
          Continue
        </Button>
      </View>
    );
  }

  return (
    <View style={{ alignItems: 'center', paddingVertical: spacing.lg }}>
      <View
        style={{
          width: 72,
          height: 72,
          borderRadius: 36,
          backgroundColor: `${color}20`,
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: spacing.lg,
        }}
      >
        <Ionicons name="camera-outline" size={36} color={color} />
      </View>
      <SansText
        style={{
          fontSize: 11,
          color: colors.textMuted,
          textTransform: 'uppercase',
          letterSpacing: 3,
          marginBottom: spacing.sm,
        }}
      >
        Photo Challenge
      </SansText>
      <SerifText
        style={{
          fontSize: 22,
          color: colors.textPrimary,
          marginBottom: spacing.md,
          textAlign: 'center',
        }}
      >
        {prompt}
      </SerifText>
      <SansText
        style={{
          fontSize: 14,
          color: colors.textTertiary,
          textAlign: 'center',
          marginBottom: spacing.xl,
          paddingHorizontal: spacing.md,
        }}
      >
        This helps break the scroll reflex and brings awareness to the present moment.
      </SansText>
      <View style={{ width: '100%', gap: spacing.sm }}>
        <Button onPress={takePhoto} color={color} size="lg" fullWidth loading={isLoading}>
          Open Camera
        </Button>
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center' }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Keep focusing instead
          </SansText>
        </Pressable>
      </View>
    </View>
  );
};

// Challenge types for level 3
type Level3ChallengeType = 'math' | 'typing' | 'physical' | 'photo';

export function FrictionChallenge({
  level,
  onComplete,
  onCancel,
  themeColor,
}: FrictionChallengeProps) {
  const [stage, setStage] = useState(0);
  // Pick a random challenge type for level 3 on mount
  const [challengeType] = useState<Level3ChallengeType>(() => {
    const types: Level3ChallengeType[] = ['math', 'typing', 'physical', 'photo'];
    return types[Math.floor(Math.random() * types.length)];
  });

  // Level 1: Just confirmation
  // Level 2: Breathing + confirmation
  // Level 3: Random challenge (math/typing/physical/photo) + confirmation

  const renderLevel3Challenge = () => {
    switch (challengeType) {
      case 'math':
        return (
          <MathChallenge
            onComplete={() => setStage(1)}
            onCancel={onCancel}
            color={themeColor}
          />
        );
      case 'typing':
        return (
          <TypingChallenge
            onComplete={() => setStage(1)}
            onCancel={onCancel}
            color={themeColor}
          />
        );
      case 'physical':
        return (
          <PhysicalChallenge
            onComplete={() => setStage(1)}
            onCancel={onCancel}
            color={themeColor}
          />
        );
      case 'photo':
        return (
          <PhotoChallenge
            onComplete={() => setStage(1)}
            onCancel={onCancel}
            color={themeColor}
          />
        );
    }
  };

  const renderChallenge = () => {
    switch (level) {
      case 1:
        return <ConfirmChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 2:
        return <DelayChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 3:
      default:
        if (stage === 0) {
          return renderLevel3Challenge();
        }
        return <ConfirmChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
    }
  };

  return (
    <Animated.View
      entering={FadeIn.duration(200)}
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: colors.overlayHeavy,
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: spacing.lg,
        zIndex: 100,
      }}
    >
      <Animated.View
        entering={FadeInDown.duration(300).springify()}
        style={{
          width: '100%',
          maxWidth: 360,
          backgroundColor: colors.surface,
          borderRadius: radius['2xl'],
          borderWidth: 1,
          borderColor: colors.border,
          padding: spacing.xl,
        }}
      >
        {renderChallenge()}
      </Animated.View>
    </Animated.View>
  );
}
