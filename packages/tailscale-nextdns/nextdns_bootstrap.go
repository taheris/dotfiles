// Copyright (c) Tailscale Inc & contributors
// SPDX-License-Identifier: BSD-3-Clause

package resolver

import (
	"bytes"
	"context"
	"errors"
	"io"
	"mime"
	"net/http"
	"net/netip"
	"sync"
	"time"

	"golang.org/x/net/dns/dnsmessage"
)

// Temporary workaround for https://github.com/tailscale/tailscale/issues/6130.
// Discover NextDNS endpoints through the existing PROFILED DoH transport, not
// UDP or an unconfigured resolver. Never change/log the private URL or metadata.
// Remove after packaged upstream has equivalent profiled, encrypted discovery.
type nextDNSDoHTransport struct {
	ctx       context.Context
	bootstrap http.RoundTripper
	build     func([]netip.Addr) http.RoundTripper
	now       func() time.Time
	mu        sync.Mutex

	unicast    http.RoundTripper
	expires    time.Time
	retryAfter time.Time
	refreshing chan struct{}
}

func newNextDNSDoHTransport(ctx context.Context, bootstrap http.RoundTripper, build func([]netip.Addr) http.RoundTripper) *nextDNSDoHTransport {
	return &nextDNSDoHTransport{ctx: ctx, bootstrap: bootstrap, build: build, now: time.Now}
}

func (t *nextDNSDoHTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	if err := req.Context().Err(); err != nil {
		if req.Body != nil {
			req.Body.Close()
		}
		return nil, err
	}
	if err := t.ctx.Err(); err != nil {
		if req.Body != nil {
			req.Body.Close()
		}
		return nil, err
	}
	t.mu.Lock()
	now := t.now()
	valid := t.unicast != nil && now.Before(t.expires)
	if !valid && t.refreshing == nil && !now.Before(t.retryAfter) {
		t.refreshing = make(chan struct{})
		// No I/O under this mutex or the forwarder's mutex. Clone the full
		// request so profile path, query parameters and headers are preserved.
		go t.refresh(req.Clone(t.ctx), t.refreshing)
	}
	pending := t.refreshing
	t.mu.Unlock()

	// On a cold/expired cache, wait for bounded discovery rather than return
	// the old-region DNS answer that a startup-only worker allowlist could retain.
	if !valid && pending != nil {
		select {
		case <-pending:
		case <-req.Context().Done():
			if req.Body != nil {
				req.Body.Close()
			}
			return nil, req.Context().Err()
		}
	}

	t.mu.Lock()
	transport := t.bootstrap
	usingUnicast := t.unicast != nil && t.now().Before(t.expires)
	if usingUnicast {
		transport = t.unicast
	}
	t.mu.Unlock()
	resp, err := transport.RoundTrip(req)
	if err == nil || !usingUnicast || req.GetBody == nil {
		return resp, err
	}
	if resp != nil && resp.Body != nil {
		resp.Body.Close()
	}
	// A DNS POST is replayable. Fall back only to the SAME profiled, verified
	// DoH service, never to plaintext DNS or another provider/profile.
	body, bodyErr := req.GetBody()
	if bodyErr != nil {
		return nil, err
	}
	retry := req.Clone(req.Context())
	retry.Body = body
	return t.bootstrap.RoundTrip(retry)
}

func (t *nextDNSDoHTransport) refresh(template *http.Request, done chan struct{}) {
	ctx, cancel := context.WithTimeout(t.ctx, 2*time.Second)
	defer cancel()
	var ips []netip.Addr
	ttl := time.Hour
	for _, typ := range []dnsmessage.Type{dnsmessage.TypeA, dnsmessage.TypeAAAA} {
		query := dnsmessage.Message{
			Header:    dnsmessage.Header{RecursionDesired: true},
			Questions: []dnsmessage.Question{{Name: dnsmessage.MustNewName("dns.nextdns.io."), Type: typ, Class: dnsmessage.ClassINET}},
		}
		packet, err := query.Pack()
		if err != nil {
			continue
		}
		req := template.Clone(ctx)
		req.Body = io.NopCloser(bytes.NewReader(packet))
		req.GetBody = nil
		req.ContentLength = int64(len(packet))
		req.TransferEncoding = nil
		req.Header.Set("Content-Type", "application/dns-message")
		req.Header.Set("Accept", "application/dns-message")
		resp, err := t.bootstrap.RoundTrip(req)
		if err != nil {
			continue
		}
		media, _, _ := mime.ParseMediaType(resp.Header.Get("Content-Type"))
		wire, readErr := io.ReadAll(io.LimitReader(resp.Body, 65536))
		resp.Body.Close()
		if resp.StatusCode != http.StatusOK || media != "application/dns-message" || readErr != nil || len(wire) >= 65536 {
			continue
		}
		addrs, lifetime, err := nextDNSBootstrapAnswers(wire, query.Questions[0])
		if err != nil {
			continue
		}
		ips = append(ips, addrs...)
		if lifetime < ttl {
			ttl = lifetime
		}
	}

	var upgraded http.RoundTripper
	if len(ips) > 0 && ttl > 0 && t.ctx.Err() == nil {
		upgraded = t.build(ips)
	}
	t.mu.Lock()
	old := t.unicast
	if upgraded != nil {
		t.unicast = upgraded
		t.expires = t.now().Add(ttl)
		t.retryAfter = time.Time{}
	} else {
		t.retryAfter = t.now().Add(30 * time.Second)
	}
	t.mu.Unlock()
	if upgraded != nil && old != nil {
		closeNextDNSIdle(old)
	}
	t.mu.Lock()
	t.refreshing = nil
	close(done)
	t.mu.Unlock()
}

func (t *nextDNSDoHTransport) CloseIdleConnections() {
	t.mu.Lock()
	unicast := t.unicast
	t.mu.Unlock()
	closeNextDNSIdle(t.bootstrap)
	if unicast != nil {
		closeNextDNSIdle(unicast)
	}
}

func closeNextDNSIdle(transport http.RoundTripper) {
	if closer, ok := transport.(interface{ CloseIdleConnections() }); ok {
		closer.CloseIdleConnections()
	}
}

// Accept only matching, successful DNS answers, including a bounded CNAME chain.
// Honour the shortest relevant TTL (capped at one hour); never cache zero TTL.
func nextDNSBootstrapAnswers(wire []byte, question dnsmessage.Question) ([]netip.Addr, time.Duration, error) {
	var message dnsmessage.Message
	if err := message.Unpack(wire); err != nil {
		return nil, 0, err
	}
	if !message.Header.Response || message.Header.ID != 0 || message.Header.Truncated || message.Header.RCode != dnsmessage.RCodeSuccess || len(message.Questions) != 1 || message.Questions[0] != question {
		return nil, 0, errors.New("invalid NextDNS bootstrap answer")
	}
	allowed := map[dnsmessage.Name]bool{question.Name: true}
	ttl := time.Hour
	for hop := 0; hop < 8; hop++ {
		changed := false
		for _, answer := range message.Answers {
			if !allowed[answer.Header.Name] || answer.Header.Class != dnsmessage.ClassINET {
				continue
			}
			if cname, ok := answer.Body.(*dnsmessage.CNAMEResource); ok && !allowed[cname.CNAME] {
				allowed[cname.CNAME] = true
				changed = true
				if d := time.Duration(answer.Header.TTL) * time.Second; d < ttl {
					ttl = d
				}
			}
		}
		if !changed {
			break
		}
	}
	var ips []netip.Addr
	seen := map[netip.Addr]bool{}
	for _, answer := range message.Answers {
		if !allowed[answer.Header.Name] || answer.Header.Class != dnsmessage.ClassINET || answer.Header.Type != question.Type {
			continue
		}
		var ip netip.Addr
		switch body := answer.Body.(type) {
		case *dnsmessage.AResource:
			ip = netip.AddrFrom4(body.A)
		case *dnsmessage.AAAAResource:
			ip = netip.AddrFrom16(body.AAAA).Unmap()
		}
		if !nextDNSPublicIP(ip) || seen[ip] {
			continue
		}
		seen[ip] = true
		ips = append(ips, ip)
		if d := time.Duration(answer.Header.TTL) * time.Second; d < ttl {
			ttl = d
		}
	}
	if len(ips) == 0 || ttl == 0 {
		return nil, 0, errors.New("no cacheable public NextDNS bootstrap addresses")
	}
	return ips, ttl, nil
}

func nextDNSPublicIP(ip netip.Addr) bool {
	if !ip.IsValid() || !ip.IsGlobalUnicast() || ip.IsPrivate() {
		return false
	}
	for _, prefix := range []string{"100.64.0.0/10", "192.0.0.0/24", "192.0.2.0/24", "198.18.0.0/15", "198.51.100.0/24", "203.0.113.0/24", "240.0.0.0/4", "2001:db8::/32"} {
		if netip.MustParsePrefix(prefix).Contains(ip) {
			return false
		}
	}
	return true
}
