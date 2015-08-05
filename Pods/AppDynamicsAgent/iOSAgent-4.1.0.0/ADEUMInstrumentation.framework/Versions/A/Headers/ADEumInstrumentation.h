//  Copyright (c) 2013 AppDynamics Technologies. All rights reserved.

#import <Foundation/Foundation.h>
#import "ADEumCollectorChannel.h"

/** The configuration of the AppDynamics SDK
 */
@interface ADEumAgentConfiguration : NSObject

/**
 * The application key.
 *
 * @warning This property is required.
 */
@property (nonatomic, copy) NSString *appKey;

/**
 * The URL of the collector.
 *
 * The SDK will send beacons to this collector.
 */
@property (nonatomic, copy) NSString *collectorURL;

/**
 * Whether debug logging is enabled.
 *
 * @warning Not recommended for production.
 */
@property (nonatomic) BOOL enableLogging;

/**
 * The custom collector channel to use.
 *
 * This is only needed when customizing the communication channel between
 * the SDK and the collector. Most users will not need this.
 */
@property (nonatomic, strong) id<ADEumCollectorChannel> collectorChannel;

/**
 * Returns a configuration with the specified app key and defaults for the other properties.
 *
 * @param appKey The application key to use.
 */
- (id)initWithAppKey:(NSString *)appKey;

/**
 * Returns a configuration with the specified app key and collector URL,
 * and defaults for the other properties.
 *
 * @param appKey The application key to use.
 * @param collectorURL The URL of the collector.
 */
- (id)initWithAppKey:(NSString *)appKey collectorURL:(NSString *)collectorURL;

@end

/** AppDynamics iOS SDK
 */
@interface ADEumInstrumentation : NSObject

///---------------------
/// @name Initialization
///---------------------

/** Initialize the SDK.
 *
 * Call this method once, early in your application's startup sequence.
 *
 * @param appKey The application key to use.
 *
 * @warning `appKey` must not be `nil`.
 */
+ (void)initWithKey:(NSString *)appKey;

/** Initialize the SDK.
 *
 * Call this method once, early in your application's startup sequence.
 *
 * @param appKey The application key to use.
 * @param collectorUrl The URL of the collector. The SDK will send beacons to this collector.
 *
 * @warning `appKey` must not be `nil`.
 * @warning `collectorUrl` must not be `nil`.
 */
+ (void)initWithKey:(NSString *)appKey collectorUrl:(NSString *)collectorUrl;

/** Initialize the SDK.
 *
 * Call this method once, early in your application's startup sequence.
 *
 * @param agentConfiguration The configuration to use.
 *
 * @warning `agentConfiguration` must not be `nil`.
 */
+ (void)initWithConfiguration:(ADEumAgentConfiguration *)agentConfiguration;

/** Change the application key.
 *
 * The SDK doesn't send all instrumentation data immediately, and calling this method causes all unsent
 * data to be discarded, so use this method sparingly.
 *
 * @param appKey The new application key to use.
 *
 * @warning `appKey` must not be `nil`.
 */
+ (void)changeAppKey:(NSString*)appKey;

///---------------------
/// @name Instrumenting application methods
///---------------------

/**
 * Call this at the beginning of a method's execution to track that method invocation.
 *
 * @param receiver The object to which this message was sent.
 * @param selector The selector describing the message that was sent.
 * @param arguments The values of the arguments of this method call. This parameter is optional and may be nil.
 *                   Additionally, you are free to send only a subset of the actual arguments.
 *
 * @return An object that must be passed to endCall:.
 *
 * @warning `receiver` must not be `nil`.
 * @warning `selector` must not be `nil`.
 *
 * @see +endCall:
 * @see +endCall:withValue:
 */
+ (id)beginCall:(id)receiver selector:(SEL)selector withArguments:(NSArray *)arguments;

/**
 * Equivalent to beginCall:receiver selector:selector arguments:nil.
 *
 * @param receiver The object to which this message was sent.
 * @param selector The selector describing the message that was sent.
 *
 * @see +beginCall:selector:withArguments:
 */
+ (id)beginCall:(id)receiver selector:(SEL)selector;

/**
 * Call this right before returning from a method to finish tracking the method invocation.
 *
 * @param call The object returned from beginCall:Selector:withArguments:.
 * @param returnValue The return value of the method. This is optional, and may be nil.
 */
+ (void)endCall:(id)call withValue:(id)returnValue;

/**
 * Equivalent to endCall:call withValue:nil.
 *
 * @param call The object returned from beginCall:Selector:withArguments:.
 *
 * @see +endCall:withValue:
 */
+ (void)endCall:(id)call;

///---------------------
/// @name Timing events
///---------------------

/**
 * Starts a timer for tracking a user-defined event with a duration.
 *
 * If this method is called multiple times without a corresponding call to stopTimerWithName,
 * every call after the first will reset the timer.
 *
 * @param name The name of the timer, which will determine the name of the corresponding metric.
 *             Generally, timers that are logically separate should have distinct names.
 * 
 * @warning `name` may not be `nil` or the empty string, and must consist only of alphanumeric characters.
 */
+ (void) startTimerWithName:(NSString*)name;

/**
 * Stops a timer for tracking a user-defined event with a duration.
 *
 * If you haven't called startTimerWithName with the given name before calling this method, this method has no effect.
 *
 * @param name The name of the timer, which will determine the name of the corresponding metric.
 *             Generally, timers that are logically separate should have distinct names.
 *
 * @warning `name` may not be `nil` or the empty string, and must consist only of alphanumeric characters.
 */
+ (void) stopTimerWithName:(NSString*)name;

///---------------------
/// @name Reporting metrics
///---------------------

/**
 * Reports the value of a custom metric.
 *
 * @param name The name of the metric.
 * @param value The value of the metric.
 *
 * @warning `name` may not be `nil` or the empty string, and must consist only of alphanumeric characters.
 */
+ (void)reportMetricWithName:(NSString*)name value:(int64_t)value;


///---------------------
/// @name Breadcrumbs tracking for crash reports
///---------------------

/**
 * Records the value of breadcrumb and assigns it a current timestamp.
 *
 * Call this when something interesting happens in your application. If your
 * application crashes at some point in the future, the breadcrumb will
 * be included in the crash report, to help you understand the problem.
 *
 * @param breadcrumb The value of breadcrumb.
 *
 * @warning Only non `nil` and non the empty string will be recorded. Breadcrumb will be truncated if longer than 2048 characters.
 */
+ (void)leaveBreadcrumb:(NSString*)breadcrumb;


///---------------------
/// @name UserData tracking
///---------------------

/**
 * Sets a key-value pair identifier that will be included in all snapshots.
 * The identifier can be used to add any data you wish.
 *
 * The key must be unique across your application.  Re-using the same key overwrites the previous value.
 * Both the key and the value are limited to 2048 characters.
 *
 * A value of null will clear the data.
 *
 * If persist is set to YES, this data is stored across multiple app instances.
 * If persist is set to NO, this data is only sent during this app instance, and is removed when the
 * instance is terminated.
 *
 * Once the whole application is destroyed, the non-persisted data is removed.
 *
 * @param key       your unique key
 * @param value     your value, or null to clear this data
 * @param persist   YES to persist through app destroys
 */
+ (void)setUserData:(NSString *)key value:(NSString *)value persist:(BOOL)persist;


// Undocumented methods, useful for debugging. These are subject to change in future releases.
+ (void)initWithKey:(NSString *)appKey enableLogging:(BOOL)enableLogging;

+ (void)initWithKey:(NSString *)appKey collectorUrl:(NSString*)collectorUrl enableLogging:(bool)enableLogging;

@end

