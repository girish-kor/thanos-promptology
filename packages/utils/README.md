# @thanos/utils

Shared utility functions for Thanos Promptology.

## Usage

```tsx
import { formatDate, parseJSON, debounce } from '@thanos/utils';
```

## Available Utilities

### String Utilities
- `capitalize(str)` - Capitalize first letter
- `slugify(str)` - Convert to URL-friendly slug
- `truncate(str, length)` - Truncate string with ellipsis

### Date Utilities
- `formatDate(date, format)` - Format date
- `getRelativeTime(date)` - Get relative time (e.g., "2 hours ago")
- `isToday(date)` - Check if date is today

### API Utilities
- `createApiClient(baseURL)` - Create Axios instance
- `handleApiError(error)` - Standardize error handling

### Function Utilities
- `debounce(fn, delay)` - Debounce function
- `throttle(fn, delay)` - Throttle function
- `retry(fn, maxAttempts)` - Retry failed promise

### Type Utilities
- `parseJSON(str)` - Safe JSON parsing
- `isEmail(str)` - Email validation

## Scripts

- `pnpm build` - Build the utilities library
- `pnpm dev` - Watch mode
- `pnpm lint` - Run ESLint

## Contributing

Add new utilities in `src/` and export from `src/index.ts`.

Include TypeScript types for all functions.
