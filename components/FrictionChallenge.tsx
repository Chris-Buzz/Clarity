import React, { useEffect, useState } from 'react';
import { View, TextInput, Pressable, Linking, Alert, Image, ActivityIndicator, Platform } from 'react-native';
import Animated, {
  FadeIn,
  FadeInDown,
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withRepeat,
  withSequence,
  ZoomIn,
} from 'react-native-reanimated';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import * as ImagePicker from 'expo-image-picker';
import { SansText, SerifText } from './Typography';
import { Button } from './Button';
import { colors, radius, spacing } from '@/constants';
import { verifyChallenge, VerificationType, isAIVerificationAvailable } from '@/services/aiVerification';

// Lazy load native modules that require dev build
let Contacts: typeof import('expo-contacts') | null = null;
let SMS: typeof import('expo-sms') | null = null;

// Try to load contacts module
try {
  Contacts = require('expo-contacts');
} catch (e) {
  console.log('expo-contacts not available - contacts challenges will be skipped');
}

// Try to load SMS module
try {
  SMS = require('expo-sms');
} catch (e) {
  console.log('expo-sms not available - SMS challenges will use fallback');
}

interface FrictionChallengeProps {
  level: number; // 1 = Gentle, 2 = Moderate, 3 = Warrior
  onComplete: () => void;
  onCancel: () => void;
  themeColor: string;
}

// Real challenge types that get people off their phones
type ChallengeType =
  | 'call_someone'
  | 'text_loved_one'
  | 'go_outside'
  | 'drink_water'
  | 'gratitude'
  | 'intention'
  | 'wait'
  | 'walk_away'
  | 'deep_breath'
  | 'contact_parent'
  | 'prove_outside'      // AI verified: prove you're outside
  | 'prove_water'        // AI verified: show water
  | 'prove_standing';    // AI verified: prove you're standing

// Challenge configurations based on level
const GENTLE_CHALLENGES: ChallengeType[] = ['deep_breath', 'drink_water', 'intention'];
const MODERATE_CHALLENGES: ChallengeType[] = ['gratitude', 'text_loved_one', 'walk_away', 'wait', 'prove_water'];
const WARRIOR_CHALLENGES: ChallengeType[] = ['call_someone', 'contact_parent', 'prove_outside', 'prove_standing'];

// Get random challenge based on level
const getRandomChallenge = (level: number): ChallengeType => {
  const challenges = level === 1
    ? GENTLE_CHALLENGES
    : level === 2
      ? MODERATE_CHALLENGES
      : WARRIOR_CHALLENGES;
  return challenges[Math.floor(Math.random() * challenges.length)];
};

// ==================== CALL SOMEONE CHALLENGE ====================
const CallSomeoneChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [selectedContact, setSelectedContact] = useState<{ name: string; phone: string } | null>(null);
  const [callMade, setCallMade] = useState(false);
  const [noContacts, setNoContacts] = useState(!Contacts);

  const pickContact = async () => {
    if (!Contacts) {
      // No contacts module - just show generic prompt
      setNoContacts(true);
      return;
    }

    try {
      const { status } = await Contacts.requestPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission needed', 'We need access to contacts for this challenge');
        setNoContacts(true);
        return;
      }

      const { data } = await Contacts.getContactsAsync({
        fields: [Contacts.Fields.PhoneNumbers, Contacts.Fields.Name],
      });

      if (data.length > 0) {
        // Pick a random contact with a phone number
        const contactsWithPhone = data.filter(c => c.phoneNumbers && c.phoneNumbers.length > 0);
        if (contactsWithPhone.length > 0) {
          const randomContact = contactsWithPhone[Math.floor(Math.random() * contactsWithPhone.length)];
          setSelectedContact({
            name: randomContact.name || 'Unknown',
            phone: randomContact.phoneNumbers![0].number || '',
          });
        }
      }
    } catch (error) {
      console.log('Contact error:', error);
      setNoContacts(true);
    }
  };

  const makeCall = async () => {
    if (selectedContact) {
      const phoneUrl = `tel:${selectedContact.phone}`;
      const canOpen = await Linking.canOpenURL(phoneUrl);
      if (canOpen) {
        await Linking.openURL(phoneUrl);
        setCallMade(true);
        setTimeout(() => {
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        }, 1000);
      }
    }
  };

  useEffect(() => {
    pickContact();
  }, []);

  if (callMade) {
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
          Real connection made
        </SerifText>
        <SansText style={{ fontSize: 14, color: colors.textTertiary, marginBottom: spacing.xl, textAlign: 'center' }}>
          That's what phones are actually for.
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
          width: 80,
          height: 80,
          borderRadius: 40,
          backgroundColor: `${color}20`,
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: spacing.lg,
        }}
      >
        <Ionicons name="call-outline" size={40} color={color} />
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
        Real Connection Challenge
      </SansText>
      <SerifText style={{ fontSize: 26, color: colors.textPrimary, marginBottom: spacing.md, textAlign: 'center' }}>
        Call someone you care about
      </SerifText>
      {selectedContact ? (
        <View style={{
          backgroundColor: colors.surface,
          padding: spacing.lg,
          borderRadius: radius.xl,
          borderWidth: 1,
          borderColor: colors.border,
          width: '100%',
          marginBottom: spacing.lg,
        }}>
          <SansText style={{ fontSize: 12, color: colors.textMuted, marginBottom: spacing.xs }}>
            Suggested contact:
          </SansText>
          <SansText style={{ fontSize: 18, color: colors.textPrimary, fontWeight: '600' }}>
            {selectedContact.name}
          </SansText>
        </View>
      ) : (
        <SansText style={{ fontSize: 14, color: colors.textTertiary, marginBottom: spacing.lg }}>
          Loading a contact suggestion...
        </SansText>
      )}
      <SansText
        style={{
          fontSize: 14,
          color: colors.textTertiary,
          textAlign: 'center',
          marginBottom: spacing.xl,
          paddingHorizontal: spacing.md,
        }}
      >
        Instead of mindless scrolling, have a real conversation. Even 30 seconds matters.
      </SansText>
      <View style={{ width: '100%', gap: spacing.sm }}>
        <Button onPress={makeCall} color={color} size="lg" fullWidth disabled={!selectedContact}>
          Make the Call
        </Button>
        <Button onPress={pickContact} variant="secondary" size="lg" fullWidth>
          Pick Different Contact
        </Button>
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center' }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Go back to what I was doing
          </SansText>
        </Pressable>
      </View>
    </View>
  );
};

// ==================== TEXT LOVED ONE CHALLENGE ====================
const TextLovedOneChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [messageSent, setMessageSent] = useState(false);

  const prompts = [
    "Tell someone you're thinking of them",
    "Ask a friend how they're doing",
    "Send a thank you to someone",
    "Check in on a family member",
    "Share something you're grateful for with someone",
  ];
  const [prompt] = useState(() => prompts[Math.floor(Math.random() * prompts.length)]);

  const openMessages = async () => {
    const isAvailable = await SMS.isAvailableAsync();
    if (isAvailable) {
      await SMS.sendSMSAsync([], ''); // Opens empty message
      setMessageSent(true);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    } else {
      // Fallback - just open messages app
      await Linking.openURL('sms:');
      setMessageSent(true);
    }
  };

  if (messageSent) {
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
          <Ionicons name="heart" size={40} color={colors.success} />
        </Animated.View>
        <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.sm }}>
          Connection sent
        </SerifText>
        <SansText style={{ fontSize: 14, color: colors.textTertiary, marginBottom: spacing.xl, textAlign: 'center' }}>
          You just made someone's day better.
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
          width: 80,
          height: 80,
          borderRadius: 40,
          backgroundColor: `${color}20`,
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: spacing.lg,
        }}
      >
        <Ionicons name="chatbubble-ellipses-outline" size={40} color={color} />
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
        Connection Challenge
      </SansText>
      <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.lg, textAlign: 'center' }}>
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
        Real connection beats endless scrolling. Send a message that matters.
      </SansText>
      <View style={{ width: '100%', gap: spacing.sm }}>
        <Button onPress={openMessages} color={color} size="lg" fullWidth>
          Open Messages
        </Button>
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center' }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Go back to what I was doing
          </SansText>
        </Pressable>
      </View>
    </View>
  );
};

// ==================== CONTACT PARENT CHALLENGE ====================
const ContactParentChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [contacted, setContacted] = useState(false);

  const actions = [
    { text: "Call Mom or Dad", icon: "call-outline" as const },
    { text: "Text your parents", icon: "chatbubble-outline" as const },
    { text: "Send a voice note to family", icon: "mic-outline" as const },
  ];
  const [action] = useState(() => actions[Math.floor(Math.random() * actions.length)]);

  const openPhone = async () => {
    await Linking.openURL('tel:');
    setContacted(true);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const openMessages = async () => {
    await Linking.openURL('sms:');
    setContacted(true);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  if (contacted) {
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
          <Ionicons name="home" size={40} color={colors.success} />
        </Animated.View>
        <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.sm }}>
          Family first
        </SerifText>
        <SansText style={{ fontSize: 14, color: colors.textTertiary, marginBottom: spacing.xl, textAlign: 'center' }}>
          They won't be around forever. This matters more than any feed.
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
          width: 80,
          height: 80,
          borderRadius: 40,
          backgroundColor: `${color}20`,
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: spacing.lg,
        }}
      >
        <Ionicons name={action.icon} size={40} color={color} />
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
        Family Challenge
      </SansText>
      <SerifText style={{ fontSize: 26, color: colors.textPrimary, marginBottom: spacing.md, textAlign: 'center' }}>
        {action.text}
      </SerifText>
      <SansText
        style={{
          fontSize: 15,
          color: colors.textTertiary,
          textAlign: 'center',
          marginBottom: spacing.xl,
          paddingHorizontal: spacing.md,
          lineHeight: 22,
        }}
      >
        When was the last time you reached out? They'd love to hear from you.
      </SansText>
      <View style={{ width: '100%', gap: spacing.sm }}>
        <Button onPress={openPhone} color={color} size="lg" fullWidth>
          Call
        </Button>
        <Button onPress={openMessages} variant="secondary" size="lg" fullWidth>
          Text
        </Button>
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center' }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Go back to what I was doing
          </SansText>
        </Pressable>
      </View>
    </View>
  );
};

// ==================== GO OUTSIDE CHALLENGE ====================
const GoOutsideChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [confirmed, setConfirmed] = useState(false);
  const [timer, setTimer] = useState(60);
  const [timerActive, setTimerActive] = useState(false);

  useEffect(() => {
    if (!timerActive || timer <= 0) return;
    const interval = setInterval(() => {
      setTimer(t => {
        if (t <= 1) {
          setConfirmed(true);
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
          return 0;
        }
        return t - 1;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [timerActive, timer]);

  if (confirmed) {
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
          <Ionicons name="sunny" size={40} color={colors.success} />
        </Animated.View>
        <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.sm }}>
          Fresh air hits different
        </SerifText>
        <SansText style={{ fontSize: 14, color: colors.textTertiary, marginBottom: spacing.xl, textAlign: 'center' }}>
          The real world is out there. Keep choosing it.
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
          width: 80,
          height: 80,
          borderRadius: 40,
          backgroundColor: `${color}20`,
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: spacing.lg,
        }}
      >
        <Ionicons name="leaf-outline" size={40} color={color} />
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
        Real World Challenge
      </SansText>
      <SerifText style={{ fontSize: 26, color: colors.textPrimary, marginBottom: spacing.md, textAlign: 'center' }}>
        Step outside for 1 minute
      </SerifText>
      {timerActive ? (
        <View style={{ alignItems: 'center', marginVertical: spacing.lg }}>
          <SansText style={{ fontSize: 72, color: color, fontWeight: '200' }}>
            {timer}
          </SansText>
          <SansText style={{ fontSize: 14, color: colors.textMuted }}>
            seconds outside
          </SansText>
        </View>
      ) : (
        <SansText
          style={{
            fontSize: 15,
            color: colors.textTertiary,
            textAlign: 'center',
            marginBottom: spacing.xl,
            paddingHorizontal: spacing.md,
            lineHeight: 22,
          }}
        >
          Put your phone down, walk outside, and take a breath. The feed will still be there. Your life is happening now.
        </SansText>
      )}
      <View style={{ width: '100%', gap: spacing.sm }}>
        {!timerActive ? (
          <Button onPress={() => setTimerActive(true)} color={color} size="lg" fullWidth>
            I'm Outside - Start Timer
          </Button>
        ) : null}
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center' }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Go back to what I was doing
          </SansText>
        </Pressable>
      </View>
    </View>
  );
};

// ==================== DRINK WATER CHALLENGE ====================
const DrinkWaterChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [confirmed, setConfirmed] = useState(false);

  const handleConfirm = () => {
    setConfirmed(true);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  if (confirmed) {
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
          <Ionicons name="water" size={40} color={colors.success} />
        </Animated.View>
        <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.sm }}>
          Body over screen
        </SerifText>
        <SansText style={{ fontSize: 14, color: colors.textTertiary, marginBottom: spacing.xl, textAlign: 'center' }}>
          Taking care of yourself is the ultimate flex.
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
          width: 80,
          height: 80,
          borderRadius: 40,
          backgroundColor: `${color}20`,
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: spacing.lg,
        }}
      >
        <Ionicons name="water-outline" size={40} color={color} />
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
        Self-Care Challenge
      </SansText>
      <SerifText style={{ fontSize: 26, color: colors.textPrimary, marginBottom: spacing.md, textAlign: 'center' }}>
        Drink a glass of water
      </SerifText>
      <SansText
        style={{
          fontSize: 15,
          color: colors.textTertiary,
          textAlign: 'center',
          marginBottom: spacing.xl,
          paddingHorizontal: spacing.md,
          lineHeight: 22,
        }}
      >
        Put the phone down. Go get water. Your brain needs hydration more than dopamine hits.
      </SansText>
      <View style={{ width: '100%', gap: spacing.sm }}>
        <Button onPress={handleConfirm} color={color} size="lg" fullWidth>
          I Drank Water
        </Button>
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center' }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Go back to what I was doing
          </SansText>
        </Pressable>
      </View>
    </View>
  );
};

// ==================== GRATITUDE CHALLENGE ====================
const GratitudeChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [items, setItems] = useState(['', '', '']);
  const filledCount = items.filter(i => i.trim().length > 0).length;
  const isComplete = filledCount >= 3;

  const handleSubmit = () => {
    if (isComplete) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      onComplete();
    }
  };

  return (
    <View style={{ alignItems: 'center', paddingVertical: spacing.lg }}>
      <View
        style={{
          width: 80,
          height: 80,
          borderRadius: 40,
          backgroundColor: `${color}20`,
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: spacing.lg,
        }}
      >
        <Ionicons name="heart-outline" size={40} color={color} />
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
        Gratitude Challenge
      </SansText>
      <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.md, textAlign: 'center' }}>
        3 things you're grateful for
      </SerifText>
      <SansText
        style={{
          fontSize: 14,
          color: colors.textTertiary,
          textAlign: 'center',
          marginBottom: spacing.lg,
        }}
      >
        Shift your mind from what you're escaping to what you have.
      </SansText>
      <View style={{ width: '100%', gap: spacing.sm, marginBottom: spacing.lg }}>
        {items.map((item, index) => (
          <TextInput
            key={index}
            value={item}
            onChangeText={(text) => {
              const newItems = [...items];
              newItems[index] = text;
              setItems(newItems);
            }}
            placeholder={`${index + 1}. I'm grateful for...`}
            placeholderTextColor={colors.textMuted}
            style={{
              width: '100%',
              backgroundColor: colors.surface,
              borderWidth: 1,
              borderColor: item.trim() ? color : colors.border,
              borderRadius: radius.lg,
              paddingHorizontal: spacing.md,
              paddingVertical: spacing.md,
              fontSize: 16,
              color: colors.textPrimary,
            }}
          />
        ))}
      </View>
      <View style={{ width: '100%', gap: spacing.sm }}>
        <Button onPress={handleSubmit} color={color} size="lg" fullWidth disabled={!isComplete}>
          {isComplete ? 'Done' : `${filledCount}/3 completed`}
        </Button>
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center' }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Go back to what I was doing
          </SansText>
        </Pressable>
      </View>
    </View>
  );
};

// ==================== INTENTION CHALLENGE ====================
const IntentionChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [intention, setIntention] = useState('');
  const isComplete = intention.trim().length >= 10;

  const handleSubmit = () => {
    if (isComplete) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      onComplete();
    }
  };

  return (
    <View style={{ alignItems: 'center', paddingVertical: spacing.lg }}>
      <View
        style={{
          width: 80,
          height: 80,
          borderRadius: 40,
          backgroundColor: `${color}20`,
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: spacing.lg,
        }}
      >
        <Ionicons name="compass-outline" size={40} color={color} />
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
        Intention Challenge
      </SansText>
      <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.md, textAlign: 'center' }}>
        What would you rather be doing?
      </SerifText>
      <SansText
        style={{
          fontSize: 14,
          color: colors.textTertiary,
          textAlign: 'center',
          marginBottom: spacing.lg,
        }}
      >
        If you weren't scrolling right now, what would actually make you happy?
      </SansText>
      <TextInput
        value={intention}
        onChangeText={setIntention}
        placeholder="I'd rather be..."
        placeholderTextColor={colors.textMuted}
        multiline
        style={{
          width: '100%',
          minHeight: 100,
          backgroundColor: colors.surface,
          borderWidth: 1,
          borderColor: isComplete ? color : colors.border,
          borderRadius: radius.lg,
          paddingHorizontal: spacing.md,
          paddingVertical: spacing.md,
          fontSize: 16,
          color: colors.textPrimary,
          textAlignVertical: 'top',
          marginBottom: spacing.lg,
        }}
      />
      <View style={{ width: '100%', gap: spacing.sm }}>
        <Button onPress={handleSubmit} color={color} size="lg" fullWidth disabled={!isComplete}>
          Set Intention
        </Button>
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center' }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Go back to what I was doing
          </SansText>
        </Pressable>
      </View>
    </View>
  );
};

// ==================== WAIT CHALLENGE ====================
const WaitChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [timer, setTimer] = useState(30);
  const pulseScale = useSharedValue(1);

  useEffect(() => {
    pulseScale.value = withRepeat(
      withSequence(
        withTiming(1.1, { duration: 1000 }),
        withTiming(1, { duration: 1000 })
      ),
      -1,
      true
    );
  }, []);

  useEffect(() => {
    if (timer <= 0) return;
    const interval = setInterval(() => {
      setTimer(t => {
        if (t <= 1) {
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
          return 0;
        }
        return t - 1;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [timer]);

  const pulseStyle = useAnimatedStyle(() => ({
    transform: [{ scale: pulseScale.value }],
  }));

  if (timer <= 0) {
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
          Still want to scroll?
        </SerifText>
        <SansText style={{ fontSize: 14, color: colors.textTertiary, marginBottom: spacing.xl, textAlign: 'center' }}>
          Sometimes the urge passes if you just wait.
        </SansText>
        <Button onPress={onComplete} color={color} size="lg" fullWidth>
          Yes, Continue
        </Button>
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center', marginTop: spacing.sm }}>
          <SansText style={{ color: colors.success, fontSize: 14, fontWeight: '600' }}>
            Actually, I'll do something else
          </SansText>
        </Pressable>
      </View>
    );
  }

  return (
    <View style={{ alignItems: 'center', paddingVertical: spacing.lg }}>
      <Animated.View
        style={[
          {
            width: 120,
            height: 120,
            borderRadius: 60,
            backgroundColor: `${color}10`,
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: spacing.lg,
            borderWidth: 3,
            borderColor: `${color}40`,
          },
          pulseStyle,
        ]}
      >
        <SansText style={{ fontSize: 48, color: color, fontWeight: '200' }}>
          {timer}
        </SansText>
      </Animated.View>
      <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.md, textAlign: 'center' }}>
        Just wait.
      </SerifText>
      <SansText
        style={{
          fontSize: 15,
          color: colors.textTertiary,
          textAlign: 'center',
          paddingHorizontal: spacing.md,
          lineHeight: 22,
        }}
      >
        Sit with the discomfort. The urge to scroll is temporary. You are stronger than the algorithm.
      </SansText>
      <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center', marginTop: spacing.xl }}>
        <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
          Go back to what I was doing
        </SansText>
      </Pressable>
    </View>
  );
};

// ==================== WALK AWAY CHALLENGE ====================
const WalkAwayChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const [confirmed, setConfirmed] = useState(false);

  const handleConfirm = () => {
    setConfirmed(true);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  if (confirmed) {
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
          <Ionicons name="footsteps" size={40} color={colors.success} />
        </Animated.View>
        <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.sm }}>
          Movement over stagnation
        </SerifText>
        <SansText style={{ fontSize: 14, color: colors.textTertiary, marginBottom: spacing.xl, textAlign: 'center' }}>
          Your body isn't designed to sit and scroll.
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
          width: 80,
          height: 80,
          borderRadius: 40,
          backgroundColor: `${color}20`,
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: spacing.lg,
        }}
      >
        <Ionicons name="walk-outline" size={40} color={color} />
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
        Movement Challenge
      </SansText>
      <SerifText style={{ fontSize: 26, color: colors.textPrimary, marginBottom: spacing.md, textAlign: 'center' }}>
        Walk to another room
      </SerifText>
      <SansText
        style={{
          fontSize: 15,
          color: colors.textTertiary,
          textAlign: 'center',
          marginBottom: spacing.xl,
          paddingHorizontal: spacing.md,
          lineHeight: 22,
        }}
      >
        Put your phone down. Physically move to a different space. Break the scroll position.
      </SansText>
      <View style={{ width: '100%', gap: spacing.sm }}>
        <Button onPress={handleConfirm} color={color} size="lg" fullWidth>
          I Moved
        </Button>
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center' }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Go back to what I was doing
          </SansText>
        </Pressable>
      </View>
    </View>
  );
};

// ==================== DEEP BREATH CHALLENGE ====================
const DeepBreathChallenge = ({
  onComplete,
  onCancel,
  color,
}: {
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const scale = useSharedValue(0.6);
  const [phase, setPhase] = useState<'inhale' | 'hold' | 'exhale'>('inhale');
  const [countdown, setCountdown] = useState(4);
  const [cycles, setCycles] = useState(0);
  const [complete, setComplete] = useState(false);

  useEffect(() => {
    if (complete) return;

    const totalTime = 12000;
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
  }, [complete]);

  useEffect(() => {
    if (cycles >= 2) {
      setComplete(true);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }
  }, [cycles]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  if (complete) {
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
          <Ionicons name="leaf" size={40} color={colors.success} />
        </Animated.View>
        <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.sm }}>
          Centered
        </SerifText>
        <SansText style={{ fontSize: 14, color: colors.textTertiary, marginBottom: spacing.xl, textAlign: 'center' }}>
          A calm mind makes better choices.
        </SansText>
        <Button onPress={onComplete} color={color} size="lg" fullWidth>
          Continue
        </Button>
      </View>
    );
  }

  return (
    <View style={{ alignItems: 'center', paddingVertical: spacing.lg }}>
      <SansText
        style={{
          fontSize: 11,
          color: colors.textMuted,
          textTransform: 'uppercase',
          letterSpacing: 3,
          marginBottom: spacing.md,
        }}
      >
        Breathing Challenge
      </SansText>
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
      <Pressable onPress={onCancel} style={{ padding: spacing.md, marginTop: spacing.lg }}>
        <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
          Go back to what I was doing
        </SansText>
      </Pressable>
    </View>
  );
};

// ==================== AI VERIFIED PHOTO CHALLENGE ====================
interface AIVerifiedChallengeConfig {
  title: string;
  description: string;
  instruction: string;
  icon: keyof typeof Ionicons.glyphMap;
  verificationType: VerificationType;
  successTitle: string;
  successMessage: string;
}

const AI_CHALLENGE_CONFIGS: Record<string, AIVerifiedChallengeConfig> = {
  prove_outside: {
    title: 'Prove You\'re Outside',
    description: 'The algorithm wants you inside scrolling. Prove you chose differently.',
    instruction: 'Take a photo showing you\'re outside - sky, trees, street, anything outdoors.',
    icon: 'leaf-outline',
    verificationType: 'outside',
    successTitle: 'Outside confirmed!',
    successMessage: 'The real world beats the feed every time.',
  },
  prove_water: {
    title: 'Show Me Water',
    description: 'Your brain is dehydrated from dopamine. Give it what it actually needs.',
    instruction: 'Take a photo of yourself with a glass or bottle of water.',
    icon: 'water-outline',
    verificationType: 'water',
    successTitle: 'Hydration verified!',
    successMessage: 'Your body over the algorithm. Always.',
  },
  prove_standing: {
    title: 'Get On Your Feet',
    description: 'You\'ve been sitting and scrolling. Stand up and prove it.',
    instruction: 'Take a photo that shows you\'re standing up - show the floor beneath you.',
    icon: 'body-outline',
    verificationType: 'standing',
    successTitle: 'Standing confirmed!',
    successMessage: 'Movement is medicine. The couch can wait.',
  },
};

const AIVerifiedChallenge = ({
  challengeKey,
  onComplete,
  onCancel,
  color,
}: {
  challengeKey: string;
  onComplete: () => void;
  onCancel: () => void;
  color: string;
}) => {
  const config = AI_CHALLENGE_CONFIGS[challengeKey];
  const [photo, setPhoto] = useState<string | null>(null);
  const [verifying, setVerifying] = useState(false);
  const [verified, setVerified] = useState(false);
  const [verificationMessage, setVerificationMessage] = useState('');
  const [failed, setFailed] = useState(false);

  const takePhoto = async () => {
    try {
      const { status } = await ImagePicker.requestCameraPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Camera needed', 'We need camera access to verify your challenge');
        return;
      }

      const result = await ImagePicker.launchCameraAsync({
        allowsEditing: false,
        quality: 0.7,
      });

      if (!result.canceled && result.assets[0]) {
        setPhoto(result.assets[0].uri);
        setFailed(false);
        verifyPhoto(result.assets[0].uri);
      }
    } catch (error) {
      console.log('Camera error:', error);
    }
  };

  const verifyPhoto = async (uri: string) => {
    setVerifying(true);
    try {
      const result = await verifyChallenge(uri, config.verificationType);

      if (result.verified) {
        setVerified(true);
        setVerificationMessage(result.message);
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      } else {
        setFailed(true);
        setVerificationMessage(result.message);
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      }
    } catch (error) {
      // On error, be lenient
      setVerified(true);
      setVerificationMessage(config.successMessage);
    } finally {
      setVerifying(false);
    }
  };

  if (verified) {
    return (
      <View style={{ alignItems: 'center', paddingVertical: spacing.lg }}>
        <Animated.View
          entering={ZoomIn.duration(300).springify()}
          style={{
            width: 100,
            height: 100,
            borderRadius: 50,
            overflow: 'hidden',
            marginBottom: spacing.lg,
            borderWidth: 4,
            borderColor: colors.success,
          }}
        >
          {photo && <Image source={{ uri: photo }} style={{ width: '100%', height: '100%' }} />}
        </Animated.View>
        <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.sm }}>
          {config.successTitle}
        </SerifText>
        <SansText style={{ fontSize: 14, color: colors.textTertiary, marginBottom: spacing.xl, textAlign: 'center' }}>
          {verificationMessage}
        </SansText>
        <Button onPress={onComplete} color={color} size="lg" fullWidth>
          Continue
        </Button>
      </View>
    );
  }

  return (
    <View style={{ alignItems: 'center', paddingVertical: spacing.lg }}>
      {photo && !verifying ? (
        <View
          style={{
            width: 120,
            height: 120,
            borderRadius: 16,
            overflow: 'hidden',
            marginBottom: spacing.lg,
            borderWidth: 3,
            borderColor: failed ? colors.danger : colors.border,
          }}
        >
          <Image source={{ uri: photo }} style={{ width: '100%', height: '100%' }} />
        </View>
      ) : (
        <View
          style={{
            width: 80,
            height: 80,
            borderRadius: 40,
            backgroundColor: `${color}20`,
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: spacing.lg,
          }}
        >
          {verifying ? (
            <ActivityIndicator size="large" color={color} />
          ) : (
            <Ionicons name={config.icon} size={40} color={color} />
          )}
        </View>
      )}

      <SansText
        style={{
          fontSize: 11,
          color: isAIVerificationAvailable() ? colors.success : colors.textMuted,
          textTransform: 'uppercase',
          letterSpacing: 3,
          marginBottom: spacing.sm,
        }}
      >
        {isAIVerificationAvailable() ? 'AI Verified Challenge' : 'Photo Challenge'}
      </SansText>

      <SerifText style={{ fontSize: 24, color: colors.textPrimary, marginBottom: spacing.md, textAlign: 'center' }}>
        {config.title}
      </SerifText>

      {verifying ? (
        <SansText style={{ fontSize: 16, color: color, marginBottom: spacing.lg }}>
          Verifying with AI...
        </SansText>
      ) : failed ? (
        <View style={{ marginBottom: spacing.lg }}>
          <SansText style={{ fontSize: 14, color: colors.danger, textAlign: 'center', marginBottom: spacing.sm }}>
            {verificationMessage}
          </SansText>
          <SansText style={{ fontSize: 13, color: colors.textMuted, textAlign: 'center' }}>
            Try again with a clearer photo.
          </SansText>
        </View>
      ) : (
        <>
          <SansText
            style={{
              fontSize: 14,
              color: colors.textTertiary,
              textAlign: 'center',
              marginBottom: spacing.sm,
            }}
          >
            {config.description}
          </SansText>
          <SansText
            style={{
              fontSize: 13,
              color: colors.textMuted,
              textAlign: 'center',
              marginBottom: spacing.xl,
              fontStyle: 'italic',
            }}
          >
            {config.instruction}
          </SansText>
        </>
      )}

      <View style={{ width: '100%', gap: spacing.sm }}>
        <Button onPress={takePhoto} color={color} size="lg" fullWidth disabled={verifying}>
          {photo ? 'Take Another Photo' : 'Open Camera'}
        </Button>
        <Pressable onPress={onCancel} style={{ padding: spacing.md, alignItems: 'center' }}>
          <SansText style={{ color: colors.textMuted, fontSize: 14 }}>
            Go back to what I was doing
          </SansText>
        </Pressable>
      </View>
    </View>
  );
};

// ==================== MAIN COMPONENT ====================
export function FrictionChallenge({
  level,
  onComplete,
  onCancel,
  themeColor,
}: FrictionChallengeProps) {
  const [challengeType] = useState<ChallengeType>(() => getRandomChallenge(level));

  const renderChallenge = () => {
    switch (challengeType) {
      case 'call_someone':
        return <CallSomeoneChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 'text_loved_one':
        return <TextLovedOneChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 'contact_parent':
        return <ContactParentChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 'go_outside':
        return <GoOutsideChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 'drink_water':
        return <DrinkWaterChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 'gratitude':
        return <GratitudeChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 'intention':
        return <IntentionChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 'wait':
        return <WaitChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 'walk_away':
        return <WalkAwayChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 'deep_breath':
        return <DeepBreathChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      // AI Verified Challenges
      case 'prove_outside':
        return <AIVerifiedChallenge challengeKey="prove_outside" onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 'prove_water':
        return <AIVerifiedChallenge challengeKey="prove_water" onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      case 'prove_standing':
        return <AIVerifiedChallenge challengeKey="prove_standing" onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
      default:
        return <WaitChallenge onComplete={onComplete} onCancel={onCancel} color={themeColor} />;
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
          backgroundColor: colors.background,
          borderRadius: radius['2xl'],
          borderWidth: 1,
          borderColor: colors.border,
          padding: spacing.xl,
          maxHeight: '85%',
        }}
      >
        {renderChallenge()}
      </Animated.View>
    </Animated.View>
  );
}
