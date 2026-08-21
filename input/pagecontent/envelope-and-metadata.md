# Document Envelope & Metadata Specification

> **Where this page sits in the guide** — *Specification*, page 1 of 4. This page is the **single source of truth for `BeInterhubDocumentReference`**. Every other page that mentions a metadata field, extension or identifier links back here instead of restating it.
>
> * **Owned by this page:** all `DocumentReference` elements, the four Belgian extensions (`homeCommunityId`, `patientAccess`, `endToEndEncryption`, `recordDateTime`), and the UTC normalization rule.
> * **Not covered here:** how the envelope is queried and returned → [Transactions](transactions.html); who may call and how the call is authenticated → [Security & Authentication](security.html); whether the payload behind `content.attachment.url` should itself be encrypted → [End-to-End Encryption](end-to-end-encryption.html); the KMEHR / XDS.b origin of each field → [KMEHR to FHIR Mapping](mapping-kmehr-to-hub.html).
> * **Previous:** [Design Rationale](resource-considerations.html) · **Next:** [Transactions](transactions.html)

## 1. Overview of the Metadata Model

In the Belgian Interhub ecosystem, document discovery is strictly separated from document retrieval — the reasoning behind that separation is recorded in [Design Rationale §3](resource-considerations.html#3-the-role-of-documentreference-as-discovery-envelope). When querying for available health records (`getTransactionList`, specified in [Transactions §2](transactions.html#2-transaction-1-gettransactionlist-mhd-iti-67-find-documentreferences)), client applications receive a lightweight metadata envelope: the **`BeInterhubDocumentReference`**.

```mermaid
classDiagram
    class BeInterhubDocumentReference {
        +masterIdentifier: Identifier (RFC 3986 URI)
        +identifier[uniqueId]: Identifier (RFC 3986 URI)
        +identifier[localId]: Identifier (Local Hub Source ID)
        +status: code (current | superseded)
        +docStatus: code (preliminary | final | amended)
        +category: CD-TRANSACTION (labresult, telemonitoring, sumehr)
        +type: LOINC (e.g. 11502-2, 10185-7)
        +date: instant (UTC ISO 8601)
        +description: string
        +securityLabel: Confidentiality (N, R, V)
    }

    class BeExtHomeCommunityId {
        +valueUri: urn:oid:1.3.6.1.4.1.21297.1.X (Hub OID)
    }

    class BeExtPatientAccess {
        +access: code (yes | no | never)
        +accessDate: date (optional)
        +deniedReason: string (optional)
    }

    class BeExtEndToEndEncryption {
        +actorId: string (NIHDI / CBE / SSIN)
        +actorType: code (NIHII, CBE, SSIN)
        +keyId: string (ETK Key ID)
    }

    class ContentAttachment {
        +contentType: application/fhir+json
        +language: nl-BE | fr-BE | de-BE | en
        +url: https://hub.../fhir/Bundle/{id}
        +format: Coding (urn:be:fgov:ehealth:...)
        +title: string
    }

    class SubjectPatient {
        +identifier: SSIN / INSS
    }

    class AuthorList {
        +author[0]: Regional Hub (Organization)
        +author[1]: Originating Hub Source (Organization)
        +author[2]: Authoring Physician (Practitioner)
    }

    BeInterhubDocumentReference *-- BeExtHomeCommunityId : extension
    BeInterhubDocumentReference *-- BeExtPatientAccess : extension
    BeInterhubDocumentReference *-- BeExtEndToEndEncryption : extension (opt)
    BeInterhubDocumentReference *-- ContentAttachment : content.attachment
    BeInterhubDocumentReference --> SubjectPatient : subject
    BeInterhubDocumentReference --> AuthorList : author[]
```

This metadata envelope provides:
1. **Clinical Context**: Document category (`CD-TRANSACTION`), precise clinical type (LOINC), clinical encounter period, and confidentiality level.
2. **Author & Institutional Attribution**: Answering hub, originating hub source organisation, and authoring healthcare practitioner.
3. **Retrieval & Routing Endpoints**: The exact RESTful URL to fetch the full FHIR Document Bundle (`type = #document`), accompanied by the repository Home Community ID.
4. **Technical Payload Characteristics**: MIME content type (`application/fhir+json`), document language, and format specification code.
5. **Belgian Governance & Access Rules**: Granular patient portal access permissions, release dates, and end-to-end encryption metadata.

Filled-in examples of this envelope for each supported document type are given in [Laboratory Reports §4](lab-report-sharing.html#4-metadata-mapping-for-gettransactionlist-mhd-iti-67) and [Telemonitoring §4](mapping-telemonitoring-to-hub.html#4-metadata-mapping-for-gettransactionlist-mhd-iti-67).

---

## 2. Element-by-Element Specification (`BeInterhubDocumentReference`)

Every row below is normative for Belgian Interhub exchanges. The legacy KMEHR and IHE XDS.b counterpart of each element — and the transformation logic between them — is listed in [KMEHR to FHIR Mapping §2](mapping-kmehr-to-hub.html#2-master-metadata-mapping-matrix); the search parameters that can be used against these elements are in [Transactions §2.2](transactions.html#22-http-interaction--query-parameters).

| Element | Card. | Type | Description & Belgian Mapping Rule |
| :--- | :--- | :--- | :--- |
| **`masterIdentifier`** | `0..1` | `Identifier` | Globally unique master identifier for this version of the document, formatted as an RFC 3986 URI (e.g., `urn:oid:1.3.6.1.4.1.21297.100.2.1.815933567` or `urn:uuid:...`). |
| **`identifier[uniqueId]`** | `1..1` | `Identifier` | Universal document entry identifier. Must use `system = "urn:ietf:rfc:3986"`. Directly maps to `XDSDocumentEntry.uniqueId` and KMEHR `transactionSummary/id`. |
| **`identifier[localId]`** | `0..*` | `Identifier` | Local identifier assigned by the originating hub source system (hospital EHR, laboratory information system, practice software, …) (e.g. `LAB-2026-03-815933567`). |
| **`status`** | `1..1` | `code` | Metadata lifecycle status: `current` (approved and active), `superseded` (replaced by a newer version), or `entered-in-error`. |
| **`docStatus`** | `0..1` | `code` | Clinical status of the underlying document: `preliminary`, `final`, `amended`. Mapped from KMEHR `iscomplete` / `isvalidated`. |
| **`category[cdTransaction]`** | `1..1` | `CodeableConcept` | Document category coded using the Belgian `CD-TRANSACTION` code system (`https://www.ehealth.fgov.be/standards/fhir/core/CodeSystem/cd-transaction`, OID `1.3.6.1.4.1.21297.100.3.1`). Examples: `sumehr`, `labresult`, `discharge`, `telemonitoring`, `note`, `referral`. |
| **`type`** | `1..1` | `CodeableConcept` | Precise clinical document type. Must use LOINC (e.g., `11502-2` for Laboratory Report, `10185-7` for Holter Study, `34133-9` for Summarization of Episode) or Belgian clinical type codes. |
| **`subject`** | `1..1` | `Reference(Patient)` | Reference to the patient. The referenced Patient resource must contain the official Belgian Social Security Identification Number (**SSIN / INSS**). |
| **`date`** | `1..1` | `instant` | Timestamp when the document metadata entry was created/indexed, standardized in **UTC (Z)** format (ISO 8601 `YYYY-MM-DDThh:mm:ssZ`). |
| **`author`** | `1..*` | `Reference(...)` | Sequence of authors. In Belgian Hub rules, author references follow a specific order of granularity: (1) Answering Hub, (2) Originating Hub Source Organisation, (3) Authoring Practitioner / Physician. |
| **`authenticator`** | `0..1` | `Reference(...)` | Healthcare professional or organization legally validating/attesting the document. |
| **`custodian`** | `0..1` | `Reference(Organization)` | Organization responsible for the long-term maintenance of the document record (e.g. the hub source organisation). |
| **`relatesTo`** | `0..*` | `BackboneElement` | Explicit relationships to previous documents (e.g., `replaces` for amended documents, `appends` for addenda). |
| **`description`** | `0..1` | `string` | UTF-8 human-readable document title or caption (e.g., *"Comprehensive Blood Biochemistry and Hematology Laboratory Report"*). |
| **`securityLabel`** | `0..*` | `CodeableConcept` | Confidentiality classification from HL7 v3 Confidentiality (`N` = Normal, `R` = Restricted, `V` = Very Restricted / Secret). |
| **`content.attachment.contentType`** | `1..1` | `code` | MIME type of the document payload. For Belgian Interhub document sharing, this is **`application/fhir+json`** (or `application/fhir+xml`). Fallback binary formats like `application/pdf` are also supported. |
| **`content.attachment.language`** | `0..1` | `code` | BCP-47 / RFC 5646 language tag (`nl-BE`, `fr-BE`, `de-BE`, `en`). |
| **`content.attachment.url`** | `1..1` | `url` | Direct RESTful URL to retrieve the full FHIR Document Bundle (MHD ITI-68 retrieve endpoint, e.g. `https://hub.cozo.be/fhir/Bundle/bundle-lab-report-example-01`). |
| **`content.attachment.title`** | `0..1` | `string` | Display title for the attachment. |
| **`content.format`** | `0..1` | `Coding` | Format code identifying the document specification (e.g. `urn:be:fgov:ehealth:lab:document:1.0`, `urn:be:fgov:ehealth:telemonitoring:document:1.0`). |
| **`context.period`** | `0..1` | `Period` | Start and end date/time of the clinical encounter, hospital stay, or telemonitoring monitoring session. |
| **`context.facilityType`** | `0..1` | `CodeableConcept` | Healthcare facility classification (Belgian Facility Type OID `1.3.6.1.4.1.21297.100.4.1`). |
| **`context.practiceSetting`** | `0..1` | `CodeableConcept` | Clinical medical specialty / practice setting (Belgian Practice Setting OID `1.3.6.1.4.1.21297.100.5.1`). |

---

## 3. Belgian Extensions Deep-Dive

### 3.1 Home Community ID (`BeExtHomeCommunityId`)
* **URL**: `https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-ext-home-community-id` (or `urn:ihe:iti:xds:2023:homeCommunityId`)
* **Cardinality**: `1..1` (Mandatory for Interhub exchanges)
* **Value**: `uri` (e.g., `urn:oid:1.3.6.1.4.1.21297.1.3` for CoZo, `urn:oid:1.3.6.1.4.1.21297.1.1` for BHN)
* **Purpose**: Identifies the regional hub responsible for managing the document. Essential for cross-community federation, allowing initiating gateways to route retrieve calls to the correct responding hub. The routing mechanics that consume this value are described in [Architecture §3.2](architecture.html#32-routing-mechanics-via-homecommunityid), and its role in the multi-hub model versus the single-NCP European model in [EHDS Alignment §3.1](ehds-alignment.html#3-belgian-advancements-beyond-baseline-ehds).

### 3.2 Belgian Patient Access Metadata (`BeExtPatientAccess`)
In the Belgian healthcare system, patients have a legal right to access their medical records via certified national/regional portals (e.g. MaSanté / MijnGezondheid). However, physicians may withhold or delay document release under specific clinical circumstances (therapeutic exception or pending consultation).

This extension *carries* the rule; enforcing it is the initiating hub's responsibility, as set out in [Security & Authentication §1.1](security.html#11-trust-model-access-control-is-the-initiating-hubs-responsibility). How it is applied at the European border is described in [EHDS Alignment §3.2](ehds-alignment.html#32-granular-patient-access-governance-beextpatientaccess).

* **URL**: `https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-ext-patient-access`
* **Sub-extensions**:
  1. `access` (`code`, `1..1`, ValueSet: `BeVSPatientAccess`):
     * `yes`: Document is accessible to the patient (subject to optional release date).
     * `no`: Document is temporarily not accessible to the patient. May be released later by the treating physician.
     * `never`: Document is permanently restricted from patient access.
  2. `accessDate` (`date`, `0..1`): Release date (inclusive) after which the document becomes visible on patient portals. Only valid when `access = yes`.
  3. `deniedReason` (`string`, `0..1`): Textual explanation why the document is withheld from the patient (applicable when `access = no` or `never`).

### 3.3 End-to-End Encryption Metadata (`BeExtEndToEndEncryption`)
This extension only *declares* that a payload is encrypted and for whom. Whether Belgium should encrypt FHIR payloads at all, which mechanism to use (JWE or CMS), and the tiered strategy this IG recommends are discussed in [End-to-End Encryption](end-to-end-encryption.html#5-recommended-strategic-solution-the-tiered-hybrid-architecture); the transport-level security that applies to every exchange regardless is specified in [Security & Authentication](security.html).

For cross-enterprise transmissions requiring application-level encryption:
* **URL**: `https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-ext-end-to-end-encryption`
* **Sub-extensions**:
  1. `actorId` (`string`, `1..1`): Identifier of the encryption recipient (NIHDI number, CBE number, or SSIN).
  2. `actorType` (`code`, `1..1`, ValueSet: `BeVSETKEncryptionActor`): `NIHII`, `NIHII-HOSPITAL`, `NIHII-PHARMACY`, `CBE`, `SSIN`, `EHP`.
  3. `applicationId` (`string`, `0..1`): Specific IT application identifier registered in the eHealth ETK depot.
  4. `keyId` (`string`, `0..1`): Encryption Token Key (ETK) identifier.

### 3.4 Source System Recording Timestamp (`BeExtRecordDateTime`)
* **URL**: `https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-ext-record-datetime`
* **Cardinality**: `0..1`
* **Value**: `instant` (UTC ISO 8601)
* **Purpose**: Records the exact timestamp when the document was persisted in the originating hub source system (corresponds to KMEHR `recorddatetime`).

---

## 4. Technical Algorithms & Developer Rules

### 4.1 Timezone Normalization to UTC (Z)
In KMEHR messages, dates and times are often transmitted with local Belgian offsets (CET `+01:00` / CEST `+02:00`) or separated into `<date>` and `<time>` elements. During transformation to FHIR Interhub metadata:
1. Concatenate date and time strings.
2. Apply the correct seasonal timezone offset.
3. Standardize into **UTC ISO 8601 (`YYYY-MM-DDThh:mm:ssZ`)**.

The full set of KMEHR-to-FHIR transformation rules this normalization belongs to is specified in [KMEHR to FHIR Mapping](mapping-kmehr-to-hub.html#2-master-metadata-mapping-matrix).

---

## Continue reading

* **Previous:** [Design Rationale](resource-considerations.html) — why discovery metadata is decoupled from the payload.
* **Next:** [Transactions](transactions.html) — how this envelope is searched (ITI-67) and how the payload it points to is retrieved (ITI-68).
* **Related:** [KMEHR to FHIR Mapping](mapping-kmehr-to-hub.html#2-master-metadata-mapping-matrix) for the legacy origin of every element; [Laboratory Reports](lab-report-sharing.html#4-metadata-mapping-for-gettransactionlist-mhd-iti-67) and [Telemonitoring](mapping-telemonitoring-to-hub.html#4-metadata-mapping-for-gettransactionlist-mhd-iti-67) for filled-in examples; [End-to-End Encryption](end-to-end-encryption.html) for the debate behind the `BeExtEndToEndEncryption` extension.
