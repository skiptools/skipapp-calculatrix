import Foundation

/// The categories of unit conversions supported by the calculator.
public enum ConversionCategory: CaseIterable, Hashable {
    case angles
    case area
    case data
    case energy
    case force
    case fuel
    case length
    case power
    case pressure
    case speed
    case temperature
    case time
    case volume
    case weight
}

// MARK: - Angle Units (base: degrees)

public enum AngleUnit: CaseIterable, Hashable {
    case degrees, radians, gradians, arcminutes, arcseconds, revolutions, milliradians

    public var factor: Double {
        switch self {
        case .degrees: return 1.0
        case .radians: return 180.0 / Double.pi
        case .gradians: return 0.9
        case .arcminutes: return 1.0 / 60.0
        case .arcseconds: return 1.0 / 3600.0
        case .revolutions: return 360.0
        case .milliradians: return 180.0 / (Double.pi * 1000.0)
        }
    }

    public func convert(_ value: Double, to target: AngleUnit) -> Double {
        return value * self.factor / target.factor
    }
}

// MARK: - Area Units (base: square meters)

public enum AreaUnit: CaseIterable, Hashable {
    case squareMillimeters, squareCentimeters, squareMeters, squareKilometers
    case hectares, ares
    case squareInches, squareFeet, squareYards, squareMiles, acres

    public var factor: Double {
        switch self {
        case .squareMillimeters: return 0.000001
        case .squareCentimeters: return 0.0001
        case .squareMeters: return 1.0
        case .squareKilometers: return 1_000_000.0
        case .hectares: return 10_000.0
        case .ares: return 100.0
        case .squareInches: return 0.00064516
        case .squareFeet: return 0.09290304
        case .squareYards: return 0.83612736
        case .squareMiles: return 2_589_988.110336
        case .acres: return 4046.8564224
        }
    }

    public func convert(_ value: Double, to target: AreaUnit) -> Double {
        return value * self.factor / target.factor
    }
}

// MARK: - Data Units (base: bytes)

public enum DataUnit: CaseIterable, Hashable {
    case bits, bytes
    case kilobits, kibibits, kilobytes, kibibytes
    case megabits, mebibits, megabytes, mebibytes
    case gigabits, gibibits, gigabytes, gibibytes
    case terabits, tebibits, terabytes, tebibytes
    case petabytes, pebibytes

    public var factor: Double {
        switch self {
        case .bits: return 0.125
        case .bytes: return 1.0
        case .kilobits: return 125.0
        case .kibibits: return 128.0
        case .kilobytes: return 1_000.0
        case .kibibytes: return 1_024.0
        case .megabits: return 125_000.0
        case .mebibits: return 131_072.0
        case .megabytes: return 1_000_000.0
        case .mebibytes: return 1_048_576.0
        case .gigabits: return 125_000_000.0
        case .gibibits: return 134_217_728.0
        case .gigabytes: return 1_000_000_000.0
        case .gibibytes: return 1_073_741_824.0
        case .terabits: return 125_000_000_000.0
        case .tebibits: return 137_438_953_472.0
        case .terabytes: return 1_000_000_000_000.0
        case .tebibytes: return 1_099_511_627_776.0
        case .petabytes: return 1_000_000_000_000_000.0
        case .pebibytes: return 1_125_899_906_842_624.0
        }
    }

    public func convert(_ value: Double, to target: DataUnit) -> Double {
        return value * self.factor / target.factor
    }
}

// MARK: - Energy Units (base: joules)

public enum EnergyUnit: CaseIterable, Hashable {
    case joules, kilojoules, megajoules
    case calories, kilocalories
    case wattHours, kilowattHours
    case electronvolts, britishThermalUnits, footPounds, therms, ergs

    public var factor: Double {
        switch self {
        case .joules: return 1.0
        case .kilojoules: return 1_000.0
        case .megajoules: return 1_000_000.0
        case .calories: return 4.184
        case .kilocalories: return 4_184.0
        case .wattHours: return 3_600.0
        case .kilowattHours: return 3_600_000.0
        case .electronvolts: return 1.602176634e-19
        case .britishThermalUnits: return 1055.06
        case .footPounds: return 1.355818
        case .therms: return 105_505_600.0
        case .ergs: return 1e-7
        }
    }

    public func convert(_ value: Double, to target: EnergyUnit) -> Double {
        return value * self.factor / target.factor
    }
}

// MARK: - Force Units (base: newtons)

public enum ForceUnit: CaseIterable, Hashable {
    case newtons, kilonewtons, meganewtons, millinewtons, micronewtons
    case dynes, poundsForce, ouncesForce, kilogramForce, poundals, kips

    public var factor: Double {
        switch self {
        case .newtons: return 1.0
        case .kilonewtons: return 1_000.0
        case .meganewtons: return 1_000_000.0
        case .millinewtons: return 0.001
        case .micronewtons: return 0.000001
        case .dynes: return 0.00001
        case .poundsForce: return 4.448222
        case .ouncesForce: return 0.2780139
        case .kilogramForce: return 9.80665
        case .poundals: return 0.138255
        case .kips: return 4_448.222
        }
    }

    public func convert(_ value: Double, to target: ForceUnit) -> Double {
        return value * self.factor / target.factor
    }
}

// MARK: - Fuel Units (base: L/100km, reciprocal)

public enum FuelUnit: CaseIterable, Hashable {
    case litersPer100km, milesPerGallonUS, milesPerGallonUK, kilometersPerLiter

    public func toBase(_ value: Double) -> Double {
        if value == 0.0 { return 0.0 }
        switch self {
        case .litersPer100km: return value
        case .milesPerGallonUS: return 235.214583 / value
        case .milesPerGallonUK: return 282.481 / value
        case .kilometersPerLiter: return 100.0 / value
        }
    }

    public func fromBase(_ baseValue: Double) -> Double {
        if baseValue == 0.0 { return 0.0 }
        switch self {
        case .litersPer100km: return baseValue
        case .milesPerGallonUS: return 235.214583 / baseValue
        case .milesPerGallonUK: return 282.481 / baseValue
        case .kilometersPerLiter: return 100.0 / baseValue
        }
    }

    public func convert(_ value: Double, to target: FuelUnit) -> Double {
        return target.fromBase(self.toBase(value))
    }
}

// MARK: - Length Units (base: meters)

public enum LengthUnit: CaseIterable, Hashable {
    case nanometers, micrometers, millimeters, centimeters, decimeters, meters, kilometers
    case inches, feet, yards, miles, nauticalMiles
    case fathoms, furlongs, mils, lightYears, astronomicalUnits, parsecs

    public var factor: Double {
        switch self {
        case .nanometers: return 1e-9
        case .micrometers: return 1e-6
        case .millimeters: return 0.001
        case .centimeters: return 0.01
        case .decimeters: return 0.1
        case .meters: return 1.0
        case .kilometers: return 1_000.0
        case .inches: return 0.0254
        case .feet: return 0.3048
        case .yards: return 0.9144
        case .miles: return 1_609.344
        case .nauticalMiles: return 1_852.0
        case .fathoms: return 1.8288
        case .furlongs: return 201.168
        case .mils: return 0.0000254
        case .lightYears: return 9.461e+15
        case .astronomicalUnits: return 1.496e+11
        case .parsecs: return 3.086e+16
        }
    }

    public func convert(_ value: Double, to target: LengthUnit) -> Double {
        return value * self.factor / target.factor
    }
}

// MARK: - Power Units (base: watts)

public enum PowerUnit: CaseIterable, Hashable {
    case milliwatts, watts, kilowatts, megawatts, gigawatts
    case horsepower, metricHorsepower, footPoundsPerSecond, btuPerHour, tonsOfRefrigeration

    public var factor: Double {
        switch self {
        case .milliwatts: return 0.001
        case .watts: return 1.0
        case .kilowatts: return 1_000.0
        case .megawatts: return 1_000_000.0
        case .gigawatts: return 1_000_000_000.0
        case .horsepower: return 745.7
        case .metricHorsepower: return 735.49875
        case .footPoundsPerSecond: return 1.355818
        case .btuPerHour: return 0.29307107
        case .tonsOfRefrigeration: return 3_516.853
        }
    }

    public func convert(_ value: Double, to target: PowerUnit) -> Double {
        return value * self.factor / target.factor
    }
}

// MARK: - Pressure Units (base: pascals)

public enum PressureUnit: CaseIterable, Hashable {
    case pascals, hectopascals, kilopascals, megapascals
    case bars, millibars, atmospheres
    case torr, millimetersOfMercury, poundsPerSquareInch, inchesOfMercury, inchesOfWater

    public var factor: Double {
        switch self {
        case .pascals: return 1.0
        case .hectopascals: return 100.0
        case .kilopascals: return 1_000.0
        case .megapascals: return 1_000_000.0
        case .bars: return 100_000.0
        case .millibars: return 100.0
        case .atmospheres: return 101_325.0
        case .torr: return 133.322
        case .millimetersOfMercury: return 133.322
        case .poundsPerSquareInch: return 6_894.757
        case .inchesOfMercury: return 3_386.389
        case .inchesOfWater: return 249.082
        }
    }

    public func convert(_ value: Double, to target: PressureUnit) -> Double {
        return value * self.factor / target.factor
    }
}

// MARK: - Speed Units (base: meters per second)

public enum SpeedUnit: CaseIterable, Hashable {
    case metersPerSecond, kilometersPerHour, milesPerHour, feetPerSecond
    case knots, mach, speedOfLight

    public var factor: Double {
        switch self {
        case .metersPerSecond: return 1.0
        case .kilometersPerHour: return 1.0 / 3.6
        case .milesPerHour: return 0.44704
        case .feetPerSecond: return 0.3048
        case .knots: return 0.514444
        case .mach: return 343.0
        case .speedOfLight: return 299_792_458.0
        }
    }

    public func convert(_ value: Double, to target: SpeedUnit) -> Double {
        return value * self.factor / target.factor
    }
}

// MARK: - Temperature Units (base: Celsius, offset-based)

public enum TemperatureUnit: CaseIterable, Hashable {
    case celsius, fahrenheit, kelvin, rankine

    public func toBase(_ value: Double) -> Double {
        switch self {
        case .celsius: return value
        case .fahrenheit: return (value - 32.0) * 5.0 / 9.0
        case .kelvin: return value - 273.15
        case .rankine: return (value - 491.67) * 5.0 / 9.0
        }
    }

    public func fromBase(_ baseValue: Double) -> Double {
        switch self {
        case .celsius: return baseValue
        case .fahrenheit: return baseValue * 9.0 / 5.0 + 32.0
        case .kelvin: return baseValue + 273.15
        case .rankine: return baseValue * 9.0 / 5.0 + 491.67
        }
    }

    public func convert(_ value: Double, to target: TemperatureUnit) -> Double {
        return target.fromBase(self.toBase(value))
    }
}

// MARK: - Time Units (base: seconds)

public enum TimeUnit: CaseIterable, Hashable {
    case nanoseconds, microseconds, milliseconds, seconds, minutes, hours, days, weeks
    case fortnights, months, years, decades, centuries

    public var factor: Double {
        switch self {
        case .nanoseconds: return 1e-9
        case .microseconds: return 1e-6
        case .milliseconds: return 0.001
        case .seconds: return 1.0
        case .minutes: return 60.0
        case .hours: return 3_600.0
        case .days: return 86_400.0
        case .weeks: return 604_800.0
        case .fortnights: return 1_209_600.0
        case .months: return 2_592_000.0
        case .years: return 31_536_000.0
        case .decades: return 315_360_000.0
        case .centuries: return 3_153_600_000.0
        }
    }

    public func convert(_ value: Double, to target: TimeUnit) -> Double {
        return value * self.factor / target.factor
    }
}

// MARK: - Volume Units (base: liters)

public enum VolumeUnit: CaseIterable, Hashable {
    case milliliters, centiliters, deciliters, liters, kiloliters
    case cubicCentimeters, cubicMeters, cubicInches, cubicFeet, cubicYards
    case usTeaspoons, usTablespoons, usFluidOunces, usCups, usPints, usQuarts, usGallons
    case imperialTeaspoons, imperialTablespoons, imperialFluidOunces
    case imperialPints, imperialQuarts, imperialGallons

    public var factor: Double {
        switch self {
        case .milliliters: return 0.001
        case .centiliters: return 0.01
        case .deciliters: return 0.1
        case .liters: return 1.0
        case .kiloliters: return 1_000.0
        case .cubicCentimeters: return 0.001
        case .cubicMeters: return 1_000.0
        case .cubicInches: return 0.016387064
        case .cubicFeet: return 28.316846592
        case .cubicYards: return 764.554857984
        case .usTeaspoons: return 0.00492892
        case .usTablespoons: return 0.0147868
        case .usFluidOunces: return 0.0295735
        case .usCups: return 0.236588
        case .usPints: return 0.473176
        case .usQuarts: return 0.946353
        case .usGallons: return 3.78541
        case .imperialTeaspoons: return 0.00591939
        case .imperialTablespoons: return 0.0177582
        case .imperialFluidOunces: return 0.0284131
        case .imperialPints: return 0.568261
        case .imperialQuarts: return 1.13652
        case .imperialGallons: return 4.54609
        }
    }

    public func convert(_ value: Double, to target: VolumeUnit) -> Double {
        return value * self.factor / target.factor
    }
}

// MARK: - Weight Units (base: kilograms)

public enum WeightUnit: CaseIterable, Hashable {
    case micrograms, milligrams, grams, kilograms, metricTons
    case ounces, pounds, stones, shortTons, longTons
    case carats, troyOunces, grains, slugs

    public var factor: Double {
        switch self {
        case .micrograms: return 1e-9
        case .milligrams: return 1e-6
        case .grams: return 0.001
        case .kilograms: return 1.0
        case .metricTons: return 1_000.0
        case .ounces: return 0.028349523125
        case .pounds: return 0.45359237
        case .stones: return 6.35029318
        case .shortTons: return 907.18474
        case .longTons: return 1_016.0469088
        case .carats: return 0.0002
        case .troyOunces: return 0.0311035
        case .grains: return 0.00006479891
        case .slugs: return 14.593903
        }
    }

    public func convert(_ value: Double, to target: WeightUnit) -> Double {
        return value * self.factor / target.factor
    }
}

// MARK: - Wrapper Enum

/// A type-safe unit that wraps any of the per-category unit enums.
public enum ConversionUnit: Hashable {
    case angle(AngleUnit)
    case area(AreaUnit)
    case data(DataUnit)
    case energy(EnergyUnit)
    case force(ForceUnit)
    case fuel(FuelUnit)
    case length(LengthUnit)
    case power(PowerUnit)
    case pressure(PressureUnit)
    case speed(SpeedUnit)
    case temperature(TemperatureUnit)
    case time(TimeUnit)
    case volume(VolumeUnit)
    case weight(WeightUnit)
}

// MARK: - Public API

/// Returns the list of available units for a given conversion category.
public func conversionUnits(for category: ConversionCategory) -> [ConversionUnit] {
    switch category {
    case .angles: return AngleUnit.allCases.map { ConversionUnit.angle($0) }
    case .area: return AreaUnit.allCases.map { ConversionUnit.area($0) }
    case .data: return DataUnit.allCases.map { ConversionUnit.data($0) }
    case .energy: return EnergyUnit.allCases.map { ConversionUnit.energy($0) }
    case .force: return ForceUnit.allCases.map { ConversionUnit.force($0) }
    case .fuel: return FuelUnit.allCases.map { ConversionUnit.fuel($0) }
    case .length: return LengthUnit.allCases.map { ConversionUnit.length($0) }
    case .power: return PowerUnit.allCases.map { ConversionUnit.power($0) }
    case .pressure: return PressureUnit.allCases.map { ConversionUnit.pressure($0) }
    case .speed: return SpeedUnit.allCases.map { ConversionUnit.speed($0) }
    case .temperature: return TemperatureUnit.allCases.map { ConversionUnit.temperature($0) }
    case .time: return TimeUnit.allCases.map { ConversionUnit.time($0) }
    case .volume: return VolumeUnit.allCases.map { ConversionUnit.volume($0) }
    case .weight: return WeightUnit.allCases.map { ConversionUnit.weight($0) }
    }
}

/// Returns a sensible default source unit for the given category.
public func defaultSourceUnit(for category: ConversionCategory) -> ConversionUnit {
    return conversionUnits(for: category)[0]
}

/// Returns a sensible default target unit for the given category.
public func defaultTargetUnit(for category: ConversionCategory) -> ConversionUnit {
    let units = conversionUnits(for: category)
    return units.count > 1 ? units[1] : units[0]
}

/// Convert a value from one unit to another.
public func convertValue(_ value: Double, from source: ConversionUnit, to target: ConversionUnit) -> Double {
    if source == target { return value }

    switch source {
    case .angle(let s):
        if case .angle(let t) = target { return s.convert(value, to: t) }
    case .area(let s):
        if case .area(let t) = target { return s.convert(value, to: t) }
    case .data(let s):
        if case .data(let t) = target { return s.convert(value, to: t) }
    case .energy(let s):
        if case .energy(let t) = target { return s.convert(value, to: t) }
    case .force(let s):
        if case .force(let t) = target { return s.convert(value, to: t) }
    case .fuel(let s):
        if case .fuel(let t) = target { return s.convert(value, to: t) }
    case .length(let s):
        if case .length(let t) = target { return s.convert(value, to: t) }
    case .power(let s):
        if case .power(let t) = target { return s.convert(value, to: t) }
    case .pressure(let s):
        if case .pressure(let t) = target { return s.convert(value, to: t) }
    case .speed(let s):
        if case .speed(let t) = target { return s.convert(value, to: t) }
    case .temperature(let s):
        if case .temperature(let t) = target { return s.convert(value, to: t) }
    case .time(let s):
        if case .time(let t) = target { return s.convert(value, to: t) }
    case .volume(let s):
        if case .volume(let t) = target { return s.convert(value, to: t) }
    case .weight(let s):
        if case .weight(let t) = target { return s.convert(value, to: t) }
    }
    return value
}
