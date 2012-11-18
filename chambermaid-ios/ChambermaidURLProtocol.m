//
//  ChambermaidURLProtocol.m
//  chambermaid-ios
//
//  Created by Martin Jansen on 18.11.12.
//  Copyright (c) 2012 Martin Jansen. All rights reserved.
//

#import "ChambermaidURLProtocol.h"

@implementation ChambermaidURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest*)theRequest
{
    return ([theRequest.URL.scheme caseInsensitiveCompare:@"chambermaid"] == NSOrderedSame);
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)theRequest
{
    return theRequest;
}

- (void)startLoading
{
    NSString *filename= [self.request.URL.path lastPathComponent];

    /* Looks like one does not need to set a MIME type because
     * UIWebView is smart enough to figure it out on its own.
     */
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL 
                                                        MIMEType:nil
                                           expectedContentLength:-1 
                                                textEncodingName:nil];
    
    NSString *resourceBase = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"chambermaid-frontend"];
    NSString *resourcePath = [resourceBase stringByAppendingPathComponent:filename];

    NSData *data = [NSData dataWithContentsOfFile:resourcePath];
    
    [[self client] URLProtocol:self 
            didReceiveResponse:response 
            cacheStoragePolicy:NSURLCacheStorageNotAllowed];

    [[self client] URLProtocol:self 
                   didLoadData:data];

    [[self client] URLProtocolDidFinishLoading:self];
}

- (void) stopLoading
{    
}
@end
