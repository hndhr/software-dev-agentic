# Mock Template

```typescript
// __tests__/mocks/Mock[InterfaceName].ts
import { vi } from 'vitest';
import type { [InterfaceName] } from '@/[path-to-interface]';

export class Mock[InterfaceName] implements [InterfaceName] {
  [methodOne] = vi.fn<Parameters<[InterfaceName]['[methodOne]']>, ReturnType<[InterfaceName]['[methodOne]']>>();
  [methodTwo] = vi.fn<Parameters<[InterfaceName]['[methodTwo]']>, ReturnType<[InterfaceName]['[methodTwo]']>>();
  // one line per interface method
}
```

## Usage example
```typescript
let mock: Mock[InterfaceName];

beforeEach(() => {
  mock = new Mock[InterfaceName]();
});

it('example', async () => {
  mock.[methodOne].mockResolvedValue([expectedValue]);
  // call system under test
  expect(mock.[methodOne]).toHaveBeenCalledWith([expectedArgs]);
});
```
