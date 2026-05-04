---
name: data-create-mapper
description: |
  Create a Mapper extending BaseMapper to convert a Response DTO to a Domain Entity.
user-invocable: false
---

Create a Mapper following `.claude/reference/contract/builder/data.md ## Mappers section` and null-safety extensions in `.claude/reference/contract/builder/utilities.md ## Null Safety Extensions section`.

## Steps

1. **Grep** `.claude/reference/contract/builder/data.md` for `## Mappers` and `.claude/reference/contract/builder/utilities.md` for `## Null Safety Extensions`; only **Read** a file in full if the section cannot be located
2. **Read** the Response class and Entity class to understand all fields
3. **Locate** the correct path: `feature_[module]/src/main/java/co/talenta/feature_[module]/data/mapper/`
4. **Create** `[Entity]Mapper.kt`

## Mapper Pattern

```kotlin
import com.mekari.commons.extension.orEmpty
import com.mekari.commons.extension.orZero
import com.mekari.commons.extension.orFalse

class FeatureEntityMapper : BaseMapper<FeatureResponse, FeatureEntity> {
    override fun map(input: FeatureResponse): FeatureEntity {
        return FeatureEntity(
            id = input.id.orEmpty(),
            name = input.name.orEmpty(),
            count = input.count.orZero(),
            isActive = input.isActive.orFalse()
        )
    }
}
```

Rules:
- **Every entity field must appear in the mapper call** — no silent defaults
- Use `.orEmpty()` for String/List, `.orZero()` for Int/Long/Double, `.orFalse()` or `.orTrue()` for Boolean
- Never use `?: ""` or `?: 0` — always the extension function
- For nested objects: create a nested mapper and delegate
- For lists: `input.items?.map { nestedMapper.map(it) }.orEmpty()`

## Output

Confirm file path, list all mapped fields, and flag any entity field not present in the response.
