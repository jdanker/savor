# Two-tier photo cache (NSCache → disk → API)

**What**: Photos resolve through three layers: L1 `NSCache` in memory (auto-evicts
under memory pressure), L2 JPEGs on disk under `Caches/PlacePhotos/{placeID}_{n}.jpg`
(survives relaunch; iOS may purge under storage pressure), L3 the Places SDK fetch
(billed), which writes back to both cache layers.

**Why here**: Photo fetches are a billed SKU and the slowest part of the detail
view. Disk hits promote back into memory so repeat opens are instant.

**Where**: `Services/PlacesService.swift` — `fetchPhotos`, `loadAndCachePhotos`,
`saveToDisk`/`loadFromDisk`, `PhotoCacheEntry`.

**Gotchas**:
- `NSCache` requires reference-type values — `[UIImage]` is wrapped in the
  `PhotoCacheEntry` class for exactly this reason.
- `loadFromDisk` probes `{placeID}_0..9.jpg` and stops at the first miss — photo
  count per place is implicit, not stored.

**Deeper**: https://developer.apple.com/documentation/foundation/nscache
