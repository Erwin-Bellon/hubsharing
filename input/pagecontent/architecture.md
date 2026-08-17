# Belgian Interhub Architecture & Federation Model

## 1. The Belgian Federated Health Ecosystem

The Belgian healthcare infrastructure is built upon a **federated, decentralized architecture** governed by the eHealth Platform (`ehealth.fgov.be`). Unlike centralized national repositories, clinical data in Belgium resides locally within hospital electronic health record (EHR) vaults, private clinical laboratories, and regional hubs.

### 1.1 Key Actors & Nodes in the Network

```
+-----------------------------------------------------------------------------------+
|                           NATIONAL METAHUB REGISTRY                               |
|                - Patient-to-Hub Indexing & Directory Services                      |
|                - National Consent & Therapeutic Link Validation                   |
+-----------------------------------------------------------------------------------+
                                         |
     +-----------------------------------+-----------------------------------+
     |                                   |                                   |
+-----------------------+     +-----------------------+     +-----------------------+
|   REGIONAL HUB (CoZo) |     |   REGIONAL HUB (RSW)  |     | REGIONAL HUB (Bruhealth)|
|  - Regional Registry  |     |  - Regional Registry  |     |  - Regional Registry  |
|  - Document Gateway   |     |  - Document Gateway   |     |  - Document Gateway   |
+-----------------------+     +-----------------------+     +-----------------------+
     |                                   |                                   |
+-----------------------+     +-----------------------+     +-----------------------+
|  Hospital EHR Vaults  |     |  Hospital EHR Vaults  |     |  Hospital EHR Vaults  |
|  (e.g. UZ Leuven)     |     |  (e.g. CHU de Liège)  |     |  (e.g. Cliniques Saint-Luc)|
+-----------------------+     +-----------------------+     +-----------------------+
```

1. **National Metahub**:
   * Acts as a central directory indicating which regional hubs hold documents for a specific patient (identified by their national **SSIN / INSS**).
   * Verifies national patient consent and registers therapeutic links between healthcare providers and patients.
2. **Regional Hubs**:
   * **CoZo** (Collaborative Care Network - Flanders/national).
   * **RSW** (Réseau Santé Wallon - Wallonia).
   * **Bruhealth / Abrumet** (Brussels Health Network).
   * **VZN KU Leuven** (Flemish Academic Hospital Network).
   * Each hub acts as a regional Document Registry and Document Gateway, managing indexing, local access control, and cross-hub routing.
3. **Hospital EHR Vaults & Clinical Repositories**:
   * Authoritative source systems where clinical documents (laboratory reports, discharge summaries, imaging studies, telemonitoring records) are created, validated, and stored.

---

## 2. Evolution: From SOAP KMEHR to RESTful FHIR MHD

Historically, Interhub communication was specified using SOAP Web Services exchanging XML payloads conforming to Belgian **KMEHR** schemas (`getTransactionList`, `getTransaction`, `putTransaction`, `getTransactionAccessList`).

The modernized Belgian Interhub specification adopts **IHE MHD (Mobile access to Health Documents)** on **HL7® FHIR® R4**, creating a standardized, RESTful architecture:

```
+-----------------------------------------------------------------------------------+
|                               MHD RESTful Client                                  |
|         (Modern EHR, Regional Portal, Mobile Health App, Telemonitoring Client)    |
+-----------------------------------------------------------------------------------+
            |                                                      |
            | ITI-67 (Find DocumentReferences)                     | ITI-68 (Retrieve Document)
            | [GET /DocumentReference?patient.identifier=...]       | [GET /Bundle/{id}]
            v                                                      v
+-----------------------------------------------------------------------------------+
|                        BELGIAN INTERHUB FHIR RESPONDER                            |
|                          (Regional Hub / Document Gateway)                        |
|                                                                                   |
|   +------------------------------------+   +------------------------------------+ |
|   | Metadata Layer: DocumentReference  |   | Payload Layer: Document Bundle     | |
|   | - Unique IDs & OID trees           |   | - Bundle (type = document)         | |
|   | - Belgian Patient Access Rules     |   | - Root Composition (Lab / TM)      | |
|   | - HomeCommunityId (Hub OID)        |   | - Clinical Resources & Narrative   | |
|   +------------------------------------+   +------------------------------------+ |
+-----------------------------------------------------------------------------------+
                                         |
     +-----------------------------------+-----------------------------------+
     | (Federated ITI-67 / ITI-68)       | (Dual-Stack Mediation)            |
     v                                   v                                   v
+-----------------------+     +-----------------------+     +-----------------------+
|  Remote Regional Hub  |     |  Legacy KMEHR Vault   |     |  EHDS Cross-Border    |
|  (Home Community B)   |     |  (SOAP/XML Bridge)    |     |  (MyHealth@EU NCP)    |
+-----------------------+     +-----------------------+     +-----------------------+
```

---

## 3. Federated Cross-Hub Routing & Identifiers

In a cross-hub scenario, an **Initiating Hub** queries or retrieves documents from one or more **Responding Hubs**. Routing is governed by standardized identifiers registered in the Belgian eHealth OID tree (`1.3.6.1.4.1.21297`):

### 3.1 Belgian National Identifiers

| Concept | URI / System | OID Root | Description & Syntax Example |
| :--- | :--- | :--- | :--- |
| **Patient SSIN / INSS** | `https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/ssin` | `1.3.6.1.4.1.21297.100.1.1` | National Social Security Identification Number (e.g. `79080412345`). |
| **Practitioner NIHDI / RIZIV** | `https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/nihdi` | `1.3.6.1.4.1.21297.100.9.1` | Healthcare professional license number (11 digits, e.g. `19876543201`). |
| **Hospital / Facility NIHDI** | `https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/nihdi` | `1.3.6.1.4.1.21297.100.11.1` | Healthcare institution accreditation number (8 digits, e.g. `71000012`). |
| **Enterprise CBE / KBO** | `https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/cbe` | `1.3.6.1.4.1.21297.100.11.2` | Crossroads Bank for Enterprises business number (10 digits, e.g. `0419052173`). |
| **Hub Home Community ID** | `urn:ietf:rfc:3986` | `1.3.6.1.4.1.21297.1.X` | URN OID identifying the regional hub (e.g. `urn:oid:1.3.6.1.4.1.21297.1.3` for CoZo). |
| **Repository Unique ID** | `urn:ietf:rfc:3986` | `1.3.6.1.4.1.21297.100.2.X` | Identifies the physical document storage repository within a hub network. |
| **CD-TRANSACTION** | `https://www.ehealth.fgov.be/standards/fhir/core/CodeSystem/cd-transaction` | `1.3.6.1.4.1.21297.100.3.1` | Document category coding system (e.g. `sumehr`, `labresult`, `telemonitoring`). |

### 3.2 Routing Mechanics via `homeCommunityId`

1. **Discovery (`getTransactionList` / ITI-67)**:
   * The Initiating Hub queries the Metahub or federated hubs for a patient.
   * Every returned `BeInterhubDocumentReference` contains the mandatory extension `homeCommunityId` (e.g. `urn:oid:1.3.6.1.4.1.21297.1.3`).
2. **Retrieval (`getTransaction` / ITI-68)**:
   * The consumer inspects `DocumentReference.content.attachment.url` and `homeCommunityId` to dispatch the retrieval request directly to the authoritative repository hosting the document bundle.

---

## 4. Dual-Stack Gateway Architecture (Transition Phase)

To enable smooth migration without breaking legacy integrations, Belgian Hubs deploy a **Dual-Stack Mediation Gateway**:

* **Legacy KMEHR Client $\rightarrow$ Modern FHIR Hub**: The gateway receives SOAP `getTransactionList` or `getTransaction` requests, queries the internal FHIR registry/repository via MHD ITI-67 / ITI-68, and transforms the resulting `DocumentReference` and `Bundle (type=document)` back into KMEHR `TransactionSummaryType` or `FolderType` XML.
* **Modern FHIR Client $\rightarrow$ Legacy KMEHR Vault**: The gateway accepts RESTful MHD searches and GET requests, translates them into SOAP KMEHR Web Service calls to legacy hospital vaults, transforms the returned KMEHR XML / attachments into standardized FHIR Document Bundles, and returns them to the client.

---

## 5. Security Architecture & Connection Routes

All Interhub transactions operate under strict Belgian healthcare regulations, the Patient Rights Act, and GDPR compliance. The security architecture provides three distinct connection routes to accommodate all integration tiers:

```
+---------------------------------------------------------------------------------------------------+
|                                  THREE AUTHENTICATION ROUTES                                      |
+---------------------------------------------------------------------------------------------------+
|  1. Hub-Issued JWT Tokens        |  2. eHealth Platform IAM          |  3. STS Token Exchange Bridge  |
|  - Asymmetric signed JWTs        |  - Centralized OIDC IdP           |  - SAML 2.0 to OAuth 2.0       |
|  - Federated Hub-to-Hub trust    |  - eID / itsme® / Enterprise cert |  - Backward compatibility for  |
|  - Validated via JWKS endpoints  |  - Automated consent validation   |    legacy hospital connectors  |
+---------------------------------------------------------------------------------------------------+
```

1. **Route 1: Hub/Enterprise-Issued JWTs**: Direct peer-to-peer trust federation between regional hubs using asymmetric signed JWT bearer tokens validated against public JWKS endpoints.
2. **Route 2: eHealth Platform IAM**: Centralized identity and access management through the national eHealth OIDC provider, resolving authenticated practitioner NIHDI licenses and institution CBE numbers.
3. **Route 3: STS Token Exchange Bridge**: Seamless backward compatibility bridge translating legacy SOAP WS-Trust / SAML 2.0 assertions from the eHealth STS into short-lived OAuth 2.0 JWTs (RFC 8693).

For complete technical specifications, see **[Interhub Security Architecture](security.html)** and the **[End-to-End Encryption Discussion Paper](end-to-end-encryption.html)**.
