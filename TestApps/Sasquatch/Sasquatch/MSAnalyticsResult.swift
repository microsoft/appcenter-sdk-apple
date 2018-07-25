@objc class MSAnalyticsResult : NSObject {
  var sendingEvents = [String: MSEventLog]()
  var succeededEvents = [String: MSEventLog]()
  var failedEvents = [String: (MSEventLog, NSError)]()
  var lastEvent: MSEventLog? = nil

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
