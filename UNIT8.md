# UNIT 8 — MOBILE & API INTEGRATION PROMPTS

---

## 8.1 Expo React Native Setup

```bash
#!/bin/bash
APP_NAME=$1

# Create Expo app
npx create-expo-app@latest $APP_NAME \
  --template expo-template-blank-typescript

cd $APP_NAME

# Core navigation and UI
npx expo install \
  expo-router \
  react-native-safe-area-context \
  react-native-screens \
  expo-linking \
  expo-constants \
  expo-status-bar

# State, data, auth
pnpm add \
  @tanstack/react-query \
  zustand \
  axios \
  react-hook-form \
  @hookform/resolvers \
  zod

# Storage
npx expo install expo-secure-store expo-file-system

# Notifications
npx expo install expo-notifications expo-device

# NativeWind (Tailwind for RN)
pnpm add nativewind tailwindcss
npx tailwindcss init

echo "✅ Expo app $APP_NAME ready"
```

### Expo Folder Structure

```
app/
├── (tabs)/
│   ├── _layout.tsx      # Tab bar
│   ├── index.tsx        # Home tab
│   ├── explore.tsx
│   └── profile.tsx
├── (auth)/
│   ├── login.tsx
│   └── register.tsx
├── _layout.tsx           # Root layout with providers
├── +not-found.tsx
src/
├── components/
├── hooks/
├── stores/
├── services/
└── types/
```

---

## 8.2 Secure Token Storage (Expo)

```typescript
// src/stores/authStore.ts (Expo version)
import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import * as SecureStore from "expo-secure-store";

const secureStorage = {
  getItem: (key: string) => SecureStore.getItemAsync(key),
  setItem: (key: string, value: string) => SecureStore.setItemAsync(key, value),
  removeItem: (key: string) => SecureStore.deleteItemAsync(key),
};

interface AuthStore {
  token: string | null;
  user: { id: string; name: string; email: string } | null;
  setAuth: (token: string, user: AuthStore["user"]) => void;
  clearAuth: () => void;
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      setAuth: (token, user) => set({ token, user }),
      clearAuth: () => set({ token: null, user: null }),
    }),
    {
      name: "auth",
      storage: createJSONStorage(() => secureStorage),
    }
  )
);
```

---

## 8.3 API Client for React Native

```typescript
// src/services/api.ts
import axios from "axios";
import { useAuthStore } from "../stores/authStore";

const BASE_URL = process.env.EXPO_PUBLIC_API_URL || "http://localhost:3001/api";

export const apiClient = axios.create({
  baseURL: BASE_URL,
  timeout: 10_000,
  headers: { "Content-Type": "application/json" },
});

apiClient.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

apiClient.interceptors.response.use(
  (res) => res.data,
  async (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().clearAuth();
    }
    return Promise.reject(error.response?.data ?? error);
  }
);
```

---

## 8.4 Stripe Payment Integration

```bash
# Backend
npm install stripe
# Frontend
npm install @stripe/stripe-js @stripe/react-stripe-js
# Expo
npx expo install @stripe/stripe-react-native
```

### Backend: Create Payment Intent

```typescript
// src/routes/payments.ts
import Stripe from "stripe";
import { Router } from "express";
import { authenticate } from "../middleware/auth";
import { prisma } from "../lib/db";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: "2024-06-20" });
const router = Router();

router.post("/create-payment-intent", authenticate, async (req, res) => {
  const { amount, currency = "usd", metadata = {} } = req.body;

  const customer = await stripe.customers.create({
    email: req.user!.email,
    metadata: { userId: req.user!.id },
  });

  const paymentIntent = await stripe.paymentIntents.create({
    amount: Math.round(amount * 100), // Convert to cents
    currency,
    customer: customer.id,
    metadata: { ...metadata, userId: req.user!.id },
    automatic_payment_methods: { enabled: true },
  });

  res.json({ clientSecret: paymentIntent.client_secret });
});

// Webhook handler
router.post("/webhook", async (req, res) => {
  const sig = req.headers["stripe-signature"] as string;
  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch {
    return res.status(400).send("Webhook signature verification failed");
  }

  switch (event.type) {
    case "payment_intent.succeeded":
      const pi = event.data.object;
      await prisma.order.update({
        where: { stripePaymentIntentId: pi.id },
        data: { status: "PAID", paidAt: new Date() },
      });
      break;

    case "payment_intent.payment_failed":
      const failedPi = event.data.object;
      await prisma.order.update({
        where: { stripePaymentIntentId: failedPi.id },
        data: { status: "FAILED" },
      });
      break;
  }

  res.json({ received: true });
});

export default router;
```

### Frontend: Stripe Payment Form

```typescript
// components/CheckoutForm.tsx
"use client";

import { useState } from "react";
import { useStripe, useElements, PaymentElement } from "@stripe/react-stripe-js";
import { Button } from "@/components/ui/button";
import { Alert, AlertDescription } from "@/components/ui/alert";

interface CheckoutFormProps {
  onSuccess: () => void;
}

export function CheckoutForm({ onSuccess }: CheckoutFormProps) {
  const stripe = useStripe();
  const elements = useElements();
  const [error, setError] = useState<string | null>(null);
  const [processing, setProcessing] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!stripe || !elements) return;

    setProcessing(true);
    setError(null);

    const { error: submitError } = await stripe.confirmPayment({
      elements,
      confirmParams: {
        return_url: `${window.location.origin}/checkout/success`,
      },
      redirect: "if_required",
    });

    if (submitError) {
      setError(submitError.message ?? "Payment failed");
    } else {
      onSuccess();
    }
    setProcessing(false);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <Alert variant="destructive">
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}
      <PaymentElement />
      <Button type="submit" className="w-full" disabled={!stripe || processing}>
        {processing ? "Processing..." : "Pay now"}
      </Button>
    </form>
  );
}
```

---

## 8.5 Webhook Handler (Generic)

```typescript
// src/middleware/webhook.ts
import crypto from "crypto";
import type { Request, Response, NextFunction } from "express";

export function verifyWebhookSignature(secret: string, headerKey = "x-signature") {
  return (req: Request, res: Response, next: NextFunction) => {
    const signature = req.headers[headerKey] as string;
    if (!signature) return res.status(401).json({ error: "Missing signature" });

    const expected = crypto
      .createHmac("sha256", secret)
      .update(JSON.stringify(req.body))
      .digest("hex");

    const isValid = crypto.timingSafeEqual(
      Buffer.from(signature.replace("sha256=", "")),
      Buffer.from(expected)
    );

    if (!isValid) return res.status(401).json({ error: "Invalid signature" });
    next();
  };
}

// Usage: router.post('/webhook/github', express.json(), verifyWebhookSignature(process.env.GITHUB_WEBHOOK_SECRET!), handler);
```

---

## 8.6 OAuth2 — Google + GitHub Login

```typescript
// NextAuth config (app/api/auth/[...nextauth]/route.ts)
import NextAuth from "next-auth";
import Google from "next-auth/providers/google";
import GitHub from "next-auth/providers/github";
import Credentials from "next-auth/providers/credentials";
import { PrismaAdapter } from "@auth/prisma-adapter";
import { prisma } from "@/lib/db";
import bcrypt from "bcryptjs";

const handler = NextAuth({
  adapter: PrismaAdapter(prisma),
  providers: [
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
    GitHub({
      clientId: process.env.GITHUB_ID!,
      clientSecret: process.env.GITHUB_SECRET!,
    }),
    Credentials({
      credentials: {
        email: { type: "email" },
        password: { type: "password" },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials.password) return null;
        const user = await prisma.user.findUnique({
          where: { email: credentials.email as string },
        });
        if (!user?.password) return null;
        const valid = await bcrypt.compare(credentials.password as string, user.password);
        return valid ? user : null;
      },
    }),
  ],
  callbacks: {
    session: ({ session, token }) => ({
      ...session,
      user: { ...session.user, id: token.sub!, role: token.role as string },
    }),
    jwt: async ({ token, user }) => {
      if (user) {
        const dbUser = await prisma.user.findUnique({ where: { email: user.email! } });
        token.role = dbUser?.role ?? "USER";
      }
      return token;
    },
  },
  pages: { signIn: "/login", error: "/login" },
  session: { strategy: "jwt" },
});

export { handler as GET, handler as POST };
```

---

## 8.7 Push Notifications (Expo)

```typescript
// src/services/notifications.ts (React Native)
import * as Notifications from "expo-notifications";
import * as Device from "expo-device";
import Constants from "expo-constants";
import { apiClient } from "./api";

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export async function registerForPushNotifications(): Promise<string | null> {
  if (!Device.isDevice) {
    console.warn("Push notifications require a physical device");
    return null;
  }

  const { status: existing } = await Notifications.getPermissionsAsync();
  let finalStatus = existing;

  if (existing !== "granted") {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }

  if (finalStatus !== "granted") return null;

  const projectId = Constants.expoConfig?.extra?.eas?.projectId;
  const { data: token } = await Notifications.getExpoPushTokenAsync({ projectId });

  // Register token with backend
  await apiClient.post("/users/push-token", { token });

  return token;
}
```

```typescript
// Backend: Send push notification
// npm install expo-server-sdk

import Expo from "expo-server-sdk";

const expo = new Expo();

export async function sendPushNotification(
  pushToken: string,
  { title, body, data }: { title: string; body: string; data?: object }
) {
  if (!Expo.isExpoPushToken(pushToken)) return;

  const chunks = expo.chunkPushNotifications([{
    to: pushToken,
    sound: "default",
    title,
    body,
    data,
  }]);

  for (const chunk of chunks) {
    await expo.sendPushNotificationsAsync(chunk);
  }
}
```
