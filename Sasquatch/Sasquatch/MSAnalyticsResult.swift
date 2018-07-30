@objc class MSAnalyticsResult : NSObject {

  var sendingEvents = [String: MSEventLog]()
  var succeededEvents = [String: MSEventLog]()
  var failedEvents = [String: (MSEventLog, NSError)]()
  var lastEvent: MSEventLog? = nil

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

  func willSend(eventLog: MSEventLog!) {
    sendingEvents[eventLog.eventId] = eventLog;
    lastEvent = eventLog;
  }
  
  func didSucceedSending(eventLog: MSEventLog!) {
    sendingEvents.removeValue(forKey: eventLog.eventId)
    succeededEvents[eventLog.eventId] = eventLog;
    if (lastEvent == nil) {
      lastEvent = eventLog;
    }
  }
  
  func didFailSending(eventLog: MSEventLog!, withError error: NSError) {
    sendingEvents.removeValue(forKey: eventLog.eventId)
    failedEvents[eventLog.eventId] = (eventLog, error);
    if (lastEvent == nil) {
      lastEvent = eventLog;
    }
  }
}
