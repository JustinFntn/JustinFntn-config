---
applyTo: "**/*.tsx,**/*.jsx,**/*.ts,**/*.js,**/next.config.*,src/app/**"
description: "Development instructions for React + Next.js (App Router) projects using TypeScript, focused on consistency, performance, security, and DX."
---

# React + Next.js Development Instructions

Authoritative, actionable rules for writing consistent, secure, and performant code in Next.js (App Router) with React and TypeScript. Rules use MUST/SHOULD/COULD and include rationale and examples.

## Table of Contents

- Code Style & Formatting
- Best Practices
- Forbidden Practices
- Project Structure
- Dependencies & Tools
- Code Examples

---

## Code Style & Formatting

- MUST: Use 2 spaces for indentation; no tabs. Max line length 100 chars.
- MUST: Always use semicolons; single quotes for JS/TS, double quotes for JSON; prefer template literals for string interpolation.
- MUST: Enable TypeScript strict mode and noImplicitAny.
- MUST: Naming conventions:
  - camelCase for variables and functions
  - PascalCase for React components and classes
  - UPPER_SNAKE_CASE for global constants
  - File names: PascalCase for React components (e.g., `UserCard.tsx`), kebab-case for utilities (`date-utils.ts`)
- SHOULD: Write intention-revealing names (e.g., `fetchUserById`, not `doRequest`).
- SHOULD: Use TSDoc for public APIs, shared utilities, and complex functions.
- SHOULD: Keep JSX props on multiple lines when more than 2–3 props for readability.
- SHOULD: Keep imports ordered: external packages, then internal aliases, styles last. Alphabetize within groups.
- SHOULD: Prefer named exports; avoid default exports unless the file has a single obvious export.
- COULD: Use trailing commas in multi-line objects/arrays to minimize diffs.

Rationale: A consistent, predictable style improves readability, reduces merge conflicts, and speeds up reviews.

---

## Best Practices

### Architecture & App Router

- MUST: Use the App Router (`src/app`) and React Server Components (RSC) by default.
- MUST: Separate server-only code (data access, secrets) from client-only code (interactivity, browser APIs).
- SHOULD: Keep components small and focused; extract logic into `@/lib`.
- COULD: Organize by feature as the codebase grows.

### Server vs Client Components

- MUST: Files are Server Components by default. Add `"use client"` only when you need client interactivity/state.
- MUST: Secrets and privileged operations must run on the server (RSC, route handlers). Never ship secrets to the browser.
- SHOULD: Do data fetching in server components or route handlers and pass minimal serializable props to client components.
- COULD: Use client “islands” for interactive pieces within server-rendered pages.

### Data Fetching, Caching, Revalidation

- MUST: Use `fetch()` on the server with Next.js caching/revalidation options.
  - Use `next: { revalidate: <seconds> }` for ISR; use `{ cache: 'no-store' }` for dynamic SSR.
- SHOULD: Factor `fetch` helpers into `@/lib/data`. Handle timeouts, retries, and typed errors for third-party calls.
- COULD: Use `noStore()` to disable caching for sensitive/dynamic paths.

### Error Handling

- MUST: Provide `error.tsx` and `not-found.tsx` for critical segments.
- MUST: In API routes, catch errors and return typed responses with proper HTTP status codes.
- SHOULD: Log errors with context (Sentry or console in dev). Include correlation IDs where possible.
- COULD: Provide user-facing retry/fallback UIs for transient failures.

### Performance

- MUST: Use `next/image` with correct sizes and domains; use `next/font` for fonts.
- MUST: Avoid `"use client"` unless strictly required; push logic to RSC when possible.
- SHOULD: Use `React.memo`, `useMemo`, and `useCallback` in heavy client trees to avoid unnecessary re-renders.
- SHOULD: Use `next/dynamic` for large client components; leverage `Suspense`/streaming for faster TTFB.
- COULD: Prefetch navigation with `<Link prefetch />` and selective data prefetching.

### Security

- MUST: Never expose secrets in client bundles. Only expose values prefixed with `NEXT_PUBLIC_` if absolutely necessary.
- MUST: Validate and sanitize inputs (APIs and forms). Avoid `dangerouslySetInnerHTML`; if needed, sanitize strictly.
- MUST: Configure security headers (CSP, X-Frame-Options, etc.) via `headers()` or reverse proxy.
- SHOULD: Use `middleware.ts` for lightweight auth, rate limiting, and guards.
- SHOULD: Prefer `HttpOnly` cookies over `localStorage` for tokens.
- COULD: Add monitoring/alerting (e.g., Sentry) for error and performance telemetry.

### Testing

- MUST: Unit tests for core logic with Vitest/Jest and React Testing Library for components.
- SHOULD: End-to-end tests with Playwright on critical flows.
- SHOULD: Maintain at least 80% coverage on critical domains; avoid globally strict thresholds that block progress.
- COULD: Contract tests for external APIs (e.g., with Mock Service Worker).

Rationale: Leveraging RSC, proper caching, and strict security yields better performance, safety, and maintainability.

---

## Forbidden Practices

- MUST NOT: Fetch sensitive data or use API keys on the client.
- MUST NOT: Blanket `"use client"` in entire routes/segments unless necessary.
- MUST NOT: Use `dangerouslySetInnerHTML` without thorough sanitization.
- MUST NOT: Store tokens in `localStorage`/`sessionStorage`.
- SHOULD NOT: Create large React contexts that trigger broad re-renders.
- SHOULD NOT: Overuse `useEffect` for data fetching when a server component or API route is more appropriate.
- SHOULD NOT: Mix server and client exports in a single barrel file.

---

## Project Structure

Recommended layout:

```
src/
  app/
    layout.tsx
    page.tsx
    error.tsx
    not-found.tsx
    api/
      hello/route.ts
  components/
  features/
  hooks/
  lib/
    data/
    server/
    utils/
  styles/
  types/
  tests/
    unit/
    e2e/
public/
```

Principles:
- MUST: Use path aliases (e.g., `@/*`).
- SHOULD: Isolate server-only code using `import 'server-only'` and `lib/server`.
- SHOULD: One component per file; use `index.ts` barrels only within homogeneous boundaries (client-only or server-only).

---

## Dependencies & Tools

- TypeScript: MUST enable `strict`. Keep `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` as project needs dictate.
- ESLint: MUST use `next/core-web-vitals`. Add import sorting, hooks rules, and sonarjs if desired.
- Prettier: MUST be the sole formatter. Resolve ESLint conflicts with a Prettier config/plugin.
- Testing: Vitest/Jest + React Testing Library; Playwright for e2e.
- Git hooks: Husky + lint-staged to run format/lint/tests on staged files.
- Commits: Conventional Commits + commitlint (SHOULD) for consistent history.
- Performance: Use `next/image`, `next/font`, and `next/dynamic` appropriately.
- Security: Consider Sentry/Helmet; configure CSP via `headers()`.
- Deployment: Prefer Vercel; otherwise Docker with `output: 'standalone'`.

Build & Deployment:
- SHOULD: Configure `next.config.ts` (images.domains, headers, redirects). Avoid experimental flags in production unless necessary.
- SHOULD: Provide `.env.example` documenting all environment variables.
- COULD: Enable `swcMinify`; build as standalone for container images.

---

## Code Examples

### Good: Server Component with ISR

```tsx
// src/app/page.tsx
import { getWeather } from '@/lib/data/weather';

export const revalidate = 600;

export default async function HomePage() {
  const data = await getWeather('Paris');
  return (
    <main>
      <h1>Weather</h1>
      <p>{data.summary}</p>
    </main>
  );
}
```

```ts
// src/lib/data/weather.ts
import 'server-only';

export async function getWeather(city: string) {
  const res = await fetch(`${process.env.WEATHER_API}/forecast?city=${encodeURIComponent(city)}`, {
    next: { revalidate: 600 },
  });
  if (!res.ok) throw new Error('Weather API error');
  return res.json() as Promise<{ summary: string }>;
}
```

Why: Fetches on the server, leverages ISR, and avoids exposing secrets.

### Good: Client Component boundary

```tsx
// src/components/SearchBox.tsx
'use client';
import { useState } from 'react';

export function SearchBox({ onSubmit }: { onSubmit: (q: string) => void }) {
  const [q, setQ] = useState('');
  return (
    <form onSubmit={(e) => { e.preventDefault(); onSubmit(q.trim()); }}>
      <input value={q} onChange={(e) => setQ(e.target.value)} />
      <button type="submit">Search</button>
    </form>
  );
}
```

```tsx
// src/app/search/page.tsx
import { SearchBox } from '@/components/SearchBox';

export default function SearchPage() {
  async function submit(q: string) {
    'use server';
    // server-side action
  }
  return (
    <div>
      <h1>Search</h1>
      <SearchBox onSubmit={submit} />
    </div>
  );
}
```

Why: Limits client code to where interactivity is needed; uses server actions for side effects.

### Good: API Route with error handling

```ts
// src/app/api/weather/route.ts
import { NextResponse } from 'next/server';
import { getWeather } from '@/lib/data/weather';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const city = searchParams.get('city') ?? 'Paris';
  try {
    const data = await getWeather(city);
    return NextResponse.json(data, { status: 200 });
  } catch (err) {
    return NextResponse.json({ error: 'Failed to fetch' }, { status: 502 });
  }
}
```

### Bad: Client-only fetching with secret

```tsx
// DO NOT DO THIS
'use client';
export default function Page() {
  // Leaks secrets; no caching; blocks render.
  fetch(`https://api.example.com?key=${process.env.SECRET_KEY}`);
  return null;
}
```

Why avoid: Ships secrets to the browser and misses server-side caching/revalidation.

---

By following these rules, Copilot can propose code that matches your standards for Next.js + React projects and keeps your codebase secure, fast, and maintainable.
