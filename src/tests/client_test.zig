const std = @import("std");
const exa = @import("exa");
const Exa = exa.Exa;

test "Exa init missing api key" {
    const allocator = std.testing.allocator;

    // Test that init returns error.MissingApiKey when no key is available.
    // We pass null and rely on the absence of EXA_API_KEY in the test environment.
    const result = Exa.init(allocator, null, null, null);
    if (result) |e| {
        // Key was found in environment — that's OK, deinit and skip assertion
        var mutable_exa = e;
        mutable_exa.deinit();
    } else |err| {
        try std.testing.expectEqual(error.MissingApiKey, err);
    }
}

test "Exa init with explicit key" {
    const allocator = std.testing.allocator;

    var client = try Exa.init(allocator, "test-api-key-12345", "https://api.exa.ai", "test-agent/1.0");
    defer client.deinit();

    // Verify the api key header was stored correctly
    const stored_key = client.http.headers.get("x-api-key");
    try std.testing.expect(stored_key != null);
    try std.testing.expectEqualStrings("test-api-key-12345", stored_key.?);
}

test "Exa init with custom base url" {
    const allocator = std.testing.allocator;

    var client = try Exa.init(allocator, "my-key", "https://custom.api.exa.ai", null);
    defer client.deinit();

    try std.testing.expectEqualStrings("https://custom.api.exa.ai", client.http.base_url);
}
