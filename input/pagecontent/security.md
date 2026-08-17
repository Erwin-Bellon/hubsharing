# Interhub Security & Authentication Architecture

## 1. Security Overview & Trust Model

Interhub communications across the Belgian federated health data network demand robust, interoperable security controls. Transitioning from legacy SOAP/WS-Security protocols to RESTful HL7® FHIR® requires modernizing authentication, authorization, and transport security while maintaining full compliance with Belgian health privacy laws, GDPR, and medical confidentiality.

The security architecture of the Belgian Interhub FHIR ecosystem is based on four foundational pillars:
1. **Transport Layer Security**: Mandatory **TLS 1.3** (or TLS 1.2 with strict cipher suites) with mutual certificate authentication (**mTLS**) using official Belgian eHealth organization certificates.
2. **RESTful Identity & Authorization**: Standardized **OAuth 2.0** (RFC 6749) and **OpenID Connect (OIDC)** frameworks conforming to **IHE IUA (Internet User Authorization)** and **SMART on FHIR Backend Services**.
3. **Three Authentication Routes**: Flexible connection models supporting direct Hub-to-Hub federation, the national eHealth IAM infrastructure, and a bridge for legacy systems via Security Token Service (STS) token exchange.
4. **Auditability & Traceability**: Comprehensive audit logging conforming to **IHE BALP (Basic Audit Logging Pattern)** and **IHE ATNA (Audit Trail and Node Authentication)**, fulfilling the legal requirements of the legacy `getTransactionAccessList` service.

---

## 2. The Three Authentication & Connection Routes

To accommodate various client environments (modern cloud EHRs, regional hub nodes, mobile applications, and legacy hospital middleware), the Belgian Interhub specification defines **three distinct authentication routes**:

```
+---------------------------------------------------------------------------------------------------+
|                                  THREE AUTHENTICATION ROUTES                                      |
+---------------------------------------------------------------------------------------------------+
|  ROUTE 1: Hub/Enterprise-Issued JWT   |  ROUTE 2: eHealth Platform IAM    |  ROUTE 3: STS Token Exchange  |
|  - Decentralized Hub Federation       |  - Centralized National IdP       |  - SAML 2.0 to OAuth 2.0 Bridge|
|  - Bilateral / Multilateral Trust     |  - eID / itsme® / Professional Cert| - Backward compatibility for  |
|  - Signed Asymmetric JWTs (JWKS)     |  - National Consent & Links       |    legacy hospital connectors |
+---------------------------------------+-----------------------------------+-------------------------------+
```

```
+-----------------------+     +-----------------------+     +-----------------------+
|  ROUTE 1: HUB JWT     |     |  ROUTE 2: eHealth IAM |     |  ROUTE 3: STS BRIDGE  |
|  (Direct Federation)  |     |  (National OIDC IdP)  |     |  (Legacy SAML Exchange|
+-----------------------+     +-----------------------+     +-----------------------+
            |                             |                             |
            | Bearer JWT                  | Bearer JWT (eHealth)        | SAML 2.0 Assertion
            | (Hub Private Key)           | (eHealth OIDC AS)           | (eHealth SOAP STS)
            |                             |                             v
            |                             |                   +-------------------+
            |                             |                   | Token Exchange    |
            |                             |                   | RFC 8693 Gateway  |
            |                             |                   +-------------------+
            |                             |                             | Bearer JWT
            v                             v                             v
+-----------------------------------------------------------------------------------+
|                        BELGIAN INTERHUB FHIR RESPONDER                            |
|             (Validates Signature, SSIN, NIHDI, CBE, & Scopes via JWKS)            |
+-----------------------------------------------------------------------------------+
```

---

### 2.1 Route 1: Hub/Enterprise-Issued JWT Bearer Tokens (Federated Trust)

In this route, regional Hubs (e.g. CoZo, RSW, Bruhealth/Abrumet) or major healthcare enterprises operate their own **OAuth 2.0 Authorization Servers (AS)**. Trust is established bilaterally or through a national hub federation trust registry.

#### Mechanics & Workflow:
1. The initiating client authenticates against its local Hub Authorization Server using the **OAuth 2.0 Client Credentials Flow** with asymmetric private key JWT authentication (`private_key_jwt`).
2. The local Hub AS issues a signed JSON Web Token (JWT) using its private RSA/ECDSA key.
3. The client presents the JWT in the HTTP `Authorization: Bearer <jwt>` header when calling the target hub's FHIR endpoints.
4. The responding hub validates the token signature using the issuer's public keys published at its **JSON Web Key Set (JWKS)** endpoint (`/.well-known/jwks.json`).

#### Sample Interhub JWT Claims Payload:
```json
{
  "iss": "https://auth.cozo.be",
  "sub": "client-hospital-uzl",
  "aud": "https://hub.bruhealth.be/fhir",
  "exp": 1773766800,
  "nbf": 1773763200,
  "iat": 1773763200,
  "jti": "b3e94a8c-9c71-4e78-9e51-12f8e12a4b89",
  "scope": "system/DocumentReference.read system/Bundle.read",
  "be:hub_origin": "urn:oid:1.3.6.1.4.1.21297.1.3",
  "be:practitioner": {
    "nihdi": "19876543201",
    "ssin": "65031212345",
    "name": "Dr. Jean Depondt",
    "role": "persphysician"
  },
  "be:organization": {
    "nihdi": "71000012",
    "cbe": "0419052173",
    "name": "UZ Leuven"
  },
  "be:patient_context": {
    "ssin": "79080412345"
  }
}
```

---

### 2.2 Route 2: eHealth Platform IAM (National Identity & Access Management)

In this route, authentication and authorization are centralized through the **Belgian eHealth Platform IAM** (Identity and Access Management) infrastructure.

#### Mechanics & Workflow:
1. **User Authentication**:
   * Interactive users (physicians, nurses, patients) authenticate via **eID**, **itsme®**, or TOTP mobile tokens.
   * Automated systems authenticate using **eHealth Enterprise Certificates**.
2. **Identity & Role Resolution**:
   * eHealth IAM validates the professional's credentials against federal authoritative databases: **CoBRHA** (healthcare institutions), **Federal Health Professionals Database** (NIHDI licenses), and **Crossroads Bank for Enterprises (CBE)**.
3. **Consent & Therapeutic Link Verification**:
   * eHealth IAM can perform pre-authorization checks against national consent registers and the central therapeutic links database.
4. **Token Issuance**:
   * eHealth IAM issues signed OAuth 2.0 Access Tokens and OIDC ID Tokens containing standardized federal health claims (`https://ehealth.fgov.be/claims/...`).
5. **Consumption**:
   * Any participating regional hub or repository verifies the token against the official eHealth JWKS endpoint (`https://iam.ehealth.fgov.be/.well-known/jwks.json`).

---

### 2.3 Route 3: Derived System Based on STS (SAML 2.0 to OAuth 2.0 Bridge)

Many Belgian hospital EHRs, laboratory information systems (LIS), and legacy connector middleware already integrate with the **eHealth Security Token Service (STS)** using SOAP WS-Trust and SAML 2.0 tokens (signed with physical eHealth X.509 keystores).

To enable these legacy systems to consume modern FHIR RESTful Interhub endpoints without an immediate, costly rewrite of their authentication stack, an **STS Token Exchange Gateway** is deployed:

```
[Legacy Hospital System]
           |
           | 1. Request SAML 2.0 Token (eHealth SOAP STS / WS-Trust)
           v
[eHealth Platform STS]
           |
           | 2. Issues Signed SAML 2.0 Assertion
           v
[Legacy Hospital System]
           |
           | 3. POST /oauth/token (grant_type=urn:ietf:params:oauth:grant-type:token-exchange)
           |    subject_token = <SAML 2.0 Base64 XML>
           |    subject_token_type = urn:ietf:params:oauth:token-type:saml2
           v
[Interhub STS Token Exchange Service (RFC 8693)]
           | - Validates SAML Signature against eHealth Trust Chain
           | - Extracts NIHDI, CBE, SSIN, and Role assertions
           | - Verifies timestamp and validity window
           | 4. Issues short-lived OAuth 2.0 JWT Access Token
           v
[Legacy Hospital System]
           |
           | 5. GET /fhir/DocumentReference (Authorization: Bearer <jwt>)
           v
[Belgian Interhub FHIR Responder]
```

#### RFC 8693 Token Exchange Request Example:
```http
POST /oauth/token HTTP/1.1
Host: auth-gateway.ehealth.fgov.be
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:token-exchange
&client_id=hospital-connector-uzl
&subject_token=PHNhbWwycDpBc3NlcnRpb24geG1sbnM6c2FtbDJwPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXNzZXJ0aW9uIi...
&subject_token_type=urn:ietf:params:oauth:token-type:saml2
&audience=https://hub.cozo.be/fhir
&scope=system/DocumentReference.read system/Bundle.read
```

#### Response:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "system/DocumentReference.read system/Bundle.read"
}
```

---

## 3. Authorization Scopes & Access Control (SMART on FHIR / IUA)

All Interhub endpoints enforce fine-grained scope-based access controls based on SMART on FHIR and IHE IUA:

| Scope | Allowed Interaction | Semantic Description |
| :--- | :--- | :--- |
| `system/DocumentReference.read` | `GET [base]/DocumentReference` | Search and read document metadata across all accessible patients (Hub-to-Hub federation). |
| `system/Bundle.read` | `GET [base]/Bundle/{id}` | Retrieve complete FHIR Document Bundles (type = `document`). |
| `patient/DocumentReference.read`| `GET [base]/DocumentReference?patient=...` | Restricted metadata search for a specific patient in context. |
| `patient/Bundle.read` | `GET [base]/Bundle/{id}` | Retrieve document bundles belonging to the authorized patient. |

---

## 4. Audit Trail & Traceability (`getTransactionAccessList` $\longleftrightarrow$ IHE BALP)

Under Belgian law (Patient Rights Act & eHealth Platform Law), every access, search, and retrieval of medical records must be immutably recorded for auditability. In the legacy KMEHR world, the `getTransactionAccessList` SOAP service exposed access logs.

In the FHIR Interhub standard, auditing is standardized using **IHE BALP (Basic Audit Logging Pattern)** and **IHE ATNA** generating FHIR **`AuditEvent`** resources:

```
+-----------------------------------------------------------------------------------+
|                               AUDITEVENT STRUCTURE                                |
|                                                                                   |
|  - type           : DCM #110112 ("Query") or #110106 ("Export")                   |
|  - subtype        : ITI-67 ("FindDocumentReferences") or ITI-68 ("RetrieveDocument")|
|  - action         : #E (Execute) or #R (Read)                                     |
|  - recorded       : 2026-03-15T10:30:05Z (UTC instant)                            |
|  - agent[0]       : Requesting Practitioner (NIHDI: 19876543201)                  |
|  - agent[1]       : Requesting Healthcare Organization (NIHDI: 71000012)          |
|  - agent[2]       : Initiating / Answering Hub (Home Community ID OID)             |
|  - entity[0]      : Patient Subject (SSIN: 79080412345)                           |
|  - entity[1]      : Queried / Retrieved DocumentReference or Bundle ID            |
|  - outcome        : #0 (Success) or #4 (Minor failure / Access Denied)            |
+-----------------------------------------------------------------------------------+
```

These `AuditEvent` records are retained by the answering hubs for the legally mandated period (minimum 10 years in Belgium) and made accessible to patients via national transparency portals.
