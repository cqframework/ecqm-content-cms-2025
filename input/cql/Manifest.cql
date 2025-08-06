/*
@description: This library uses content published in the 2025-05-08 eCQM Terminology Update to construct
the relevant aspects of an "expected" manifest describing the release, including:
* Direct Reference Codes (see DirectReferenceCodeExtensions)
* System Version and Value Set Version Manifest Parameters (see SystemVersionParameters and ValueSetVersionParameters)
* System and Value Set Related Artifact Entries (see SystemVersionRelatedArtifacts and ValueSetVersionRelatedArtifacts)
*/
library Manifest

using FHIR version '4.0.1'

include FHIRHelpers version '4.4.000'

// These libraries were constructed with the CQF-Tooling SpreadsheetToCQL command
include "bps_cms_20250508"
include "cs_versions_cms_20250508"
include "drc_cms_20250508"

/*
@description: Value Sets with definition version referenced directly by measures in the 2025 Annual Update
*/
define MeasureValueSetVersions:
  "bps_cms_20250508"."value-set-bps-2025-05-08" VS
    return {
        id: VS."Value Set OID",
        url: 'http://cts.nlm.nih.gov/fhir/ValueSet/' + VS."Value Set OID",
        version: VS."Definition Version",
        title: VS."Value Set Name"
    }

/*
@description: Member Value Sets used in Grouping Value Sets referenced directly by measures in the 2025 Annual Update
*/
define GroupedValueSets:
  "bps_cms_20250508"."value-set-bps-2025-05-08" VS
    where VS."Grouping Member OID" is not null and VS."Grouping Member OID" != ''
    return {
      id: VS."Grouping Member OID",
      url: 'http://cts.nlm.nih.gov/fhir/ValueSet/' + VS."Grouping Member OID",
      version: null,
      title: VS."Grouping Member Name"
    }

define OnlyGroupedValueSets:
  GroupedValueSets GVS
    without MeasureValueSetVersions VSV such that GVS.url = VSV.url

define GroupedCounts: {
  GroupedCount: Count(GroupedValueSets),
  OnlyGroupedCount: Count(OnlyGroupedValueSets)
}

/*
@description: All value sets referenced in the 2025 Annual Update
@comment: Note that the version of member value sets cannot be determined
with the information available in the published downloads if the value set is
only a grouped value set.
*/
define ValueSetVersions:
  MeasureValueSetVersions
    union (
      GroupedValueSets GSV
        without MeasureValueSetVersions VSV such that GSV.url = VSV.url
        return {
          id: GSV.id,
          url: GSV.url,
          version: 'GROUPED',
          title: GSV.title
        }
    )

/*
@description: A mapping from CodeSystem name to THO URL
*/
define CodeSystemUrls: {
    { name: 'CDCREC', url: 'urn:oid:2.16.840.1.113883.6.238' },
    { name: 'CDT', url: 'http://www.ada.org/cdt' },
    { name: 'CPT', url: 'http://www.ama-assn.org/go/cpt' },
    { name: 'CVX', url: 'http://hl7.org/fhir/sid/cvx' },
    { name: 'HCPCS', url: 'http://www.cms.gov/Medicare/Coding/HCPCSReleaseCodeSets' },
    { name: 'HSLOC', url: 'https://www.cdc.gov/nhsn/cdaportal/terminology/codesystem/hsloc.html' },
    { name: 'ICD9CM', url: 'http://hl7.org/fhir/sid/icd-9-cm' },
    { name: 'ICD10CM', url: 'http://hl7.org/fhir/sid/icd-10-cm' },
    { name: 'ICD10PCS', url: 'http://www.cms.gov/Medicare/Coding/ICD10' },
    { name: 'LOINC', url: 'http://loinc.org' },
    { name: 'PresentOnAdmission', url: 'https://www.cms.gov/Medicare/Medicare-Fee-for-Service-Payment/HospitalAcqCond/Coding' },
    { name: 'RXNORM', url: 'http://www.nlm.nih.gov/research/umls/rxnorm' },
    { name: 'SNOMEDCT', url: 'http://snomed.info/sct' },
    { name: 'SOP', url: 'https://nahdo.org/sopt' }
}

/*
@description: Search set bundles for the SNOMED and RxNORM code systems from VSAC UAT as of 8/5
@comment: SNOMED and RxNORM version specifiers in VSAC have "short versions", see GetShortVersion
*/
define CodeSystemBundles:
  [Bundle] B

define CodeSystems:
  CodeSystemBundles.entry E
    return E.resource as CodeSystem

define CodeSystemUrlsAndVersions:
  CodeSystems CS
    return { url: CS.url, version: CS.version, name: CS.name, shortVersion: GetShortVersion(CS.url, CS.version) }

/*
@description: SNOMED and RxNORM have "short version" strings that are used in the VSAC downloadables
@comment: For SNOMED and RXNORM, the short version is the publication date formatted as `YYYY-MM`.
*/
define function GetShortVersion(url String, version String):
  case url
    when 'http://snomed.info/sct' then ((Split(version, '/').last()) T return T.substring(0, 4) + '-' + T.substring(4, 2))
    when 'http://www.nlm.nih.gov/research/umls/rxnorm' then version.substring(4, 4) + '-' + version.substring(0, 2)
    else version
  end

define CodeSystemVersions:
  "cs_versions_cms_20250508"."Code System Versions" CS
    return {
        id: CS."Code System OID",
        url: CodeSystemUrls.where(name = CS."Code System").single().url,
        version: Coalesce(
            CodeSystemUrlsAndVersions.where(name = CS."Code System" and shortVersion = CS."Code System Version").first().version, 
            CS."Code System Version".replaceMatches('-', '')
        ),
        name: CS."Code System",
        title: CS."Code System",
        shortVersion: CS."Code System Version"
    }

define DirectReferenceCodes:
  "drc_cms_20250508"."drc-2025-05-08" DRC
    return {
        code: DRC."Code",
        system: CodeSystemUrls.where(name = DRC."Code System").single().url,
        version: Coalesce(
            CodeSystemUrlsAndVersions.where(name = DRC."Code System" and shortVersion = DRC."Code System Version").first().version,
            DRC."Code System Version".replaceMatches('-', '')
        ),
        display: DRC.Description
    }

// Manifest
// DRC Extensions
define DirectReferenceCodeExtensions:
  DirectReferenceCodes DRC
    return '{ "url": "http://hl7.org/fhir/StructureDefinition/cqf-directReferenceCode", "valueCoding": { "system": "' + DRC.system + '", "version": "' + DRC.version + '", "code": "' + DRC.code + '", "display": "' + DRC.display + '" } }'

// ManifestParameters
  // SystemVersions
/*
{
    "name": "system-version",
    "valueCanonical": "http://snomed.info/sct|http://snomed.info/sct/731000124108/version/20240901",
    "_valueCanonical": {
        "extension": [{
            "url": "http://hl7.org/fhir/StructureDefinition/display",
            "valueString": "SNOMEDCT, 2024-09"
        }]
    }
},
*/
define SystemVersionParameters:
  CodeSystemVersions CS
    return '{ "name": "system-version", "valueCanonical": "' + CS.url + '|' + CS.version + '", "_valueCanonical": { "extension": [{ "url": "http://hl7.org/fhir/StructureDefinition/display", "valueString": "' + CS.title + ', ' + CS.shortVersion + '" }] } }'

// ManifestParameters
  // ValueSetVersions
define ValueSetVersionParameters:
  ValueSetVersions VS
    return '{ "name": "canonicalVersion", "valueCanonical": "' + VS.url + '|' + VS.version + '", "_valueCanonical": { "extension": [{ "url": "http://hl7.org/fhir/StructureDefinition/display", "valueString": "' + VS.title + ', ' + VS.version + '" }] } }'

/*
{
    "type": "depends-on",
    "display": "ValueSet Level of Severity of Retinopathy Findings, 20250208",
    "resource": "http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1377|20250208",
    "_resource": {
        "extension": [
            {
                "url": "http://hl7.org/fhir/StructureDefinition/cqf-resourceType",
                "valueCode": "ValueSet"
            }
        ]
    }
}
*/
// RelatedArtifact
  // SystemVersions
define SystemVersionRelatedArtifacts:
  CodeSystemVersions CS
    return '{ "type": "depends-on", "display": "Code System ' + CS.title + ', ' + CS.shortVersion + '", "resource": "' + CS.url + '|' + CS.version + '", "_resource": { "extension": [{ "url": "http://hl7.org/fhir/StructureDefinition/cqf-resourceType", "valueCode": "CodeSystem" }]}}'

// RelatedArtifact
  // ValueSetVersions
define ValueSetVersionRelatedArtifacts:
  ValueSetVersions VS
    return '{ "type": "depends-on", "display": "Value Set ' + VS.title + ', ' + VS.version + '", "resource": "' + VS.url + '|' + VS.version + '", "_resource": { "extension": [{ "url": "http://hl7.org/fhir/StructureDefinition/cqf-resourceType", "valueCode": "ValueSet" }]}}'
