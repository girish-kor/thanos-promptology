# UNIT 7 — REAL-TIME SYSTEMS IMPLEMENTATION PROMPTS

---

## 7.1 Thanos Prompt — Real-Time Chat System

```
Build a complete real-time chat system.

Stack: Node.js + Socket.io + Redis (Pub/Sub) + Prisma + Next.js
Scale: Multi-server (Socket.io with Redis adapter)

Generate:
1. Socket.io server setup with Redis adapter
2. Auth middleware for socket connections (JWT)
3. Room-based chat (channels/rooms)
4. Message persistence (Prisma)
5. Online presence tracking (Redis)
6. React hooks: useSocket, useChat, usePresence
7. ChatRoom React component
8. Message list with optimistic updates
9. Typing indicators

Events:
  Client → Server: join_room, leave_room, send_message, typing_start, typing_stop
  Server → Client: new_message, user_joined, user_left, typing, message_deleted

Include: reconnection handling, message pagination, unread count
```

---

## 7.2 Socket.io Server Setup

```bash
npm install socket.io @socket.io/redis-adapter ioredis
```

```typescript
// src/socket/index.ts
import { Server, Socket } from "socket.io";
import { createClient } from "redis";
import { createAdapter } from "@socket.io/redis-adapter";
import http from "http";
import jwt from "jsonwebtoken";
import { prisma } from "../lib/db";

interface AuthSocket extends Socket {
  userId?: string;
  userName?: string;
}

export async function initSocket(httpServer: http.Server) {
  const pubClient = createClient({ url: process.env.REDIS_URL });
  const subClient = pubClient.duplicate();
  await Promise.all([pubClient.connect(), subClient.connect()]);

  const io = new Server(httpServer, {
    cors: { origin: process.env.FRONTEND_URL, credentials: true },
    adapter: createAdapter(pubClient, subClient),
  });

  // Auth middleware
  io.use(async (socket: AuthSocket, next) => {
    const token = socket.handshake.auth.token as string;
    if (!token) return next(new Error("Authentication required"));

    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET!) as { id: string; name: string };
      socket.userId = payload.id;
      socket.userName = payload.name;
      await pubClient.hSet("online_users", payload.id, socket.id);
      next();
    } catch {
      next(new Error("Invalid token"));
    }
  });

  io.on("connection", (socket: AuthSocket) => {
    console.log(`User ${socket.userId} connected`);

    // Join room
    socket.on("join_room", async ({ roomId }: { roomId: string }) => {
      await socket.join(roomId);

      // Load last 50 messages
      const messages = await prisma.message.findMany({
        where: { roomId, deletedAt: null },
        include: { author: { select: { id: true, name: true, image: true } } },
        orderBy: { createdAt: "asc" },
        take: 50,
      });

      socket.emit("room_history", messages);
      socket.to(roomId).emit("user_joined", {
        userId: socket.userId,
        name: socket.userName,
      });
    });

    // Send message
    socket.on("send_message", async ({ roomId, content }: { roomId: string; content: string }) => {
      if (!content.trim() || !socket.userId) return;

      const message = await prisma.message.create({
        data: { content: content.trim(), roomId, authorId: socket.userId },
        include: { author: { select: { id: true, name: true, image: true } } },
      });

      io.to(roomId).emit("new_message", message);
    });

    // Typing indicators
    socket.on("typing_start", ({ roomId }: { roomId: string }) => {
      socket.to(roomId).emit("typing", { userId: socket.userId, name: socket.userName, isTyping: true });
    });

    socket.on("typing_stop", ({ roomId }: { roomId: string }) => {
      socket.to(roomId).emit("typing", { userId: socket.userId, name: socket.userName, isTyping: false });
    });

    // Disconnect
    socket.on("disconnect", async () => {
      if (socket.userId) {
        await pubClient.hDel("online_users", socket.userId);
        io.emit("user_offline", { userId: socket.userId });
      }
    });
  });

  return io;
}
```

---

## 7.3 React Socket Hook

```typescript
// hooks/useSocket.ts
import { useEffect, useRef, useCallback } from "react";
import { io, type Socket } from "socket.io-client";
import { useAuthStore } from "@/stores/authStore";

let socketInstance: Socket | null = null;

export function useSocket() {
  const { accessToken } = useAuthStore();
  const socketRef = useRef<Socket | null>(null);

  useEffect(() => {
    if (!accessToken) return;
    if (!socketInstance) {
      socketInstance = io(process.env.NEXT_PUBLIC_WS_URL!, {
        auth: { token: accessToken },
        transports: ["websocket"],
        reconnectionAttempts: 5,
        reconnectionDelay: 1000,
      });
    }
    socketRef.current = socketInstance;

    return () => {
      // Don't disconnect on component unmount — maintain singleton
    };
  }, [accessToken]);

  const emit = useCallback(<T>(event: string, data?: T) => {
    socketRef.current?.emit(event, data);
  }, []);

  const on = useCallback(<T>(event: string, handler: (data: T) => void) => {
    socketRef.current?.on(event, handler);
    return () => socketRef.current?.off(event, handler);
  }, []);

  return { socket: socketRef.current, emit, on };
}
```

```typescript
// hooks/useChat.ts
import { useState, useEffect, useCallback, useRef } from "react";
import { useSocket } from "./useSocket";

interface Message {
  id: string;
  content: string;
  authorId: string;
  author: { id: string; name: string; image?: string };
  createdAt: string;
}

interface TypingUser { userId: string; name: string; }

export function useChat(roomId: string) {
  const { emit, on } = useSocket();
  const [messages, setMessages] = useState<Message[]>([]);
  const [typingUsers, setTypingUsers] = useState<TypingUser[]>([]);
  const typingTimeout = useRef<NodeJS.Timeout>();

  useEffect(() => {
    emit("join_room", { roomId });

    const offHistory = on<Message[]>("room_history", (msgs) => setMessages(msgs));
    const offNew = on<Message>("new_message", (msg) =>
      setMessages((prev) => [...prev, msg])
    );
    const offTyping = on<TypingUser & { isTyping: boolean }>("typing", ({ userId, name, isTyping }) => {
      setTypingUsers((prev) =>
        isTyping
          ? [...prev.filter((u) => u.userId !== userId), { userId, name }]
          : prev.filter((u) => u.userId !== userId)
      );
    });

    return () => { offHistory(); offNew(); offTyping(); };
  }, [roomId]);

  const sendMessage = useCallback((content: string) => {
    emit("send_message", { roomId, content });
  }, [roomId]);

  const handleTyping = useCallback(() => {
    emit("typing_start", { roomId });
    clearTimeout(typingTimeout.current);
    typingTimeout.current = setTimeout(() => {
      emit("typing_stop", { roomId });
    }, 1500);
  }, [roomId]);

  return { messages, typingUsers, sendMessage, handleTyping };
}
```

---

## 7.4 Server-Sent Events (SSE) — Live Notifications

```typescript
// src/routes/notifications.ts
import { Router, type Request, type Response } from "express";
import { authenticate } from "../middleware/auth";
import { pubClient } from "../lib/redis";

const router = Router();

router.get("/stream", authenticate, async (req: Request, res: Response) => {
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.flushHeaders();

  const userId = req.user!.id;
  const channel = `notifications:${userId}`;

  // Send heartbeat every 30s to prevent timeout
  const heartbeat = setInterval(() => {
    res.write(`: heartbeat\n\n`);
  }, 30_000);

  // Subscribe to user-specific channel
  const subscriber = pubClient.duplicate();
  await subscriber.connect();
  await subscriber.subscribe(channel, (message) => {
    res.write(`data: ${message}\n\n`);
  });

  req.on("close", async () => {
    clearInterval(heartbeat);
    await subscriber.unsubscribe(channel);
    await subscriber.disconnect();
    res.end();
  });
});

// Publish notification (call from anywhere in the app)
export async function pushNotification(userId: string, notification: {
  type: string;
  title: string;
  message: string;
  data?: unknown;
}) {
  await pubClient.publish(
    `notifications:${userId}`,
    JSON.stringify({ ...notification, timestamp: Date.now() })
  );
}

export default router;
```

```typescript
// hooks/useNotifications.ts (React)
import { useEffect, useCallback } from "react";
import { useAuthStore } from "@/stores/authStore";
import toast from "react-hot-toast";

export function useNotifications() {
  const { accessToken } = useAuthStore();

  useEffect(() => {
    if (!accessToken) return;

    const es = new EventSource(
      `${process.env.NEXT_PUBLIC_API_URL}/notifications/stream`,
      { withCredentials: true }
    );

    es.onmessage = (event) => {
      const notification = JSON.parse(event.data);
      toast(notification.message, { icon: "🔔" });
    };

    es.onerror = () => es.close();

    return () => es.close();
  }, [accessToken]);
}
```

---

## 7.5 Redis Pub/Sub Pattern

```typescript
// src/lib/pubsub.ts
import { Redis } from "ioredis";

const publisher = new Redis(process.env.REDIS_URL!);
const subscriber = new Redis(process.env.REDIS_URL!);

type Handler = (data: unknown) => void;
const handlers = new Map<string, Set<Handler>>();

subscriber.on("message", (channel, message) => {
  const channelHandlers = handlers.get(channel);
  if (!channelHandlers) return;
  const data = JSON.parse(message);
  channelHandlers.forEach((fn) => fn(data));
});

export const pubsub = {
  async publish(channel: string, data: unknown) {
    await publisher.publish(channel, JSON.stringify(data));
  },

  async subscribe(channel: string, handler: Handler) {
    if (!handlers.has(channel)) {
      handlers.set(channel, new Set());
      await subscriber.subscribe(channel);
    }
    handlers.get(channel)!.add(handler);

    return async () => {
      handlers.get(channel)?.delete(handler);
      if (handlers.get(channel)?.size === 0) {
        handlers.delete(channel);
        await subscriber.unsubscribe(channel);
      }
    };
  },
};

// Usage
// await pubsub.publish("orders:created", { orderId: "123", userId: "u1" });
// const unsub = await pubsub.subscribe("orders:created", (data) => console.log(data));
```

---

## 7.6 Real-Time Dashboard — Live Metrics

```typescript
// components/LiveMetrics.tsx
"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

interface Metric { activeUsers: number; requestsPerMin: number; errorRate: number; }

export function LiveMetrics() {
  const [metrics, setMetrics] = useState<Metric | null>(null);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    const es = new EventSource("/api/metrics/stream");

    es.onopen = () => setConnected(true);
    es.onmessage = (e) => setMetrics(JSON.parse(e.data));
    es.onerror = () => { setConnected(false); es.close(); };

    return () => es.close();
  }, []);

  return (
    <div className="grid grid-cols-3 gap-4">
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">
            Active Users {connected && <span className="text-green-500 ml-1">●</span>}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <span className="text-3xl font-bold">{metrics?.activeUsers ?? "—"}</span>
        </CardContent>
      </Card>
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Req/min</CardTitle>
        </CardHeader>
        <CardContent>
          <span className="text-3xl font-bold">{metrics?.requestsPerMin ?? "—"}</span>
        </CardContent>
      </Card>
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Error Rate</CardTitle>
        </CardHeader>
        <CardContent>
          <span className="text-3xl font-bold">{metrics?.errorRate ? `${metrics.errorRate}%` : "—"}</span>
        </CardContent>
      </Card>
    </div>
  );
}
```
