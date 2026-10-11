-- Private mystery-card lookup was not included in the release. Consumers
-- already fall back to the server-provided MantraName; do not invent mappings.
warn("[Project Rain] Mystery-card lookup unavailable; using live names where supplied.");
return {};
