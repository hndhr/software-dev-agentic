# ViewModel Hook Templates

## TanStack Query pattern (external API)
```typescript
'use client';
import { useQuery } from '@tanstack/react-query';
import type { [Verb][Feature]UseCase } from '@/domain/use-cases/[feature]/[Verb][Feature]UseCase';

interface [Feature]ViewModelDeps {
  [verbFeature]UseCase: [Verb][Feature]UseCase;
}

export function use[Feature]ViewModel({ [verbFeature]UseCase }: [Feature]ViewModelDeps) {
  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['[feature]'],
    queryFn: () => [verbFeature]UseCase.execute({ /* params */ }),
  });

  return {
    data: data ?? null,
    isLoading,
    isError,
    errorMessage: error?.message ?? null,
  } as const;
}
```

## Server Actions pattern (full-stack DB)
```typescript
'use client';
import { useState, useCallback, useEffect } from 'react';
import { [verb][Feature]Action } from './actions/[verb][Feature]Action';

export function use[Feature]ViewModel() {
  const [data, setData] = useState<[ReturnType] | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    const result = await [verb][Feature]Action({});
    if (result?.data) setData(result.data);
    else if (result?.serverError) setError(result.serverError);
    setIsLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);

  return { data, isLoading, error, refresh: load } as const;
}
```
