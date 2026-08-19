# TMP Message Example

The resources and transformations in this IG start from a basic JSON message that pushes telemonitoring information from a provider to a hospital (or another consumer). 

```mermaid
flowchart LR
    subgraph Message["<b>TMP Base JSON Message</b>"]
        T1["telemonitoringId"]
        T2["carepath (id, version)"]
        T3["prescriber (NIHDI)"]
        T4["patientId (SSIN)"]
        T5["service (Clinical Code)"]
        T6["attachments[] (PDF / Report)"]
    end

    subgraph FHIR["<b>Target FHIR Interhub Resources</b>"]
        F1["<b>TelemonitoringDiagnosticReport</b><br/>• telemonitoring-id extension<br/>• carepath extension<br/>• presentedForm (attachment)"]
        F2["<b>BeTelemonitoringComposition</b><br/>• author (prescriber)<br/>• subject (patient)<br/>• type (service LOINC)"]
    end

    T1 --> F1
    T2 --> F1
    T6 --> F1
    T3 --> F2
    T4 --> F2
    T5 --> F2
```

This is an example of a message that can be sent by a provider:

```json
{
  "telemonitoringId": "",
  "status": "requested",
  "prescriber": "",
  "patientId": "",
  "service": "",
  "prescriberApplication": "",
  "attachments": [
    {
      "id": "",
      "name": "",
      "etag": "",
      "contentType": "application/pdf",
      "contentLanguage": "nl",
      "lastModified": "",
      "uri": "",
      "headers": {
        "additionalProperty": ""
      }
    }
  ],
  "carepath": {
    "id": "",
    "version": ""
  },
  "patientAuthenticationToken": "",
  "patientAuthenticationUrl": ""
}
```
