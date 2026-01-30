import { GoogleGenerativeAI } from '@google/generative-ai';
import * as FileSystem from 'expo-file-system';

// Initialize Gemini - user needs to add their API key
const API_KEY = process.env.EXPO_PUBLIC_GEMINI_API_KEY || '';

const genAI = API_KEY ? new GoogleGenerativeAI(API_KEY) : null;

export type VerificationType =
  | 'outside' // Verify person is outside
  | 'water' // Verify person is drinking/holding water
  | 'exercise' // Verify person is doing physical activity
  | 'different_room' // Verify person moved to different location
  | 'real_call' // Verify phone call screen
  | 'sunlight' // Verify natural light/outdoors
  | 'standing' // Verify person is standing up
  | 'nature' // Verify outdoor nature scene;

interface VerificationResult {
  verified: boolean;
  confidence: number;
  message: string;
  details?: string;
}

// Convert image URI to base64
async function imageToBase64(imageUri: string): Promise<string> {
  try {
    const base64 = await FileSystem.readAsStringAsync(imageUri, {
      encoding: FileSystem.EncodingType.Base64,
    });
    return base64;
  } catch (error) {
    console.error('Error converting image to base64:', error);
    throw error;
  }
}

// Verification prompts for different challenge types
const VERIFICATION_PROMPTS: Record<VerificationType, string> = {
  outside: `Analyze this image and determine if the person taking the photo is OUTSIDE (outdoors).
Look for: sky, clouds, trees, buildings exterior, streets, grass, natural light, outdoor scenery.
NOT outside: indoor rooms, offices, bedrooms, living rooms, bathrooms.
Respond with JSON: {"verified": true/false, "confidence": 0-100, "reason": "brief explanation"}`,

  water: `Analyze this image and determine if there is a GLASS or BOTTLE of WATER visible, or someone drinking water.
Look for: water bottle, glass of clear liquid, person drinking, water container.
Respond with JSON: {"verified": true/false, "confidence": 0-100, "reason": "brief explanation"}`,

  exercise: `Analyze this image and determine if the person appears to be doing PHYSICAL EXERCISE or just finished exercising.
Look for: exercise pose, workout clothing, gym equipment, stretching, active position, sweaty appearance.
Respond with JSON: {"verified": true/false, "confidence": 0-100, "reason": "brief explanation"}`,

  different_room: `Analyze this image and determine if this appears to be a DIFFERENT LOCATION than where someone would typically use their phone (like a couch or bed).
Look for: standing position, hallway, kitchen, different room, walking, movement.
Respond with JSON: {"verified": true/false, "confidence": 0-100, "reason": "brief explanation"}`,

  real_call: `Analyze this image and determine if it shows a PHONE CALL in progress or someone on a phone call.
Look for: phone to ear, call screen, video call, someone talking on phone.
Respond with JSON: {"verified": true/false, "confidence": 0-100, "reason": "brief explanation"}`,

  sunlight: `Analyze this image and determine if there is NATURAL SUNLIGHT present.
Look for: sun, windows with daylight, outdoor lighting, natural brightness, shadows from sun.
Respond with JSON: {"verified": true/false, "confidence": 0-100, "reason": "brief explanation"}`,

  standing: `Analyze this image and determine if the person taking this photo appears to be STANDING UP.
Look for: standing perspective, vertical angle, floor visible below, not sitting/lying position.
Respond with JSON: {"verified": true/false, "confidence": 0-100, "reason": "brief explanation"}`,

  nature: `Analyze this image and determine if this shows NATURE or an outdoor natural environment.
Look for: trees, plants, grass, sky, parks, gardens, natural scenery, wildlife.
Respond with JSON: {"verified": true/false, "confidence": 0-100, "reason": "brief explanation"}`,
};

// Messages for verified/not verified states
const VERIFICATION_MESSAGES: Record<VerificationType, { success: string; failure: string }> = {
  outside: {
    success: "Confirmed! Fresh air detected. The real world looks good on you.",
    failure: "Hmm, this doesn't look like outside. Step out and try again!",
  },
  water: {
    success: "Hydration confirmed! Your brain thanks you.",
    failure: "I don't see water. Go grab a glass and show me!",
  },
  exercise: {
    success: "Movement detected! Your body thanks you.",
    failure: "I need to see you moving! Show me some action.",
  },
  different_room: {
    success: "New location confirmed! Breaking the scroll position.",
    failure: "Looks like you haven't moved. Walk to another room!",
  },
  real_call: {
    success: "Real connection confirmed! That's what phones are for.",
    failure: "I need to see you making a call. Pick up the phone!",
  },
  sunlight: {
    success: "Natural light detected! Vitamin D incoming.",
    failure: "I don't see sunlight. Find a window or step outside!",
  },
  standing: {
    success: "Standing confirmed! No more couch scrolling.",
    failure: "You need to stand up. Get on your feet!",
  },
  nature: {
    success: "Nature spotted! The algorithm can't compete with this.",
    failure: "I don't see nature. Go find some trees or grass!",
  },
};

export async function verifyChallenge(
  imageUri: string,
  verificationType: VerificationType
): Promise<VerificationResult> {
  // If no API key, always verify (graceful fallback)
  if (!genAI) {
    console.log('No Gemini API key - skipping verification');
    return {
      verified: true,
      confidence: 100,
      message: VERIFICATION_MESSAGES[verificationType].success,
      details: 'Verification skipped (no API key)',
    };
  }

  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    // Convert image to base64
    const imageBase64 = await imageToBase64(imageUri);

    // Create the prompt
    const prompt = VERIFICATION_PROMPTS[verificationType];

    // Send to Gemini
    const result = await model.generateContent([
      {
        inlineData: {
          mimeType: 'image/jpeg',
          data: imageBase64,
        },
      },
      prompt,
    ]);

    const response = await result.response;
    const text = response.text();

    // Parse JSON response
    try {
      // Extract JSON from response (handle markdown code blocks)
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        const verified = parsed.verified === true;
        const confidence = parsed.confidence || 0;

        return {
          verified,
          confidence,
          message: verified
            ? VERIFICATION_MESSAGES[verificationType].success
            : VERIFICATION_MESSAGES[verificationType].failure,
          details: parsed.reason,
        };
      }
    } catch (parseError) {
      console.error('Error parsing Gemini response:', parseError);
    }

    // Fallback if parsing fails - be lenient
    return {
      verified: true,
      confidence: 50,
      message: VERIFICATION_MESSAGES[verificationType].success,
      details: 'Could not parse AI response',
    };
  } catch (error) {
    console.error('Gemini verification error:', error);

    // On error, be lenient and allow
    return {
      verified: true,
      confidence: 0,
      message: VERIFICATION_MESSAGES[verificationType].success,
      details: 'Verification error - allowing challenge',
    };
  }
}

// Check if AI verification is available
export function isAIVerificationAvailable(): boolean {
  return !!API_KEY && !!genAI;
}

// Get a user-friendly message about verification status
export function getVerificationStatusMessage(): string {
  if (isAIVerificationAvailable()) {
    return 'AI verification enabled';
  }
  return 'Add EXPO_PUBLIC_GEMINI_API_KEY to enable AI verification';
}
