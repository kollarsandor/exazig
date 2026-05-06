/// Websets subsystem types.
const std = @import("std");

// ---------------------------------------------------------------------------
// Enumerations
// ---------------------------------------------------------------------------

pub const WebsetPriority = enum {
    low, medium, high,
    pub fn toString(self: WebsetPriority) []const u8 {
        return switch (self) { .low => "low", .medium => "medium", .high => "high" };
    }
    pub fn fromString(s: []const u8) ?WebsetPriority {
        if (std.mem.eql(u8, s, "low")) return .low;
        if (std.mem.eql(u8, s, "medium")) return .medium;
        if (std.mem.eql(u8, s, "high")) return .high;
        return null;
    }
};

pub const WebsetSearchBehavior = enum {
    override, append,
    pub fn toString(self: WebsetSearchBehavior) []const u8 {
        return switch (self) { .override => "override", .append => "append" };
    }
    pub fn fromString(s: []const u8) ?WebsetSearchBehavior {
        if (std.mem.eql(u8, s, "override")) return .override;
        if (std.mem.eql(u8, s, "append")) return .append;
        return null;
    }
};

pub const EnrichmentFormat = enum {
    text, date, number, options, email, phone, url,
    pub fn toString(self: EnrichmentFormat) []const u8 {
        return switch (self) {
            .text => "text", .date => "date", .number => "number",
            .options => "options", .email => "email", .phone => "phone", .url => "url",
        };
    }
    pub fn fromString(s: []const u8) ?EnrichmentFormat {
        if (std.mem.eql(u8, s, "text")) return .text;
        if (std.mem.eql(u8, s, "date")) return .date;
        if (std.mem.eql(u8, s, "number")) return .number;
        if (std.mem.eql(u8, s, "options")) return .options;
        if (std.mem.eql(u8, s, "email")) return .email;
        if (std.mem.eql(u8, s, "phone")) return .phone;
        if (std.mem.eql(u8, s, "url")) return .url;
        return null;
    }
};

pub const ImportFormat = enum {
    csv, webset,
    pub fn toString(self: ImportFormat) []const u8 {
        return switch (self) { .csv => "csv", .webset => "webset" };
    }
    pub fn fromString(s: []const u8) ?ImportFormat {
        if (std.mem.eql(u8, s, "csv")) return .csv;
        if (std.mem.eql(u8, s, "webset")) return .webset;
        return null;
    }
};

pub const ImportStatus = enum {
    pending, processing, completed, failed,
    pub fn toString(self: ImportStatus) []const u8 {
        return switch (self) {
            .pending => "pending", .processing => "processing",
            .completed => "completed", .failed => "failed",
        };
    }
    pub fn fromString(s: []const u8) ?ImportStatus {
        if (std.mem.eql(u8, s, "pending")) return .pending;
        if (std.mem.eql(u8, s, "processing")) return .processing;
        if (std.mem.eql(u8, s, "completed")) return .completed;
        if (std.mem.eql(u8, s, "failed")) return .failed;
        return null;
    }
};

pub const ImportFailedReason = enum {
    invalid_format, invalid_file_content, missing_identifier,
    pub fn toString(self: ImportFailedReason) []const u8 {
        return switch (self) {
            .invalid_format => "invalid_format",
            .invalid_file_content => "invalid_file_content",
            .missing_identifier => "missing_identifier",
        };
    }
    pub fn fromString(s: []const u8) ?ImportFailedReason {
        if (std.mem.eql(u8, s, "invalid_format")) return .invalid_format;
        if (std.mem.eql(u8, s, "invalid_file_content")) return .invalid_file_content;
        if (std.mem.eql(u8, s, "missing_identifier")) return .missing_identifier;
        return null;
    }
};

pub const ImportSource = enum {
    import_, webset,
    pub fn toString(self: ImportSource) []const u8 {
        return switch (self) { .import_ => "import", .webset => "webset" };
    }
    pub fn fromString(s: []const u8) ?ImportSource {
        if (std.mem.eql(u8, s, "import")) return .import_;
        if (std.mem.eql(u8, s, "webset")) return .webset;
        return null;
    }
};

pub const ScopeSourceType = enum {
    import_, webset,
    pub fn toString(self: ScopeSourceType) []const u8 {
        return switch (self) { .import_ => "import", .webset => "webset" };
    }
    pub fn fromString(s: []const u8) ?ScopeSourceType {
        if (std.mem.eql(u8, s, "import")) return .import_;
        if (std.mem.eql(u8, s, "webset")) return .webset;
        return null;
    }
};

pub const WebsetStatus = enum {
    idle, running, paused,
    pub fn toString(self: WebsetStatus) []const u8 {
        return switch (self) { .idle => "idle", .running => "running", .paused => "paused" };
    }
    pub fn fromString(s: []const u8) ?WebsetStatus {
        if (std.mem.eql(u8, s, "idle")) return .idle;
        if (std.mem.eql(u8, s, "running")) return .running;
        if (std.mem.eql(u8, s, "paused")) return .paused;
        return null;
    }
};

pub const WebsetSearchStatus = enum {
    created, running, completed, canceled,
    pub fn toString(self: WebsetSearchStatus) []const u8 {
        return switch (self) {
            .created => "created", .running => "running",
            .completed => "completed", .canceled => "canceled",
        };
    }
    pub fn fromString(s: []const u8) ?WebsetSearchStatus {
        if (std.mem.eql(u8, s, "created")) return .created;
        if (std.mem.eql(u8, s, "running")) return .running;
        if (std.mem.eql(u8, s, "completed")) return .completed;
        if (std.mem.eql(u8, s, "canceled")) return .canceled;
        return null;
    }
};

pub const WebsetEnrichmentStatus = enum {
    pending, canceled, completed,
    pub fn toString(self: WebsetEnrichmentStatus) []const u8 {
        return switch (self) {
            .pending => "pending", .canceled => "canceled", .completed => "completed",
        };
    }
    pub fn fromString(s: []const u8) ?WebsetEnrichmentStatus {
        if (std.mem.eql(u8, s, "pending")) return .pending;
        if (std.mem.eql(u8, s, "canceled")) return .canceled;
        if (std.mem.eql(u8, s, "completed")) return .completed;
        return null;
    }
};

pub const WebhookStatus = enum {
    active, inactive,
    pub fn toString(self: WebhookStatus) []const u8 {
        return switch (self) { .active => "active", .inactive => "inactive" };
    }
    pub fn fromString(s: []const u8) ?WebhookStatus {
        if (std.mem.eql(u8, s, "active")) return .active;
        if (std.mem.eql(u8, s, "inactive")) return .inactive;
        return null;
    }
};

pub const MonitorStatus = enum {
    enabled, disabled,
    pub fn toString(self: MonitorStatus) []const u8 {
        return switch (self) { .enabled => "enabled", .disabled => "disabled" };
    }
    pub fn fromString(s: []const u8) ?MonitorStatus {
        if (std.mem.eql(u8, s, "enabled")) return .enabled;
        if (std.mem.eql(u8, s, "disabled")) return .disabled;
        return null;
    }
};

pub const MonitorRunStatus = enum {
    created, running, completed, canceled,
    pub fn toString(self: MonitorRunStatus) []const u8 {
        return switch (self) {
            .created => "created", .running => "running",
            .completed => "completed", .canceled => "canceled",
        };
    }
    pub fn fromString(s: []const u8) ?MonitorRunStatus {
        if (std.mem.eql(u8, s, "created")) return .created;
        if (std.mem.eql(u8, s, "running")) return .running;
        if (std.mem.eql(u8, s, "completed")) return .completed;
        if (std.mem.eql(u8, s, "canceled")) return .canceled;
        return null;
    }
};

pub const MonitorRunType = enum {
    search, refresh,
    pub fn toString(self: MonitorRunType) []const u8 {
        return switch (self) { .search => "search", .refresh => "refresh" };
    }
    pub fn fromString(s: []const u8) ?MonitorRunType {
        if (std.mem.eql(u8, s, "search")) return .search;
        if (std.mem.eql(u8, s, "refresh")) return .refresh;
        return null;
    }
};

pub const Satisfied = enum {
    yes, no, unclear,
    pub fn toString(self: Satisfied) []const u8 {
        return switch (self) { .yes => "yes", .no => "no", .unclear => "unclear" };
    }
    pub fn fromString(s: []const u8) ?Satisfied {
        if (std.mem.eql(u8, s, "yes")) return .yes;
        if (std.mem.eql(u8, s, "no")) return .no;
        if (std.mem.eql(u8, s, "unclear")) return .unclear;
        return null;
    }
};

pub const Source = enum {
    search, import_,
    pub fn toString(self: Source) []const u8 {
        return switch (self) { .search => "search", .import_ => "import" };
    }
    pub fn fromString(s: []const u8) ?Source {
        if (std.mem.eql(u8, s, "search")) return .search;
        if (std.mem.eql(u8, s, "import")) return .import_;
        return null;
    }
};

pub const EventType = enum {
    webset_created,
    webset_deleted,
    webset_paused,
    webset_idle,
    webset_search_created,
    webset_search_canceled,
    webset_search_completed,
    webset_search_updated,
    import_created,
    import_completed,
    webset_item_created,
    webset_item_enriched,
    monitor_created,
    monitor_updated,
    monitor_deleted,
    monitor_run_created,
    monitor_run_completed,
    webset_export_created,
    webset_export_completed,

    pub fn toString(self: EventType) []const u8 {
        return switch (self) {
            .webset_created => "webset.created",
            .webset_deleted => "webset.deleted",
            .webset_paused => "webset.paused",
            .webset_idle => "webset.idle",
            .webset_search_created => "webset.search.created",
            .webset_search_canceled => "webset.search.canceled",
            .webset_search_completed => "webset.search.completed",
            .webset_search_updated => "webset.search.updated",
            .import_created => "import.created",
            .import_completed => "import.completed",
            .webset_item_created => "webset.item.created",
            .webset_item_enriched => "webset.item.enriched",
            .monitor_created => "monitor.created",
            .monitor_updated => "monitor.updated",
            .monitor_deleted => "monitor.deleted",
            .monitor_run_created => "monitor.run.created",
            .monitor_run_completed => "monitor.run.completed",
            .webset_export_created => "webset.export.created",
            .webset_export_completed => "webset.export.completed",
        };
    }

    pub fn fromString(s: []const u8) ?EventType {
        if (std.mem.eql(u8, s, "webset.created")) return .webset_created;
        if (std.mem.eql(u8, s, "webset.deleted")) return .webset_deleted;
        if (std.mem.eql(u8, s, "webset.paused")) return .webset_paused;
        if (std.mem.eql(u8, s, "webset.idle")) return .webset_idle;
        if (std.mem.eql(u8, s, "webset.search.created")) return .webset_search_created;
        if (std.mem.eql(u8, s, "webset.search.canceled")) return .webset_search_canceled;
        if (std.mem.eql(u8, s, "webset.search.completed")) return .webset_search_completed;
        if (std.mem.eql(u8, s, "webset.search.updated")) return .webset_search_updated;
        if (std.mem.eql(u8, s, "import.created")) return .import_created;
        if (std.mem.eql(u8, s, "import.completed")) return .import_completed;
        if (std.mem.eql(u8, s, "webset.item.created")) return .webset_item_created;
        if (std.mem.eql(u8, s, "webset.item.enriched")) return .webset_item_enriched;
        if (std.mem.eql(u8, s, "monitor.created")) return .monitor_created;
        if (std.mem.eql(u8, s, "monitor.updated")) return .monitor_updated;
        if (std.mem.eql(u8, s, "monitor.deleted")) return .monitor_deleted;
        if (std.mem.eql(u8, s, "monitor.run.created")) return .monitor_run_created;
        if (std.mem.eql(u8, s, "monitor.run.completed")) return .monitor_run_completed;
        if (std.mem.eql(u8, s, "webset.export.created")) return .webset_export_created;
        if (std.mem.eql(u8, s, "webset.export.completed")) return .webset_export_completed;
        return null;
    }
};

// ---------------------------------------------------------------------------
// Entity type
// ---------------------------------------------------------------------------

pub const WebsetEntity = union(enum) {
    company: void,
    person: void,
    article: void,
    research_paper: void,
    custom: struct { description: []const u8 },

    pub fn toString(self: WebsetEntity) []const u8 {
        return switch (self) {
            .company => "company",
            .person => "person",
            .article => "article",
            .research_paper => "research_paper",
            .custom => "custom",
        };
    }
};

// ---------------------------------------------------------------------------
// Parameter structs
// ---------------------------------------------------------------------------

pub const RequestOptions = struct {
    priority: ?WebsetPriority = null,
    headers: ?std.StringHashMap([]const u8) = null,
};

pub const CreateCriterionParameters = struct {
    description: []const u8,
};

pub const SearchCriterion = struct {
    description: []const u8,
};

pub const Option = struct {
    label: []const u8,
};

pub const CreateEnrichmentParameters = struct {
    description: []const u8,
    format: ?EnrichmentFormat = null,
    options: ?[]Option = null,
    metadata: ?std.json.Value = null,
};

pub const UpdateEnrichmentParameters = struct {
    description: ?[]const u8 = null,
    format: ?EnrichmentFormat = null,
    options: ?[]Option = null,
    metadata: ?std.json.Value = null,
};

pub const CreateWebhookParameters = struct {
    events: []EventType,
    url: []const u8,
    metadata: ?std.json.Value = null,
};

pub const UpdateWebhookParameters = struct {
    events: ?[]EventType = null,
    url: ?[]const u8 = null,
    metadata: ?std.json.Value = null,
};

pub const ExcludeItem = struct {
    source: ImportSource,
    id: []const u8,
};

pub const ScopeRelationship = struct {
    definition: []const u8,
    limit: ?u64 = null,
};

pub const ScopeItem = struct {
    source: ScopeSourceType,
    id: []const u8,
    relationship: ?ScopeRelationship = null,
};

pub const CreateWebsetParametersSearch = struct {
    query: []const u8,
    count: ?i64 = 10,
    entity: ?WebsetEntity = null,
    criteria: ?[]CreateCriterionParameters = null,
    exclude: ?[]ExcludeItem = null,
    scope: ?[]ScopeItem = null,
};

pub const ImportItem = struct {
    source: ImportSource,
    id: []const u8,
};

pub const CreateWebsetParameters = struct {
    search: ?CreateWebsetParametersSearch = null,
    imports: ?[]ImportItem = null,
    enrichments: ?[]CreateEnrichmentParameters = null,
    external_id: ?[]const u8 = null,
    metadata: ?std.json.Value = null,
};

pub const CreateWebsetSearchParameters = struct {
    count: i64,
    query: []const u8,
    entity: ?WebsetEntity = null,
    criteria: ?[]CreateCriterionParameters = null,
    exclude: ?[]ExcludeItem = null,
    scope: ?[]ScopeItem = null,
    behavior: WebsetSearchBehavior = .override,
    metadata: ?std.json.Value = null,
};

pub const UpdateWebsetRequest = struct {
    metadata: ?std.json.Value = null,
};

pub const PreviewWebsetParameters = struct {
    query: []const u8,
    entity: ?WebsetEntity = null,
};

pub const MonitorCadence = struct {
    cron: []const u8,
    timezone: ?[]const u8 = "Etc/UTC",
};

pub const MonitorBehaviorSearchConfig = struct {
    query: ?[]const u8 = null,
    criteria: ?[]SearchCriterion = null,
    entity: ?WebsetEntity = null,
    count: i64,
    behavior: WebsetSearchBehavior = .append,
};

pub const MonitorBehaviorSearch = struct {
    config: MonitorBehaviorSearchConfig,
};

pub const MonitorBehaviorRefreshTarget = union(enum) {
    enrichments: struct { ids: ?[][]const u8 },
    contents: void,
};

pub const MonitorBehaviorRefresh = struct {
    config: MonitorBehaviorRefreshTarget,
};

pub const MonitorBehavior = union(enum) {
    search: MonitorBehaviorSearch,
    refresh: MonitorBehaviorRefresh,
};

pub const CreateMonitorParameters = struct {
    webset_id: []const u8,
    cadence: MonitorCadence,
    behavior: MonitorBehavior,
    metadata: ?std.json.Value = null,
};

pub const UpdateMonitor = struct {
    status: ?MonitorStatus = null,
    metadata: ?std.json.Value = null,
};

pub const CsvImportConfig = struct {
    identifier: ?i64 = null,
};

pub const CreateImportParameters = struct {
    size: ?f64 = null,
    count: ?f64 = null,
    title: ?[]const u8 = null,
    format: ImportFormat,
    entity: WebsetEntity,
    csv: ?CsvImportConfig = null,
    metadata: ?std.json.Value = null,
};

pub const UpdateImport = struct {
    metadata: ?std.json.Value = null,
    title: ?[]const u8 = null,
};

// ---------------------------------------------------------------------------
// Response / resource structs
// ---------------------------------------------------------------------------

pub const Progress = struct {
    found: f64,
    completion: f64,
};

pub const Reference = struct {
    title: ?[]const u8 = null,
    snippet: ?[]const u8 = null,
    url: []const u8,

    pub fn deinit(self: Reference, allocator: std.mem.Allocator) void {
        if (self.title) |v| allocator.free(v);
        if (self.snippet) |v| allocator.free(v);
        allocator.free(self.url);
    }
};

pub const EnrichmentResult = struct {
    object: []const u8,
    format: EnrichmentFormat,
    result: ?[][]const u8,
    reasoning: ?[]const u8,
    references: []Reference,
    enrichment_id: []const u8,

    pub fn deinit(self: EnrichmentResult, allocator: std.mem.Allocator) void {
        allocator.free(self.object);
        if (self.result) |r| {
            for (r) |s| allocator.free(s);
            allocator.free(r);
        }
        if (self.reasoning) |v| allocator.free(v);
        for (self.references) |r| r.deinit(allocator);
        allocator.free(self.references);
        allocator.free(self.enrichment_id);
    }
};

pub const WebsetSearchCriterion = struct {
    description: []const u8,
    success_rate: f64,

    pub fn deinit(self: WebsetSearchCriterion, allocator: std.mem.Allocator) void {
        allocator.free(self.description);
    }
};

pub const WebsetEnrichmentOption = struct {
    label: []const u8,
    pub fn deinit(self: WebsetEnrichmentOption, allocator: std.mem.Allocator) void {
        allocator.free(self.label);
    }
};

pub const WebsetItemEvaluation = struct {
    criterion: []const u8,
    reasoning: []const u8,
    satisfied: Satisfied,
    references: ?[]Reference,

    pub fn deinit(self: WebsetItemEvaluation, allocator: std.mem.Allocator) void {
        allocator.free(self.criterion);
        allocator.free(self.reasoning);
        if (self.references) |refs| {
            for (refs) |r| r.deinit(allocator);
            allocator.free(refs);
        }
    }
};

pub const WebsetItemPropertiesPersonFields = struct {
    url: []const u8,
    description: []const u8,
    content: ?[]const u8,
    name: ?[]const u8,
    location: ?[]const u8,
};

pub const WebsetItemPropertiesCompanyFields = struct {
    url: []const u8,
    description: []const u8,
    content: ?[]const u8,
    name: ?[]const u8,
    industry: ?[]const u8,
};

pub const WebsetItemPropertiesArticleFields = struct {
    url: []const u8,
    description: []const u8,
    content: ?[]const u8,
    title: ?[]const u8,
    published_date: ?[]const u8,
};

pub const WebsetItemPropertiesResearchPaperFields = struct {
    url: []const u8,
    description: []const u8,
    content: ?[]const u8,
    title: ?[]const u8,
    authors: ?[][]const u8,
};

pub const WebsetItemPropertiesCustomFields = struct {
    url: []const u8,
    description: []const u8,
    content: ?[]const u8,
};

pub const WebsetItemProperties = union(enum) {
    person: WebsetItemPropertiesPersonFields,
    company: WebsetItemPropertiesCompanyFields,
    article: WebsetItemPropertiesArticleFields,
    research_paper: WebsetItemPropertiesResearchPaperFields,
    custom: WebsetItemPropertiesCustomFields,

    pub fn deinit(self: WebsetItemProperties, allocator: std.mem.Allocator) void {
        switch (self) {
            .person => |p| {
                allocator.free(p.url);
                allocator.free(p.description);
                if (p.content) |v| allocator.free(v);
                if (p.name) |v| allocator.free(v);
                if (p.location) |v| allocator.free(v);
            },
            .company => |c| {
                allocator.free(c.url);
                allocator.free(c.description);
                if (c.content) |v| allocator.free(v);
                if (c.name) |v| allocator.free(v);
                if (c.industry) |v| allocator.free(v);
            },
            .article => |a| {
                allocator.free(a.url);
                allocator.free(a.description);
                if (a.content) |v| allocator.free(v);
                if (a.title) |v| allocator.free(v);
                if (a.published_date) |v| allocator.free(v);
            },
            .research_paper => |r| {
                allocator.free(r.url);
                allocator.free(r.description);
                if (r.content) |v| allocator.free(v);
                if (r.title) |v| allocator.free(v);
                if (r.authors) |authors| {
                    for (authors) |a| allocator.free(a);
                    allocator.free(authors);
                }
            },
            .custom => |c| {
                allocator.free(c.url);
                allocator.free(c.description);
                if (c.content) |v| allocator.free(v);
            },
        }
    }
};

pub const WebsetItem = struct {
    id: []const u8,
    object: []const u8,
    source: Source,
    source_id: []const u8,
    webset_id: []const u8,
    properties: WebsetItemProperties,
    evaluations: []WebsetItemEvaluation,
    enrichments: []EnrichmentResult,
    created_at: []const u8,
    updated_at: []const u8,

    pub fn deinit(self: WebsetItem, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.object);
        allocator.free(self.source_id);
        allocator.free(self.webset_id);
        self.properties.deinit(allocator);
        for (self.evaluations) |e| e.deinit(allocator);
        allocator.free(self.evaluations);
        for (self.enrichments) |e| e.deinit(allocator);
        allocator.free(self.enrichments);
        allocator.free(self.created_at);
        allocator.free(self.updated_at);
    }
};

pub const WebsetEnrichment = struct {
    id: []const u8,
    object: []const u8,
    status: WebsetEnrichmentStatus,
    webset_id: []const u8,
    title: ?[]const u8,
    description: []const u8,
    format: ?EnrichmentFormat,
    options: ?[]WebsetEnrichmentOption,
    instructions: ?[]const u8,
    metadata: ?std.json.Value,
    created_at: []const u8,
    updated_at: []const u8,

    pub fn deinit(self: WebsetEnrichment, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.object);
        allocator.free(self.webset_id);
        if (self.title) |v| allocator.free(v);
        allocator.free(self.description);
        if (self.options) |opts| {
            for (opts) |o| o.deinit(allocator);
            allocator.free(opts);
        }
        if (self.instructions) |v| allocator.free(v);
        if (self.metadata) |v| {
            const utils = @import("../utils.zig");
            utils.freeValue(allocator, v);
        }
        allocator.free(self.created_at);
        allocator.free(self.updated_at);
    }
};

pub const WebsetSearchRecallExpected = struct {
    total: i64,
    confidence: []const u8,
};

pub const WebsetSearchRecall = struct {
    expected: WebsetSearchRecallExpected,
    reasoning: []const u8,
};

pub const WebsetSearch = struct {
    id: []const u8,
    object: []const u8,
    webset_id: []const u8,
    status: WebsetSearchStatus,
    query: []const u8,
    entity: ?WebsetEntity,
    criteria: []WebsetSearchCriterion,
    count: i64,
    behavior: ?WebsetSearchBehavior,
    exclude: ?[]ExcludeItem,
    scope: ?[]ScopeItem,
    progress: Progress,
    recall: ?WebsetSearchRecall,
    metadata: ?std.json.Value,
    canceled_at: ?[]const u8,
    canceled_reason: ?[]const u8,
    created_at: []const u8,
    updated_at: []const u8,

    pub fn deinit(self: WebsetSearch, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.object);
        allocator.free(self.webset_id);
        allocator.free(self.query);
        for (self.criteria) |c| c.deinit(allocator);
        allocator.free(self.criteria);
        if (self.exclude) |ex| {
            for (ex) |e| allocator.free(e.id);
            allocator.free(ex);
        }
        if (self.scope) |sc| {
            for (sc) |s| {
                allocator.free(s.id);
                if (s.relationship) |r| allocator.free(r.definition);
            }
            allocator.free(sc);
        }
        if (self.recall) |r| {
            allocator.free(r.expected.confidence);
            allocator.free(r.reasoning);
        }
        if (self.metadata) |v| {
            const utils = @import("../utils.zig");
            utils.freeValue(allocator, v);
        }
        if (self.canceled_at) |v| allocator.free(v);
        if (self.canceled_reason) |v| allocator.free(v);
        allocator.free(self.created_at);
        allocator.free(self.updated_at);
    }
};

pub const MonitorRun = struct {
    id: []const u8,
    object: []const u8,
    status: MonitorRunStatus,
    monitor_id: []const u8,
    type: MonitorRunType,
    completed_at: ?[]const u8,
    failed_at: ?[]const u8,
    canceled_at: ?[]const u8,
    created_at: []const u8,
    updated_at: []const u8,

    pub fn deinit(self: MonitorRun, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.object);
        allocator.free(self.monitor_id);
        if (self.completed_at) |v| allocator.free(v);
        if (self.failed_at) |v| allocator.free(v);
        if (self.canceled_at) |v| allocator.free(v);
        allocator.free(self.created_at);
        allocator.free(self.updated_at);
    }
};

pub const Monitor = struct {
    id: []const u8,
    object: []const u8,
    status: MonitorStatus,
    webset_id: []const u8,
    cadence: MonitorCadence,
    behavior: MonitorBehavior,
    last_run: ?MonitorRun,
    next_run_at: ?[]const u8,
    metadata: std.json.Value,
    created_at: []const u8,
    updated_at: []const u8,

    pub fn deinit(self: Monitor, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.object);
        allocator.free(self.webset_id);
        allocator.free(self.cadence.cron);
        if (self.cadence.timezone) |v| allocator.free(v);
        if (self.last_run) |r| r.deinit(allocator);
        if (self.next_run_at) |v| allocator.free(v);
        const utils = @import("../utils.zig");
        utils.freeValue(allocator, self.metadata);
        allocator.free(self.created_at);
        allocator.free(self.updated_at);
    }
};

pub const Webset = struct {
    id: []const u8,
    object: []const u8,
    status: WebsetStatus,
    dashboard_url: []const u8,
    title: ?[]const u8,
    external_id: ?[]const u8,
    searches: []WebsetSearch,
    enrichments: []WebsetEnrichment,
    monitors: []Monitor,
    metadata: ?std.json.Value,
    created_at: []const u8,
    updated_at: []const u8,

    pub fn deinit(self: Webset, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.object);
        allocator.free(self.dashboard_url);
        if (self.title) |v| allocator.free(v);
        if (self.external_id) |v| allocator.free(v);
        for (self.searches) |s| s.deinit(allocator);
        allocator.free(self.searches);
        for (self.enrichments) |e| e.deinit(allocator);
        allocator.free(self.enrichments);
        for (self.monitors) |m| m.deinit(allocator);
        allocator.free(self.monitors);
        if (self.metadata) |v| {
            const utils = @import("../utils.zig");
            utils.freeValue(allocator, v);
        }
        allocator.free(self.created_at);
        allocator.free(self.updated_at);
    }
};

pub const GetWebsetResponse = Webset;

pub const Webhook = struct {
    id: []const u8,
    object: []const u8,
    status: WebhookStatus,
    events: []EventType,
    url: []const u8,
    secret: ?[]const u8,
    metadata: ?std.json.Value,
    created_at: []const u8,
    updated_at: []const u8,

    pub fn deinit(self: Webhook, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.object);
        allocator.free(self.events);
        allocator.free(self.url);
        if (self.secret) |v| allocator.free(v);
        if (self.metadata) |v| {
            const utils = @import("../utils.zig");
            utils.freeValue(allocator, v);
        }
        allocator.free(self.created_at);
        allocator.free(self.updated_at);
    }
};

pub const WebhookAttempt = struct {
    id: []const u8,
    object: []const u8,
    event_id: []const u8,
    event_type: EventType,
    webhook_id: []const u8,
    url: []const u8,
    successful: bool,
    response_headers: std.json.Value,
    response_body: ?[]const u8,
    response_status_code: f64,
    attempt: f64,
    attempted_at: []const u8,

    pub fn deinit(self: WebhookAttempt, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.object);
        allocator.free(self.event_id);
        allocator.free(self.webhook_id);
        allocator.free(self.url);
        const utils = @import("../utils.zig");
        utils.freeValue(allocator, self.response_headers);
        if (self.response_body) |v| allocator.free(v);
        allocator.free(self.attempted_at);
    }
};

pub const Import = struct {
    id: []const u8,
    object: []const u8,
    status: ImportStatus,
    format: ImportFormat,
    entity: ?WebsetEntity,
    title: []const u8,
    count: f64,
    metadata: std.json.Value,
    failed_reason: ?ImportFailedReason,
    failed_at: ?[]const u8,
    failed_message: ?[]const u8,
    created_at: []const u8,
    updated_at: []const u8,

    pub fn deinit(self: Import, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.object);
        allocator.free(self.title);
        const utils = @import("../utils.zig");
        utils.freeValue(allocator, self.metadata);
        if (self.failed_at) |v| allocator.free(v);
        if (self.failed_message) |v| allocator.free(v);
        allocator.free(self.created_at);
        allocator.free(self.updated_at);
    }
};

pub const CreateImportResponse = struct {
    id: []const u8,
    object: []const u8,
    status: ImportStatus,
    format: ImportFormat,
    entity: ?WebsetEntity,
    title: []const u8,
    count: f64,
    metadata: std.json.Value,
    failed_reason: ?ImportFailedReason,
    failed_at: ?[]const u8,
    failed_message: ?[]const u8,
    upload_url: []const u8,
    upload_valid_until: []const u8,
    created_at: []const u8,
    updated_at: []const u8,

    pub fn deinit(self: CreateImportResponse, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.object);
        allocator.free(self.title);
        const utils = @import("../utils.zig");
        utils.freeValue(allocator, self.metadata);
        if (self.failed_at) |v| allocator.free(v);
        if (self.failed_message) |v| allocator.free(v);
        allocator.free(self.upload_url);
        allocator.free(self.upload_valid_until);
        allocator.free(self.created_at);
        allocator.free(self.updated_at);
    }
};

pub const PreviewWebsetResponseEnrichment = struct {
    description: []const u8,
    format: EnrichmentFormat,
    options: ?[]Option,

    pub fn deinit(self: PreviewWebsetResponseEnrichment, allocator: std.mem.Allocator) void {
        allocator.free(self.description);
        if (self.options) |opts| {
            for (opts) |o| allocator.free(o.label);
            allocator.free(opts);
        }
    }
};

pub const PreviewWebsetResponseSearchCriterion = struct {
    description: []const u8,
    pub fn deinit(self: PreviewWebsetResponseSearchCriterion, allocator: std.mem.Allocator) void {
        allocator.free(self.description);
    }
};

pub const PreviewWebsetResponseSearch = struct {
    entity: WebsetEntity,
    criteria: []PreviewWebsetResponseSearchCriterion,
    pub fn deinit(self: PreviewWebsetResponseSearch, allocator: std.mem.Allocator) void {
        for (self.criteria) |c| c.deinit(allocator);
        allocator.free(self.criteria);
    }
};

pub const PreviewWebsetResponse = struct {
    search: PreviewWebsetResponseSearch,
    enrichments: []PreviewWebsetResponseEnrichment,

    pub fn deinit(self: PreviewWebsetResponse, allocator: std.mem.Allocator) void {
        self.search.deinit(allocator);
        for (self.enrichments) |e| e.deinit(allocator);
        allocator.free(self.enrichments);
    }
};

// ---------------------------------------------------------------------------
// Paginated list responses
// ---------------------------------------------------------------------------

pub const ListWebsetsResponse = struct {
    data: []Webset,
    has_more: bool,
    next_cursor: ?[]const u8,
    pub fn deinit(self: ListWebsetsResponse, allocator: std.mem.Allocator) void {
        for (self.data) |w| w.deinit(allocator);
        allocator.free(self.data);
        if (self.next_cursor) |v| allocator.free(v);
    }
};

pub const ListWebsetItemResponse = struct {
    data: []WebsetItem,
    has_more: bool,
    next_cursor: ?[]const u8,
    pub fn deinit(self: ListWebsetItemResponse, allocator: std.mem.Allocator) void {
        for (self.data) |item| item.deinit(allocator);
        allocator.free(self.data);
        if (self.next_cursor) |v| allocator.free(v);
    }
};

pub const ListWebsetSearchesResponse = struct {
    data: []WebsetSearch,
    has_more: bool,
    next_cursor: ?[]const u8,
    pub fn deinit(self: ListWebsetSearchesResponse, allocator: std.mem.Allocator) void {
        for (self.data) |s| s.deinit(allocator);
        allocator.free(self.data);
        if (self.next_cursor) |v| allocator.free(v);
    }
};

pub const ListWebsetEnrichmentsResponse = struct {
    data: []WebsetEnrichment,
    has_more: bool,
    next_cursor: ?[]const u8,
    pub fn deinit(self: ListWebsetEnrichmentsResponse, allocator: std.mem.Allocator) void {
        for (self.data) |e| e.deinit(allocator);
        allocator.free(self.data);
        if (self.next_cursor) |v| allocator.free(v);
    }
};

pub const ListWebhooksResponse = struct {
    data: []Webhook,
    has_more: bool,
    next_cursor: ?[]const u8,
    pub fn deinit(self: ListWebhooksResponse, allocator: std.mem.Allocator) void {
        for (self.data) |w| w.deinit(allocator);
        allocator.free(self.data);
        if (self.next_cursor) |v| allocator.free(v);
    }
};

pub const ListWebhookAttemptsResponse = struct {
    data: []WebhookAttempt,
    has_more: bool,
    next_cursor: ?[]const u8,
    pub fn deinit(self: ListWebhookAttemptsResponse, allocator: std.mem.Allocator) void {
        for (self.data) |a| a.deinit(allocator);
        allocator.free(self.data);
        if (self.next_cursor) |v| allocator.free(v);
    }
};

pub const ListMonitorsResponse = struct {
    data: []Monitor,
    has_more: bool,
    next_cursor: ?[]const u8,
    pub fn deinit(self: ListMonitorsResponse, allocator: std.mem.Allocator) void {
        for (self.data) |m| m.deinit(allocator);
        allocator.free(self.data);
        if (self.next_cursor) |v| allocator.free(v);
    }
};

pub const ListMonitorRunsResponse = struct {
    data: []MonitorRun,
    has_more: bool,
    next_cursor: ?[]const u8,
    pub fn deinit(self: ListMonitorRunsResponse, allocator: std.mem.Allocator) void {
        for (self.data) |r| r.deinit(allocator);
        allocator.free(self.data);
        if (self.next_cursor) |v| allocator.free(v);
    }
};

pub const ListImportsResponse = struct {
    data: []Import,
    has_more: bool,
    next_cursor: ?[]const u8,
    pub fn deinit(self: ListImportsResponse, allocator: std.mem.Allocator) void {
        for (self.data) |im| im.deinit(allocator);
        allocator.free(self.data);
        if (self.next_cursor) |v| allocator.free(v);
    }
};

// ---------------------------------------------------------------------------
// Event types
// ---------------------------------------------------------------------------

pub fn WebsetEvent_data(comptime T: type) type {
    return struct {
        id: []const u8,
        object: []const u8,
        type: []const u8,
        created_at: []const u8,
        data: T,
    };
}

pub const WebsetCreatedEvent = WebsetEvent_data(Webset);
pub const WebsetDeletedEvent = WebsetEvent_data(Webset);
pub const WebsetIdleEvent = WebsetEvent_data(Webset);
pub const WebsetPausedEvent = WebsetEvent_data(Webset);
pub const WebsetItemCreatedEvent = WebsetEvent_data(WebsetItem);
pub const WebsetItemEnrichedEvent = WebsetEvent_data(WebsetItem);
pub const WebsetSearchCreatedEvent = WebsetEvent_data(WebsetSearch);
pub const WebsetSearchUpdatedEvent = WebsetEvent_data(WebsetSearch);
pub const WebsetSearchCanceledEvent = WebsetEvent_data(WebsetSearch);
pub const WebsetSearchCompletedEvent = WebsetEvent_data(WebsetSearch);
pub const ImportCreatedEvent = WebsetEvent_data(Import);
pub const ImportCompletedEvent = WebsetEvent_data(Import);
pub const MonitorCreatedEvent = WebsetEvent_data(Monitor);
pub const MonitorUpdatedEvent = WebsetEvent_data(Monitor);
pub const MonitorDeletedEvent = WebsetEvent_data(Monitor);
pub const MonitorRunCreatedEvent = WebsetEvent_data(MonitorRun);
pub const MonitorRunCompletedEvent = WebsetEvent_data(MonitorRun);

pub const WebsetEvent = union(enum) {
    webset_created: WebsetCreatedEvent,
    webset_deleted: WebsetDeletedEvent,
    webset_idle: WebsetIdleEvent,
    webset_paused: WebsetPausedEvent,
    webset_item_created: WebsetItemCreatedEvent,
    webset_item_enriched: WebsetItemEnrichedEvent,
    webset_search_created: WebsetSearchCreatedEvent,
    webset_search_updated: WebsetSearchUpdatedEvent,
    webset_search_canceled: WebsetSearchCanceledEvent,
    webset_search_completed: WebsetSearchCompletedEvent,
    import_created: ImportCreatedEvent,
    import_completed: ImportCompletedEvent,
    monitor_created: MonitorCreatedEvent,
    monitor_updated: MonitorUpdatedEvent,
    monitor_deleted: MonitorDeletedEvent,
    monitor_run_created: MonitorRunCreatedEvent,
    monitor_run_completed: MonitorRunCompletedEvent,

    pub fn parse(allocator: std.mem.Allocator, json_bytes: []const u8) !WebsetEvent {
        const ws_json = @import("json.zig");
        return ws_json.parseWebsetEvent(allocator, json_bytes);
    }
};

pub const ListEventsResponse = struct {
    data: []WebsetEvent,
    has_more: bool,
    next_cursor: ?[]const u8,
};
