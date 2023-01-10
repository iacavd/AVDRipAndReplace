param actionGroupName string
param emailContact string
param location string
param logAnalyticsWorkspaceResourceId string
param tags object

var logAlerts = [
  {
    name: 'AVD Rip and Replace Failed'
    description: 'The AVD Rip & Replace solution successfully added new session host to the specified AVD host pool.'
    severity: 0
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category  == "JobStreams"\n| where ResultDescription has "AVD Rip & Replace failed"'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'ResultDescription'
              operator: 'Include'
              values: [
                  '*'
              ]
          }
          ]
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
  {
    name: 'AVD Rip and Replace Succeeded'
    description: 'The AVD Rip & Replace solution successfully added new session host to the specified AVD host pool.'
    severity: 3
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category  == "JobStreams"\n| where ResultDescription has "AVD Rip & Replace succeeded"'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'ResultDescription'
              operator: 'Include'
              values: [
                  '*'
              ]
          }
          ]
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
  {
    name: 'New Image Found for AVD Environment'
    description: 'New Image Found for AVD Environment. Please close this alert to act as approval in workflow.'
    severity: 3
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    muteActionsDuration: 'P1D'
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category == "JobStreams"\n| extend jsonResourceDescription = parse_json(ResultDescription)\n| where jsonResourceDescription.NewImageFound == true'
          timeAggregation: 'Count'
          resourceIdColumn: '_ResourceId'
          dimensions: [
            {
              name: 'ResultDescription'
              operator: 'Include'
              values: [
                  '*'
              ]
          }
          ]
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
  {
    name: 'New Blob Uploaded to AVD Storage Container'
    description: 'New Blob Uploaded to AVD Storage Container. Please close this alert to act as approval in workflow.'
    severity: 3
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    muteActionsDuration: 'P1D'
    criteria: {
      allOf: [
        {
          query: 'StorageBlobLogs\n| where OperationName == "PutBlob" and StatusText == "Success"\n\n'
          timeAggregation: 'Count'
          dimensions: []
          operator: 'GreaterThan'
          resourceIdColumn: '_ResourceId'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
]

resource actionGroup 'Microsoft.Insights/actionGroups@2019-06-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: 'EmailAlerts'
    enabled: true
    emailReceivers: [
      {
        name: emailContact
        emailAddress: emailContact
        useCommonAlertSchema: true
      }
    ]
  }
}

resource scheduledQueryRules 'Microsoft.Insights/scheduledQueryRules@2021-08-01' = [for i in range(0, length(logAlerts)): {
  name: logAlerts[i].name
  location: location
  tags: tags
  properties: {
    actions: {
      actionGroups: [
        actionGroup.id
      ]
      customProperties: {}
    }
    criteria: logAlerts[i].criteria
    displayName: logAlerts[i].name
    description: logAlerts[i].description
    autoMitigate: false
    enabled: true
    evaluationFrequency: logAlerts[i].evaluationFrequency
    scopes: [
      logAnalyticsWorkspaceResourceId
    ]
    severity: logAlerts[i].severity
    windowSize: logAlerts[i].windowSize
  }
}]
