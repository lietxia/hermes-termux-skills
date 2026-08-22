# AGP / Kotlin / KSP Version Compatibility Matrix (Termux)

Tested combinations that work on Termux ARM64.

## ✅ Working Combinations

| AGP | Kotlin | KSP | Hilt | JDK | Notes |
|-----|--------|-----|------|-----|-------|
| 8.9.1 | 2.3.10 | 2.3.6 | 2.58 | 17 or 21 | Default for Haven |
| 8.9.1 | 2.3.21 | 2.3.9 | 2.58 | 17 or 21 | Latest stable Kotlin |
| 9.2.0 | 2.3.21 | 2.3.9 | ❌ incompatible | 21 | AGP 9 breaks Hilt |

## ❌ Known Incompatible

| Combination | Error | Fix |
|-------------|-------|-----|
| AGP 9.x + Hilt 2.58 | `Could not find AGP base extension` | Stay on AGP 8.x |
| Kotlin 2.3.10 + KSP 2.3.10 | `Plugin not found` (KSP 2.3.10 doesn't exist) | Use KSP 2.3.9 |
| AGP 9.x + `kotlin.android` plugin | `plugin is no longer required` | Remove plugin from build.gradle.kts |
| AGP 9.x + `kotlinOptions {}` | `deprecated, error in 2.3.x` | Use `compilerOptions {}` DSL |
| includeBuild with different AGP versions | `Using multiple versions of AGP` | Unify all modules to same AGP |

## Key Rules

1. **KSP version must match Kotlin minor version** (e.g., Kotlin 2.3.x → KSP 2.3.x)
2. **KSP may lag behind Kotlin** (Kotlin 2.3.10 → use KSP 2.3.9, the latest available)
3. **AGP 8.x and 9.x cannot coexist** in the same build (including includeBuild modules)
4. **AGP 9.0+ requires JDK 21**
5. **AGP 9.0+ removes `kotlin.android` plugin** (Kotlin is built-in)
6. **Hilt ≤2.58 is incompatible with AGP 9.x** (uses removed BaseExtension)
