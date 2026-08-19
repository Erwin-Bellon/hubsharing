# Laboratory Report Document Sharing (LabReport)

## 1. Overview & Business Context

Laboratory test results represent one of the highest-volume document categories in the Belgian healthcare ecosystem. In legacy KMEHR exchanges, laboratory reports were transmitted under the `CD-TRANSACTION` code `labresult`, often embedding structured KMEHR `<item>` elements or base64-encoded PDF/text files.

Under the modernized Interhub FHIR specification, all laboratory reports are published and shared as **self-contained FHIR Document Bundles (`Bundle.type = #document`)**. This specification directly integrates the work of **HL7 Belgium (`BeLaboratoryReport`)**, the Belgian **DIGIRELAB Phase 3** initiative, and the **EHDS EU Laboratory Report (`Composition-eu-lab`)** standard.

---

## 2. Document Architecture & Composition Structure

A Belgian Laboratory Report FHIR Document is structured as follows:

```mermaid
flowchart TD
    subgraph Bundle["<b>LABORATORY REPORT FHIR BUNDLE</b> (Bundle.type = 'document')<br/>• identifier: urn:oid:1.3.6.1.4.1.21297.100.2.1.815933567<br/>• timestamp: 2026-03-15T10:30:00Z"]
        direction TB

        subgraph RootComp["<b>entry[0] : BeInterhubLabComposition (Root Composition)</b>"]
            CompData["• type: LOINC 11502-2 ('Laboratory report')<br/>• category: CD-TRANSACTION #labresult<br/>• status: #final<br/>• title: 'Biochemistry & Hematology Laboratory Report'<br/>• section[0]: 'Clinical Biochemistry' (LOINC 18719-5)<br/>&nbsp;&nbsp;↳ narrative text.div (XHTML)"]
        end

        subgraph PanelRep["<b>entry[1] : DiagnosticReport</b> (Panel Header & Conclusion)"]
            RepData["• category: v2-0074 #LAB ('Laboratory')<br/>• code: LOINC 11502-2 ('Laboratory report')<br/>• status: #final<br/>• conclusion: 'All fasting parameters within normal limits'"]
        end

        subgraph DiscreteEntries["<b>entry[2..N] : Discrete Observations, Specimens & Context</b>"]
            direction TB
            ObsGlu["<b>Observation (Glucose)</b><br/>• LOINC 1558-6 (Fasting Glucose)<br/>• value: 92 mg/dL (Ref: 70-99)"]
            ObsCrea["<b>Observation (Creatinine)</b><br/>• LOINC 2160-0 (Serum Creatinine)<br/>• value: 0.95 mg/dL (Ref: 0.70-1.20)"]
            Specimen["<b>Specimen (Blood)</b><br/>• SNOMED 119297000 (Blood specimen)<br/>• collected: 2026-03-15T08:15:00Z"]
            Patient["<b>Patient (Jan Peeters)</b><br/>• SSIN: 79080412345"]
            Practitioner["<b>Practitioner (Dr. Danièle Govaerts)</b><br/>• NIHDI: 10000007999"]
            Org["<b>Organization (UZ Leuven)</b><br/>• NIHDI: 71000012"]
        end

        RootComp -->|"subject"| Patient
        RootComp -->|"author"| Practitioner
        RootComp -->|"author / custodian"| Org
        RootComp -->|"section.entry"| PanelRep
        RootComp -->|"section.entry"| ObsGlu
        RootComp -->|"section.entry"| ObsCrea

        PanelRep -->|"result"| ObsGlu
        PanelRep -->|"result"| ObsCrea
        PanelRep -->|"specimen"| Specimen
        PanelRep -->|"subject"| Patient
        PanelRep -->|"performer"| Org
        PanelRep -->|"resultsInterpreter"| Practitioner

        ObsGlu -->|"subject"| Patient
        ObsGlu -->|"specimen"| Specimen
        ObsCrea -->|"subject"| Patient
        ObsCrea -->|"specimen"| Specimen
    end
```

---

## 3. Key Clinical Coding & Laboratory Disciplines

### 3.1 Standard Document & Category Identifiers
* **`Bundle.type`**: `#document` (Mandatory).
* **`Composition.category`**: `https://www.ehealth.fgov.be/standards/fhir/core/CodeSystem/cd-transaction#labresult` ("Laboratory Result").
* **`Composition.type`**: `http://loinc.org#11502-2` ("Laboratory report").
* **`DiagnosticReport.category`**: `http://terminology.hl7.org/CodeSystem/v2-0074#LAB` ("Laboratory").

### 3.2 Laboratory Specialties & Section Codes
Sections within the Composition organize results by medical laboratory specialty:

| Specialty / Panel | LOINC Code | LOINC Display Name |
| :--- | :--- | :--- |
| **Clinical Biochemistry / Chemistry** | `18719-5` | Chemistry studies (set) |
| **Hematology & Coagulation** | `18723-7` | Hematology studies (set) |
| **Microbiology & Bacteriology** | `18725-2` | Microbiology studies (set) |
| **Immunology & Serology** | `18727-8` | Serology studies (set) |
| **Therapeutic Drug Monitoring (TDM)** | `18721-1` | Therapeutic drug monitoring studies (set) |
| **Urinalysis** | `18729-4` | Urinalysis studies (set) |
| **Molecular Diagnostics & Genetics** | `18728-6` | Molecular pathology studies (set) |

---

## 4. Metadata Mapping for `getTransactionList` (MHD ITI-67)

When the laboratory document is indexed in the hub registry, the corresponding `BeInterhubDocumentReference` is populated:

* `category`: `https://www.ehealth.fgov.be/standards/fhir/core/CodeSystem/cd-transaction#labresult`
* `type`: `http://loinc.org#11502-2`
* `subject`: Reference to Patient with SSIN (`79080412345`)
* `content.attachment.contentType`: `application/fhir+json`
* `content.attachment.url`: `https://hub.cozo.be/fhir/Bundle/bundle-lab-report-example-01`
* `content.format`: `urn:be:fgov:ehealth:lab:document:1.0`
* `extension[patientAccess].access`: `yes` (or `no` if results are pending consultation with the prescribing physician).

---

## 5. Complete JSON Document Walkthrough

Below is a complete, valid example of a shared Laboratory Report FHIR Document Bundle (`BundleLabReportExample`):

```json
{
  "resourceType": "Bundle",
  "id": "bundle-lab-report-example-01",
  "meta": {
    "profile": [
      "https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-interhub-document-bundle"
    ]
  },
  "identifier": {
    "system": "urn:ietf:rfc:3986",
    "value": "urn:oid:1.3.6.1.4.1.21297.100.2.1.815933567"
  },
  "type": "document",
  "timestamp": "2026-03-15T10:30:00Z",
  "entry": [
    {
      "fullUrl": "http://example.org/Composition/CompLabReportExample",
      "resource": {
        "resourceType": "Composition",
        "id": "CompLabReportExample",
        "meta": {
          "profile": [
            "https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-interhub-lab-composition"
          ]
        },
        "identifier": {
          "system": "https://uzleuven.be/lab/compositions",
          "value": "COMP-LAB-2026-815933567"
        },
        "status": "final",
        "type": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "11502-2",
              "display": "Laboratory report"
            }
          ]
        },
        "category": {
          "coding": [
            {
              "system": "https://www.ehealth.fgov.be/standards/fhir/core/CodeSystem/cd-transaction",
              "code": "labresult",
              "display": "Laboratory Result"
            }
          ]
        },
        "subject": { "reference": "Patient/PatientPeeters" },
        "date": "2026-03-15T10:30:00Z",
        "author": [
          { "reference": "Practitioner/DrDanieleGovaerts" },
          { "reference": "Organization/OrgUZLeuven" }
        ],
        "title": "Biochemistry & Hematology Laboratory Report",
        "custodian": { "reference": "Organization/OrgUZLeuven" },
        "section": [
          {
            "title": "Clinical Biochemistry",
            "code": {
              "coding": [
                {
                  "system": "http://loinc.org",
                  "code": "18719-5",
                  "display": "Chemistry studies (set)"
                }
              ]
            },
            "text": {
              "status": "generated",
              "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Clinical Biochemistry:</b> Fasting glucose: 92 mg/dL (Normal). Serum creatinine: 0.95 mg/dL (Normal).</p></div>"
            },
            "entry": [
              { "reference": "DiagnosticReport/DiagnosticReportLabExample" },
              { "reference": "Observation/ObsGlucoseExample" },
              { "reference": "Observation/ObsCreatinineExample" }
            ]
          }
        ]
      }
    },
    {
      "fullUrl": "http://example.org/DiagnosticReport/DiagnosticReportLabExample",
      "resource": {
        "resourceType": "DiagnosticReport",
        "id": "DiagnosticReportLabExample",
        "status": "final",
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/v2-0074",
                "code": "LAB",
                "display": "Laboratory"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "11502-2",
              "display": "Laboratory report"
            }
          ]
        },
        "subject": { "reference": "Patient/PatientPeeters" },
        "effectiveDateTime": "2026-03-15T08:15:00Z",
        "issued": "2026-03-15T10:30:00Z",
        "performer": [{ "reference": "Organization/OrgUZLeuven" }],
        "resultsInterpreter": [{ "reference": "Practitioner/DrDanieleGovaerts" }],
        "result": [
          { "reference": "Observation/ObsGlucoseExample" },
          { "reference": "Observation/ObsCreatinineExample" }
        ],
        "specimen": [{ "reference": "Specimen/SpecimenBloodExample" }],
        "conclusion": "All fasting biochemistry parameters within normal reference limits."
      }
    },
    {
      "fullUrl": "http://example.org/Observation/ObsGlucoseExample",
      "resource": {
        "resourceType": "Observation",
        "id": "ObsGlucoseExample",
        "status": "final",
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/v2-0074",
                "code": "LAB",
                "display": "Laboratory"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "1558-6",
              "display": "Fasting glucose [Mass/volume] in Serum or Plasma"
            }
          ]
        },
        "subject": { "reference": "Patient/PatientPeeters" },
        "effectiveDateTime": "2026-03-15T08:15:00Z",
        "performer": [{ "reference": "Practitioner/DrDanieleGovaerts" }],
        "valueQuantity": {
          "value": 92,
          "unit": "mg/dL",
          "system": "http://unitsofmeasure.org",
          "code": "mg/dL"
        },
        "referenceRange": [
          {
            "low": { "value": 70, "unit": "mg/dL", "system": "http://unitsofmeasure.org", "code": "mg/dL" },
            "high": { "value": 99, "unit": "mg/dL", "system": "http://unitsofmeasure.org", "code": "mg/dL" }
          }
        ],
        "specimen": { "reference": "Specimen/SpecimenBloodExample" }
      }
    },
    {
      "fullUrl": "http://example.org/Observation/ObsCreatinineExample",
      "resource": {
        "resourceType": "Observation",
        "id": "ObsCreatinineExample",
        "status": "final",
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/v2-0074",
                "code": "LAB",
                "display": "Laboratory"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "2160-0",
              "display": "Creatinine [Mass/volume] in Serum or Plasma"
            }
          ]
        },
        "subject": { "reference": "Patient/PatientPeeters" },
        "effectiveDateTime": "2026-03-15T08:15:00Z",
        "performer": [{ "reference": "Practitioner/DrDanieleGovaerts" }],
        "valueQuantity": {
          "value": 0.95,
          "unit": "mg/dL",
          "system": "http://unitsofmeasure.org",
          "code": "mg/dL"
        },
        "referenceRange": [
          {
            "low": { "value": 0.70, "unit": "mg/dL", "system": "http://unitsofmeasure.org", "code": "mg/dL" },
            "high": { "value": 1.20, "unit": "mg/dL", "system": "http://unitsofmeasure.org", "code": "mg/dL" }
          }
        ],
        "specimen": { "reference": "Specimen/SpecimenBloodExample" }
      }
    },
    {
      "fullUrl": "http://example.org/Specimen/SpecimenBloodExample",
      "resource": {
        "resourceType": "Specimen",
        "id": "SpecimenBloodExample",
        "type": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "119297000",
              "display": "Blood specimen"
            }
          ]
        },
        "subject": { "reference": "Patient/PatientPeeters" },
        "collection": {
          "collectedDateTime": "2026-03-15T08:15:00Z"
        }
      }
    },
    {
      "fullUrl": "http://example.org/Patient/PatientPeeters",
      "resource": {
        "resourceType": "Patient",
        "id": "PatientPeeters",
        "identifier": [
          {
            "system": "https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/ssin",
            "value": "79080412345"
          }
        ],
        "name": [{ "family": "Peeters", "given": ["Jan"] }],
        "gender": "male",
        "birthDate": "1979-08-04"
      }
    },
    {
      "fullUrl": "http://example.org/Practitioner/DrDanieleGovaerts",
      "resource": {
        "resourceType": "Practitioner",
        "id": "DrDanieleGovaerts",
        "identifier": [
          {
            "system": "https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/nihdi",
            "value": "10000007999"
          }
        ],
        "name": [{ "family": "Govaerts", "given": ["Danièle"] }]
      }
    },
    {
      "fullUrl": "http://example.org/Organization/OrgUZLeuven",
      "resource": {
        "resourceType": "Organization",
        "id": "OrgUZLeuven",
        "identifier": [
          {
            "system": "https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/nihdi",
            "value": "71000012"
          }
        ],
        "name": "UZ Leuven"
      }
    }
  ]
}
```
