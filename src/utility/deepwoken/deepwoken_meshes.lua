local data = require("@src/utility/string_map")(inline_asset_b96("@assets/deepwoken_meshes.json"));
-- The release contains one percent-encoded space-padded ID; ESP uses bare digits.
data["2877143560"] = data["2877143560"] or data["%202877143560%20"];
return data;
