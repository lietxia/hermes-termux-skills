# AGP Compatibility Matrix

| AGP | Kotlin | JDK | Notes |
|-----|--------|-----|-------|
| 8.9.1 | 2.3.10 | 17 | Stable, Hilt compatible |
| 9.2.0 | 2.3.10+ | 21 | Remove `kotlin.android` plugin, Hilt incompatible |

## AGP 9.x Breaking Changes

- `kotlin.android` plugin built-in → **REMOVE** from all build.gradle.kts
- `kotlinOptions` deprecated → use `compilerOptions` DSL
- Hilt 2.58 **does NOT work** with AGP 9.x → stick with AGP 8.x if using Hilt

## includeBuild Version Unification

All `includeBuild` modules MUST use the same AGP and Kotlin version as root:

```bash
# Check all AGP versions
grep -r "androidGradlePlugin\|agp" gradle/libs.versions.toml */gradle/libs.versions.toml
```

## Dependency Verification

```bash
echo 'org.gradle.dependency.verification=off' >> gradle.properties
find . -name "verification-metadata.xml" -path "*/gradle/*" -exec rm -f {} \;
```

## Memory Optimization

```properties
# gradle.properties (11GB+ RAM)
org.gradle.jvmargs=-Xmx8192m -XX:MaxMetaspaceSize=512m
```