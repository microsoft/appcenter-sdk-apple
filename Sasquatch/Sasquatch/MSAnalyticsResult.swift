// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

@objcMembers
class MSAnalyticsResult : NSObject {

  var sendingEvents = [String: EventLog]()
  var succeededEvents = [String: EventLog]()
  var failedEvents = [String: (EventLog, NSError)]()
  var lastEvent: EventLog? = nil

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

  func willSend(eventLog: EventLog!) {
    sendingEvents[eventLog.eventId] = eventLog;
    lastEvent = eventLog;
  }
  
  func didSucceedSending(eventLog: EventLog!) {
    sendingEvents.removeValue(forKey: eventLog.eventId)
    succeededEvents[eventLog.eventId] = eventLog;
    if (lastEvent == nil) {
      lastEvent = eventLog;
    }
  }
  
  func didFailSending(eventLog: EventLog!, withError error: NSError) {
    sendingEvents.removeValue(forKey: eventLog.eventId)
    failedEvents[eventLog.eventId] = (eventLog, error);
    if (lastEvent == nil) {
      lastEvent = eventLog;
    }
  }
}
