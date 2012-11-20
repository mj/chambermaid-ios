//
//  ChambermaidDataURLProtocol.h
//  chambermaid-ios
//
//  Created by Martin Jansen on 20.11.12.
//  Copyright (c) 2012 Martin Jansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChambermaidDataURLProtocol : NSURLProtocol <NSURLConnectionDelegate>
{
    NSURLConnection *wrappedConnection;
    NSURLRequest *wrappedRequest;
}

@end
