# View + Page Templates

## View Component
```typescript
// src/presentation/features/[feature]/[Feature]View.tsx
'use client';
import { useDI } from '@/di/DIContext';
import { use[Feature]ViewModel } from './use[Feature]ViewModel';

export function [Feature]View() {
  const { [verbFeature]UseCase } = useDI();
  const { data, isLoading, isError, errorMessage } = use[Feature]ViewModel({ [verbFeature]UseCase });

  if (isLoading) return <div>Loading...</div>;
  if (isError) return <div>{errorMessage ?? 'Something went wrong'}</div>;

  return (
    <div>
      {/* render data */}
    </div>
  );
}
```

## App Router Page (Server Component)
```typescript
// src/app/[route]/page.tsx
import { [Feature]View } from '@/presentation/features/[feature]/[Feature]View';

export default function [Feature]Page() {
  return <[Feature]View />;
}
```

## Route constant
```typescript
// src/presentation/navigation/routes.ts — add:
[feature]: '/[route]',
```
