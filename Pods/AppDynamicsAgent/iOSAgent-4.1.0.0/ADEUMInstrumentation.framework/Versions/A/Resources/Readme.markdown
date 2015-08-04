About the AppDynamics iOS SDK
==============

The AppDynamics iOS SDK is a framework that allows you to monitor the performance of an iOS application as it runs.
    It will automatically detect and instrument HTTP requests that the enclosing application sends via NSURLConnection,
    as well as any application crashes that occur. You can also call into it to instrument specific methods in your own
    code, to measure durations of operations in your application (like application start up, for example), or to report
    an arbitrary metric.

Quick install
=============

To use the AppDynamics iOS SDK with your application, follow these steps:

1. Link your project against EUMInstrumentation.framework. The easiest way to do this is to drag the
    EUMInstrumentation.framework bundle into your project's Frameworks group in Xcode.

2. Add a call to initialize the SDK in the UIApplicationDelegate method "didFinishLaunchingWithOptions". This method
    will be called when your application starts up. It looks something like:

       - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
        {
            [ADEumInstrumentation initWithKey:@"<YOUR APP KEY HERE>"];
            // other tasks
            return YES;
        }

    If you don't know your app key, see the [documentation](http://docs.appdynamics.com/).

3. Link your project against the following libraries:

    - SystemConfiguration.framework
    - CoreTelephony.framework
    - libz.dylib
    - libsqlite3.dylib

Instrumenting methods
==============

While the AppDynamics iOS SDK instruments some system method automatically, you can also use it to instrument methods
    in your own code. When you do this, you'll be able to see how often the instrumented method is invoked, and how
    long it takes to run. To do this, add a call at the beginning and end of the method you'd like to instrument:
    
        - (void)startTimerWithName
        {
            id tracker = [ADEumInstrumentation beginCall:self selector:_cmd];
            
            // Implementation of method here ...
            
            [ADEumInstrumentation endCall:tracker];
        }

Timing events
==============

Sometimes you want to time an event in your application that spans multiple methods. You can do this by calling the
    SDK when the event starts, and then again when it ends. For example, to track the time a user spends viewing
    a screen, the instrumentation looks like:

    - (void)viewDidAppear:(BOOL)animated
    {
        [super viewDidAppear:animated];
        [ADEumInstrumentation startTimerWithName:@"View Lifetime"];
    }

    - (void)viewDidDisappear:(BOOL)animated
    {
        [super viewDidDisappear:animated];
        [ADEumInstrumentation stopTimerWithName:@"View Lifetime"];
    }

Reporting metrics
==============

If you'd like to report some other type of data, you can use a metric. The only requirement is that the metric value
    must be an integer. Reporting a metric looks like this:
    
        [ADEumInstrumentation reportMetricWithName:@"My custom metric" value:<VALUE HERE>];

Reporting custom HTTP requests
==============

While the SDK can automatically discover HTTP requests made through the Objective-C system libraries, you might be
    using some other HTTP library that the SDK doesn't automatically instrument. In that case, you can explicitly
    report your HTTP requests.

Suppose you have a method like this for making HTTP requests:

        - (NSData *)sendRequest:(NSURL *)url error:(NSError **)error
        {
            // implementation omitted

            NSData *result = nil;
            if (errorOccurred)
            {
                *error = theError;
            }
            else
            {
                result = responseBody;
            }
            return result;
        }

Here's how you would augment this method to report requests to the SDK:

        - (NSData *)sendRequest:(NSURL *)url error:(NSError **)error
        {
            ADEumHTTPRequestTracker *tracker = [ADEumHTTPRequestTracker requestTrackerWithURL:url];
            // implementation omitted

            NSData *result = nil;
            if (errorOccurred)
            {
                *error = theError;
                tracker.error = theError;
            }
            else
            {
                tracker.statusCode = theStatusCode;
                tracker.allHeaderFields = theResponseHeaders;
                result = responseBody;
            }
            [tracker reportDone];
            return result;
        }

Documentation
==============

For a more detailed description of how to use SDK, or for troubleshooting information, please see the
    [official documentation](http://docs.appdynamics.com/).