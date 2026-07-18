//
//  LocationService.swift
//  Savor
//

import CoreLocation

/// One-shot "where am I" lookup for distance sorting.
///
/// Uses CLLocationUpdate.liveUpdates (the modern async-sequence API) instead of the
/// CLLocationManager delegate pattern — we only need a single fix, so we take the first
/// update that carries a location and stop iterating. Breaking out of the sequence ends
/// location delivery, so there's no lingering GPS usage (or status-bar indicator).
///
/// Iterating liveUpdates also triggers the when-in-use permission prompt automatically
/// if authorization hasn't been determined yet, which is why there's no explicit
/// requestWhenInUseAuthorization() call here.
final class LocationService {
    enum LocationError: Error {
        case denied
        case unavailable
    }

    func currentLocation() async throws -> CLLocation {
        for try await update in CLLocationUpdate.liveUpdates() {
            if update.authorizationDenied || update.authorizationDeniedGlobally {
                throw LocationError.denied
            }
            if let location = update.location {
                return location
            }
            // Updates can arrive without a location while the permission prompt is up
            // or before the first fix — keep iterating until one carries a location.
        }
        throw LocationError.unavailable
    }
}
