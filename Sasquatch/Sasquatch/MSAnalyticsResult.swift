// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

@objcMembers
class MSAnalyticsResult : NSObject {

  var sendingEvents = [String: MSACEventLog]()
  var succeededEvents = [String: MSACEventLog]()
  var failedEvents = [String: (MSACEventLog, NSError)]()
  var lastEvent: MSACEventLog? = nil

  var lastEventState: String? {
    guard let eventId = self.lastEvent?.eventId else {
      return nil
    }
    if self.sendingEvents[eventId] != nil {
      return "Sending"
    } else if self.succeededEvents[eventId] != nil {
      return "Succeeded"
    } else if self.failedEvents[eventId] != nil {
      return "Failed"
    }
    return nil
  }

  func willSend(eventLog: MSACEventLog!) {
    sendingEvents[eventLog.eventId] = eventLog;
    lastEvent = eventLog;
  }
  
  func didSucceedSending(eventLog: MSACEventLog!) {
    sendingEvents.removeValue(forKey: eventLog.eventId)
    succeededEvents[eventLog.eventId] = eventLog;
    if (lastEvent == nil) {
      lastEvent = eventLog;
    }
  }
  
  func didFailSending(eventLog: MSACEventLog!, withError error: NSError) {
    sendingEvents.removeValue(forKey: eventLog.eventId)
    failedEvents[eventLog.eventId] = (eventLog, error);
    if (lastEvent == nil) {
      lastEvent = eventLog;
    }
  }
}
