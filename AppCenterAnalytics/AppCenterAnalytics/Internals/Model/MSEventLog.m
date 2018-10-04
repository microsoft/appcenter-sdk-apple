#import "AppCenter+Internal.h"
#import "MSAnalyticsInternal.h"
#import "MSCSData.h"
#import "MSCSModelConstants.h"
#import "MSEventLogPrivate.h"
#import "MSEventProperties.h"
#import "MSEventPropertiesInternal.h"

static NSString *const kMSTypeEvent = @"event";

static NSString *const kMSId = @"id";

static NSString *const kMSTypedProperties = @"typedProperties";

@implementation MSEventLog

- (instancetype)init {
    if ((self = [super init])) {
        self.type = kMSTypeEvent;
    }
    return self;
}

- (NSMutableDictionary *)serializeToDictionary {
    NSMutableDictionary *dict = [super serializeToDictionary];

    if (self.eventId) {
        dict[kMSId] = self.eventId;
    }
    if (self.typedProperties) {
        dict[kMSTypedProperties] = [self.typedProperties serializeToArray];
    }
    return dict;
}

- (BOOL)isValid {
    return [super isValid] && self.eventId;
}

- (BOOL)isEqual:(id)object {
    if (![(NSObject *) object isKindOfClass:[MSEventLog class]] ||
            ![super isEqual:object]) {
        return NO;
    }
    MSEventLog *eventLog = (MSEventLog *) object;
    return ((!self.eventId && !eventLog.eventId) ||
            [self.eventId isEqualToString:eventLog.eventId]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _eventId = [coder decodeObjectForKey:kMSId];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.eventId forKey:kMSId];
}

#pragma mark - MSAbstractLog

- (MSCommonSchemaLog *)toCommonSchemaLogForTargetToken:(NSString *)token {
    MSCommonSchemaLog *csLog = [super toCommonSchemaLogForTargetToken:token];

    // Event name goes to part A.
    csLog.name = self.name;

    // Event properties goes to part C.
    MSCSData *data = [MSCSData new];
    csLog.data = data;
    csLog.data.properties =
            [self convertACPropertiesToCSproperties:self.properties];
    return csLog;
}

#pragma mark - Helper

- (NSDictionary<NSString *, NSString *> *)convertACPropertiesToCSproperties:
        (NSDictionary<NSString *, NSString *> *)acProperties {
    NSMutableDictionary *csProperties;
    if (acProperties) {
        csProperties = [NSMutableDictionary new];
        for (NSString *acKey in acProperties) {

            // Properties keys are mixed up with other keys from Data, make sure they
            // don't conflict.
            if ([acKey isEqualToString:kMSDataBaseData] ||
                    [acKey isEqualToString:kMSDataBaseDataType]) {
                MSLogWarning(MSAnalytics.logTag,
                        @"Cannot use %@ in properties, skipping that property.",
                        acKey);
                continue;
            }

            // If the key contains a '.' then it's nested objects (i.e: "a.b":"value"
            // => {"a":{"b":"value"}}).
            NSArray *csKeys = [acKey componentsSeparatedByString:@"."];
            NSUInteger lastIndex = csKeys.count - 1;
            NSMutableDictionary *destProperties = csProperties;
            for (NSUInteger i = 0; i < lastIndex; i++) {
                NSMutableDictionary *subObject = nil;
                if ([(NSObject *) destProperties[csKeys[i]] isKindOfClass:[NSMutableDictionary class]]) {
                    subObject = destProperties[csKeys[i]];
                }
                if (!subObject) {
                    if (destProperties[csKeys[i]]) {
                        MSLogWarning(MSAnalytics.logTag,
                                @"Property key '%@' already has a value, the old value will be overridden.",
                                csKeys[i]);
                    }
                    subObject = [NSMutableDictionary new];
                    destProperties[csKeys[i]] = subObject;
                }
                destProperties = subObject;
            }
            if (destProperties[csKeys[lastIndex]]) {
                [destProperties removeObjectForKey:csKeys[lastIndex]];
                MSLogWarning(MSAnalytics.logTag,
                        @"Property key '%@' already has a value, the old value will be overridden.",
                        csKeys[lastIndex]);
            }
            destProperties[csKeys[lastIndex]] = acProperties[acKey];
        }
    }
    return csProperties;
}

@end
