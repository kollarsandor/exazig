/// exazig — Zig client for the Exa AI REST API.
///
/// Every public type from every subsystem is re-exported here so callers only
/// need a single import:
///
///     const exa = @import("exa");
///
/// Nothing requires navigating sub-namespaces like exa.websets.types.Webset;
/// everything is available as exa.Webset, exa.SearchParams, etc.

// ---------------------------------------------------------------------------
// Top-level client + iterator
// ---------------------------------------------------------------------------

pub const Exa = @import("client.zig").Exa;
pub const StreamIterator = @import("client.zig").StreamIterator;

// ---------------------------------------------------------------------------
// Core request-parameter types
// ---------------------------------------------------------------------------

pub const SearchParams = @import("types.zig").SearchParams;
pub const FindSimilarParams = @import("types.zig").FindSimilarParams;
pub const GetContentsParams = @import("types.zig").GetContentsParams;
pub const ContentsOptions = @import("types.zig").ContentsOptions;
pub const TextContentsOptions = @import("types.zig").TextContentsOptions;
pub const SummaryContentsOptions = @import("types.zig").SummaryContentsOptions;
pub const HighlightsContentsOptions = @import("types.zig").HighlightsContentsOptions;
pub const ContextContentsOptions = @import("types.zig").ContextContentsOptions;
pub const ExtrasOptions = @import("types.zig").ExtrasOptions;

// ---------------------------------------------------------------------------
// Core enumerations
// ---------------------------------------------------------------------------

pub const SearchType = @import("types.zig").SearchType;
pub const Category = @import("types.zig").Category;
pub const LivecrawlOption = @import("types.zig").LivecrawlOption;
pub const VerbosityOption = @import("types.zig").VerbosityOption;
pub const SectionTag = @import("types.zig").SectionTag;
pub const GroundingConfidence = @import("types.zig").GroundingConfidence;

// ---------------------------------------------------------------------------
// Core response types
// ---------------------------------------------------------------------------

pub const SearchResponse = @import("types.zig").SearchResponse;
pub const Result = @import("types.zig").Result;
pub const AnswerResponse = @import("types.zig").AnswerResponse;
pub const AnswerResult = @import("types.zig").AnswerResult;
pub const StreamChunk = @import("types.zig").StreamChunk;
pub const CostDollars = @import("types.zig").CostDollars;
pub const CostDollarsSearch = @import("types.zig").CostDollarsSearch;
pub const CostDollarsContents = @import("types.zig").CostDollarsContents;
pub const DeepSearchOutput = @import("types.zig").DeepSearchOutput;
pub const DeepSearchOutputGrounding = @import("types.zig").DeepSearchOutputGrounding;
pub const DeepSearchOutputGroundingCitation = @import("types.zig").DeepSearchOutputGroundingCitation;
pub const ContentStatus = @import("types.zig").ContentStatus;

// ---------------------------------------------------------------------------
// Core entity types
// ---------------------------------------------------------------------------

pub const Entity = @import("types.zig").Entity;
pub const CompanyEntity = @import("types.zig").CompanyEntity;
pub const PersonEntity = @import("types.zig").PersonEntity;
pub const EntityCompanyProperties = @import("types.zig").EntityCompanyProperties;
pub const EntityCompanyPropertiesWorkforce = @import("types.zig").EntityCompanyPropertiesWorkforce;
pub const EntityCompanyPropertiesHeadquarters = @import("types.zig").EntityCompanyPropertiesHeadquarters;
pub const EntityCompanyPropertiesFundingRound = @import("types.zig").EntityCompanyPropertiesFundingRound;
pub const EntityCompanyPropertiesFinancials = @import("types.zig").EntityCompanyPropertiesFinancials;
pub const EntityCompanyPropertiesWebTraffic = @import("types.zig").EntityCompanyPropertiesWebTraffic;
pub const EntityDateRange = @import("types.zig").EntityDateRange;
pub const EntityPersonPropertiesCompanyRef = @import("types.zig").EntityPersonPropertiesCompanyRef;
pub const EntityPersonPropertiesWorkHistoryEntry = @import("types.zig").EntityPersonPropertiesWorkHistoryEntry;
pub const EntityPersonProperties = @import("types.zig").EntityPersonProperties;

// ---------------------------------------------------------------------------
// Websets — enumerations
// ---------------------------------------------------------------------------

pub const WebsetPriority = @import("websets/types.zig").WebsetPriority;
pub const WebsetSearchBehavior = @import("websets/types.zig").WebsetSearchBehavior;
pub const EnrichmentFormat = @import("websets/types.zig").EnrichmentFormat;
pub const ImportFormat = @import("websets/types.zig").ImportFormat;
pub const ImportStatus = @import("websets/types.zig").ImportStatus;
pub const ImportFailedReason = @import("websets/types.zig").ImportFailedReason;
pub const ImportSource = @import("websets/types.zig").ImportSource;
pub const ScopeSourceType = @import("websets/types.zig").ScopeSourceType;
pub const WebsetStatus = @import("websets/types.zig").WebsetStatus;
pub const WebsetSearchStatus = @import("websets/types.zig").WebsetSearchStatus;
pub const WebsetEnrichmentStatus = @import("websets/types.zig").WebsetEnrichmentStatus;
pub const WebhookStatus = @import("websets/types.zig").WebhookStatus;
pub const WebsetMonitorStatus = @import("websets/types.zig").MonitorStatus;
pub const WebsetMonitorRunStatus = @import("websets/types.zig").MonitorRunStatus;
pub const WebsetMonitorRunType = @import("websets/types.zig").MonitorRunType;
pub const Satisfied = @import("websets/types.zig").Satisfied;
pub const WebsetItemSource = @import("websets/types.zig").Source;
pub const WebsetEventType = @import("websets/types.zig").EventType;
pub const WebsetEntity = @import("websets/types.zig").WebsetEntity;

// ---------------------------------------------------------------------------
// Websets — request-parameter types
// ---------------------------------------------------------------------------

pub const WebsetRequestOptions = @import("websets/types.zig").RequestOptions;
pub const CreateCriterionParameters = @import("websets/types.zig").CreateCriterionParameters;
pub const SearchCriterion = @import("websets/types.zig").SearchCriterion;
pub const EnrichmentOption = @import("websets/types.zig").Option;
pub const CreateEnrichmentParameters = @import("websets/types.zig").CreateEnrichmentParameters;
pub const UpdateEnrichmentParameters = @import("websets/types.zig").UpdateEnrichmentParameters;
pub const CreateWebhookParameters = @import("websets/types.zig").CreateWebhookParameters;
pub const UpdateWebhookParameters = @import("websets/types.zig").UpdateWebhookParameters;
pub const ExcludeItem = @import("websets/types.zig").ExcludeItem;
pub const ScopeRelationship = @import("websets/types.zig").ScopeRelationship;
pub const ScopeItem = @import("websets/types.zig").ScopeItem;
pub const CreateWebsetParametersSearch = @import("websets/types.zig").CreateWebsetParametersSearch;
pub const ImportItem = @import("websets/types.zig").ImportItem;
pub const CreateWebsetParameters = @import("websets/types.zig").CreateWebsetParameters;
pub const CreateWebsetSearchParameters = @import("websets/types.zig").CreateWebsetSearchParameters;
pub const UpdateWebsetRequest = @import("websets/types.zig").UpdateWebsetRequest;
pub const PreviewWebsetParameters = @import("websets/types.zig").PreviewWebsetParameters;
pub const WebsetMonitorCadence = @import("websets/types.zig").MonitorCadence;
pub const WebsetMonitorBehaviorSearchConfig = @import("websets/types.zig").MonitorBehaviorSearchConfig;
pub const WebsetMonitorBehaviorSearch = @import("websets/types.zig").MonitorBehaviorSearch;
pub const WebsetMonitorBehaviorRefreshTarget = @import("websets/types.zig").MonitorBehaviorRefreshTarget;
pub const WebsetMonitorBehaviorRefresh = @import("websets/types.zig").MonitorBehaviorRefresh;
pub const WebsetMonitorBehavior = @import("websets/types.zig").MonitorBehavior;
pub const CreateWebsetMonitorParameters = @import("websets/types.zig").CreateMonitorParameters;
pub const UpdateWebsetMonitor = @import("websets/types.zig").UpdateMonitor;
pub const CsvImportConfig = @import("websets/types.zig").CsvImportConfig;
pub const CreateImportParameters = @import("websets/types.zig").CreateImportParameters;
pub const UpdateImport = @import("websets/types.zig").UpdateImport;

// ---------------------------------------------------------------------------
// Websets — response and resource types
// ---------------------------------------------------------------------------

pub const WebsetProgress = @import("websets/types.zig").Progress;
pub const WebsetReference = @import("websets/types.zig").Reference;
pub const EnrichmentResult = @import("websets/types.zig").EnrichmentResult;
pub const WebsetSearchCriterion = @import("websets/types.zig").WebsetSearchCriterion;
pub const WebsetEnrichmentOption = @import("websets/types.zig").WebsetEnrichmentOption;
pub const WebsetItemEvaluation = @import("websets/types.zig").WebsetItemEvaluation;
pub const WebsetItemPropertiesPersonFields = @import("websets/types.zig").WebsetItemPropertiesPersonFields;
pub const WebsetItemPropertiesCompanyFields = @import("websets/types.zig").WebsetItemPropertiesCompanyFields;
pub const WebsetItemPropertiesArticleFields = @import("websets/types.zig").WebsetItemPropertiesArticleFields;
pub const WebsetItemPropertiesResearchPaperFields = @import("websets/types.zig").WebsetItemPropertiesResearchPaperFields;
pub const WebsetItemPropertiesCustomFields = @import("websets/types.zig").WebsetItemPropertiesCustomFields;
pub const WebsetItemProperties = @import("websets/types.zig").WebsetItemProperties;
pub const WebsetItem = @import("websets/types.zig").WebsetItem;
pub const WebsetEnrichment = @import("websets/types.zig").WebsetEnrichment;
pub const WebsetSearchRecallExpected = @import("websets/types.zig").WebsetSearchRecallExpected;
pub const WebsetSearchRecall = @import("websets/types.zig").WebsetSearchRecall;
pub const WebsetSearch = @import("websets/types.zig").WebsetSearch;
pub const WebsetMonitorRun = @import("websets/types.zig").MonitorRun;
pub const WebsetMonitor = @import("websets/types.zig").Monitor;
pub const Webset = @import("websets/types.zig").Webset;
pub const GetWebsetResponse = @import("websets/types.zig").GetWebsetResponse;
pub const Webhook = @import("websets/types.zig").Webhook;
pub const WebhookAttempt = @import("websets/types.zig").WebhookAttempt;
pub const WebsetImport = @import("websets/types.zig").Import;
pub const CreateImportResponse = @import("websets/types.zig").CreateImportResponse;
pub const PreviewWebsetResponseEnrichment = @import("websets/types.zig").PreviewWebsetResponseEnrichment;
pub const PreviewWebsetResponseSearchCriterion = @import("websets/types.zig").PreviewWebsetResponseSearchCriterion;
pub const PreviewWebsetResponseSearch = @import("websets/types.zig").PreviewWebsetResponseSearch;
pub const PreviewWebsetResponse = @import("websets/types.zig").PreviewWebsetResponse;
pub const ListWebsetsResponse = @import("websets/types.zig").ListWebsetsResponse;
pub const ListWebsetItemResponse = @import("websets/types.zig").ListWebsetItemResponse;
pub const ListWebsetSearchesResponse = @import("websets/types.zig").ListWebsetSearchesResponse;
pub const ListWebsetEnrichmentsResponse = @import("websets/types.zig").ListWebsetEnrichmentsResponse;
pub const ListWebhooksResponse = @import("websets/types.zig").ListWebhooksResponse;
pub const ListWebhookAttemptsResponse = @import("websets/types.zig").ListWebhookAttemptsResponse;
pub const ListWebsetMonitorsResponse = @import("websets/types.zig").ListMonitorsResponse;
pub const ListWebsetMonitorRunsResponse = @import("websets/types.zig").ListMonitorRunsResponse;
pub const ListImportsResponse = @import("websets/types.zig").ListImportsResponse;

// ---------------------------------------------------------------------------
// Websets — event types
// ---------------------------------------------------------------------------

pub const WebsetEventData = @import("websets/types.zig").WebsetEvent_data;
pub const WebsetCreatedEvent = @import("websets/types.zig").WebsetCreatedEvent;
pub const WebsetDeletedEvent = @import("websets/types.zig").WebsetDeletedEvent;
pub const WebsetIdleEvent = @import("websets/types.zig").WebsetIdleEvent;
pub const WebsetPausedEvent = @import("websets/types.zig").WebsetPausedEvent;
pub const WebsetItemCreatedEvent = @import("websets/types.zig").WebsetItemCreatedEvent;
pub const WebsetItemEnrichedEvent = @import("websets/types.zig").WebsetItemEnrichedEvent;
pub const WebsetSearchCreatedEvent = @import("websets/types.zig").WebsetSearchCreatedEvent;
pub const WebsetSearchUpdatedEvent = @import("websets/types.zig").WebsetSearchUpdatedEvent;
pub const WebsetSearchCanceledEvent = @import("websets/types.zig").WebsetSearchCanceledEvent;
pub const WebsetSearchCompletedEvent = @import("websets/types.zig").WebsetSearchCompletedEvent;
pub const WebsetImportCreatedEvent = @import("websets/types.zig").ImportCreatedEvent;
pub const WebsetImportCompletedEvent = @import("websets/types.zig").ImportCompletedEvent;
pub const WebsetMonitorCreatedEvent = @import("websets/types.zig").MonitorCreatedEvent;
pub const WebsetMonitorUpdatedEvent = @import("websets/types.zig").MonitorUpdatedEvent;
pub const WebsetMonitorDeletedEvent = @import("websets/types.zig").MonitorDeletedEvent;
pub const WebsetMonitorRunCreatedEvent = @import("websets/types.zig").MonitorRunCreatedEvent;
pub const WebsetMonitorRunCompletedEvent = @import("websets/types.zig").MonitorRunCompletedEvent;
pub const WebsetEvent = @import("websets/types.zig").WebsetEvent;
pub const ListEventsResponse = @import("websets/types.zig").ListEventsResponse;

// ---------------------------------------------------------------------------
// Research — enumerations
// ---------------------------------------------------------------------------

pub const ResearchModel = @import("research/types.zig").ResearchModel;
pub const ResearchStatus = @import("research/types.zig").ResearchStatus;
pub const ResearchSearchType = @import("research/types.zig").ResearchSearchType;

// ---------------------------------------------------------------------------
// Research — operation types
// ---------------------------------------------------------------------------

pub const ResearchResult = @import("research/types.zig").ResearchResult;
pub const ResearchThinkOperation = @import("research/types.zig").ResearchThinkOperation;
pub const ResearchSearchOperation = @import("research/types.zig").ResearchSearchOperation;
pub const ResearchCrawlOperation = @import("research/types.zig").ResearchCrawlOperation;
pub const ResearchOperation = @import("research/types.zig").ResearchOperation;

// ---------------------------------------------------------------------------
// Research — event types
// ---------------------------------------------------------------------------

pub const ResearchDefinitionEvent = @import("research/types.zig").ResearchDefinitionEvent;
pub const ResearchCostDollars = @import("research/types.zig").ResearchCostDollars;
pub const ResearchOutputCompleted = @import("research/types.zig").ResearchOutputCompleted;
pub const ResearchOutputFailed = @import("research/types.zig").ResearchOutputFailed;
pub const ResearchOutputEvent = @import("research/types.zig").ResearchOutputEvent;
pub const ResearchPlanDefinitionEvent = @import("research/types.zig").ResearchPlanDefinitionEvent;
pub const ResearchPlanOperationEvent = @import("research/types.zig").ResearchPlanOperationEvent;
pub const ResearchPlanOutputTasks = @import("research/types.zig").ResearchPlanOutputTasks;
pub const ResearchPlanOutputStop = @import("research/types.zig").ResearchPlanOutputStop;
pub const ResearchPlanOutputEvent = @import("research/types.zig").ResearchPlanOutputEvent;
pub const ResearchTaskDefinitionEvent = @import("research/types.zig").ResearchTaskDefinitionEvent;
pub const ResearchTaskOperationEvent = @import("research/types.zig").ResearchTaskOperationEvent;
pub const ResearchTaskOutput = @import("research/types.zig").ResearchTaskOutput;
pub const ResearchTaskOutputEvent = @import("research/types.zig").ResearchTaskOutputEvent;
pub const ResearchEvent = @import("research/types.zig").ResearchEvent;

// ---------------------------------------------------------------------------
// Research — DTO types
// ---------------------------------------------------------------------------

pub const ResearchOutput = @import("research/types.zig").ResearchOutput;
pub const ResearchBaseDto = @import("research/types.zig").ResearchBaseDto;
pub const ResearchDto = @import("research/types.zig").ResearchDto;
pub const ListResearchResponseDto = @import("research/types.zig").ListResearchResponseDto;
pub const ResearchCreateRequestDto = @import("research/types.zig").ResearchCreateRequestDto;

// ---------------------------------------------------------------------------
// Search Monitors — enumerations
// ---------------------------------------------------------------------------

pub const SearchMonitorStatus = @import("monitors/types.zig").SearchMonitorStatus;
pub const SearchMonitorRunStatus = @import("monitors/types.zig").SearchMonitorRunStatus;
pub const SearchMonitorRunFailReason = @import("monitors/types.zig").SearchMonitorRunFailReason;
pub const SearchMonitorWebhookEvent = @import("monitors/types.zig").SearchMonitorWebhookEvent;

// ---------------------------------------------------------------------------
// Search Monitors — content option types
// ---------------------------------------------------------------------------

pub const SearchMonitorTextContents = @import("monitors/types.zig").SearchMonitorTextContents;
pub const SearchMonitorHighlightsContents = @import("monitors/types.zig").SearchMonitorHighlightsContents;
pub const SearchMonitorSummaryContents = @import("monitors/types.zig").SearchMonitorSummaryContents;
pub const SearchMonitorExtrasContents = @import("monitors/types.zig").SearchMonitorExtrasContents;
pub const SearchMonitorContents = @import("monitors/types.zig").SearchMonitorContents;

// ---------------------------------------------------------------------------
// Search Monitors — core struct types
// ---------------------------------------------------------------------------

pub const SearchMonitorSearch = @import("monitors/types.zig").SearchMonitorSearch;
pub const SearchMonitorTrigger = @import("monitors/types.zig").SearchMonitorTrigger;
pub const SearchMonitorWebhook = @import("monitors/types.zig").SearchMonitorWebhook;
pub const SearchMonitorGroundingCitation = @import("monitors/types.zig").GroundingCitation;
pub const SearchMonitorGroundingEntry = @import("monitors/types.zig").GroundingEntry;
pub const SearchMonitorRunOutput = @import("monitors/types.zig").SearchMonitorRunOutput;
pub const SearchMonitor = @import("monitors/types.zig").SearchMonitor;
pub const CreateSearchMonitorResponse = @import("monitors/types.zig").CreateSearchMonitorResponse;
pub const SearchMonitorRun = @import("monitors/types.zig").SearchMonitorRun;
pub const CreateSearchMonitorParams = @import("monitors/types.zig").CreateSearchMonitorParams;
pub const UpdateSearchMonitorParams = @import("monitors/types.zig").UpdateSearchMonitorParams;
pub const TriggerSearchMonitorResponse = @import("monitors/types.zig").TriggerSearchMonitorResponse;
pub const ListSearchMonitorsResponse = @import("monitors/types.zig").ListSearchMonitorsResponse;
pub const ListSearchMonitorRunsResponse = @import("monitors/types.zig").ListSearchMonitorRunsResponse;

// ---------------------------------------------------------------------------
// Subsystem client types (for use in struct fields, function signatures, etc.)
// ---------------------------------------------------------------------------

pub const WebsetsClient = @import("websets/client.zig").WebsetsClient;
pub const WebsetItemsClient = @import("websets/items.zig").WebsetItemsClient;
pub const WebsetSearchesClient = @import("websets/searches.zig").WebsetSearchesClient;
pub const WebsetEnrichmentsClient = @import("websets/enrichments.zig").WebsetEnrichmentsClient;
pub const WebsetWebhooksClient = @import("websets/webhooks.zig").WebsetWebhooksClient;
pub const WebsetMonitorsSubClient = @import("websets/monitors.zig").WebsetMonitorsClient;
pub const WebsetImportsClient = @import("websets/imports.zig").WebsetImportsClient;
pub const WebsetEventsClient = @import("websets/events.zig").WebsetEventsClient;
pub const ResearchClient = @import("research/client.zig").ResearchClient;
pub const ResearchStreamIterator = @import("research/client.zig").ResearchStreamIterator;
pub const SearchMonitorsClient = @import("monitors/client.zig").SearchMonitorsClient;
pub const SearchMonitorRunsClient = @import("monitors/client.zig").SearchMonitorRunsClient;

// ---------------------------------------------------------------------------
// Subsystem namespaces (for direct method access via client.websets, etc.)
// ---------------------------------------------------------------------------

pub const websets = @import("websets/root.zig");
pub const research = @import("research/root.zig");
pub const monitors = @import("monitors/root.zig");

// ---------------------------------------------------------------------------
// Internal namespaces (available for advanced / testing use)
// ---------------------------------------------------------------------------

pub const types = @import("types.zig");
pub const utils = @import("utils.zig");
pub const json_utils = @import("json_utils.zig");
