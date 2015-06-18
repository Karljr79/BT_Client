//  Copyright (c) 2015 AppDynamics Technologies. All rights reserved.

#import <Foundation/Foundation.h>

/**
 * If the SDK does not automatically discover your HTTP requests, use this class to explicitly
 * report them. Note that most users will not need to use this class; check the documentation
 * for the list of HTTP APIs that are automatically discovered.
 */
@interface ADEumHTTPRequestTracker : NSObject

/**
 * Begins tracking an HTTP request.
 *
 * Call this immediately before sending an HTTP request to track it manually.
 *
 * @param url The URL being requested.
 *
 * @warning `url` may not be `nil`.
 * @warning One of ADEumInstrumentation's initWithKey: methods must be called before this method.
 */
+ (ADEumHTTPRequestTracker *)requestTrackerWithURL:(NSURL *)url;

/**
 * Stops tracking an HTTP request.
 *
 * Immediately after receiving a response or an error, set the appropriate properties and call this method
 * to report the outcome of the HTTP request. You should not continue to use this object after calling
 * this method -- if you need to track another request, call requestTrackerWithURL:.
 */
- (void)reportDone;

/**
 * An error describing the failure to receive a response, if one occurred.
 *
 * If the request was successful, this should be `nil`.
 */
@property (copy, nonatomic) NSError *error;

/**
 * The status code of response, if one was received.
 *
 * If a response was received, this should be an an integer. If an error occurred and a
 * response was not received, this should be `nil`.
 */
@property (copy, nonatomic) NSNumber *statusCode;

/**
 * A dictionary representing the keys and values from the server’s response header.
 *
 * If an error occurred and a response was not received, this should be `nil`.
 */
@property (copy, nonatomic) NSDictionary *allHeaderFields;

@end