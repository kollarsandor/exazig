/**
 * exazig — C API for the Exa AI client library.
 *
 * Build the C-compatible static library with:
 *     zig build                       # produces zig-out/lib/libexazig_c.a
 *                                     #      and zig-out/include/exazig.h
 *
 * Link your C project with:
 *     -L$(ZIG_OUT)/lib -lexazig_c
 *     -I$(ZIG_OUT)/include
 *
 * All strings returned by accessor functions are owned by the parent struct
 * and remain valid until that struct is freed.  Do NOT free individual
 * strings — free the parent with the corresponding *_free() function.
 *
 * Thread-safety: each ExaClient may only be used from one thread at a time.
 */

#ifndef EXAZIG_H
#define EXAZIG_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* -------------------------------------------------------------------------
 * Error codes
 * ---------------------------------------------------------------------- */

typedef enum {
    EXA_OK               = 0,
    EXA_ERR_MISSING_KEY  = 1,  /**< EXA_API_KEY not set and no key provided */
    EXA_ERR_NETWORK      = 2,  /**< HTTP or TLS error */
    EXA_ERR_PARSE        = 3,  /**< Unexpected API response format */
    EXA_ERR_OOM          = 4,  /**< Out of memory */
    EXA_ERR_TIMEOUT      = 5,  /**< Operation timed out */
    EXA_ERR_INVALID_ARG  = 6,  /**< NULL or invalid argument passed */
    EXA_ERR_UNKNOWN      = 99,
} ExaErrorCode;

/* -------------------------------------------------------------------------
 * Opaque handle types
 * ---------------------------------------------------------------------- */

/** Top-level Exa client.  Create with exa_client_create(); free with
 *  exa_client_destroy(). */
typedef struct ExaClient ExaClient;

/** A list of search / contents / findSimilar results.  Free with
 *  exa_search_results_free(). */
typedef struct ExaSearchResults ExaSearchResults;

/** An answer response.  Free with exa_answer_free(). */
typedef struct ExaAnswerResponse ExaAnswerResponse;

/* -------------------------------------------------------------------------
 * Client lifecycle
 * ---------------------------------------------------------------------- */

/**
 * Create an Exa client.
 *
 * @param api_key    Your Exa API key, or NULL to read EXA_API_KEY from the
 *                   environment.
 * @param base_url   Override the API base URL, or NULL for the default
 *                   (https://api.exa.ai).
 * @param user_agent Override the User-Agent header, or NULL for the default.
 * @param err_out    If non-NULL, receives the error code on failure.
 * @return           New ExaClient, or NULL on error.
 */
ExaClient* exa_client_create(
    const char*   api_key,
    const char*   base_url,
    const char*   user_agent,
    ExaErrorCode* err_out
);

/**
 * Destroy an Exa client and release all associated resources.
 * Passing NULL is a no-op.
 */
void exa_client_destroy(ExaClient* client);

/* -------------------------------------------------------------------------
 * Search
 * ---------------------------------------------------------------------- */

/**
 * Perform an Exa search.
 *
 * @param client      Client created with exa_client_create().
 * @param query       Search query string (UTF-8, null-terminated).
 * @param num_results Number of results to request (<= 0 → server default).
 * @param err_out     If non-NULL, receives the error code on failure.
 * @return            New ExaSearchResults, or NULL on error.  Free with
 *                    exa_search_results_free().
 */
ExaSearchResults* exa_search(
    ExaClient*    client,
    const char*   query,
    int           num_results,
    ExaErrorCode* err_out
);

/**
 * Retrieve page contents for the given URLs.
 *
 * @param client    Client created with exa_client_create().
 * @param urls      Array of null-terminated URL strings.
 * @param url_count Number of entries in the urls array.
 * @param err_out   If non-NULL, receives the error code on failure.
 * @return          New ExaSearchResults, or NULL on error.
 */
ExaSearchResults* exa_get_contents(
    ExaClient*    client,
    const char**  urls,
    size_t        url_count,
    ExaErrorCode* err_out
);

/**
 * Find pages similar to the given URL.
 *
 * @param client      Client created with exa_client_create().
 * @param url         Source URL (UTF-8, null-terminated).
 * @param num_results Number of results to request (<= 0 → server default).
 * @param err_out     If non-NULL, receives the error code on failure.
 * @return            New ExaSearchResults, or NULL on error.
 */
ExaSearchResults* exa_find_similar(
    ExaClient*    client,
    const char*   url,
    int           num_results,
    ExaErrorCode* err_out
);

/** Free a search results object.  Passing NULL is a no-op. */
void exa_search_results_free(ExaSearchResults* results);

/** Return the number of results in the response. */
size_t exa_search_results_count(const ExaSearchResults* results);

/**
 * Return the URL of result at the given index.
 * Valid until exa_search_results_free() is called.
 * Returns NULL if results is NULL or index is out of range.
 */
const char* exa_result_url(const ExaSearchResults* results, size_t index);

/**
 * Return the unique ID of result at the given index.
 * Valid until exa_search_results_free() is called.
 */
const char* exa_result_id(const ExaSearchResults* results, size_t index);

/**
 * Return the page title of result at the given index, or NULL if not present.
 * Valid until exa_search_results_free() is called.
 */
const char* exa_result_title(const ExaSearchResults* results, size_t index);

/**
 * Return the relevance score of result at the given index.
 *
 * @param has_score  If non-NULL, set to 1 when the score is present, 0 when
 *                   not available.
 * @return           Score value, or 0.0 if not present.
 */
double exa_result_score(
    const ExaSearchResults* results,
    size_t                  index,
    int*                    has_score
);

/**
 * Return the extracted page text for result at the given index, or NULL if
 * text was not requested or is not available.
 * Valid until exa_search_results_free() is called.
 */
const char* exa_result_text(const ExaSearchResults* results, size_t index);

/**
 * Return the AI-generated summary for result at the given index, or NULL if
 * a summary was not requested or is not available.
 * Valid until exa_search_results_free() is called.
 */
const char* exa_result_summary(const ExaSearchResults* results, size_t index);

/* -------------------------------------------------------------------------
 * Answer
 * ---------------------------------------------------------------------- */

/**
 * Ask Exa a question and receive an AI-generated answer with citations.
 *
 * @param client  Client created with exa_client_create().
 * @param query   Question string (UTF-8, null-terminated).
 * @param err_out If non-NULL, receives the error code on failure.
 * @return        New ExaAnswerResponse, or NULL on error.  Free with
 *                exa_answer_free().
 */
ExaAnswerResponse* exa_answer(
    ExaClient*    client,
    const char*   query,
    ExaErrorCode* err_out
);

/** Free an answer response.  Passing NULL is a no-op. */
void exa_answer_free(ExaAnswerResponse* answer);

/**
 * Return the plain-text answer string, or NULL if the answer is a structured
 * JSON object (check exa_answer_json() in that case).
 * Valid until exa_answer_free() is called.
 */
const char* exa_answer_text(const ExaAnswerResponse* answer);

/**
 * Return the structured answer as a JSON string, or NULL if the answer is
 * plain text (check exa_answer_text() in that case).
 * Valid until exa_answer_free() is called.
 */
const char* exa_answer_json(const ExaAnswerResponse* answer);

/** Return the number of citations for the answer. */
size_t exa_answer_citations_count(const ExaAnswerResponse* answer);

/**
 * Return the unique ID of citation at the given index.
 * Valid until exa_answer_free() is called.
 */
const char* exa_answer_citation_id(
    const ExaAnswerResponse* answer,
    size_t                   index
);

/**
 * Return the URL of citation at the given index.
 * Valid until exa_answer_free() is called.
 */
const char* exa_answer_citation_url(
    const ExaAnswerResponse* answer,
    size_t                   index
);

/**
 * Return the title of citation at the given index, or NULL if not present.
 * Valid until exa_answer_free() is called.
 */
const char* exa_answer_citation_title(
    const ExaAnswerResponse* answer,
    size_t                   index
);

/* -------------------------------------------------------------------------
 * Misc
 * ---------------------------------------------------------------------- */

/** Return the exazig library version string (e.g. "2.11.0"). */
const char* exa_version(void);

#ifdef __cplusplus
}
#endif
#endif /* EXAZIG_H */
