/// C API for exazig.  Exported functions use the C calling convention and
/// own all memory via std.heap.page_allocator, which maps directly to OS
/// virtual memory without requiring libc.
const std = @import("std");
const exa_mod = @import("root.zig");
const Exa = exa_mod.Exa;
const types = exa_mod.types;
const utils = exa_mod.utils;

const alloc = std.heap.page_allocator;

// ---------------------------------------------------------------------------
// Error codes (must match include/exazig.h)
// ---------------------------------------------------------------------------

pub const ExaErrorCode = enum(c_int) {
    ok = 0,
    missing_key = 1,
    network = 2,
    parse = 3,
    oom = 4,
    timeout = 5,
    invalid_arg = 6,
    unknown = 99,
};

fn mapError(err: anyerror) ExaErrorCode {
    return switch (err) {
        error.MissingApiKey => .missing_key,
        error.OutOfMemory => .oom,
        error.Timeout => .timeout,
        else => .network,
    };
}

fn setErr(out: ?*ExaErrorCode, code: ExaErrorCode) void {
    if (out) |o| o.* = code;
}

// ---------------------------------------------------------------------------
// Internal opaque types
// ---------------------------------------------------------------------------

pub const ExaClient = struct {
    exa: Exa,
};

const CCitation = struct {
    id: [:0]u8,
    url: [:0]u8,
    title: ?[:0]u8,
};

const CResult = struct {
    url: [:0]u8,
    id: [:0]u8,
    title: ?[:0]u8,
    score: f64,
    has_score: bool,
    text: ?[:0]u8,
    summary: ?[:0]u8,
};

pub const ExaSearchResults = struct {
    results: []CResult,

    fn destroy(self: *ExaSearchResults) void {
        for (self.results) |r| {
            alloc.free(r.url);
            alloc.free(r.id);
            if (r.title) |v| alloc.free(v);
            if (r.text) |v| alloc.free(v);
            if (r.summary) |v| alloc.free(v);
        }
        alloc.free(self.results);
        alloc.destroy(self);
    }
};

pub const ExaAnswerResponse = struct {
    text: ?[:0]u8,
    json: ?[:0]u8,
    citations: []CCitation,

    fn destroy(self: *ExaAnswerResponse) void {
        if (self.text) |v| alloc.free(v);
        if (self.json) |v| alloc.free(v);
        for (self.citations) |c| {
            alloc.free(c.id);
            alloc.free(c.url);
            if (c.title) |v| alloc.free(v);
        }
        alloc.free(self.citations);
        alloc.destroy(self);
    }
};

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

fn dupeZ(s: []const u8) ![:0]u8 {
    const buf = try alloc.allocSentinel(u8, s.len, 0);
    @memcpy(buf, s);
    return buf;
}

fn dupeZOpt(s: ?[]const u8) !?[:0]u8 {
    return if (s) |str| try dupeZ(str) else null;
}

fn buildCResults(src: []const types.Result) ![]CResult {
    const out = try alloc.alloc(CResult, src.len);
    var n: usize = 0;
    errdefer {
        for (out[0..n]) |r| {
            alloc.free(r.url);
            alloc.free(r.id);
            if (r.title) |v| alloc.free(v);
            if (r.text) |v| alloc.free(v);
            if (r.summary) |v| alloc.free(v);
        }
        alloc.free(out);
    }
    for (src) |r| {
        const url = try dupeZ(r.url);
        errdefer alloc.free(url);
        const id = try dupeZ(r.id);
        errdefer alloc.free(id);
        const title = try dupeZOpt(r.title);
        errdefer if (title) |v| alloc.free(v);
        const text = try dupeZOpt(r.text);
        errdefer if (text) |v| alloc.free(v);
        const summary = try dupeZOpt(r.summary);
        out[n] = CResult{
            .url = url,
            .id = id,
            .title = title,
            .score = r.score orelse 0.0,
            .has_score = r.score != null,
            .text = text,
            .summary = summary,
        };
        n += 1;
    }
    return out;
}

fn makeSearchResults(src_results: []const types.Result, err_out: ?*ExaErrorCode) ?*ExaSearchResults {
    const ptr = alloc.create(ExaSearchResults) catch {
        setErr(err_out, .oom);
        return null;
    };
    ptr.results = buildCResults(src_results) catch {
        alloc.destroy(ptr);
        setErr(err_out, .oom);
        return null;
    };
    setErr(err_out, .ok);
    return ptr;
}

// ---------------------------------------------------------------------------
// Exported: version
// ---------------------------------------------------------------------------

export fn exa_version() [*:0]const u8 {
    return "2.11.0";
}

// ---------------------------------------------------------------------------
// Exported: client lifecycle
// ---------------------------------------------------------------------------

export fn exa_client_create(
    api_key: ?[*:0]const u8,
    base_url: ?[*:0]const u8,
    user_agent: ?[*:0]const u8,
    err_out: ?*ExaErrorCode,
) ?*ExaClient {
    const key = if (api_key) |k| std.mem.span(k) else null;
    const base = if (base_url) |b| std.mem.span(b) else null;
    const ua = if (user_agent) |u| std.mem.span(u) else null;

    const ptr = alloc.create(ExaClient) catch {
        setErr(err_out, .oom);
        return null;
    };

    ptr.exa = Exa.init(alloc, key, base, ua) catch |e| {
        alloc.destroy(ptr);
        setErr(err_out, mapError(e));
        return null;
    };

    setErr(err_out, .ok);
    return ptr;
}

export fn exa_client_destroy(client: ?*ExaClient) void {
    if (client) |c| {
        c.exa.deinit();
        alloc.destroy(c);
    }
}

// ---------------------------------------------------------------------------
// Exported: search
// ---------------------------------------------------------------------------

export fn exa_search(
    client: ?*ExaClient,
    query: ?[*:0]const u8,
    num_results: c_int,
    err_out: ?*ExaErrorCode,
) ?*ExaSearchResults {
    const c = client orelse { setErr(err_out, .invalid_arg); return null; };
    const q = if (query) |qs| std.mem.span(qs) else { setErr(err_out, .invalid_arg); return null; };

    const nr: ?i64 = if (num_results > 0) @intCast(num_results) else null;
    const resp = c.exa.search(alloc, .{ .query = q, .num_results = nr }) catch |e| {
        setErr(err_out, mapError(e));
        return null;
    };
    defer resp.deinit();

    return makeSearchResults(resp.results, err_out);
}

export fn exa_get_contents(
    client: ?*ExaClient,
    urls: ?[*]const [*:0]const u8,
    url_count: usize,
    err_out: ?*ExaErrorCode,
) ?*ExaSearchResults {
    const c = client orelse { setErr(err_out, .invalid_arg); return null; };
    const url_ptrs = urls orelse { setErr(err_out, .invalid_arg); return null; };

    const url_list = alloc.alloc([]const u8, url_count) catch {
        setErr(err_out, .oom);
        return null;
    };
    defer alloc.free(url_list);

    for (0..url_count) |i| url_list[i] = std.mem.span(url_ptrs[i]);

    const resp = c.exa.getContents(alloc, .{ .urls = url_list }) catch |e| {
        setErr(err_out, mapError(e));
        return null;
    };
    defer resp.deinit();

    return makeSearchResults(resp.results, err_out);
}

export fn exa_find_similar(
    client: ?*ExaClient,
    url: ?[*:0]const u8,
    num_results: c_int,
    err_out: ?*ExaErrorCode,
) ?*ExaSearchResults {
    const c = client orelse { setErr(err_out, .invalid_arg); return null; };
    const u = if (url) |us| std.mem.span(us) else { setErr(err_out, .invalid_arg); return null; };

    const nr: ?i64 = if (num_results > 0) @intCast(num_results) else null;
    const resp = c.exa.findSimilar(alloc, .{ .url = u, .num_results = nr }) catch |e| {
        setErr(err_out, mapError(e));
        return null;
    };
    defer resp.deinit();

    return makeSearchResults(resp.results, err_out);
}

export fn exa_search_results_free(results: ?*ExaSearchResults) void {
    if (results) |r| r.destroy();
}

export fn exa_search_results_count(results: ?*const ExaSearchResults) usize {
    return if (results) |r| r.results.len else 0;
}

export fn exa_result_url(results: ?*const ExaSearchResults, index: usize) ?[*:0]const u8 {
    const r = results orelse return null;
    if (index >= r.results.len) return null;
    return r.results[index].url.ptr;
}

export fn exa_result_id(results: ?*const ExaSearchResults, index: usize) ?[*:0]const u8 {
    const r = results orelse return null;
    if (index >= r.results.len) return null;
    return r.results[index].id.ptr;
}

export fn exa_result_title(results: ?*const ExaSearchResults, index: usize) ?[*:0]const u8 {
    const r = results orelse return null;
    if (index >= r.results.len) return null;
    return if (r.results[index].title) |t| t.ptr else null;
}

export fn exa_result_score(
    results: ?*const ExaSearchResults,
    index: usize,
    has_score: ?*c_int,
) f64 {
    const r = results orelse { if (has_score) |hs| hs.* = 0; return 0.0; };
    if (index >= r.results.len) { if (has_score) |hs| hs.* = 0; return 0.0; }
    const res = r.results[index];
    if (has_score) |hs| hs.* = if (res.has_score) 1 else 0;
    return res.score;
}

export fn exa_result_text(results: ?*const ExaSearchResults, index: usize) ?[*:0]const u8 {
    const r = results orelse return null;
    if (index >= r.results.len) return null;
    return if (r.results[index].text) |t| t.ptr else null;
}

export fn exa_result_summary(results: ?*const ExaSearchResults, index: usize) ?[*:0]const u8 {
    const r = results orelse return null;
    if (index >= r.results.len) return null;
    return if (r.results[index].summary) |s| s.ptr else null;
}

// ---------------------------------------------------------------------------
// Exported: answer
// ---------------------------------------------------------------------------

export fn exa_answer(
    client: ?*ExaClient,
    query: ?[*:0]const u8,
    err_out: ?*ExaErrorCode,
) ?*ExaAnswerResponse {
    const c = client orelse { setErr(err_out, .invalid_arg); return null; };
    const q = if (query) |qs| std.mem.span(qs) else { setErr(err_out, .invalid_arg); return null; };

    const resp = c.exa.answer(alloc, q, null, null) catch |e| {
        setErr(err_out, mapError(e));
        return null;
    };
    defer resp.deinit(alloc);

    const ptr = alloc.create(ExaAnswerResponse) catch {
        setErr(err_out, .oom);
        return null;
    };

    var ans_text: ?[:0]u8 = null;
    var ans_json: ?[:0]u8 = null;

    switch (resp.answer) {
        .text => |t| {
            ans_text = dupeZ(t) catch {
                alloc.destroy(ptr);
                setErr(err_out, .oom);
                return null;
            };
        },
        .object => |v| {
            const json_bytes = std.json.stringifyAlloc(alloc, v, .{}) catch {
                alloc.destroy(ptr);
                setErr(err_out, .oom);
                return null;
            };
            defer alloc.free(json_bytes);
            const sentinel = alloc.allocSentinel(u8, json_bytes.len, 0) catch {
                alloc.destroy(ptr);
                setErr(err_out, .oom);
                return null;
            };
            @memcpy(sentinel, json_bytes);
            ans_json = sentinel;
        },
    }

    const cits = alloc.alloc(CCitation, resp.citations.len) catch {
        if (ans_text) |v| alloc.free(v);
        if (ans_json) |v| alloc.free(v);
        alloc.destroy(ptr);
        setErr(err_out, .oom);
        return null;
    };

    var n: usize = 0;
    for (resp.citations) |cit| {
        const cid = dupeZ(cit.id) catch {
            freeCitations(cits[0..n]);
            alloc.free(cits);
            if (ans_text) |v| alloc.free(v);
            if (ans_json) |v| alloc.free(v);
            alloc.destroy(ptr);
            setErr(err_out, .oom);
            return null;
        };
        const curl = dupeZ(cit.url) catch {
            alloc.free(cid);
            freeCitations(cits[0..n]);
            alloc.free(cits);
            if (ans_text) |v| alloc.free(v);
            if (ans_json) |v| alloc.free(v);
            alloc.destroy(ptr);
            setErr(err_out, .oom);
            return null;
        };
        const ctitle = dupeZOpt(cit.title) catch {
            alloc.free(cid);
            alloc.free(curl);
            freeCitations(cits[0..n]);
            alloc.free(cits);
            if (ans_text) |v| alloc.free(v);
            if (ans_json) |v| alloc.free(v);
            alloc.destroy(ptr);
            setErr(err_out, .oom);
            return null;
        };
        cits[n] = CCitation{ .id = cid, .url = curl, .title = ctitle };
        n += 1;
    }

    ptr.* = ExaAnswerResponse{ .text = ans_text, .json = ans_json, .citations = cits };
    setErr(err_out, .ok);
    return ptr;
}

fn freeCitations(cits: []CCitation) void {
    for (cits) |c| {
        alloc.free(c.id);
        alloc.free(c.url);
        if (c.title) |v| alloc.free(v);
    }
}

export fn exa_answer_free(answer: ?*ExaAnswerResponse) void {
    if (answer) |a| a.destroy();
}

export fn exa_answer_text(answer: ?*const ExaAnswerResponse) ?[*:0]const u8 {
    const a = answer orelse return null;
    return if (a.text) |t| t.ptr else null;
}

export fn exa_answer_json(answer: ?*const ExaAnswerResponse) ?[*:0]const u8 {
    const a = answer orelse return null;
    return if (a.json) |j| j.ptr else null;
}

export fn exa_answer_citations_count(answer: ?*const ExaAnswerResponse) usize {
    return if (answer) |a| a.citations.len else 0;
}

export fn exa_answer_citation_id(answer: ?*const ExaAnswerResponse, index: usize) ?[*:0]const u8 {
    const a = answer orelse return null;
    if (index >= a.citations.len) return null;
    return a.citations[index].id.ptr;
}

export fn exa_answer_citation_url(answer: ?*const ExaAnswerResponse, index: usize) ?[*:0]const u8 {
    const a = answer orelse return null;
    if (index >= a.citations.len) return null;
    return a.citations[index].url.ptr;
}

export fn exa_answer_citation_title(answer: ?*const ExaAnswerResponse, index: usize) ?[*:0]const u8 {
    const a = answer orelse return null;
    if (index >= a.citations.len) return null;
    return if (a.citations[index].title) |t| t.ptr else null;
}
