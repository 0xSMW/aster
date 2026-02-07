#include <errno.h>
#include <netdb.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#ifdef __APPLE__
#include <CoreFoundation/CoreFoundation.h>
#include <Security/SecTrust.h>
#include <Security/SecureTransport.h>
#endif

// macOS-first TLS socket helper for Aster stdlib.
//
// This lives in C so we can implement SecureTransport's callback-based IO
// without requiring Aster function pointers/closures.
//
// It is linked into Aster binaries that import core.net/core.http.

typedef struct {
  int fd;
#ifdef __APPLE__
  SSLContextRef ssl;
#endif
} AsterTlsConn;

#ifdef __APPLE__
static OSStatus aster_tls_sock_read(SSLConnectionRef connection, void* data, size_t* io_len) {
  if (!connection || !data || !io_len) return errSecParam;
  AsterTlsConn* c = (AsterTlsConn*)connection;
  ssize_t n = read(c->fd, data, *io_len);
  if (n > 0) {
    *io_len = (size_t)n;
    return noErr;
  }
  if (n == 0) {
    *io_len = 0;
    return errSSLClosedGraceful;
  }
  if (errno == EAGAIN || errno == EWOULDBLOCK) return errSSLWouldBlock;
  return errSecIO;
}

static OSStatus aster_tls_sock_write(SSLConnectionRef connection, const void* data, size_t* io_len) {
  if (!connection || !data || !io_len) return errSecParam;
  AsterTlsConn* c = (AsterTlsConn*)connection;
  ssize_t n = write(c->fd, data, *io_len);
  if (n >= 0) {
    *io_len = (size_t)n;
    return noErr;
  }
  if (errno == EAGAIN || errno == EWOULDBLOCK) return errSSLWouldBlock;
  return errSecIO;
}
#endif

static int aster_tcp_connect(const char* host, uint16_t port) {
  if (!host || !*host) return -1;

  char port_str[16];
  snprintf(port_str, sizeof(port_str), "%u", (unsigned)port);

  struct addrinfo hints;
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  struct addrinfo* res = NULL;
  if (getaddrinfo(host, port_str, &hints, &res) != 0) return -1;

  int fd = -1;
  for (struct addrinfo* ai = res; ai; ai = ai->ai_next) {
    int s = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
    if (s < 0) continue;
    if (connect(s, ai->ai_addr, ai->ai_addrlen) == 0) {
      fd = s;
      break;
    }
    close(s);
  }

  freeaddrinfo(res);
  return fd;
}

// void* aster_tls_connect(const char* host, u16 port, i32 timeout_ms)
void* aster_tls_connect(const char* host, uint16_t port, int32_t timeout_ms) {
  (void)timeout_ms;
#ifndef __APPLE__
  (void)host;
  (void)port;
  return NULL;
#else
  int fd = aster_tcp_connect(host, port);
  if (fd < 0) return NULL;

  AsterTlsConn* c = (AsterTlsConn*)calloc(1, sizeof(AsterTlsConn));
  if (!c) {
    close(fd);
    return NULL;
  }
  c->fd = fd;

  SSLContextRef ssl = SSLCreateContext(kCFAllocatorDefault, kSSLClientSide, kSSLStreamType);
  if (!ssl) goto fail;

  OSStatus st = SSLSetIOFuncs(ssl, aster_tls_sock_read, aster_tls_sock_write);
  if (st != noErr) goto fail_ssl;

  st = SSLSetConnection(ssl, (SSLConnectionRef)c);
  if (st != noErr) goto fail_ssl;

  if (host) {
    (void)SSLSetPeerDomainName(ssl, host, strlen(host));
  }

  // Handshake (blocking).
  for (;;) {
    st = SSLHandshake(ssl);
    if (st == noErr) break;
    if (st == errSSLWouldBlock) continue;
    goto fail_ssl;
  }

  // Best-effort trust evaluation.
  SecTrustRef trust = NULL;
  st = SSLCopyPeerTrust(ssl, &trust);
  if (st == noErr && trust) {
    bool ok = SecTrustEvaluateWithError(trust, NULL);
    CFRelease(trust);
    if (!ok) goto fail_ssl;
  }

  c->ssl = ssl;
  return c;

fail_ssl:
  if (ssl) {
    (void)SSLClose(ssl);
    (void)SSLDisposeContext(ssl);
  }
fail:
  if (fd >= 0) close(fd);
  free(c);
  return NULL;
#endif
}

// isize aster_tls_read(void* conn, u8* buf, usize cap)
ssize_t aster_tls_read(void* conn, uint8_t* buf, size_t cap) {
#ifndef __APPLE__
  (void)conn;
  (void)buf;
  (void)cap;
  return -1;
#else
  if (!conn || !buf) return -1;
  AsterTlsConn* c = (AsterTlsConn*)conn;
  size_t n = 0;
  OSStatus st = SSLRead(c->ssl, buf, cap, &n);
  if (st == noErr) return (ssize_t)n;
  if (st == errSSLClosedGraceful || st == errSSLClosedAbort) return 0;
  if (st == errSSLWouldBlock) return -2;
  return -1;
#endif
}

// isize aster_tls_write(void* conn, const u8* buf, usize len)
ssize_t aster_tls_write(void* conn, const uint8_t* buf, size_t len) {
#ifndef __APPLE__
  (void)conn;
  (void)buf;
  (void)len;
  return -1;
#else
  if (!conn || !buf) return -1;
  AsterTlsConn* c = (AsterTlsConn*)conn;
  size_t n = 0;
  OSStatus st = SSLWrite(c->ssl, buf, len, &n);
  if (st == noErr) return (ssize_t)n;
  if (st == errSSLClosedGraceful || st == errSSLClosedAbort) return 0;
  if (st == errSSLWouldBlock) return -2;
  return -1;
#endif
}

// i32 aster_tls_close(void* conn)
int32_t aster_tls_close(void* conn) {
#ifndef __APPLE__
  (void)conn;
  return 0;
#else
  if (!conn) return 0;
  AsterTlsConn* c = (AsterTlsConn*)conn;
  if (c->ssl) {
    (void)SSLClose(c->ssl);
    (void)SSLDisposeContext(c->ssl);
    c->ssl = NULL;
  }
  if (c->fd >= 0) {
    close(c->fd);
    c->fd = -1;
  }
  free(c);
  return 0;
#endif
}
