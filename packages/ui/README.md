# @thanos/ui

Shared UI component library for the Thanos Promptology project.

## Usage

Import components from the UI package:

```tsx
import { Button, Card, Dialog } from '@thanos/ui';
```

## Project Structure

- `components/` - Reusable components
- `hooks/` - Shared hooks
- `styles/` - Component styles
- `types/` - TypeScript types

## Available Components

- Button
- Card
- Dialog
- Form
- Input
- Select
- Table
- Tabs

## Scripts

- `pnpm build` - Build the component library
- `pnpm dev` - Watch mode
- `pnpm lint` - Run ESLint
- `pnpm type-check` - Type check

## Contributing

When adding new components:

1. Create component in `src/components/`
2. Add TypeScript types
3. Export from index file
4. Build and test
