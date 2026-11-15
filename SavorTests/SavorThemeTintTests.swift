//
//  SavorThemeTintTests.swift
//  SavorTests
//

import Testing

@testable import Savor

/// The tile tint is derived from an SF Symbol name, so the mapping is coupled by
/// string to the icon names the models produce. These tests pin that coupling:
/// renaming an icon in a model without updating the theme fails here instead of
/// silently turning every tile peach.
///
/// `@MainActor` because the app target defaults to main-actor isolation, which
/// makes `Tint`'s `Equatable` conformance main-actor-isolated too; comparing
/// tints from a nonisolated test is a warning now and an error in Swift 6 mode.
@MainActor
struct SavorThemeTintTests {
    @Test func restaurantIconsMapToTheirTint() {
        #expect(SavorTheme.tint(forSymbol: "fork.knife") == .peach)
        #expect(SavorTheme.tint(forSymbol: "birthday.cake.fill") == .peach)
        #expect(SavorTheme.tint(forSymbol: "fish.fill") == .sage)
        #expect(SavorTheme.tint(forSymbol: "wineglass.fill") == .sage)
        #expect(SavorTheme.tint(forSymbol: "cup.and.saucer.fill") == .butter)
    }

    @Test func unknownSymbolFallsBackToPeach() {
        #expect(SavorTheme.tint(forSymbol: "not.a.real.symbol") == .peach)
        #expect(SavorTheme.tint(forSymbol: "") == .peach)
    }

    /// Goes through the real model helpers rather than repeating their strings,
    /// so this is the test that breaks if `Restaurant.iconName` changes.
    @Test func modelIconNamesLandOnTheIntendedTint() {
        let sushi = makeRestaurant(name: "Sushi", types: ["japanese_restaurant"])
        let cafe = makeRestaurant(name: "Cafe", types: ["cafe"])
        let wineBar = makeRestaurant(name: "Wine", types: ["wine_bar"])
        let plain = makeRestaurant(name: "Plain", types: ["restaurant"])

        #expect(SavorTheme.tint(forSymbol: sushi.iconName) == .sage)
        #expect(SavorTheme.tint(forSymbol: cafe.iconName) == .butter)
        #expect(SavorTheme.tint(forSymbol: wineBar.iconName) == .sage)
        #expect(SavorTheme.tint(forSymbol: plain.iconName) == .peach)
    }

    @Test func smartCategoryIconsAreAllTinted() {
        #expect(SavorTheme.tint(forSymbol: SmartCategory.coffee.iconName) == .butter)
        #expect(SavorTheme.tint(forSymbol: SmartCategory.breakfast.iconName) == .butter)
        #expect(SavorTheme.tint(forSymbol: SmartCategory.lunch.iconName) == .butter)
        #expect(SavorTheme.tint(forSymbol: SmartCategory.dinner.iconName) == .peach)
        #expect(SavorTheme.tint(forSymbol: SmartCategory.takeout.iconName) == .peach)
    }
}
