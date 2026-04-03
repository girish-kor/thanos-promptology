# UNIT 3 — FRONTEND RAPID PROTOTYPING PROMPTS

---

## 3.1 Thanos Prompt — Generate Complete Next.js Page

```
Stack: Next.js 14 App Router + TypeScript + Tailwind CSS + shadcn/ui
Generate: app/dashboard/page.tsx — a full admin dashboard page

Requirements:
- Stats row: 4 metric cards (users, revenue, orders, conversion rate)
- Data table: paginated, sortable, with search input
- Quick actions sidebar
- Breadcrumb navigation
- All data from mock/placeholder — no real API calls yet
- Fully responsive (mobile-first)
- Use shadcn/ui: Card, Table, Button, Input, Badge, DropdownMenu
- TypeScript interfaces for all data shapes
- No "any" types

Output: Single complete file. Production-ready.
```

### Dashboard Component (Ready-to-use)

```typescript
// app/dashboard/page.tsx
import { Suspense } from "react";
import { StatsGrid } from "@/components/dashboard/StatsGrid";
import { DataTable } from "@/components/dashboard/DataTable";
import { DashboardSkeleton } from "@/components/dashboard/DashboardSkeleton";

export default function DashboardPage() {
  return (
    <div className="flex flex-col gap-6 p-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">Welcome back, here's what's happening.</p>
      </div>
      <Suspense fallback={<DashboardSkeleton />}>
        <StatsGrid />
        <DataTable />
      </Suspense>
    </div>
  );
}
```

---

## 3.2 Authentication UI Scaffold

```bash
# Prompt to generate all auth pages at once:
```

```
Generate all authentication pages for a Next.js 14 App Router app.

Stack: Next.js 14 + TypeScript + Tailwind + shadcn/ui + react-hook-form + zod

Files to generate:
1. app/(auth)/login/page.tsx
2. app/(auth)/register/page.tsx
3. app/(auth)/forgot-password/page.tsx
4. app/(auth)/reset-password/page.tsx
5. app/(auth)/layout.tsx — centered layout with logo
6. lib/validators/auth.ts — Zod schemas
7. hooks/useAuth.ts — auth state and actions

Each page must have:
- Form with react-hook-form + zodResolver
- Loading state on submit button
- Error message display
- Success redirect
- Link to other auth pages
- Accessible (labels, aria)

Use shadcn/ui: Form, FormField, FormControl, FormMessage, Input, Button, Card
```

### Zod Auth Validators

```typescript
// lib/validators/auth.ts
import { z } from "zod";

export const loginSchema = z.object({
  email: z.string().email("Invalid email address"),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

export const registerSchema = z
  .object({
    name: z.string().min(2, "Name must be at least 2 characters"),
    email: z.string().email("Invalid email address"),
    password: z
      .string()
      .min(8)
      .regex(/[A-Z]/, "Must contain uppercase")
      .regex(/[0-9]/, "Must contain number"),
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords don't match",
    path: ["confirmPassword"],
  });

export const forgotPasswordSchema = z.object({
  email: z.string().email("Invalid email address"),
});

export const resetPasswordSchema = z
  .object({
    password: z.string().min(8),
    confirmPassword: z.string(),
    token: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords don't match",
    path: ["confirmPassword"],
  });

export type LoginInput = z.infer<typeof loginSchema>;
export type RegisterInput = z.infer<typeof registerSchema>;
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;
```

### Login Page

```typescript
// app/(auth)/login/page.tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { signIn } from "next-auth/react";
import Link from "next/link";
import { loginSchema, type LoginInput } from "@/lib/validators/auth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Alert, AlertDescription } from "@/components/ui/alert";

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);

  const form = useForm<LoginInput>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "" },
  });

  const onSubmit = async (data: LoginInput) => {
    setError(null);
    const result = await signIn("credentials", {
      email: data.email,
      password: data.password,
      redirect: false,
    });

    if (result?.error) {
      setError("Invalid email or password");
      return;
    }

    router.push("/dashboard");
    router.refresh();
  };

  return (
    <Card className="w-full max-w-md">
      <CardHeader>
        <CardTitle>Welcome back</CardTitle>
        <CardDescription>Sign in to your account</CardDescription>
      </CardHeader>
      <CardContent>
        {error && (
          <Alert variant="destructive" className="mb-4">
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="email"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Email</FormLabel>
                  <FormControl>
                    <Input type="email" placeholder="you@example.com" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="password"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Password</FormLabel>
                  <FormControl>
                    <Input type="password" placeholder="••••••••" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <Button type="submit" className="w-full" disabled={form.formState.isSubmitting}>
              {form.formState.isSubmitting ? "Signing in..." : "Sign in"}
            </Button>
          </form>
        </Form>
        <div className="mt-4 text-center text-sm">
          <Link href="/forgot-password" className="text-primary hover:underline">
            Forgot password?
          </Link>
          {" · "}
          <Link href="/register" className="text-primary hover:underline">
            Create account
          </Link>
        </div>
      </CardContent>
    </Card>
  );
}
```

---

## 3.3 Reusable Data Table

```typescript
// components/DataTable.tsx
"use client";

import { useState } from "react";
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  type ColumnDef,
  type SortingState,
  flexRender,
} from "@tanstack/react-table";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from "@/components/ui/table";
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight } from "lucide-react";

interface DataTableProps<TData, TValue> {
  columns: ColumnDef<TData, TValue>[];
  data: TData[];
  searchKey?: string;
}

export function DataTable<TData, TValue>({
  columns, data, searchKey,
}: DataTableProps<TData, TValue>) {
  const [sorting, setSorting] = useState<SortingState>([]);
  const [globalFilter, setGlobalFilter] = useState("");

  const table = useReactTable({
    data,
    columns,
    state: { sorting, globalFilter },
    onSortingChange: setSorting,
    onGlobalFilterChange: setGlobalFilter,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    initialState: { pagination: { pageSize: 10 } },
  });

  return (
    <div className="space-y-4">
      {searchKey && (
        <Input
          placeholder="Search..."
          value={globalFilter}
          onChange={(e) => setGlobalFilter(e.target.value)}
          className="max-w-sm"
        />
      )}
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((hg) => (
              <TableRow key={hg.id}>
                {hg.headers.map((header) => (
                  <TableHead
                    key={header.id}
                    onClick={header.column.getToggleSortingHandler()}
                    className={header.column.getCanSort() ? "cursor-pointer select-none" : ""}
                  >
                    {flexRender(header.column.columnDef.header, header.getContext())}
                    {{ asc: " ↑", desc: " ↓" }[header.column.getIsSorted() as string] ?? null}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow key={row.id}>
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={columns.length} className="text-center text-muted-foreground py-8">
                  No results found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          Page {table.getState().pagination.pageIndex + 1} of {table.getPageCount()}
        </p>
        <div className="flex gap-1">
          {[
            { Icon: ChevronsLeft, fn: () => table.setPageIndex(0), disabled: !table.getCanPreviousPage() },
            { Icon: ChevronLeft, fn: () => table.previousPage(), disabled: !table.getCanPreviousPage() },
            { Icon: ChevronRight, fn: () => table.nextPage(), disabled: !table.getCanNextPage() },
            { Icon: ChevronsRight, fn: () => table.setPageIndex(table.getPageCount() - 1), disabled: !table.getCanNextPage() },
          ].map(({ Icon, fn, disabled }, i) => (
            <Button key={i} variant="outline" size="icon" onClick={fn} disabled={disabled}>
              <Icon className="h-4 w-4" />
            </Button>
          ))}
        </div>
      </div>
    </div>
  );
}
```

---

## 3.4 React Query API Hook Generator

```typescript
// hooks/usePosts.ts
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import type { Post, CreatePostInput, UpdatePostInput } from "@/types/post";

const QUERY_KEY = "posts";

export function usePosts(params?: { page?: number; limit?: number }) {
  return useQuery({
    queryKey: [QUERY_KEY, params],
    queryFn: () => api.get<{ posts: Post[]; total: number }>("/posts", { params }),
    staleTime: 30_000,
  });
}

export function usePost(id: string) {
  return useQuery({
    queryKey: [QUERY_KEY, id],
    queryFn: () => api.get<Post>(`/posts/${id}`),
    enabled: !!id,
  });
}

export function useCreatePost() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreatePostInput) => api.post<Post>("/posts", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] }),
  });
}

export function useUpdatePost() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: UpdatePostInput & { id: string }) =>
      api.patch<Post>(`/posts/${id}`, data),
    onSuccess: (_, { id }) => {
      qc.invalidateQueries({ queryKey: [QUERY_KEY] });
      qc.invalidateQueries({ queryKey: [QUERY_KEY, id] });
    },
  });
}

export function useDeletePost() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/posts/${id}`),
    onMutate: async (id) => {
      await qc.cancelQueries({ queryKey: [QUERY_KEY] });
      const prev = qc.getQueryData([QUERY_KEY]);
      qc.setQueryData([QUERY_KEY], (old: any) => ({
        ...old,
        posts: old?.posts?.filter((p: Post) => p.id !== id),
      }));
      return { prev };
    },
    onError: (_, __, ctx) => qc.setQueryData([QUERY_KEY], ctx?.prev),
    onSettled: () => qc.invalidateQueries({ queryKey: [QUERY_KEY] }),
  });
}
```

---

## 3.5 Zustand Store Template

```typescript
// stores/authStore.ts
import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";

interface User {
  id: string;
  email: string;
  name: string;
  role: "USER" | "ADMIN";
}

interface AuthStore {
  user: User | null;
  accessToken: string | null;
  isAuthenticated: boolean;
  setUser: (user: User, token: string) => void;
  clearUser: () => void;
  updateUser: (data: Partial<User>) => void;
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set) => ({
      user: null,
      accessToken: null,
      isAuthenticated: false,
      setUser: (user, accessToken) =>
        set({ user, accessToken, isAuthenticated: true }),
      clearUser: () =>
        set({ user: null, accessToken: null, isAuthenticated: false }),
      updateUser: (data) =>
        set((state) => ({
          user: state.user ? { ...state.user, ...data } : null,
        })),
    }),
    {
      name: "auth-storage",
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({ user: state.user, accessToken: state.accessToken }),
    }
  )
);
```

---

## 3.6 API Client Setup

```typescript
// lib/api.ts
import axios, { type AxiosRequestConfig } from "axios";
import { useAuthStore } from "@/stores/authStore";

const baseURL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001/api";

export const apiClient = axios.create({ baseURL, withCredentials: true });

apiClient.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

apiClient.interceptors.response.use(
  (res) => res.data,
  async (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().clearUser();
      window.location.href = "/login";
    }
    return Promise.reject(error.response?.data ?? error);
  }
);

export const api = {
  get: <T>(url: string, config?: AxiosRequestConfig) =>
    apiClient.get<never, T>(url, config),
  post: <T>(url: string, data?: unknown, config?: AxiosRequestConfig) =>
    apiClient.post<never, T>(url, data, config),
  put: <T>(url: string, data?: unknown, config?: AxiosRequestConfig) =>
    apiClient.put<never, T>(url, data, config),
  patch: <T>(url: string, data?: unknown, config?: AxiosRequestConfig) =>
    apiClient.patch<never, T>(url, data, config),
  delete: <T>(url: string, config?: AxiosRequestConfig) =>
    apiClient.delete<never, T>(url, config),
};
```
