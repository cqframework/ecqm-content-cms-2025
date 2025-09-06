/*
@description: A library of timezone and precision test cases important for demonstrating measure logic behaves as expected, including:

1. Comparison calculations
2. "Day Of" calculations
3. Timezone Normalization calculations
4. Boundary calculations
5. Measure Period value
*/
library TimezoneTesting

using QICore version '6.0.0'

include FHIRHelpers version '4.4.000'
include QICoreCommon version '4.0.000'
include CQMCommon version '4.1.000'

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00Z, @2027-01-01T00:00:00Z )

context Patient

/*
# Comparison Calculations

Comparison tests are not exhaustive, but a representative set of cases is provided for comparison:

Starts on or after
*/

define ProcedureStartsOnOrAfter:
  [Encounter] E
    with [Procedure] P
      such that P.performed.toInterval() starts on or after start E.period

/*
# "Day Of" Calculations

"Day Of" calculations are critical for clinical logic, as many aspects of clinical care are tied to the "day" (i.e. midnight), rather than absolute time lapsed. These tests capture some examples of these types of calculations.

Same day as
*/

define ProcedureSameDayAs:
  [Encounter] E
    with [Procedure] P
      such that P.performed.toInterval() starts same day as start E.period

/*
# Timezone Normalization Calculations

Duration between events in different timezones
*/

define ProcedureWithin24Hours:
  [Encounter] E
    with [Procedure] P
      such that P.performed.toInterval() starts 24 hours or less on or after start of E.period

/*
# Boundary Calculations

LengthInDays
*/

define ProceduresMoreThan2DaysAfter:
  [Encounter] E
    with [Procedure] P
      such that difference in days between start of P.performed.toInterval() and start of E.period >= 2

/*
# Measure Period Value

Measurement period
*/

define EncountersDuringMeasurementPeriod:
  [Encounter] E
    where E.period ends during day of "Measurement Period"

