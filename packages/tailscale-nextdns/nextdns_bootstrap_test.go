// Copyright (c) Tailscale Inc & contributors
// SPDX-License-Identifier: BSD-3-Clause

package resolver

import (
	"bytes"
	"context"
	"errors"
	"io"
	"net/http"
	"net/netip"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"golang.org/x/net/dns/dnsmessage"
)

// Offline fixtures only. No UDP, socket listeners, private live IDs or network.
type nextDNSFixtureTransport struct {
	roundTrip func(*http.Request) (*http.Response, error)
	closed    atomic.Int32
}

func (t *nextDNSFixtureTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	return t.roundTrip(r)
}
func (t *nextDNSFixtureTransport) CloseIdleConnections() { t.closed.Add(1) }

func nextDNSFixtureRequest(t *testing.T, ctx context.Context) *http.Request {
	t.Helper()
	wire, err := (&dnsmessage.Message{Header: dnsmessage.Header{RecursionDesired: true}, Questions: []dnsmessage.Question{{Name: dnsmessage.MustNewName("cache.nixos.org."), Type: dnsmessage.TypeA, Class: dnsmessage.ClassINET}}}).Pack()
	if err != nil {
		t.Fatal(err)
	}
	r, err := http.NewRequestWithContext(ctx, "POST", "https://dns.nextdns.io/f00baa/device/model?device_ip=100.100.100.1", bytes.NewReader(wire))
	if err != nil {
		t.Fatal(err)
	}
	r.Header.Set("Content-Type", "application/dns-message")
	r.Header.Set("X-Fixture-Metadata", "keep-me")
	return r
}

func nextDNSFixtureMessage(t *testing.T, r *http.Request) dnsmessage.Message {
	t.Helper()
	if r.Method != "POST" || r.URL.Scheme != "https" || r.URL.Host != "dns.nextdns.io" || r.URL.Path != "/f00baa/device/model" || r.URL.RawQuery != "device_ip=100.100.100.1" || r.Header.Get("X-Fixture-Metadata") != "keep-me" {
		t.Error("profile URL, transport or device metadata was changed")
	}
	wire, err := io.ReadAll(r.Body)
	r.Body.Close()
	if err != nil {
		t.Fatal(err)
	}
	var message dnsmessage.Message
	if err := message.Unpack(wire); err != nil {
		t.Fatal(err)
	}
	return message
}

func nextDNSFixtureReply(t *testing.T, query dnsmessage.Message, ips []string, ttl uint32) *http.Response {
	t.Helper()
	message := dnsmessage.Message{Header: dnsmessage.Header{Response: true}, Questions: query.Questions}
	for _, value := range ips {
		ip := netip.MustParseAddr(value)
		header := dnsmessage.ResourceHeader{Name: query.Questions[0].Name, Class: dnsmessage.ClassINET, TTL: ttl}
		if ip.Is4() && query.Questions[0].Type == dnsmessage.TypeA {
			header.Type = dnsmessage.TypeA
			message.Answers = append(message.Answers, dnsmessage.Resource{Header: header, Body: &dnsmessage.AResource{A: ip.As4()}})
		} else if ip.Is6() && query.Questions[0].Type == dnsmessage.TypeAAAA {
			header.Type = dnsmessage.TypeAAAA
			message.Answers = append(message.Answers, dnsmessage.Resource{Header: header, Body: &dnsmessage.AAAAResource{AAAA: ip.As16()}})
		}
	}
	wire, err := message.Pack()
	if err != nil {
		t.Fatal(err)
	}
	return &http.Response{StatusCode: http.StatusOK, Header: http.Header{"Content-Type": {"application/dns-message"}}, Body: io.NopCloser(bytes.NewReader(wire))}
}

func TestNextDNSBootstrapProfiledDiscoveryAndCache(t *testing.T) {
	var discovery, payload, local atomic.Int32
	bootstrap := &nextDNSFixtureTransport{roundTrip: func(r *http.Request) (*http.Response, error) {
		q := nextDNSFixtureMessage(t, r)
		if q.Questions[0].Name.String() == "dns.nextdns.io." {
			discovery.Add(1)
			return nextDNSFixtureReply(t, q, []string{"38.175.121.133", "2a00:11c0:47:1::2"}, 60), nil
		}
		payload.Add(1)
		return nextDNSFixtureReply(t, q, nil, 60), nil
	}}
	unicast := &nextDNSFixtureTransport{roundTrip: func(r *http.Request) (*http.Response, error) {
		q := nextDNSFixtureMessage(t, r)
		local.Add(1)
		return nextDNSFixtureReply(t, q, nil, 60), nil
	}}
	clock := time.Unix(1000, 0)
	var builds atomic.Int32
	transport := newNextDNSDoHTransport(context.Background(), bootstrap, func(ips []netip.Addr) http.RoundTripper {
		if len(ips) != 2 {
			t.Errorf("got %d endpoint addresses, want both families", len(ips))
		}
		builds.Add(1)
		return unicast
	})
	transport.now = func() time.Time { return clock }
	for i := 0; i < 2; i++ {
		resp, err := transport.RoundTrip(nextDNSFixtureRequest(t, context.Background()))
		if err != nil {
			t.Fatal(err)
		}
		resp.Body.Close()
	}
	if discovery.Load() != 2 || payload.Load() != 0 || local.Load() != 2 || builds.Load() != 1 {
		t.Fatalf("cold/cache requests: discovery=%d anycast-payload=%d local=%d builds=%d", discovery.Load(), payload.Load(), local.Load(), builds.Load())
	}
	clock = clock.Add(61 * time.Second)
	resp, err := transport.RoundTrip(nextDNSFixtureRequest(t, context.Background()))
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()
	if discovery.Load() != 4 || builds.Load() != 2 || unicast.closed.Load() != 1 {
		t.Fatal("expired endpoint TTL did not refresh/close old idle connections")
	}
	transport.CloseIdleConnections()
	if bootstrap.closed.Load() != 1 || unicast.closed.Load() != 2 {
		t.Fatal("CloseIdleConnections did not reach both transports")
	}
}

func TestNextDNSBootstrapFailureKeepsProfiledFallback(t *testing.T) {
	var discovery, payload, builds atomic.Int32
	bootstrap := &nextDNSFixtureTransport{roundTrip: func(r *http.Request) (*http.Response, error) {
		q := nextDNSFixtureMessage(t, r)
		if q.Questions[0].Name.String() == "dns.nextdns.io." {
			discovery.Add(1)
			return nil, errors.New("synthetic discovery failure")
		}
		payload.Add(1)
		return nextDNSFixtureReply(t, q, nil, 60), nil
	}}
	transport := newNextDNSDoHTransport(context.Background(), bootstrap, func([]netip.Addr) http.RoundTripper { builds.Add(1); return bootstrap })
	for i := 0; i < 2; i++ {
		resp, err := transport.RoundTrip(nextDNSFixtureRequest(t, context.Background()))
		if err != nil {
			t.Fatal(err)
		}
		resp.Body.Close()
	}
	if discovery.Load() != 2 || payload.Load() != 2 || builds.Load() != 0 {
		t.Fatal("failed discovery was not cooled down with same-profile fallback")
	}
}

func TestNextDNSBootstrapUnicastErrorReplaysSameBody(t *testing.T) {
	var discovery, replay atomic.Int32
	original := nextDNSFixtureRequest(t, context.Background())
	body, _ := original.GetBody()
	expected, _ := io.ReadAll(body)
	body.Close()
	bootstrap := &nextDNSFixtureTransport{roundTrip: func(r *http.Request) (*http.Response, error) {
		wire, _ := io.ReadAll(r.Body)
		r.Body.Close()
		var q dnsmessage.Message
		if err := q.Unpack(wire); err != nil {
			t.Fatal(err)
		}
		if q.Questions[0].Name.String() == "dns.nextdns.io." {
			discovery.Add(1)
			return nextDNSFixtureReply(t, q, []string{"38.175.121.133"}, 60), nil
		}
		if !bytes.Equal(wire, expected) || r.URL.String() != original.URL.String() {
			t.Error("fallback changed the DNS body/profile URI")
		}
		replay.Add(1)
		return nextDNSFixtureReply(t, q, nil, 60), nil
	}}
	broken := &nextDNSFixtureTransport{roundTrip: func(r *http.Request) (*http.Response, error) {
		nextDNSFixtureMessage(t, r)
		return nil, errors.New("synthetic unicast transport failure")
	}}
	transport := newNextDNSDoHTransport(context.Background(), bootstrap, func([]netip.Addr) http.RoundTripper { return broken })
	resp, err := transport.RoundTrip(original)
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()
	if discovery.Load() != 2 || replay.Load() != 1 {
		t.Fatal("did not replay once to existing profiled DoH transport")
	}
}

func TestNextDNSBootstrapConcurrentColdRequests(t *testing.T) {
	var discovery atomic.Int32
	bootstrap := &nextDNSFixtureTransport{roundTrip: func(r *http.Request) (*http.Response, error) {
		q := nextDNSFixtureMessage(t, r)
		discovery.Add(1)
		return nextDNSFixtureReply(t, q, []string{"38.175.121.133"}, 60), nil
	}}
	unicast := &nextDNSFixtureTransport{roundTrip: func(r *http.Request) (*http.Response, error) {
		return nextDNSFixtureReply(t, nextDNSFixtureMessage(t, r), nil, 60), nil
	}}
	transport := newNextDNSDoHTransport(context.Background(), bootstrap, func([]netip.Addr) http.RoundTripper { return unicast })
	var wg sync.WaitGroup
	for i := 0; i < 12; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			resp, err := transport.RoundTrip(nextDNSFixtureRequest(t, context.Background()))
			if err != nil {
				t.Error(err)
				return
			}
			resp.Body.Close()
		}()
	}
	wg.Wait()
	if discovery.Load() != 2 {
		t.Fatalf("%d bootstrap queries; want one A/AAAA pair", discovery.Load())
	}
}

func TestNextDNSBootstrapResponseErrorsAndPartialFamily(t *testing.T) {
	for _, mode := range []string{"http-error", "wrong-media", "malformed", "blocked", "private-address", "partial-family"} {
		t.Run(mode, func(t *testing.T) {
			var builds, payload atomic.Int32
			bootstrap := &nextDNSFixtureTransport{roundTrip: func(r *http.Request) (*http.Response, error) {
				q := nextDNSFixtureMessage(t, r)
				if q.Questions[0].Name.String() != "dns.nextdns.io." {
					payload.Add(1)
					return nextDNSFixtureReply(t, q, nil, 60), nil
				}
				if mode == "partial-family" && q.Questions[0].Type == dnsmessage.TypeAAAA {
					return nil, context.DeadlineExceeded
				}
				ips := []string{"38.175.121.133"}
				if mode == "private-address" {
					ips = []string{"192.168.1.1"}
				}
				resp := nextDNSFixtureReply(t, q, ips, 60)
				switch mode {
				case "http-error":
					resp.StatusCode = 503
				case "wrong-media":
					resp.Header.Set("Content-Type", "text/html")
				case "malformed":
					resp.Body = io.NopCloser(bytes.NewReader([]byte("invalid DNS")))
				case "blocked":
					message := dnsmessage.Message{Header: dnsmessage.Header{Response: true, RCode: dnsmessage.RCodeNameError}, Questions: q.Questions}
					wire, _ := message.Pack()
					resp.Body = io.NopCloser(bytes.NewReader(wire))
				}
				return resp, nil
			}}
			unicast := &nextDNSFixtureTransport{roundTrip: func(r *http.Request) (*http.Response, error) {
				return nextDNSFixtureReply(t, nextDNSFixtureMessage(t, r), nil, 60), nil
			}}
			transport := newNextDNSDoHTransport(context.Background(), bootstrap, func([]netip.Addr) http.RoundTripper { builds.Add(1); return unicast })
			resp, err := transport.RoundTrip(nextDNSFixtureRequest(t, context.Background()))
			if err != nil {
				t.Fatal(err)
			}
			resp.Body.Close()
			if mode == "partial-family" {
				if builds.Load() != 1 || payload.Load() != 0 {
					t.Fatal("valid A answer lost when AAAA failed")
				}
			} else if builds.Load() != 0 || payload.Load() != 1 {
				t.Fatal("invalid/blocked discovery bypassed same-profile fallback")
			}
		})
	}
}

func TestNextDNSBootstrapCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	bootstrap := &nextDNSFixtureTransport{roundTrip: func(*http.Request) (*http.Response, error) {
		t.Error("canceled request performed I/O")
		return nil, errors.New("unexpected I/O")
	}}
	transport := newNextDNSDoHTransport(ctx, bootstrap, func([]netip.Addr) http.RoundTripper { return bootstrap })
	if _, err := transport.RoundTrip(nextDNSFixtureRequest(t, context.Background())); !errors.Is(err, context.Canceled) {
		t.Fatal("daemon cancellation not respected")
	}
	transport = newNextDNSDoHTransport(context.Background(), bootstrap, func([]netip.Addr) http.RoundTripper { return bootstrap })
	if _, err := transport.RoundTrip(nextDNSFixtureRequest(t, ctx)); !errors.Is(err, context.Canceled) {
		t.Fatal("request cancellation not respected")
	}
}

func TestNextDNSBootstrapAnswersValidation(t *testing.T) {
	question := dnsmessage.Question{Name: dnsmessage.MustNewName("dns.nextdns.io."), Type: dnsmessage.TypeA, Class: dnsmessage.ClassINET}
	makeWire := func(ttl uint32, name dnsmessage.Name, ip string) dnsmessage.Message {
		return dnsmessage.Message{Header: dnsmessage.Header{Response: true}, Questions: []dnsmessage.Question{question}, Answers: []dnsmessage.Resource{{Header: dnsmessage.ResourceHeader{Name: name, Type: dnsmessage.TypeA, Class: dnsmessage.ClassINET, TTL: ttl}, Body: &dnsmessage.AResource{A: netip.MustParseAddr(ip).As4()}}}}
	}
	valid := makeWire(60, question.Name, "38.175.121.133")
	wire, _ := valid.Pack()
	ips, ttl, err := nextDNSBootstrapAnswers(wire, question)
	if err != nil || len(ips) != 1 || ttl != time.Minute {
		t.Fatal("valid answer rejected")
	}
	for name, mutate := range map[string]func(*dnsmessage.Message){
		"not-response":   func(m *dnsmessage.Message) { m.Header.Response = false },
		"wrong-id":       func(m *dnsmessage.Message) { m.Header.ID = 1 },
		"truncated":      func(m *dnsmessage.Message) { m.Header.Truncated = true },
		"refused":        func(m *dnsmessage.Message) { m.Header.RCode = dnsmessage.RCodeRefused },
		"wrong-question": func(m *dnsmessage.Message) { m.Questions = nil },
		"unrelated":      func(m *dnsmessage.Message) { m.Answers[0].Header.Name = dnsmessage.MustNewName("other.example.") },
		"zero-ttl":       func(m *dnsmessage.Message) { m.Answers[0].Header.TTL = 0 },
	} {
		t.Run(name, func(t *testing.T) {
			message := makeWire(60, question.Name, "38.175.121.133")
			mutate(&message)
			wire, _ := message.Pack()
			if _, _, err := nextDNSBootstrapAnswers(wire, question); err == nil {
				t.Fatal("invalid answer accepted")
			}
		})
	}
	alias := dnsmessage.MustNewName("endpoint.nextdns.io.")
	cname := makeWire(120, alias, "38.175.121.133")
	cname.Answers = append(cname.Answers, dnsmessage.Resource{Header: dnsmessage.ResourceHeader{Name: question.Name, Type: dnsmessage.TypeCNAME, Class: dnsmessage.ClassINET, TTL: 30}, Body: &dnsmessage.CNAMEResource{CNAME: alias}})
	wire, _ = cname.Pack()
	if _, ttl, err := nextDNSBootstrapAnswers(wire, question); err != nil || ttl != 30*time.Second {
		t.Fatal("out-of-order CNAME chain/minimum TTL not honoured")
	}
	for _, value := range []string{"127.0.0.1", "192.168.1.1", "100.64.0.1", "169.254.1.1", "203.0.113.1", "198.18.0.1", "0.0.0.0", "::1", "fc00::1", "fe80::1", "2001:db8::1"} {
		if nextDNSPublicIP(netip.MustParseAddr(value)) {
			t.Errorf("non-public endpoint accepted: %s", value)
		}
	}
}
