# @thanos/config

Shared configuration for the Thanos Promptology project.

## Includes

- ESLint configuration
- TypeScript configuration
- CSS/styling presets

## Usage

### ESLint

In `apps/*/eslintrc.json`:

```json
{
  "extends": ["@thanos/config"]
}
```

### TypeScript

In `apps/*/tsconfig.json`:

```json
{
  "extends": "@thanos/config/tsconfig.base.json"
}
```

## Available Configs

- `tsconfig.base.json` - Base TypeScript configuration
- `tsconfig.react.json` - React/Next.js specific
- `tsconfig.node.json` - Node.js/backend specific
- `eslint.js` - ESLint configuration

## Customization

Each app can extend and override these configs as needed for their specific requirements.
