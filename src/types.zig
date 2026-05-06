/// Core types for the Exa AI API client.
const std = @import("std");
const utils = @import("utils.zig");

// ---------------------------------------------------------------------------
// Enumerations
// ---------------------------------------------------------------------------

pub const Category = enum {
    company,
    research_paper,
    news,
    pdf,
    personal_site,
    financial_report,
    people,

    pub fn toString(self: Category) []const u8 {
        return switch (self) {
            .company => "company",
            .research_paper => "research paper",
            .news => "news",
            .pdf => "pdf",
            .personal_site => "personal site",
            .financial_report => "financial report",
            .people => "people",
        };
    }

    pub fn fromString(s: []const u8) ?Category {
        if (std.mem.eql(u8, s, "company")) return .company;
        if (std.mem.eql(u8, s, "research paper")) return .research_paper;
        if (std.mem.eql(u8, s, "news")) return .news;
        if (std.mem.eql(u8, s, "pdf")) return .pdf;
        if (std.mem.eql(u8, s, "personal site")) return .personal_site;
        if (std.mem.eql(u8, s, "financial report")) return .financial_report;
        if (std.mem.eql(u8, s, "people")) return .people;
        return null;
    }
};

pub const SearchType = enum {
    auto,
    fast,
    deep_lite,
    deep,
    deep_reasoning,
    neural,
    instant,

    pub fn toString(self: SearchType) []const u8 {
        return switch (self) {
            .auto => "auto",
            .fast => "fast",
            .deep_lite => "deeplite",
            .deep => "deep",
            .deep_reasoning => "deepreasoning",
            .neural => "neural",
            .instant => "instant",
        };
    }

    pub fn fromString(s: []const u8) ?SearchType {
        if (std.mem.eql(u8, s, "auto")) return .auto;
        if (std.mem.eql(u8, s, "fast")) return .fast;
        if (std.mem.eql(u8, s, "deeplite")) return .deep_lite;
        if (std.mem.eql(u8, s, "deep")) return .deep;
        if (std.mem.eql(u8, s, "deepreasoning")) return .deep_reasoning;
        if (std.mem.eql(u8, s, "neural")) return .neural;
        if (std.mem.eql(u8, s, "instant")) return .instant;
        return null;
    }
};

pub const LivecrawlOption = enum {
    always,
    fallback,
    never,
    auto,
    preferred,

    pub fn toString(self: LivecrawlOption) []const u8 {
        return switch (self) {
            .always => "always",
            .fallback => "fallback",
            .never => "never",
            .auto => "auto",
            .preferred => "preferred",
        };
    }

    pub fn fromString(s: []const u8) ?LivecrawlOption {
        if (std.mem.eql(u8, s, "always")) return .always;
        if (std.mem.eql(u8, s, "fallback")) return .fallback;
        if (std.mem.eql(u8, s, "never")) return .never;
        if (std.mem.eql(u8, s, "auto")) return .auto;
        if (std.mem.eql(u8, s, "preferred")) return .preferred;
        return null;
    }
};

pub const VerbosityOption = enum {
    compact,
    standard,
    full,

    pub fn toString(self: VerbosityOption) []const u8 {
        return switch (self) {
            .compact => "compact",
            .standard => "standard",
            .full => "full",
        };
    }

    pub fn fromString(s: []const u8) ?VerbosityOption {
        if (std.mem.eql(u8, s, "compact")) return .compact;
        if (std.mem.eql(u8, s, "standard")) return .standard;
        if (std.mem.eql(u8, s, "full")) return .full;
        return null;
    }
};

pub const SectionTag = enum {
    unspecified,
    header,
    navigation,
    banner,
    body,
    sidebar,
    footer,
    metadata,

    pub fn toString(self: SectionTag) []const u8 {
        return switch (self) {
            .unspecified => "unspecified",
            .header => "header",
            .navigation => "navigation",
            .banner => "banner",
            .body => "body",
            .sidebar => "sidebar",
            .footer => "footer",
            .metadata => "metadata",
        };
    }

    pub fn fromString(s: []const u8) ?SectionTag {
        if (std.mem.eql(u8, s, "unspecified")) return .unspecified;
        if (std.mem.eql(u8, s, "header")) return .header;
        if (std.mem.eql(u8, s, "navigation")) return .navigation;
        if (std.mem.eql(u8, s, "banner")) return .banner;
        if (std.mem.eql(u8, s, "body")) return .body;
        if (std.mem.eql(u8, s, "sidebar")) return .sidebar;
        if (std.mem.eql(u8, s, "footer")) return .footer;
        if (std.mem.eql(u8, s, "metadata")) return .metadata;
        return null;
    }
};

pub const GroundingConfidence = enum {
    low,
    medium,
    high,

    pub fn toString(self: GroundingConfidence) []const u8 {
        return switch (self) {
            .low => "low",
            .medium => "medium",
            .high => "high",
        };
    }

    pub fn fromString(s: []const u8) ?GroundingConfidence {
        if (std.mem.eql(u8, s, "low")) return .low;
        if (std.mem.eql(u8, s, "medium")) return .medium;
        if (std.mem.eql(u8, s, "high")) return .high;
        return null;
    }
};

// ---------------------------------------------------------------------------
// Content Option Structs
// ---------------------------------------------------------------------------

pub const TextContentsOptions = struct {
    max_characters: ?i64 = null,
    include_html_tags: ?bool = null,
    verbosity: ?VerbosityOption = null,
    include_sections: ?[]const SectionTag = null,
    exclude_sections: ?[]const SectionTag = null,
};

pub const SummaryContentsOptions = struct {
    query: ?[]const u8 = null,
    schema: ?std.json.Value = null,
};

pub const HighlightsContentsOptions = struct {
    query: ?[]const u8 = null,
    max_characters: ?i64 = null,
    num_sentences: ?i64 = null,
    highlights_per_url: ?i64 = null,
};

pub const ContextContentsOptions = struct {
    max_characters: ?i64 = null,
};

pub const ExtrasOptions = struct {
    links: ?i64 = null,
    image_links: ?i64 = null,
};

pub const ContentsOptions = struct {
    text: ?union(enum) { enabled: bool, options: TextContentsOptions } = null,
    highlights: ?union(enum) { enabled: bool, options: HighlightsContentsOptions } = null,
    summary: ?union(enum) { enabled: bool, options: SummaryContentsOptions } = null,
    context: ?union(enum) { enabled: bool, options: ContextContentsOptions } = null,
    livecrawl: ?LivecrawlOption = null,
    livecrawl_timeout: ?i64 = null,
    max_age_hours: ?i64 = null,
    subpages: ?i64 = null,
    subpage_target: ?union(enum) { single: []const u8, multiple: []const []const u8 } = null,
    extras: ?ExtrasOptions = null,
};

// ---------------------------------------------------------------------------
// Search Parameter Structs
// ---------------------------------------------------------------------------

pub const SearchParams = struct {
    query: []const u8,
    contents: ?union(enum) { disabled: void, options: ContentsOptions } = null,
    num_results: ?i64 = null,
    include_domains: ?[]const []const u8 = null,
    exclude_domains: ?[]const []const u8 = null,
    start_crawl_date: ?[]const u8 = null,
    end_crawl_date: ?[]const u8 = null,
    start_published_date: ?[]const u8 = null,
    end_published_date: ?[]const u8 = null,
    include_text: ?[]const []const u8 = null,
    exclude_text: ?[]const []const u8 = null,
    search_type: ?SearchType = null,
    category: ?Category = null,
    flags: ?[]const []const u8 = null,
    moderation: ?bool = null,
    user_location: ?[]const u8 = null,
    additional_queries: ?[]const []const u8 = null,
    system_prompt: ?[]const u8 = null,
    output_schema: ?std.json.Value = null,
};

pub const FindSimilarParams = struct {
    url: []const u8,
    contents: ?union(enum) { disabled: void, options: ContentsOptions } = null,
    num_results: ?i64 = null,
    include_domains: ?[]const []const u8 = null,
    exclude_domains: ?[]const []const u8 = null,
    start_crawl_date: ?[]const u8 = null,
    end_crawl_date: ?[]const u8 = null,
    start_published_date: ?[]const u8 = null,
    end_published_date: ?[]const u8 = null,
    include_text: ?[]const []const u8 = null,
    exclude_text: ?[]const []const u8 = null,
    exclude_source_domain: ?bool = null,
    category: ?Category = null,
    flags: ?[]const []const u8 = null,
};

pub const GetContentsParams = struct {
    urls: []const []const u8,
    text: ?union(enum) { enabled: bool, options: TextContentsOptions } = null,
    summary: ?union(enum) { enabled: bool, options: SummaryContentsOptions } = null,
    highlights: ?union(enum) { enabled: bool, options: HighlightsContentsOptions } = null,
    context: ?union(enum) { enabled: bool, options: ContextContentsOptions } = null,
    livecrawl: ?LivecrawlOption = null,
    livecrawl_timeout: ?i64 = null,
    max_age_hours: ?i64 = null,
    filter_empty_results: ?bool = null,
    subpages: ?i64 = null,
    subpage_target: ?union(enum) { single: []const u8, multiple: []const []const u8 } = null,
    extras: ?ExtrasOptions = null,
    flags: ?[]const []const u8 = null,
};

// ---------------------------------------------------------------------------
// Entity Types
// ---------------------------------------------------------------------------

pub const EntityCompanyPropertiesWorkforce = struct {
    total: ?i64 = null,
};

pub const EntityCompanyPropertiesHeadquarters = struct {
    address: ?[]const u8 = null,
    city: ?[]const u8 = null,
    postal_code: ?[]const u8 = null,
    country: ?[]const u8 = null,
};

pub const EntityCompanyPropertiesFundingRound = struct {
    name: ?[]const u8 = null,
    date: ?[]const u8 = null,
    amount: ?i64 = null,
};

pub const EntityCompanyPropertiesFinancials = struct {
    revenue_annual: ?i64 = null,
    funding_total: ?i64 = null,
    funding_latest_round: ?EntityCompanyPropertiesFundingRound = null,
};

pub const EntityCompanyPropertiesWebTraffic = struct {
    visits_monthly: ?i64 = null,
};

pub const EntityCompanyProperties = struct {
    name: ?[]const u8 = null,
    founded_year: ?i64 = null,
    description: ?[]const u8 = null,
    workforce: ?EntityCompanyPropertiesWorkforce = null,
    headquarters: ?EntityCompanyPropertiesHeadquarters = null,
    financials: ?EntityCompanyPropertiesFinancials = null,
    web_traffic: ?EntityCompanyPropertiesWebTraffic = null,
};

pub const EntityDateRange = struct {
    from_date: ?[]const u8 = null,
    to_date: ?[]const u8 = null,
};

pub const EntityPersonPropertiesCompanyRef = struct {
    id: ?[]const u8 = null,
    name: ?[]const u8 = null,
};

pub const EntityPersonPropertiesWorkHistoryEntry = struct {
    title: ?[]const u8 = null,
    location: ?[]const u8 = null,
    dates: ?EntityDateRange = null,
    company: ?EntityPersonPropertiesCompanyRef = null,
};

pub const EntityPersonProperties = struct {
    name: ?[]const u8 = null,
    location: ?[]const u8 = null,
    work_history: ?[]EntityPersonPropertiesWorkHistoryEntry = null,
};

pub const CompanyEntity = struct {
    id: []const u8,
    version: i64,
    properties: EntityCompanyProperties,
};

pub const PersonEntity = struct {
    id: []const u8,
    version: i64,
    properties: EntityPersonProperties,
};

pub const Entity = union(enum) {
    company: CompanyEntity,
    person: PersonEntity,
};

// ---------------------------------------------------------------------------
// Result Types
// ---------------------------------------------------------------------------

pub const Result = struct {
    url: []const u8,
    id: []const u8,
    title: ?[]const u8 = null,
    score: ?f64 = null,
    published_date: ?[]const u8 = null,
    author: ?[]const u8 = null,
    image: ?[]const u8 = null,
    favicon: ?[]const u8 = null,
    subpages: ?[]Result = null,
    extras: ?std.json.Value = null,
    entities: ?[]Entity = null,
    text: ?[]const u8 = null,
    summary: ?[]const u8 = null,
    highlights: ?[][]const u8 = null,
    highlight_scores: ?[]f64 = null,

    /// Frees all heap memory owned by this result.
    pub fn deinit(self: Result, allocator: std.mem.Allocator) void {
        allocator.free(self.url);
        allocator.free(self.id);
        if (self.title) |v| allocator.free(v);
        if (self.published_date) |v| allocator.free(v);
        if (self.author) |v| allocator.free(v);
        if (self.image) |v| allocator.free(v);
        if (self.favicon) |v| allocator.free(v);
        if (self.text) |v| allocator.free(v);
        if (self.summary) |v| allocator.free(v);
        if (self.subpages) |pages| {
            for (pages) |page| page.deinit(allocator);
            allocator.free(pages);
        }
        if (self.extras) |v| utils.freeValue(allocator, v);
        if (self.entities) |ents| {
            for (ents) |ent| freeEntity(allocator, ent);
            allocator.free(ents);
        }
        if (self.highlights) |hl| {
            for (hl) |h| allocator.free(h);
            allocator.free(hl);
        }
        if (self.highlight_scores) |hs| allocator.free(hs);
    }

    pub fn format(self: Result, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("Result{{ url={s}, id={s}, title={?s}, score={?d} }}", .{
            self.url,
            self.id,
            self.title,
            self.score,
        });
    }
};

fn freeEntity(allocator: std.mem.Allocator, ent: Entity) void {
    switch (ent) {
        .company => |c| {
            allocator.free(c.id);
            const p = c.properties;
            if (p.name) |v| allocator.free(v);
            if (p.description) |v| allocator.free(v);
            if (p.headquarters) |hq| {
                if (hq.address) |v| allocator.free(v);
                if (hq.city) |v| allocator.free(v);
                if (hq.postal_code) |v| allocator.free(v);
                if (hq.country) |v| allocator.free(v);
            }
            if (p.financials) |f| {
                if (f.funding_latest_round) |r| {
                    if (r.name) |v| allocator.free(v);
                    if (r.date) |v| allocator.free(v);
                }
            }
        },
        .person => |pe| {
            allocator.free(pe.id);
            const p = pe.properties;
            if (p.name) |v| allocator.free(v);
            if (p.location) |v| allocator.free(v);
            if (p.work_history) |wh| {
                for (wh) |entry| {
                    if (entry.title) |v| allocator.free(v);
                    if (entry.location) |v| allocator.free(v);
                    if (entry.dates) |d| {
                        if (d.from_date) |v| allocator.free(v);
                        if (d.to_date) |v| allocator.free(v);
                    }
                    if (entry.company) |c| {
                        if (c.id) |v| allocator.free(v);
                        if (c.name) |v| allocator.free(v);
                    }
                }
                allocator.free(wh);
            }
        },
    }
}

// ---------------------------------------------------------------------------
// Answer and Stream Types
// ---------------------------------------------------------------------------

pub const AnswerResult = struct {
    id: []const u8,
    url: []const u8,
    title: ?[]const u8 = null,
    published_date: ?[]const u8 = null,
    author: ?[]const u8 = null,
    text: ?[]const u8 = null,

    pub fn deinit(self: AnswerResult, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.url);
        if (self.title) |v| allocator.free(v);
        if (self.published_date) |v| allocator.free(v);
        if (self.author) |v| allocator.free(v);
        if (self.text) |v| allocator.free(v);
    }

    pub fn format(self: AnswerResult, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("AnswerResult{{ id={s}, url={s}, title={?s} }}", .{
            self.id,
            self.url,
            self.title,
        });
    }
};

pub const StreamChunk = struct {
    content: ?[]const u8 = null,
    citations: ?[]AnswerResult = null,

    pub fn hasData(self: StreamChunk) bool {
        return self.content != null or self.citations != null;
    }

    pub fn deinit(self: StreamChunk, allocator: std.mem.Allocator) void {
        if (self.content) |v| allocator.free(v);
        if (self.citations) |cits| {
            for (cits) |c| c.deinit(allocator);
            allocator.free(cits);
        }
    }

    pub fn format(self: StreamChunk, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("StreamChunk{{ content={?s}, citations_count={d} }}", .{
            self.content,
            if (self.citations) |c| c.len else @as(usize, 0),
        });
    }
};

pub const AnswerResponse = struct {
    answer: union(enum) { text: []const u8, object: std.json.Value },
    citations: []AnswerResult,
    cost_dollars: ?CostDollars = null,

    pub fn deinit(self: AnswerResponse, allocator: std.mem.Allocator) void {
        switch (self.answer) {
            .text => |t| allocator.free(t),
            .object => |v| utils.freeValue(allocator, v),
        }
        for (self.citations) |c| c.deinit(allocator);
        allocator.free(self.citations);
    }

    pub fn format(self: AnswerResponse, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("AnswerResponse{{ citations_count={d} }}", .{self.citations.len});
    }
};

// ---------------------------------------------------------------------------
// Cost, Output, and Response Types
// ---------------------------------------------------------------------------

pub const CostDollarsSearch = struct {
    neural: ?f64 = null,
    keyword: ?f64 = null,
};

pub const CostDollarsContents = struct {
    text: ?f64 = null,
    summary: ?f64 = null,
};

pub const CostDollars = struct {
    total: f64,
    search: ?CostDollarsSearch = null,
    contents: ?CostDollarsContents = null,
};

pub const DeepSearchOutputGroundingCitation = struct {
    url: []const u8,
    title: []const u8,
};

pub const DeepSearchOutputGrounding = struct {
    field: []const u8,
    citations: []DeepSearchOutputGroundingCitation,
    confidence: GroundingConfidence,
};

pub const DeepSearchOutput = struct {
    content: union(enum) { text: []const u8, object: std.json.Value },
    grounding: []DeepSearchOutputGrounding,

    pub fn deinit(self: DeepSearchOutput, allocator: std.mem.Allocator) void {
        switch (self.content) {
            .text => |t| allocator.free(t),
            .object => |v| utils.freeValue(allocator, v),
        }
        for (self.grounding) |g| {
            allocator.free(g.field);
            for (g.citations) |c| {
                allocator.free(c.url);
                allocator.free(c.title);
            }
            allocator.free(g.citations);
        }
        allocator.free(self.grounding);
    }
};

pub const ContentStatus = struct {
    id: []const u8,
    status: []const u8,
    source: []const u8,
};

pub fn SearchResponse(comptime T: type) type {
    return struct {
        results: []T,
        resolved_search_type: ?[]const u8 = null,
        auto_date: ?[]const u8 = null,
        context: ?[]const u8 = null,
        output: ?DeepSearchOutput = null,
        statuses: ?[]ContentStatus = null,
        cost_dollars: ?CostDollars = null,
        search_time: ?f64 = null,
        allocator: std.mem.Allocator,

        pub fn deinit(self: @This()) void {
            for (self.results) |r| r.deinit(self.allocator);
            self.allocator.free(self.results);
            if (self.resolved_search_type) |v| self.allocator.free(v);
            if (self.auto_date) |v| self.allocator.free(v);
            if (self.context) |v| self.allocator.free(v);
            if (self.output) |o| o.deinit(self.allocator);
            if (self.statuses) |ss| {
                for (ss) |s| {
                    self.allocator.free(s.id);
                    self.allocator.free(s.status);
                    self.allocator.free(s.source);
                }
                self.allocator.free(ss);
            }
        }

        pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            try writer.print("SearchResponse{{ results_count={d} }}", .{self.results.len});
        }
    };
}
