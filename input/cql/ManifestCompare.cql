/*
@description: This library compares code system and value set versions used in different manifests
*/
library ManifestCompare

using FHIR version '4.0.1'

include FHIRHelpers version '4.4.000'

define QDMManifest:
  singleton from (
    [Library] L
      where L.id = 'ecqm-update-2025-05-08-expected'
  )

define FHIRManifest:
  singleton from (
    [Library] L
      //where L.id = 'ecqm-fhir-update-2025' // Use FHIR Update for Code System Comparison
      where L.id = 'Manifest-Partial-Set-Release-2025' // Use Partial Release for Value Set Comparison
  )

define QDMParameters:
  QDMManifest.contained.where(id = '#exp-params').single() as FHIR.Parameters

define FHIRParameters:
  FHIRManifest.contained.where(id = '#exp-params').single() as FHIR.Parameters

define ParameterCounts: {
    QDM: QDMParameters.parameter.count(),
    FHIR: FHIRParameters.parameter.count()
}

define SystemVersionsInFHIR:
  FHIRParameters.parameter.where(name = 'system-version').value.value

define ValueSetVersionsInFHIR:
  FHIRParameters.parameter.where(name = 'canonical-version' and PositionOf('/Library/', value) = -1 and PositionOf('/Measure/', value) = -1).value.value

define SystemVersionsInQDM:
  QDMParameters.parameter.where(name = 'system-version').value.value

define ValueSetVersionsInQDM:
  QDMParameters.parameter.where(name = 'canonicalVersion' and PositionOf('/Library/', value) = -1 and PositionOf('/Measure/', value) = -1).value.value

define SystemVersionCounts: {
  QDM: Count(SystemVersionsInQDM),
  FHIR: Count(SystemVersionsInFHIR)
}

define ValueSetVersionCounts: {
  QDM: Count(ValueSetVersionsInQDM),
  FHIR: Count(ValueSetVersionsInFHIR)
}

define SystemVersionsInFHIRNotQDM: SystemVersionsInFHIR except SystemVersionsInQDM
define SystemVersionsInQDMNotFHIR: SystemVersionsInQDM except SystemVersionsInFHIR

define SystemsInFHIR:
  SystemVersionsInFHIR CS
    return {
      system: Split(CS, '|').first()
    }

define ValueSetsInFHIR:
  ValueSetVersionsInFHIR VS
    return {
      url: Split(VS, '|').first()
    }

define SystemsWithVersionsInFHIR:
  SystemsInFHIR CS
    return {
      system: CS.system,
      versions: SystemVersionsInFHIR CSV where CSV.startsWith(CS.system + '|') return Split(CSV, '|').last()
    }

define ValueSetsWithVersionsInFHIR:
  ValueSetsInFHIR VS
    return {
      url: VS.url,
      version: (ValueSetVersionsInFHIR VSV where VSV.startsWith(VS.url + '|') return Split(VSV, '|').last()).single()
    }
  
define SystemsInQDM:
  SystemVersionsInQDM CS
    return {
      system: Split(CS, '|').first()
    }

define ValueSetsInQDM:
  ValueSetVersionsInQDM VS
    return {
      url: Split(VS, '|').first()
    }

define SystemsWithVersionsInQDM:
  SystemsInQDM CS
    return {
      system: CS.system,
      versions: SystemVersionsInQDM CSV where CSV.startsWith(CS.system + '|') return Split(CSV, '|').last()
    }

define ValueSetsWithVersionsInQDM:
  ValueSetsInQDM VS
    return {
      url: VS.url,
      version: (ValueSetVersionsInQDM VSV where VSV.startsWith(VS.url + '|') return Split(VSV, '|').last()).single()
    }

define VSACCapabilities:
  singleton from (
    [TerminologyCapabilities] TC
      where TC.id = 'vsac-fhir-terminology'
  )

define SystemsWithVersionsInVSAC:
  VSACCapabilities.codeSystem CS
    return {
      system: CS.uri.value,
      versions: CS.version V return V.code.value
    }
    
define Systems:
  SystemsInFHIR union SystemsInQDM

define ValueSets:
  ValueSetsInFHIR union ValueSetsInQDM

define _SystemComparison:
  Systems CS
    return {
      system: CS.system,
      QDM: (SystemsWithVersionsInQDM QCS where QCS.system = CS.system return QCS.versions).single(),
      FHIR: (SystemsWithVersionsInFHIR FCS where FCS.system = CS.system return FCS.versions).single(),
      VSAC: (SystemsWithVersionsInVSAC VCS where VCS.system = CS.system return VCS.versions).single()
    }

define _SystemComparisonString:
  Combine(
    _SystemComparison SC
      return '{ "system": "' + SC.system + '", "QDM": "' + Coalesce(Combine(SC.QDM S return Split(S, '/').last(), ','), '') + '", "FHIR", "' + Coalesce(Combine(SC.FHIR S return Split(S, '/').last(), ','), '') + '", "VSAC", "' + Coalesce(Combine(SC.VSAC S return Split(S, '/').last(), ','), '') + '" }',
    '\r\n'
  )

define _ValueSetComparison:
  ValueSets VS
    return {
      url: VS.url,
      QDM: (ValueSetsWithVersionsInQDM QVS where QVS.url = VS.url return QVS.version).single(),
      FHIR: (ValueSetsWithVersionsInFHIR FVS where FVS.url = VS.url return FVS.version).single()
    }

define _ValueSetComparisonQDMOnly:
  _ValueSetComparison VSC
    where VSC.QDM is not null and VSC.FHIR is null

define _ValueSetComparisonFHIROnly:
  _ValueSetComparison VSC
    where VSC.QDM is null and VSC.FHIR is not null

define _ValueSetComparisonFHIRDiffers:
  _ValueSetComparison VSC
    where VSC.QDM != VSC.FHIR
      and VSC.QDM != 'GROUPED'

define _ValueSetComparisonFHIRMatches:
  _ValueSetComparison VSC
    where VSC.QDM = VSC.FHIR
      or (VSC.QDM = 'GROUPED' and VSC.FHIR is not null)

define _ValueSetComparisonCounts: {
  Total: Count(_ValueSetComparison),
  QDMOnly: Count(_ValueSetComparisonQDMOnly),
  FHIROnly: Count(_ValueSetComparisonFHIROnly),
  Differs: Count(_ValueSetComparisonFHIRDiffers),
  Matches: Count(_ValueSetComparisonFHIRMatches)
}

define _ValueSetComparisonCSV:
  Combine(
    _ValueSetComparison VC
      return VC.url + ', ' + Coalesce(VC.QDM, '') + ', ' + Coalesce(VC.FHIR, ''),
    '\r\n'
  )

define _ValueSetComparisonString:
  Combine(
    _ValueSetComparison VC
      return '{ "url": "' + VC.url + '", "QDM": "' + Coalesce(VC.QDM, '') + '", FHIR", "' + Coalesce(VC.FHIR, '') + '" }',
    '\r\n'
  )

define _ValueSetsToPin:
  _ValueSetComparison VSC
    where VSC.QDM != 'GROUPED' or (VSC.QDM = 'GROUPED' and VSC.FHIR is not null)
    return {
      url: VSC.url,
      version: if VSC.QDM = 'GROUPED' then VSC.FHIR else VSC.QDM
    }

// ValueSetVersionParameters for FHIR (pin all value sets used in QDM 5/8 release)
// Note that this does not include pins for the grouped value sets that are not in the FHIR release yet, since we don't know what version to pin them to
// We could potentially figure that out by asking, for each of those value sets, what was the latest version as of 5/8?
define _ValueSetVersionParameters:
  _ValueSetsToPin VS
    return '{ "name": "canonicalVersion", "valueCanonical": "' + VS.url + '|' + VS.version + '" }'
