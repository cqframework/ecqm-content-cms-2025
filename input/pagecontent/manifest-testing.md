# Test Case 1

Value Set: Hospice Care Referral or Admission

    http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.365

Definition versions:

* `20250515` - Latest
* `20191010` - Referenced in `ecqm-update-2025-05-08`
* `20171013`

Intended behavior is to use the `20191010` definition version of this value set, as published with the 2025-05-08 Annual Update

MADiE should be using the `manifest` parameter to specify which expansion profile to use, but...

## Summary

If we use the `expansion` parameter of `ecqm-update-2025-05-08`, we get the expected expansion using the 2019-10-10 definition version.

Using `manifest` parameter always gives latest, whether we specify the FHIR or QDM manifest URL

Using `expansion` of `ecqm-fhir-update-2025` gives an error (this may be due to work-in-progress?)

## Details

### Expansion with latest:

    http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.365/$expand

Returns 2025-05-15, as expected (15 concepts)

### Expansion with version 20191010

    http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.365/$expand?valueSetVersion=20191010

Returns 2019-10-10, as expected (9 concepts)

### Expansion with `expansion` parameter of `ecqm-update-2025-05-08`

    http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.365/$expand?expansion=ecqm-update-2025-05-08

Returns 2019-10-10, as expected (9 concepts)

### Expansion with `manifest` parameter of `http://cts.nlm.nih.gov/fhir/Library/ecqm-update-2025-05-08`

    http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.365/$expand?manifest=http://cts.nlm.nih.gov/fhir/Library/ecqm-update-2025-05-08

**Returns 2025-05-15, the latest version, not the expected 2019-10-10 version**

### Expansion with `expansion` parameter of `ecqm-fhir-update-2025`

    http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.365/$expand?expansion=ecqm-fhir-update-2025

**Getting resource does not exist, though I swear I ran this earlier and got the "latest version" (2025-05-15)**

### Expansion with `manifest` parameter of `http://cts.nlm.nih.gov/fhir/Library/ecqm-fhir-update-2025`

    http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.365/$expand?manifest=http://cts.nlm.nih.gov/fhir/Library/ecqm-fhir-update-2025

**Returns 2025-05-15, the latest version, which with the manifest as defined, is correct, since the canonical version is not pinned, but this is why we want to update the FHIR manifest with the canonicalVersion parameters, so that with that manifest, it's the same as running the next case**

### Expansion with `canonicalVersion` parameter of `http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.365|20191010`

    http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.365/$expand?canonicalVersion=http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.365|20191010

Returns 2019-10-10, as expected (9 concepts)

# Test Case 2

Value Set: Cancer

    https://uat-cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1010

Definition Versions:

* `2020-03-06` (latest)

Grouping Value Sets:

    http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1078

Definition Versions:

* `2025-01-30` - latest
* `2024-01-23`
* `2022-02-18` - Referenced in eCQM Update 2023-05-04
* `2021-02-18`
* ...

    http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1079

Definition Versions:

* `2025-01-31` - latest
* `2024-01-23`
* `2023-02-17` - Referenced in eCQM Update 2023-05-04

Intended behavior is to use the versions of the value sets that were active when the manifest was released (2023-05-04).

## Summary

If we provide the `expansion` parameter, we get the correct expansion (5195 codes)

If we provide the `system-version` and `canonicalVersion` parameters directly, we get close to the right expansion (5101) codes

However, if we provide the `manifest` parameter, we get what is effectively the latest version expansion (6963 codes) (though it is does appear to be using the right SNOMED version)

## Details

Expand with expansion - Returns the expected result

https://uat-cts.nlm.nih.gov/fhir/ValueSet/$expand?url=http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1010&expansion=eCQM%20Update%202023-05-04

Expand with parameters - Returns almost the expected result (it appears to only apply one of each of the system-version and canonicalVersion parameters supplied

https://uat-cts.nlm.nih.gov/fhir/ValueSet/$expand?url=http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1010&valueSetVersion=20200306&system-version=http://hl7.org/fhir/sid/icd-10-cm|2022&system-version=http://snomed.info/sct|http://snomed.info/sct/731000124108/version/20220901&canonicalVersion=http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1078|20220218&canonicalVersion=http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1079|20230217

Expand with manifest - Returns correct code system version, but with latest versions of value set expansions

https://uat-cts.nlm.nih.gov/fhir/ValueSet/$expand?url=http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.1010&manifest=http://cts.nlm.nih.gov/fhir/Library/ecqm-update-2023-05-04

Note that the Manifest resource does not include the value set versions of the grouping value sets as either dependencies or canonicalVersion parameters, so this doesn't necessarily mean the functionality isn't working, it just means I can't validate it with this test case because the Manifest does not contain the expected parameters.

