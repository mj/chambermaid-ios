//
//  ChambermaidDataURLProtocol.m
//  chambermaid-ios
//
//  Created by Martin Jansen on 20.11.12.
//  Copyright (c) 2012 Martin Jansen. All rights reserved.
//

#import "ChambermaidDataURLProtocol.h"

@implementation ChambermaidDataURLProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest*)theRequest
{
    return [@"chambermaid-data" isEqualToString:theRequest.URL.scheme];
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)theRequest
{
    return theRequest;
}

- (OSStatus) extractIdentity:(SecIdentityRef*)outIdentity 
                    andTrust:(SecTrustRef*)outTrust
                  fromPKCS12:(CFDataRef)inPKCS12Data
{
    OSStatus securityError = errSecSuccess;
    
    const void *keys[] =   { kSecImportExportPassphrase };
    const void *values[] = { CFSTR("") };
    
    CFDictionaryRef optionsDictionary = CFDictionaryCreate(
                                                           NULL, keys,
                                                           values, 1,
                                                           NULL, NULL);
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import(inPKCS12Data,
                                    optionsDictionary,
                                    &items);
    
    if (securityError == 0) {
        CFDictionaryRef identityAndTrust = CFArrayGetValueAtIndex(items, 0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue(identityAndTrust, kSecImportItemIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        const void *tempTrust = NULL;
        tempTrust = CFDictionaryGetValue(identityAndTrust, kSecImportItemTrust);
        *outTrust = (SecTrustRef)tempTrust;
    }
    
    if (optionsDictionary) {
        CFRelease(optionsDictionary);
    }
    
    return securityError;
}

- (NSURL*) wrappedURLFor:(NSURL*)URL
{
    NSString *host  = self.request.URL.host;
    NSString *path  = self.request.URL.path;
    NSString *query = self.request.URL.query;
    NSNumber *port  = self.request.URL.port;
    
    NSString *wrappedURL = [NSString stringWithFormat: @"https://%@:%@%@?%@", host, port, path, query];
    
    return [NSURL URLWithString:wrappedURL];
}

- (void)startLoading
{
    NSURL *wrappedURL = [self wrappedURLFor:self.request.URL];

    wrappedRequest = [[NSURLRequest alloc] initWithURL:wrappedURL
                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                       timeoutInterval:40.0];
    wrappedConnection = [[NSURLConnection alloc] initWithRequest:wrappedRequest 
                                                        delegate:self];
    
    [wrappedConnection start];
}

- (void)stopLoading
{
	[wrappedConnection cancel];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate implementation

- (BOOL) connectionShouldUseCredentialStorage:(NSURLConnection *)connection 
{
	return YES;
}

- (BOOL)connection:(NSURLConnection*)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return YES;
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge 
{
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newData
{
    [self.client URLProtocol:self 
                 didLoadData:newData];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)newResponse
{
    [self.client URLProtocol:self 
          didReceiveResponse:newResponse
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten 
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)newCachedResponse
{
	return newCachedResponse;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)newRequest redirectResponse:(NSURLResponse *)redirectResponse
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	return newRequest;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    id sender = [challenge sender];
    
    NSString *certPath = [[NSBundle mainBundle] pathForResource:@"chambermaid-client" 
                                                         ofType:@"p12"];
    NSData *PKCS12Data = [[NSData alloc] initWithContentsOfFile:certPath];
    CFDataRef inPKCS12Data = (__bridge_retained CFDataRef)PKCS12Data;
    
    SecIdentityRef identity;
    SecTrustRef trust;
    SecCertificateRef certificate;
    OSStatus status = noErr;
    
    status = [self extractIdentity:&identity 
                          andTrust:&trust 
                        fromPKCS12:inPKCS12Data];
    SecIdentityCopyCertificate(identity, &certificate);
    
    const void *certs[] = {certificate};
    CFArrayRef certificates = CFArrayCreate(kCFAllocatorDefault, certs, 1, NULL);
    
    NSURLCredential *credential = [NSURLCredential credentialWithIdentity:identity
                                                             certificates:(__bridge_transfer NSArray*)certificates
                                                              persistence:NSURLCredentialPersistencePermanent];

    [sender useCredential:credential forAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	[self.client URLProtocol:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    [self.client URLProtocolDidFinishLoading:self];
}

@end
